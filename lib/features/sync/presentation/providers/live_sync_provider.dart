/// Battuta — Live Stage Synchronization Riverpod Provider.
///
/// Bridges [LiveSyncService] streams to reactive UI state for stage cue banners,
/// director control bars, and live musician devices.
library;

import 'dart:async';
import 'dart:io';

import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bonsoir_session_discovery.dart';
import '../../data/lan_address_resolver.dart';
import '../../data/lan_websocket_sync_service.dart';
import '../../domain/models/live_join_address.dart';
import '../../domain/models/live_session.dart';
import '../../domain/models/sync_cue_payload.dart';
import '../../domain/services/live_session_discovery.dart';
import '../../domain/services/live_sync_service.dart';

/// Model name of this device ("Pixel 8", "Joel's iPad"), or `null` when the
/// platform has none to give. Replaced in tests through
/// [liveDeviceNameProvider].
final liveDeviceModelProvider = FutureProvider<String?>((ref) async {
  try {
    final plugin = DeviceInfoPlugin();
    final String? name;
    if (Platform.isAndroid) {
      name = (await plugin.androidInfo).model;
    } else if (Platform.isIOS) {
      name = (await plugin.iosInfo).name;
    } else {
      name = null;
    }
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  } catch (_) {
    // No plugin (tests, desktop): fall back below.
  }
  return null;
});

/// Name this device shows to the band: the signed-in profile name, else the
/// device model, else "Battuta device" (never "localhost").
final liveDeviceNameProvider = Provider<String>((ref) {
  final profileName = ref.watch(myProfileProvider).value?.displayName.trim();
  if (profileName != null && profileName.isNotEmpty) return profileName;
  final accountName = ref.watch(currentUserProvider)?.displayName?.trim();
  if (accountName != null && accountName.isNotEmpty) return accountName;
  final model = ref.watch(liveDeviceModelProvider).value;
  if (model != null && model.isNotEmpty) return model;
  return 'Battuta device';
});

/// mDNS discovery of Live sessions. Replaced by a fake in widget tests.
final liveSessionDiscoveryProvider = Provider<LiveSessionDiscovery>(
  (ref) => BonsoirSessionDiscovery(),
);

/// Finds this device's Wi-Fi / hotspot address. Replaced in widget tests.
final lanAddressResolverProvider = Provider<LanAddressResolver>(
  (ref) => const SystemLanAddressResolver(),
);

/// Provider for the underlying [LiveSyncService] implementation.
final liveSyncServiceProvider = Provider<LiveSyncService>((ref) {
  final service = LanWebSocketSyncService(
    deviceName: ref.read(liveDeviceNameProvider),
  );
  // The name may arrive later (profile, device model).
  ref.listen(liveDeviceNameProvider, (_, name) => service.deviceName = name);
  ref.onDispose(() => service.dispose());
  return service;
});

/// What went wrong last when hosting or joining; the UI localizes it.
enum LiveConnectIssue {
  /// Hosting needs a Wi-Fi or hotspot address and there is none.
  noNetwork,
  timeout,
  unreachable,
  hostFailed,
}

@immutable
class LiveSyncUiState {
  const LiveSyncUiState({
    this.status = LiveSyncStatus.disconnected,
    this.mode = LiveSyncMode.follower,
    this.activeSectionId,
    this.queuedSectionLabel,
    this.activeCue,
    this.pendingRequests = const [],
    this.serverPort,
    this.sessions = const [],
    this.searching = false,
    this.searchTimedOut = false,
    this.joinAddress,
    this.followers = const [],
    this.issue,
    this.sessionName = '',
    this.followingAddress,
    this.pendingJoin,
  });

  final LiveSyncStatus status;
  final LiveSyncMode mode;
  final String? activeSectionId;
  final String? queuedSectionLabel;
  final SyncCuePayload? activeCue;
  final List<SyncCuePayload> pendingRequests;
  final int? serverPort;

  /// Sessions found nearby while browsing as a follower.
  final List<LiveSession> sessions;

  /// Browsing is on and nothing has been found yet.
  final bool searching;

  /// Browsing found nothing for 5 seconds (multicast may be blocked).
  final bool searchTimedOut;

  /// Where followers can join this device's hosted session.
  final LiveJoinAddress? joinAddress;

  /// Device names of the followers connected to this host.
  final List<String> followers;
  final LiveConnectIssue? issue;

  /// Name of the session being hosted.
  final String sessionName;

  /// The director this device follows (or is trying to), while it does.
  final LiveJoinAddress? followingAddress;

  /// A link asked to join another session while one is running; the Live
  /// page asks the user before leaving.
  final LiveJoinAddress? pendingJoin;

