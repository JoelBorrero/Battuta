/// Battuta — Live Stage Synchronization Riverpod Provider.
///
/// Bridges [LiveSyncService] streams to reactive UI state for stage cue banners,
/// director control bars, and live musician devices.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lan_websocket_sync_service.dart';
import '../../domain/models/sync_cue_payload.dart';
import '../../domain/services/live_sync_service.dart';

/// Provider for the underlying [LiveSyncService] implementation.
final liveSyncServiceProvider = Provider<LiveSyncService>((ref) {
  final service = LanWebSocketSyncService();
  ref.onDispose(() => service.dispose());
  return service;
});

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
  });

  final LiveSyncStatus status;
  final LiveSyncMode mode;
  final String? activeSectionId;
  final String? queuedSectionLabel;
  final SyncCuePayload? activeCue;
  final List<SyncCuePayload> pendingRequests;
  final int? serverPort;

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
  }) {
    return LiveSyncUiState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      activeSectionId: activeSectionId ?? this.activeSectionId,
      queuedSectionLabel: queuedSectionLabel ?? this.queuedSectionLabel,
      activeCue: clearActiveCue ? null : (activeCue ?? this.activeCue),
      pendingRequests: pendingRequests ?? this.pendingRequests,
      serverPort: serverPort ?? this.serverPort,
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
          serverPort == other.serverPort;

  @override
  int get hashCode => Object.hash(
    status,
    mode,
    activeSectionId,
    queuedSectionLabel,
    activeCue,
    Object.hashAll(pendingRequests),
    serverPort,
  );
}

final liveSyncControllerProvider =
    NotifierProvider<LiveSyncNotifier, LiveSyncUiState>(LiveSyncNotifier.new);

class LiveSyncNotifier extends Notifier<LiveSyncUiState> {
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  LiveSyncUiState build() {
    final service = ref.watch(liveSyncServiceProvider);

    _listenToService(service);

    ref.onDispose(() {
      for (final sub in _subs) {
        sub.cancel();
      }
      _subs.clear();
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
        service.followerRequestStream.listen((req) {
          state = state.copyWith(
            pendingRequests: [...state.pendingRequests, req],
          );
        }),
      );
    }
  }

  Future<void> connect(String host, int port, {String? token}) async {
    final service = ref.read(liveSyncServiceProvider);
    await service.connect(host, port, token: token);
    state = state.copyWith(status: service.status);
  }

  Future<int?> startDirectorServer({int port = 0}) async {
    final service = ref.read(liveSyncServiceProvider);
    if (service is LanWebSocketSyncService) {
      final boundPort = await service.startDirectorServer(port: port);
      state = state.copyWith(
        status: service.status,
        mode: LiveSyncMode.director,
        serverPort: boundPort,
      );
      return boundPort;
    }
    return null;
  }

  Future<void> disconnect() async {
    final service = ref.read(liveSyncServiceProvider);
    await service.disconnect();
    state = state.copyWith(
      status: service.status,
      clearActiveCue: true,
      serverPort: null,
    );
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
