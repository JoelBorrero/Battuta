/// Battuta — Local LAN WebSocket Live Stage Synchronization Service.
///
/// Implements [LiveSyncService] using pure `dart:io` WebSockets and HTTP server.
/// Features Director/Follower coordination, LeaderLock conflict resolution,
/// and automatic 2-measure lookahead stage cue emissions.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/models/sync_cue_payload.dart';
import '../domain/services/live_sync_service.dart';

class LanWebSocketSyncService implements LiveSyncService {
  LanWebSocketSyncService({LiveSyncMode initialMode = LiveSyncMode.follower})
    : _mode = initialMode;

  LiveSyncStatus _status = LiveSyncStatus.disconnected;
  LiveSyncMode _mode;
  String? _activeSectionId;
  String? _queuedSectionId;

  int _sequenceNumber = 0;
  int _lastSeenSequenceNumber = -1;

  HttpServer? _server;
  final List<WebSocket> _connectedClients = [];
  WebSocket? _clientSocket;
  StreamSubscription<dynamic>? _clientSub;

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

  /// Number of active connected follower clients (Director mode).
  int get connectedFollowersCount => _connectedClients.length;

  @override
  void setSyncMode(LiveSyncMode mode) {
    _mode = mode;
  }

  /// Starts the Director WebSocket server on [address] and [port].
  ///
  /// Passing `port: 0` binds to an available ephemeral port on the host.
  Future<int> startDirectorServer({
    String address = '127.0.0.1',
    int port = 0,
  }) async {
    await disconnect();
    _mode = LiveSyncMode.director;
    _setStatus(LiveSyncStatus.connecting);

    final server = await HttpServer.bind(address, port);
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
    _setStatus(LiveSyncStatus.connecting);

    try {
      final wsUrl = 'ws://$host:$port';
      final socket = await WebSocket.connect(wsUrl);
      _clientSocket = socket;
      _setStatus(LiveSyncStatus.connected);

      _clientSub = socket.listen(
        (dynamic data) => _handleFollowerIncomingMessage(data),
        onDone: () {
          _setStatus(LiveSyncStatus.disconnected);
        },
        onError: (Object _) {
          _setStatus(LiveSyncStatus.error);
        },
      );
    } catch (_) {
      _setStatus(LiveSyncStatus.error);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _clientSub?.cancel();
    _clientSub = null;

    if (_clientSocket != null) {
      await _clientSocket?.close();
      _clientSocket = null;
    }

    for (final client in _connectedClients) {
      await client.close();
    }
    _connectedClients.clear();

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

    client.listen(
      (dynamic data) {
        _handleDirectorIncomingMessage(client, data);
      },
      onDone: () {
        _connectedClients.remove(client);
      },
      onError: (Object _) {
        _connectedClients.remove(client);
      },
    );
  }

  void _handleDirectorIncomingMessage(WebSocket sender, dynamic data) {
    try {
      final json = jsonDecode(data.toString()) as Map<String, dynamic>;
      final type = json['type'] as String?;

      if (type == 'follower_request') {
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
  }
}
