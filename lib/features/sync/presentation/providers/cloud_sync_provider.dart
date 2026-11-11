/// Battuta — Cloud Sync State & Riverpod Providers.
///
/// Coordinates two-way synchronization between local Drift SQLite
/// and Supabase PostgreSQL with reactive UI state emission.
library;

import 'package:battuta/core/database/database_providers.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/sync/data/supabase_cloud_sync_service.dart';
import 'package:battuta/features/sync/domain/models/cloud_sync_result.dart';
import 'package:battuta/features/sync/domain/services/cloud_sync_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CloudSyncStatus { idle, syncing, success, offline, error }

class CloudSyncState extends Equatable {
  const CloudSyncState({
    this.status = CloudSyncStatus.idle,
    this.lastSyncedAt,
    this.errorMessage,
    this.lastResult,
  });

  final CloudSyncStatus status;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final CloudSyncResult? lastResult;

  bool get isSyncing => status == CloudSyncStatus.syncing;
  bool get isOffline => status == CloudSyncStatus.offline;

  CloudSyncState copyWith({
    CloudSyncStatus? status,
    DateTime? lastSyncedAt,
    String? errorMessage,
    CloudSyncResult? lastResult,
  }) {
    return CloudSyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage,
      lastResult: lastResult ?? this.lastResult,
    );
  }

  @override
  List<Object?> get props => [status, lastSyncedAt, errorMessage, lastResult];
}

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final clientManager = ref.watch(supabaseClientManagerProvider);
  return SupabaseCloudSyncService(db: db, clientManager: clientManager);
});

class CloudSyncNotifier extends Notifier<CloudSyncState> {
  @override
  CloudSyncState build() => const CloudSyncState();

  Future<CloudSyncResult>? _inFlight;

  /// Runs a sync, or joins the one already running: a second trigger (rapid
  /// taps, a resume while syncing) waits for the same result instead of
  /// reporting the service's "already active" refusal as an error.
  Future<CloudSyncResult> triggerSync({String? teamId}) {
    final running = _inFlight;
    if (running != null) return running;
    final run = _sync(teamId: teamId);
    _inFlight = run;
    return run.whenComplete(() => _inFlight = null);
  }

  Future<CloudSyncResult> _sync({String? teamId}) async {
    final service = ref.read(cloudSyncServiceProvider);
    state = state.copyWith(status: CloudSyncStatus.syncing, errorMessage: null);

    final result = await service.syncAll(teamId: teamId);

    if (result.isSuccess) {
      // Versions and setlists pulled from the backend appear in the lists.
      if (result.pulledCount > 0) {
        ref
          ..invalidate(repertoireProvider)
          ..invalidate(setlistsProvider);
      }
      state = state.copyWith(
        status: CloudSyncStatus.success,
        lastSyncedAt: result.timestamp,
        lastResult: result,
      );
    } else if (result.isOffline) {
      state = state.copyWith(
        status: CloudSyncStatus.offline,
        errorMessage: result.errorMessage,
        lastResult: result,
      );
    } else {
      state = state.copyWith(
        status: CloudSyncStatus.error,
        errorMessage: result.errorMessage,
        lastResult: result,
      );
    }

    return result;
  }

  void clearError() {
    if (state.status == CloudSyncStatus.error ||
        state.status == CloudSyncStatus.offline) {
      state = state.copyWith(status: CloudSyncStatus.idle, errorMessage: null);
    }
  }
}

final cloudSyncProvider = NotifierProvider<CloudSyncNotifier, CloudSyncState>(
  CloudSyncNotifier.new,
);