  bool get isReconnecting => status == LiveSyncStatus.reconnecting;
  bool get isConnected => status == LiveSyncStatus.connected;
  bool get isDirector => mode == LiveSyncMode.director;

  LiveSyncUiState copyWith({
    LiveSyncStatus? status,
    LiveSyncMode? mode,
    String? activeSectionId,
    String? queuedSectionLabel,
    SyncCuePayload? activeCue,
    bool clearActiveCue = false,
    List<SyncCuePayload>? pendingRequests,
    int? serverPort,
    bool clearServerPort = false,
    List<LiveSession>? sessions,
    bool? searching,
    bool? searchTimedOut,
    LiveJoinAddress? joinAddress,
    bool clearJoinAddress = false,
    List<String>? followers,
    LiveConnectIssue? issue,
    bool clearIssue = false,
    String? sessionName,
    LiveJoinAddress? followingAddress,
    bool clearFollowingAddress = false,
    LiveJoinAddress? pendingJoin,
    bool clearPendingJoin = false,
  }) {
    return LiveSyncUiState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      activeSectionId: activeSectionId ?? this.activeSectionId,
      queuedSectionLabel: queuedSectionLabel ?? this.queuedSectionLabel,
      activeCue: clearActiveCue ? null : (activeCue ?? this.activeCue),
      pendingRequests: pendingRequests ?? this.pendingRequests,
      serverPort: clearServerPort ? null : (serverPort ?? this.serverPort),
      sessions: sessions ?? this.sessions,
      searching: searching ?? this.searching,
      searchTimedOut: searchTimedOut ?? this.searchTimedOut,
      joinAddress: clearJoinAddress ? null : (joinAddress ?? this.joinAddress),
      followers: followers ?? this.followers,
      issue: clearIssue ? null : (issue ?? this.issue),
      sessionName: sessionName ?? this.sessionName,
      followingAddress: clearFollowingAddress
          ? null
          : (followingAddress ?? this.followingAddress),
      pendingJoin: clearPendingJoin ? null : (pendingJoin ?? this.pendingJoin),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveSyncUiState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          mode == other.mode &&
          activeSectionId == other.activeSectionId &&
          queuedSectionLabel == other.queuedSectionLabel &&
          activeCue == other.activeCue &&
          listEquals(pendingRequests, other.pendingRequests) &&
          serverPort == other.serverPort &&
          listEquals(sessions, other.sessions) &&
          searching == other.searching &&
          searchTimedOut == other.searchTimedOut &&
          joinAddress == other.joinAddress &&
          listEquals(followers, other.followers) &&
          issue == other.issue &&
          sessionName == other.sessionName &&
          followingAddress == other.followingAddress &&
          pendingJoin == other.pendingJoin;

  @override
  int get hashCode => Object.hash(
    status,
    mode,
    activeSectionId,
    queuedSectionLabel,
    activeCue,
    Object.hashAll(pendingRequests),
    serverPort,
    Object.hashAll(sessions),
    searching,
    searchTimedOut,
    joinAddress,
    Object.hashAll(followers),
    issue,
    sessionName,
    followingAddress,
    pendingJoin,
  );
}

final liveSyncControllerProvider =
    NotifierProvider<LiveSyncNotifier, LiveSyncUiState>(LiveSyncNotifier.new);

class LiveSyncNotifier extends Notifier<LiveSyncUiState> {
  final List<StreamSubscription<dynamic>> _subs = [];
  StreamSubscription<List<LiveSession>>? _browseSub;
  Timer? _searchTimer;

  /// The hosting start in flight; concurrent calls share it.
  Future<bool>? _hosting;

  /// Bumped per join so a superseded attempt cannot touch the state.
  int _joinGeneration = 0;

  /// How long browsing may find nothing before "No sessions found nearby".
  static const _searchTimeout = Duration(seconds: 5);

  @override
  LiveSyncUiState build() {
    final service = ref.watch(liveSyncServiceProvider);
    final discovery = ref.read(liveSessionDiscoveryProvider);

    _listenToService(service);

    ref.onDispose(() {
      // Never leave a ghost session announced on the network.
      unawaited(discovery.stopAdvertising());
      for (final sub in _subs) {
        sub.cancel();
      }
      _subs.clear();
      _browseSub?.cancel();
      _browseSub = null;
      _searchTimer?.cancel();
    });

    return LiveSyncUiState(
      status: service.status,
      mode: service.mode,
      activeSectionId: service.activeSectionId,
      queuedSectionLabel: service.queuedSectionId,
    );
  }

