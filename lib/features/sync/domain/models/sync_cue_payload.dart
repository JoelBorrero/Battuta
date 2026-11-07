/// Battuta — Live Stage Synchronization Cue Payload.
///
/// Immutable domain model representing an on-stage cue broadcast from a director
/// to follower musician devices over local LAN WebSocket.
library;

import 'package:flutter/foundation.dart';

@immutable
class SyncCuePayload {
  const SyncCuePayload({
    required this.songId,
    required this.currentSectionId,
    required this.nextSectionLabel,
    required this.triggerMeasureIndex,
    required this.leaderTimestampMs,
    required this.sequenceNumber,
  });

  /// Identifier of the active song in repertoire.
  final String songId;

  /// Identifier of the currently active section (e.g. verse-1).
  final String currentSectionId;

  /// Human-readable upcoming transition preview (e.g. "NEXT: CORO").
  final String nextSectionLabel;

  /// Target measure index at which the upcoming section transition executes.
  final int triggerMeasureIndex;

  /// Monotonic or epoch timestamp in milliseconds recorded by the stage director.
  final int leaderTimestampMs;

  /// Monotonically increasing sequence number to resolve race conditions and leader locks.
  final int sequenceNumber;

  /// Creates a [SyncCuePayload] from a JSON map.
  factory SyncCuePayload.fromJson(Map<String, dynamic> json) {
    return SyncCuePayload(
      songId: json['songId'] as String,
      currentSectionId: json['currentSectionId'] as String,
      nextSectionLabel: json['nextSectionLabel'] as String,
      triggerMeasureIndex: (json['triggerMeasureIndex'] as num).toInt(),
      leaderTimestampMs: (json['leaderTimestampMs'] as num).toInt(),
      sequenceNumber: (json['sequenceNumber'] as num).toInt(),
    );
  }

  /// Serializes this cue payload to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'songId': songId,
      'currentSectionId': currentSectionId,
      'nextSectionLabel': nextSectionLabel,
      'triggerMeasureIndex': triggerMeasureIndex,
      'leaderTimestampMs': leaderTimestampMs,
      'sequenceNumber': sequenceNumber,
    };
  }

  SyncCuePayload copyWith({
    String? songId,
    String? currentSectionId,
    String? nextSectionLabel,
    int? triggerMeasureIndex,
    int? leaderTimestampMs,
    int? sequenceNumber,
  }) {
    return SyncCuePayload(
      songId: songId ?? this.songId,
      currentSectionId: currentSectionId ?? this.currentSectionId,
      nextSectionLabel: nextSectionLabel ?? this.nextSectionLabel,
      triggerMeasureIndex: triggerMeasureIndex ?? this.triggerMeasureIndex,
      leaderTimestampMs: leaderTimestampMs ?? this.leaderTimestampMs,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncCuePayload &&
          runtimeType == other.runtimeType &&
          songId == other.songId &&
          currentSectionId == other.currentSectionId &&
          nextSectionLabel == other.nextSectionLabel &&
          triggerMeasureIndex == other.triggerMeasureIndex &&
          leaderTimestampMs == other.leaderTimestampMs &&
          sequenceNumber == other.sequenceNumber;

  @override
  int get hashCode => Object.hash(
    songId,
    currentSectionId,
    nextSectionLabel,
    triggerMeasureIndex,
    leaderTimestampMs,
    sequenceNumber,
  );

  @override
  String toString() {
    return 'SyncCuePayload(songId: $songId, currentSectionId: $currentSectionId, '
        'nextSectionLabel: $nextSectionLabel, triggerMeasure: $triggerMeasureIndex, '
        'seq: $sequenceNumber)';
  }
}
