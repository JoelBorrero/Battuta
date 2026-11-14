/// Battuta — Local LAN WebSocket Live Stage Synchronization Service.
///
/// Implements [LiveSyncService] using pure `dart:io` WebSockets and HTTP server.
/// Features Director/Follower coordination, LeaderLock conflict resolution,
/// and automatic 2-measure lookahead stage cue emissions.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/models/live_join_address.dart';
import '../domain/models/sync_cue_payload.dart';
import '../domain/services/live_sync_service.dart';

/// Why a follower could not join.
enum LiveConnectFailure { timeout, unreachable }

/// Thrown by [LanWebSocketSyncService.connect]. [message] is English, for
/// logs; the UI maps [reason] to a localized string.
class LiveConnectException implements Exception {
  const LiveConnectException(this.reason, this.message);

  final LiveConnectFailure reason;
  final String message;

  @override
  String toString() => 'LiveConnectException: $message';
}

class LanWebSocketSyncService implements LiveSyncService {
  LanWebSocketSyncService({
    LiveSyncMode initialMode = LiveSyncMode.follower,
    this.deviceName = 'Battuta',
    this.connectTimeout = const Duration(seconds: 5),
    this.reconnectDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 5),
    ],
  }) : _mode = initialMode;

  /// Sent to the director as `hello` so it can list who is connected.
  String deviceName;

  /// How long a follower waits for the director before giving up.
  final Duration connectTimeout;

  /// Waits between reconnect attempts; the last one repeats until Leave.
  final List<Duration> reconnectDelays;

  /// Address and port of the director this follower belongs to, kept so a
  /// dropped connection can be re-established. `null` when not following.
  ({String host, int port})? _target;

  /// Bumped on every connect / disconnect so a stale reconnect loop stops.
  int _generation = 0;

  LiveSyncStatus _status = LiveSyncStatus.disconnected;
  LiveSyncMode _mode;
  String? _activeSectionId;
  String? _queuedSectionId;

  int _sequenceNumber = 0;
  int _lastSeenSequenceNumber = -1;

  HttpServer? _server;
  final List<WebSocket> _connectedClients = [];
  final Map<WebSocket, String> _clientNames = {};
  WebSocket? _clientSocket;
  StreamSubscription<dynamic>? _clientSub;

  final _followersController = StreamController<List<String>>.broadcast();
  final _statusController = StreamController<LiveSyncStatus>.broadcast();
  final _activeSectionController = StreamController<String>.broadcast();
  final _queuedSectionController = StreamController<String>.broadcast();
  final _cueController = StreamController<SyncCuePayload>.broadcast();
  final _followerRequestController =
      StreamController<SyncCuePayload>.broadcast();

  final List<SyncCuePayload> _pendingFollowerRequests = [];

  @override
  LiveSyncStatus get status => _status;

  @override
  Stream<LiveSyncStatus> get statusStream => _statusController.stream;

  @override
  LiveSyncMode get mode => _mode;

  @override
  String? get activeSectionId => _activeSectionId;

  @override
  Stream<String> get activeSectionStream => _activeSectionController.stream;

  @override
  String? get queuedSectionId => _queuedSectionId;

  @override
  Stream<String> get queuedSectionStream => _queuedSectionController.stream;

  /// Stream of full incoming stage cue payloads.
  Stream<SyncCuePayload> get cueStream => _cueController.stream;

  /// Stream of follower override requests queued by director's LeaderLock.
  Stream<SyncCuePayload> get followerRequestStream =>
      _followerRequestController.stream;

  /// In-memory queue of pending follower transition requests held by director.
  List<SyncCuePayload> get pendingFollowerRequests =>
      List.unmodifiable(_pendingFollowerRequests);

  /// Current bound server port if director server is running, or null.
  int? get serverPort => _server?.port;

  /// The address the director server is bound to, or null.
  InternetAddress? get serverAddress => _server?.address;

  /// Number of active connected follower clients (Director mode).
  int get connectedFollowersCount => _connectedClients.length;

  /// Device names of the connected followers, in connection order. A follower
  /// that has not said hello yet is listed as an empty name.
  List<String> get followerNames => [
    for (final c in _connectedClients) _clientNames[c] ?? '',
  ];

  /// Emits [followerNames] whenever a follower joins, leaves or says hello.
  Stream<List<String>> get followersStream => _followersController.stream;

  @override
  void setSyncMode(LiveSyncMode mode) {
    _mode = mode;
  }

  /// Starts the Director WebSocket server on [address] (an [InternetAddress]
  /// or host string; every IPv4 interface by default, so other devices can reach it) and [port].
  ///
  /// When [port] is taken an ephemeral port is used instead; passing
  /// `port: 0` asks for one straight away. Returns the bound port.
  Future<int> startDirectorServer({
    Object? address,
    int port = liveDefaultPort,
  }) {
    // Calls run one after the other: each one closes what the previous one
    // bound before binding, so two taps never leave a server behind.
    final previous = _hostTail;
    final run = previous == null
        ? _bindDirectorServer(address, port)
        : previous.then((_) => _bindDirectorServer(address, port));
    final tail = run.then<void>((_) {}, onError: (Object _) {});
    _hostTail = tail;
    unawaited(
      tail.whenComplete(() {
        if (identical(_hostTail, tail)) _hostTail = null;
      }),
    );
    return run;
  }

  /// The last queued hosting start, or `null` when none is running.
  Future<void>? _hostTail;

  Future<int> _bindDirectorServer(Object? address, int port) async {
    await disconnect();
    _mode = LiveSyncMode.director;
    _setStatus(LiveSyncStatus.connecting);

    final Object bindAddress = address ?? InternetAddress.anyIPv4;
    HttpServer server;
    try {
      server = await HttpServer.bind(bindAddress, port);
    } on SocketException {
      if (port == 0) {
        _setStatus(LiveSyncStatus.error);
        rethrow;
      }
      try {
        server = await HttpServer.bind(bindAddress, 0);
      } on SocketException {
        _setStatus(LiveSyncStatus.error);
        rethrow;
      }
    }
    _server = server;

    server
        .transform(WebSocketTransformer())
        .listen(
          _handleDirectorIncomingClient,
          onError: (Object error) {
            _setStatus(LiveSyncStatus.error);
          },
        );

    _setStatus(LiveSyncStatus.connected);
    return server.port;
  }

  @override
  Future<void> connect(String host, int port, {String? token}) async {
    await disconnect();
    final generation = _generation;
    _setStatus(LiveSyncStatus.connecting);

    _target = (host: host, port: port);
    try {
      await _openSocket(host, port, generation);
    } on LiveConnectException {
      // A newer connect / Leave owns the state now; only report to the caller.
      if (generation == _generation) {
        _target = null;
        _setStatus(LiveSyncStatus.error);
      }
      rethrow;
    }
  }

  /// Opens the follower socket and starts listening. Throws
  /// [LiveConnectException] on timeout or when nothing answers.
  Future<void> _openSocket(String host, int port, int generation) async {
    final attempt = WebSocket.connect('ws://$host:$port');
    final WebSocket socket;
    try {
      socket = await attempt.timeout(connectTimeout);
    } on TimeoutException {
      // The attempt may still finish later; never leave that socket open.
      unawaited(attempt.then((s) => s.close()).catchError((Object _) => null));
      throw const LiveConnectException(
        LiveConnectFailure.timeout,
        'The director did not answer in time.',
      );
    } on Exception catch (error) {
      throw LiveConnectException(
        LiveConnectFailure.unreachable,
        'Could not reach the director: $error',
      );
    }

    if (generation != _generation) {
      // Left (or joined elsewhere) while connecting.
      await socket.close();
      return;
    }
    _clientSocket = socket;
    // A new socket may reach a relaunched director whose numbering starts
    // over, so nothing seen on the old one counts any more.
    _lastSeenSequenceNumber = -1;
    _activeSectionId = null;
    _queuedSectionId = null;
    _setStatus(LiveSyncStatus.connected);
    _sendToDirector({'type': 'hello', 'deviceName': deviceName});

    _clientSub = socket.listen(
      (dynamic data) => _handleFollowerIncomingMessage(data),
      onDone: () => _onFollowerSocketClosed(socket),
      onError: (Object _) => _onFollowerSocketClosed(socket),
    );
  }

  void _onFollowerSocketClosed(WebSocket socket) {
    if (!identical(socket, _clientSocket) || _target == null) return;
    _clientSocket = null;
    _clientSub = null;
    unawaited(_reconnect(_generation));
  }

  /// Retries until it connects or [disconnect] / [connect] bumps the
  /// generation (Leave).
  Future<void> _reconnect(int generation) async {
    final target = _target;
    if (target == null || reconnectDelays.isEmpty) {
      _setStatus(LiveSyncStatus.disconnected);
      return;
    }
    _setStatus(LiveSyncStatus.reconnecting);
    var attempt = 0;
    while (generation == _generation) {
      final index = attempt < reconnectDelays.length
          ? attempt
          : reconnectDelays.length - 1;
      await Future<void>.delayed(reconnectDelays[index]);
      if (generation != _generation) return;
      try {
        await _openSocket(target.host, target.port, generation);
        return;
      } on LiveConnectException {
        attempt++;
      }
    }
  }

  static Future<void> _closeQuietly(WebSocket socket) async {
    try {
      await socket.close().timeout(const Duration(seconds: 1));
    } catch (_) {
      // Already gone or unresponsive: nothing more to do.
    }
  }

  @override
  Future<void> disconnect() async {
    _generation++;
    _target = null;
    await _clientSub?.cancel();
    _clientSub = null;

    final socket = _clientSocket;
    _clientSocket = null;

    final clients = List.of(_connectedClients);
    _connectedClients.clear();
    _clientNames.clear();
    // In parallel and bounded: a peer that vanished from Wi-Fi never answers
    // the close handshake, and Leave / End must not wait for it.
    await Future.wait([
      if (socket != null) _closeQuietly(socket),
      for (final client in clients) _closeQuietly(client),
    ]);
    if (clients.isNotEmpty) _followersController.add(const []);

    if (_server != null) {
      await _server?.close(force: true);
      _server = null;
    }

    _activeSectionId = null;
    _queuedSectionId = null;
    _lastSeenSequenceNumber = -1;
    _setStatus(LiveSyncStatus.disconnected);
  }

  @override
  Future<void> queueNextSection(
    String sectionId, {
    String? externalSyncId,
  }) async {
    if (_mode == LiveSyncMode.director) {
      _sequenceNumber++;
      _queuedSectionId = sectionId;
      _queuedSectionController.add(sectionId);

      _broadcastJson({
        'type': 'queue',
        'sectionId': sectionId,
        'externalSyncId': externalSyncId,
        'sequenceNumber': _sequenceNumber,
        'leaderTimestampMs': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      // Follower attempting to queue next section -> sends request to director
      _sendToDirector({
        'type': 'follower_request',
        'action': 'queue',
        'sectionId': sectionId,
        'externalSyncId': externalSyncId,
        'timestampMs': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  @override
  Future<void> jumpNowSection(
    String sectionId, {
    String? externalSyncId,
  }) async {
    if (_mode == LiveSyncMode.director) {
      _sequenceNumber++;
      _activeSectionId = sectionId;
      _activeSectionController.add(sectionId);

      _broadcastJson({
        'type': 'jump',
        'sectionId': sectionId,
        'externalSyncId': externalSyncId,
        'sequenceNumber': _sequenceNumber,
        'leaderTimestampMs': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      // Follower attempting override -> LeaderLock sends request to director
      _sendToDirector({
        'type': 'follower_request',
        'action': 'jump',
        'sectionId': sectionId,
        'externalSyncId': externalSyncId,
        'timestampMs': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  @override
  Future<void> clearQueuedSection() async {
    if (_mode == LiveSyncMode.director) {
      _sequenceNumber++;
      _queuedSectionId = null;
      _broadcastJson({
        'type': 'clear_queue',
        'sequenceNumber': _sequenceNumber,
        'leaderTimestampMs': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  /// Calculates and broadcasts an automatic 2-measure lookahead cue.
  ///
  /// For instance, if performing measure 14, [triggerMeasureIndex] resolves to 16.
  SyncCuePayload emitLookaheadCue({
    required String songId,
    required String currentSectionId,
    required String nextSectionLabel,
    required int currentMeasureIndex,
    int lookaheadMeasures = 2,
  }) {
    _sequenceNumber++;
    final triggerMeasure = currentMeasureIndex + lookaheadMeasures;
    final payload = SyncCuePayload(
      songId: songId,
      currentSectionId: currentSectionId,
      nextSectionLabel: nextSectionLabel,
      triggerMeasureIndex: triggerMeasure,
      leaderTimestampMs: DateTime.now().millisecondsSinceEpoch,
      sequenceNumber: _sequenceNumber,
    );

    _queuedSectionId = nextSectionLabel;
    _queuedSectionController.add(nextSectionLabel);
    _cueController.add(payload);

    if (_mode == LiveSyncMode.director) {
      _broadcastJson({'type': 'cue', 'payload': payload.toJson()});
    }

    return payload;
  }

  /// Helper to calculate lookahead trigger measure pure calculation.
  static int calculateLookaheadMeasure(
    int currentMeasureIndex, {
    int lookaheadMeasures = 2,
  }) {
    return currentMeasureIndex + lookaheadMeasures;
  }

  void _setStatus(LiveSyncStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(newStatus);
    }
  }

  void _handleDirectorIncomingClient(WebSocket client) {
    _connectedClients.add(client);
    _followersController.add(followerNames);

    void dropped() {
      if (_connectedClients.remove(client)) {
        _clientNames.remove(client);
        _followersController.add(followerNames);
      }
    }

    client.listen(
      (dynamic data) {
        _handleDirectorIncomingMessage(client, data);
      },
      onDone: dropped,
      onError: (Object _) => dropped(),
    );
  }

  void _handleDirectorIncomingMessage(WebSocket sender, dynamic data) {
    try {
      final json = jsonDecode(data.toString()) as Map<String, dynamic>;
      final type = json['type'] as String?;

      if (type == 'hello') {
        final name = (json['deviceName'] as String?)?.trim() ?? '';
        if (_connectedClients.contains(sender)) {
          _clientNames[sender] = name;
          _followersController.add(followerNames);
        }
      } else if (type == 'follower_request') {
        // LeaderLock conflict resolution: Follower override attempts are
        // not executed directly on the live stage, but queued as requests.
        final req = SyncCuePayload(
          songId: (json['songId'] as String?) ?? '',
          currentSectionId: (json['sectionId'] as String?) ?? '',
          nextSectionLabel: 'REQUEST: ${json['action']}',
          triggerMeasureIndex: 0,
          leaderTimestampMs:
              (json['timestampMs'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
          sequenceNumber: -1,
        );
        _pendingFollowerRequests.add(req);
        _followerRequestController.add(req);
      }
    } catch (_) {
      // Ignore malformed client frames
    }
  }

  void _handleFollowerIncomingMessage(dynamic data) {
    try {
      final json = jsonDecode(data.toString()) as Map<String, dynamic>;
      final type = json['type'] as String?;
      final seq = json['sequenceNumber'] as int?;

      // LeaderLock monotonic check: Reject out-of-order or stale messages
      if (seq != null && seq <= _lastSeenSequenceNumber) {
        return;
      }
      if (seq != null) {
        _lastSeenSequenceNumber = seq;
      }

      if (type == 'cue') {
        final payloadJson = json['payload'] as Map<String, dynamic>;
        final payload = SyncCuePayload.fromJson(payloadJson);
        if (payload.sequenceNumber <= _lastSeenSequenceNumber &&
            _lastSeenSequenceNumber != payload.sequenceNumber) {
          return;
        }
        _lastSeenSequenceNumber = payload.sequenceNumber;
        _queuedSectionId = payload.nextSectionLabel;
        _queuedSectionController.add(payload.nextSectionLabel);
        _cueController.add(payload);
      } else if (type == 'jump') {
        final secId = json['sectionId'] as String;
        _activeSectionId = secId;
        _activeSectionController.add(secId);
      } else if (type == 'queue') {
        final secId = json['sectionId'] as String;
        _queuedSectionId = secId;
        _queuedSectionController.add(secId);
      } else if (type == 'clear_queue') {
        _queuedSectionId = null;
      }
    } catch (_) {
      // Ignore malformed director frames
    }
  }

  void _broadcastJson(Map<String, dynamic> data) {
    final text = jsonEncode(data);
    for (final client in _connectedClients) {
      try {
        client.add(text);
      } catch (_) {
        // Socket may have disconnected
      }
    }
  }

  void _sendToDirector(Map<String, dynamic> data) {
    final socket = _clientSocket;
    if (socket != null) {
      try {
        socket.add(jsonEncode(data));
      } catch (_) {
        // Socket closed
      }
    }
  }

  /// Disposes internal controllers and resources.
  Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
    await _activeSectionController.close();
    await _queuedSectionController.close();
    await _cueController.close();
    await _followerRequestController.close();
    await _followersController.close();
  }
}