  void _listenToService(LiveSyncService service) {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();

    _subs.add(
      service.statusStream.listen((status) {
        state = state.copyWith(status: status);
        // The host's server died: stop announcing it.
        if (status == LiveSyncStatus.error &&
            service.mode == LiveSyncMode.director) {
          unawaited(ref.read(liveSessionDiscoveryProvider).stopAdvertising());
        }
      }),
    );

    _subs.add(
      service.activeSectionStream.listen((sec) {
        state = state.copyWith(activeSectionId: sec);
      }),
    );

    _subs.add(
      service.queuedSectionStream.listen((sec) {
        state = state.copyWith(queuedSectionLabel: sec);
      }),
    );

    if (service is LanWebSocketSyncService) {
      _subs.add(
        service.cueStream.listen((cue) {
          state = state.copyWith(
            activeCue: cue,
            queuedSectionLabel: cue.nextSectionLabel,
          );
        }),
      );

      _subs.add(
        service.followersStream.listen((names) {
          state = state.copyWith(followers: names);
        }),
      );

      _subs.add(
        service.followerRequestStream.listen((req) {
          state = state.copyWith(
            pendingRequests: [...state.pendingRequests, req],
          );
        }),
      );
    }
  }

  /// A `battuta-live://` link arrived. With nothing running it joins at
  /// once; during a session it only asks the page to confirm leaving it
  /// (the same address is a no-op).
  Future<void> handleLiveLink(LiveJoinAddress address) async {
    final busy =
        state.isConnected ||
        state.isReconnecting ||
        state.status == LiveSyncStatus.connecting;
    if (!busy) {
      await joinAddress(address);
      return;
    }
    if (address == (state.joinAddress ?? state.followingAddress)) return;
    state = state.copyWith(pendingJoin: address);
  }

  /// The user agreed to leave the running session for [LiveSyncUiState.pendingJoin].
  Future<void> confirmPendingJoin() async {
    final address = state.pendingJoin;
    if (address == null) return;
    state = state.copyWith(clearPendingJoin: true);
    await joinAddress(address);
  }

  /// The user kept the running session.
  void cancelPendingJoin() {
    if (state.pendingJoin != null) {
      state = state.copyWith(clearPendingJoin: true);
    }
  }

  /// Joins the director at [address], ending anything this device was
  /// hosting. Failures land in [LiveSyncUiState.issue].
  Future<bool> joinAddress(LiveJoinAddress address) async {
    final service = ref.read(liveSyncServiceProvider);
    final generation = ++_joinGeneration;
    stopBrowsing();
    await ref.read(liveSessionDiscoveryProvider).stopAdvertising();
    if (!ref.mounted || generation != _joinGeneration) return false;
    service.setSyncMode(LiveSyncMode.follower);
    state = state.copyWith(
      mode: LiveSyncMode.follower,
      clearIssue: true,
      clearPendingJoin: true,
      status: LiveSyncStatus.connecting,
      followingAddress: address,
      clearServerPort: true,
      clearJoinAddress: true,
      followers: const [],
    );
    try {
      await service.connect(address.host, address.port);
      if (!ref.mounted || generation != _joinGeneration) return false;
      state = state.copyWith(status: service.status);
      return true;
    } on LiveConnectException catch (e) {
      // A newer join owns the state; this failure is history.
      if (!ref.mounted || generation != _joinGeneration) return false;
      state = state.copyWith(
        status: service.status,
        clearFollowingAddress: true,
        issue: switch (e.reason) {
          LiveConnectFailure.timeout => LiveConnectIssue.timeout,
          LiveConnectFailure.unreachable => LiveConnectIssue.unreachable,
        },
      );
      return false;
    }
  }

  /// Joins a session found by discovery.
  Future<bool> joinSession(LiveSession session) =>
      joinAddress(LiveJoinAddress(host: session.host, port: session.port));

  /// Starts hosting: binds the server, announces it on the network and
  /// exposes the address followers can type or scan. Returns `false` (with
  /// [LiveSyncUiState.issue] set) when there is no Wi-Fi / hotspot address
  /// or the server cannot start.
  Future<bool> startHosting({required String sessionName}) {
    // A second tap (or a resume) while one start runs shares its result.
    final running = _hosting;
    if (running != null) return running;
    final run = _startHosting(sessionName).whenComplete(() => _hosting = null);
    _hosting = run;
    return run;
  }

