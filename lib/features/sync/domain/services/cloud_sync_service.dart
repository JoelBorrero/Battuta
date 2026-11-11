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

  /// Runs a complete two-way sync for the signed-in account: pushes local
  /// pending mutations (song versions, scores, setlists) to Supabase, then
  /// pulls what changed on the backend into local Drift and removes what the
  /// account can no longer see. Without a session or connection it returns an
  /// offline result and leaves local data untouched.
  ///
  /// [teamId] is ignored (organizations are synced by their own data layer).
  Future<CloudSyncResult> syncAll({String? teamId});

  /// Pushes the account's local changes to Supabase.
  Future<CloudSyncResult> pushLocalChanges();

  /// Pulls updated entities from Supabase and applies them to Drift using
  /// Last-Write-Wins (LWW) conflict resolution.
  Future<CloudSyncResult> pullRemoteChanges({String? teamId});
}
