/// Battuta — Supabase cloud sync of songs, scores and setlists.
///
/// Two-way sync between the local Drift database (the source of truth for the
/// UI, always usable offline) and the Supabase schema where a song is a *work*
/// with many *versions*. A local song row is one version.
///
/// A run goes: claim local-mode data for the signed-in account, give legacy
/// rows UUID ids, **push** the account's dirty versions, scores and setlists
/// (last write wins against edits made on another device), then **pull** what
/// changed on the backend and remove what is no longer visible. It never blocks
/// local saves: without a session or a connection it returns an offline result
/// and leaves the local data untouched.
library;

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/services/supabase_client_manager.dart';
import 'package:battuta/core/utils/logger.dart';
import 'package:battuta/features/organizations/data/backend_gateway.dart';
import 'package:battuta/features/sync/data/local_data_claim.dart';
import 'package:battuta/features/sync/data/scores_sync.dart';
import 'package:battuta/features/sync/data/setlists_sync.dart';
import 'package:battuta/features/sync/data/sync_context.dart';
import 'package:battuta/features/sync/data/versions_sync.dart';
import 'package:battuta/features/sync/domain/models/cloud_sync_result.dart';
import 'package:battuta/features/sync/domain/services/cloud_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class SupabaseCloudSyncService implements CloudSyncService {
  /// `clientProvider` overrides where the client comes from (tests); by
  /// default it is the one of [clientManager].
  SupabaseCloudSyncService({
    required this.db,
    required this.clientManager,
    this._clientProvider,
  });

  final AppDatabase db;
  final SupabaseClientManager clientManager;
  final SupabaseClientProvider? _clientProvider;

  bool _isSyncing = false;
  DateTime? _lastSyncedAt;

  @override
  bool get isSyncing => _isSyncing;

  @override
  DateTime? get lastSyncedAt => _lastSyncedAt;

  supa.SupabaseClient? get _client =>
      _clientProvider != null ? _clientProvider() : clientManager.client;

  /// Songs and setlists have no demo data: in demo mode there is nothing to
  /// sync, so the run reports offline and the local data stays as it is.
  static const _demoReason =
      'Demo mode does not sync songs or setlists with the cloud.';

  @override
  Future<CloudSyncResult> syncAll({String? teamId, bool isDemo = false}) {
    return _run(isDemo: isDemo, push: true, pull: true);
  }

  @override
  Future<CloudSyncResult> pushLocalChanges({bool isDemo = false}) {
    return _run(isDemo: isDemo, push: true, pull: false);
  }

  @override
  Future<CloudSyncResult> pullRemoteChanges({
    String? teamId,
    bool isDemo = false,
  }) {
    return _run(isDemo: isDemo, push: false, pull: true);
  }

  Future<CloudSyncResult> _run({
    required bool isDemo,
    required bool push,
    required bool pull,
  }) async {
    if (isDemo) return CloudSyncResult.offline(reason: _demoReason);
    if (_isSyncing) {
      return CloudSyncResult.failure(error: 'A sync cycle is already active.');
    }
    final client = _client;
    if (client == null) {
      return CloudSyncResult.offline(
        reason: 'Supabase client is not configured. Local changes cached.',
      );
    }
    final accountId = client.auth.currentUser?.id;
    if (accountId == null) {
      return CloudSyncResult.offline(
        reason: 'Please sign in to sync personal workspace with the cloud.',
      );
    }

    _isSyncing = true;
    final ctx = SyncContext(
      db: db,
      client: client,
      accountId: accountId,
      currentAccount: () => _client?.auth.currentUser?.id,
    );
    try {
      if (push) {
        ctx.ensureCurrent();
        await claimLocalData(db, accountId);
        await migrateLegacySongIds(db, accountId);
        await VersionsSync(ctx).push();
        await ScoresSync(ctx).push();
        await SetlistsSync(ctx).push();
      }
      if (pull) {
        await VersionsSync(ctx).pull();
        await ScoresSync(ctx).pull();
        await SetlistsSync(ctx).pull();
      }

      if (ctx.errors.isNotEmpty) {
        AppLogger.error('Cloud sync skipped rows: ${ctx.errors.join('; ')}');
        return CloudSyncResult.failure(
          error:
              '${ctx.errors.length} item(s) could not be synced: '
              '${ctx.errors.first}',
        );
      }
      _lastSyncedAt = DateTime.now();
      return CloudSyncResult.success(
        pushedCount: ctx.pushed,
        pulledCount: ctx.pulled,
        timestamp: _lastSyncedAt,
      );
    } on StaleAccountException {
      AppLogger.info('Cloud sync stopped: the signed-in account changed.');
      return CloudSyncResult.failure(
        error: 'The signed-in account changed during the sync.',
      );
    } catch (e, st) {
      final failure = mapBackendError(e, st);
      if (failure.errorCode == BackendErrorCode.offline) {
        AppLogger.info('Cloud sync offline: $e');
        return CloudSyncResult.offline();
      }
      AppLogger.error('Cloud sync error: $e', error: e, stackTrace: st);
      return CloudSyncResult.failure(error: _describe(failure));
    } finally {
      _isSyncing = false;
    }
  }

  String _describe(Failure failure) {
    final code = failure.errorCode;
    return code == null || code == BackendErrorCode.unknown
        ? 'Sync failed: ${failure.message}'
        : 'Sync failed: ${code.code}';
  }
}