  Future<bool> _startHosting(String sessionName) async {
    final service = ref.read(liveSyncServiceProvider);
    if (service is! LanWebSocketSyncService) return false;
    state = state.copyWith(clearIssue: true, sessionName: sessionName);

    final address = await ref.read(lanAddressResolverProvider).resolve();
    if (!ref.mounted) return false;
    if (address == null) {
      state = state.copyWith(issue: LiveConnectIssue.noNetwork);
      return false;
    }

    final int port;
    try {
      port = await service.startDirectorServer();
    } on SocketException {
      if (!ref.mounted) return false;
      state = state.copyWith(
        status: service.status,
        issue: LiveConnectIssue.hostFailed,
      );
      return false;
    }
    if (!ref.mounted) return false;
    state = state.copyWith(
      status: service.status,
      mode: LiveSyncMode.director,
      serverPort: port,
      joinAddress: LiveJoinAddress(host: address, port: port),
      followers: const [],
    );
    await ref
        .read(liveSessionDiscoveryProvider)
        .advertise(
          sessionName: sessionName,
          directorName: ref.read(liveDeviceNameProvider),
          port: port,
        );
    return true;
  }

  /// Brings hosting back after the app returns to the foreground (iOS may
  /// have closed the server while suspended): restarts the server and
  /// announces it again. Does nothing when the server still answers.
  Future<void> ensureHosting() async {
    final address = state.joinAddress;
    if (_hosting != null) return;
    if (!state.isDirector || !state.isConnected || address == null) return;
    try {
      final probe = await Socket.connect(
        InternetAddress.loopbackIPv4,
        address.port,
        timeout: const Duration(seconds: 1),
      );
      probe.destroy();
      return;
    } on Object {
      // Not answering: restart below.
    }
    await startHosting(sessionName: state.sessionName);
  }

  /// Starts listing nearby sessions.
  void startBrowsing() {
    if (_browseSub != null) return;
    state = state.copyWith(
      sessions: const [],
      searching: true,
      searchTimedOut: false,
    );
    _searchTimer = Timer(_searchTimeout, () {
      if (!ref.mounted) return;
      if (state.sessions.isEmpty) {
        state = state.copyWith(searching: false, searchTimedOut: true);
      }
    });
    _browseSub = ref.read(liveSessionDiscoveryProvider).browse().listen((
      sessions,
    ) {
      if (!ref.mounted) return;
      state = state.copyWith(
        sessions: sessions,
        searching: sessions.isEmpty && !state.searchTimedOut,
      );
    }, onError: (Object _) {});
  }

  /// Stops listing nearby sessions.
  void stopBrowsing() {
    _searchTimer?.cancel();
    _searchTimer = null;
    final sub = _browseSub;
    _browseSub = null;
    if (sub == null) return;
    unawaited(sub.cancel());
    if (ref.mounted) {
      state = state.copyWith(
        sessions: const [],
        searching: false,
        searchTimedOut: false,
      );
    }
  }

  /// Leaves a followed session or stops hosting.
  Future<void> disconnect() async {
    final service = ref.read(liveSyncServiceProvider);
    _joinGeneration++;
    await ref.read(liveSessionDiscoveryProvider).stopAdvertising();
    await service.disconnect();
    if (!ref.mounted) return;
    state = state.copyWith(
      status: service.status,
      clearFollowingAddress: true,
      clearPendingJoin: true,
      clearActiveCue: true,
      clearServerPort: true,
      clearJoinAddress: true,
      followers: const [],
      clearIssue: true,
    );
  }

  void clearIssue() {
    state = state.copyWith(clearIssue: true);
  }

  void setSyncMode(LiveSyncMode mode) {
    final service = ref.read(liveSyncServiceProvider);
    service.setSyncMode(mode);
    state = state.copyWith(mode: mode);
  }

  Future<void> queueNextSection(String sectionId) async {
    final service = ref.read(liveSyncServiceProvider);
    await service.queueNextSection(sectionId);
    state = state.copyWith(queuedSectionLabel: sectionId);
  }

  Future<void> jumpNowSection(String sectionId) async {
    final service = ref.read(liveSyncServiceProvider);
    await service.jumpNowSection(sectionId);
    state = state.copyWith(activeSectionId: sectionId);
  }

  void emitLookaheadCue({
    required String songId,
    required String currentSectionId,
    required String nextSectionLabel,
    required int currentMeasureIndex,
    int lookaheadMeasures = 2,
  }) {
    final service = ref.read(liveSyncServiceProvider);
    if (service is LanWebSocketSyncService) {
      final cue = service.emitLookaheadCue(
        songId: songId,
        currentSectionId: currentSectionId,
        nextSectionLabel: nextSectionLabel,
        currentMeasureIndex: currentMeasureIndex,
        lookaheadMeasures: lookaheadMeasures,
      );
      state = state.copyWith(
        activeCue: cue,
        queuedSectionLabel: nextSectionLabel,
      );
    }
  }

  void dismissCue() {
    state = state.copyWith(clearActiveCue: true);
  }
}
