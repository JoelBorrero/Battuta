/// Battuta — Live Stage Synchronization Service Interface.
///
/// Abstract contract for v1.1 live stage synchronization, supporting:
/// - ProPresenter 7.9+ REST API integration
/// - Local LAN multi-director WebSocket hub
/// - 'Queue Next' (amber) preview and 'Jump Now' instant stage triggering
/// - Section externalSyncId UUID mappings.
library;

import 'dart:async';

/// Connection status to external stage presentation systems.
enum LiveSyncStatus {
  /// Not connected to any stage presentation system.
  disconnected,

  /// Connection attempt in progress.
  connecting,

  /// Actively synchronized with stage presentation software.
  connected,

  /// Connection dropped; attempting automatic reconnection.
  reconnecting,

  /// Connection error occurred.
  error,
}

/// Synchronization mode for the local device.
enum LiveSyncMode {
  /// Follows the active director's live section and slide selection.
  follower,

  /// Controls the stage and broadcasts section transitions to follower devices.
  director,
}

/// Abstract contract for v1.1 live stage presentation synchronization.
///
/// Designed to compile in pure Dart with zero external plugin dependencies.
abstract class LiveSyncService {
  /// Current connection status to stage presentation software.
  LiveSyncStatus get status;

  /// Stream of connection status changes.
  Stream<LiveSyncStatus> get statusStream;

  /// Current sync role (director or follower).
  LiveSyncMode get mode;

  /// Active section ID currently being performed on stage.
  String? get activeSectionId;

  /// Stream of active section ID changes broadcast by the director.
  Stream<String> get activeSectionStream;

  /// Section ID currently queued for upcoming transition (amber preview).
  String? get queuedSectionId;

  /// Stream of queued section ID changes.
  Stream<String> get queuedSectionStream;

  /// Connects to stage software or local LAN sync hub at [host]:[port].
  Future<void> connect(String host, int port, {String? token});

  /// Disconnects from the active session.
  Future<void> disconnect();

  /// Sets whether this device operates as director or follower.
  void setSyncMode(LiveSyncMode mode);

  /// Broadcasts a 'Queue Next' preview for [sectionId] (amber UI indicator).
  ///
  /// [externalSyncId] is the ProPresenter presentation group UUID if available.
  Future<void> queueNextSection(String sectionId, {String? externalSyncId});

  /// Broadcasts an immediate 'Jump Now' transition to [sectionId].
  ///
  /// [externalSyncId] is the ProPresenter presentation group UUID if available.
  Future<void> jumpNowSection(String sectionId, {String? externalSyncId});

  /// Clears the currently queued section without transitioning.
  Future<void> clearQueuedSection();
}
