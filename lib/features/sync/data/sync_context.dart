/// Shared state of one song/setlist sync run.
library;

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/data/backend_gateway.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Thrown when the signed-in account changed while a sync was running. The run
/// stops before touching the local database for the stale account.
class StaleAccountException implements Exception {
  const StaleAccountException();

  @override
  String toString() => 'The signed-in account changed during the sync.';
}

class SyncContext {
  SyncContext({
    required this.db,
    required this.client,
    required this.accountId,
    required this._currentAccount,
  });

  /// Rows per request when asking the backend for a list of ids.
  static const idChunkSize = 80;

  /// Rows per request when fetching full rows.
  static const rowChunkSize = 40;

  /// Rows per page when listing a whole table.
  static const pageSize = 1000;

  final AppDatabase db;
  final supa.SupabaseClient client;

  /// The account this run belongs to.
  final String accountId;
  final String? Function() _currentAccount;

  int pushed = 0;
  int pulled = 0;

  /// Rows that could not be synced (the run continues with the others).
  final List<String> errors = [];

  /// Throws [StaleAccountException] unless [accountId] is still signed in.
  /// Called right before every local write.
  void ensureCurrent() {
    if (_currentAccount() != accountId) throw const StaleAccountException();
  }

  /// Pages through a listing until a short page comes back.
  Future<List<Map<String, dynamic>>> fetchAll(
    Future<List<dynamic>> Function(int from, int to) page,
  ) async {
    final rows = <Map<String, dynamic>>[];
    for (var from = 0; ; from += pageSize) {
      final batch = await page(from, from + pageSize - 1);
      rows.addAll(batch.cast<Map<String, dynamic>>());
      if (batch.length < pageSize) return rows;
    }
  }

  /// Runs one row's sync. Offline and stale-account errors abort the whole run;
  /// any other failure is recorded and the run goes on with the next row.
  Future<void> guardRow(String what, Future<void> Function() body) async {
    try {
      await body();
    } on StaleAccountException {
      rethrow;
    } catch (e, st) {
      report(what, e, st);
    }
  }

  /// Records a failure that only concerns one row ([what]) and returns it. The
  /// ones that stop the whole run (offline, deactivated account) are thrown.
  Failure report(String what, Object error, [StackTrace? stackTrace]) {
    final failure = mapBackendError(error, stackTrace);
    if (failure.errorCode == BackendErrorCode.offline ||
        failure.errorCode == BackendErrorCode.accountDeactivated) {
      throw failure;
    }
    errors.add('$what: ${failure.message}');
    return failure;
  }
}

/// Convenience for the data layers: a typed failure of a thrown error.
Failure asFailure(Object error, [StackTrace? stackTrace]) =>
    mapBackendError(error, stackTrace);
