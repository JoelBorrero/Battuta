/// Battuta — Cloud Sync Service Contract.
///
/// Abstract interface for two-way synchronization between local Drift SQLite
/// tables and Supabase cloud tables following Clean Architecture.
library;

import 'package:battuta/features/sync/domain/models/cloud_sync_result.dart';

abstract class CloudSyncService {
  /// Whether a sync cycle is currently active.
  bool get isSyncing;

  /// The timestamp of the last successful sync cycle, or null if never synced.
  DateTime? get lastSyncedAt;

  /// Runs a complete two-way sync: pushes local pending mutations to Supabase,
  /// then pulls remote updates newer than [lastSyncedAt] into local Drift.
  Future<CloudSyncResult> syncAll({String? teamId});

  /// Pushes local Drift entities (Scores, Songs, Setlists) to Supabase.
  Future<CloudSyncResult> pushLocalChanges();

  /// Pulls updated entities from Supabase and applies them to Drift using
  /// Last-Write-Wins (LWW) conflict resolution.
  Future<CloudSyncResult> pullRemoteChanges({String? teamId});
}
