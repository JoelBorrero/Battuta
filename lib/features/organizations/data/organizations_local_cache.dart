/// Drift-backed offline cache for the backend rows of the signed-in account.
///
/// Rows are stored as entity JSON keyed by `(accountId, kind, id)` and grouped
/// by `scopeId` (the organization id, or empty for account level rows). All
/// reads are streams so the UI updates both offline and after a refresh.
library;

import 'dart:async';
import 'dart:convert';

import 'package:battuta/core/database/app_database.dart';
import 'package:drift/drift.dart';

/// Names of the cached collections.
abstract final class CacheKind {
  static const profile = 'profile';
  static const organization = 'organization';
  static const member = 'member';
  static const band = 'band';
  static const bandMember = 'band_member';
  static const inviteLink = 'invite_link';
  static const invitation = 'invitation';
  static const myInvitation = 'my_invitation';
  static const archiveRequest = 'archive_request';
  static const notification = 'notification';
  static const event = 'event';
  static const schedule = 'schedule';
  static const assignment = 'assignment';
  static const absence = 'absence';
  static const repertoire = 'repertoire';
}

/// A JSON row to cache: [id] is the entity id, [json] its serialization.
typedef CacheRow = ({String id, Map<String, dynamic> json});

class OrganizationsLocalCache {
  /// [currentAccount] reports the signed-in account. When given, every write
  /// for any other account is silently dropped, so an operation that was
  /// started before an account switch can never leave rows behind.
  OrganizationsLocalCache(this._db, {this._currentAccount});

  final AppDatabase _db;
  final String? Function()? _currentAccount;

  // ---- Ordering of fetches against newer writes ----------------------------

  static const _fetchStartKey = #cacheFetchStart;
  int _tick = 0;
  int _activeFetches = 0;
  final Map<String, int> _touched = {};

  static String _touchKey(String accountId, String kind, String id) =>
      '$accountId|$kind|$id';

  bool _isCurrent(String accountId) {
    final current = _currentAccount;
    return current == null || current() == accountId;
  }

  /// Runs a fetch-then-store operation. Rows upserted or removed by someone
  /// else (a realtime change, a local write) while it was running are newer
  /// than its snapshot, so [replaceAll] leaves them alone.
  Future<T> runFetch<T>(Future<T> Function() body) {
    final inherited = Zone.current[_fetchStartKey];
    if (inherited != null) return body();
    _activeFetches++;
    return runZoned(() async {
      try {
        return await body();
      } finally {
        if (--_activeFetches == 0) _touched.clear();
      }
    }, zoneValues: {_fetchStartKey: _tick});
  }

  void _touch(String accountId, String kind, String id) {
    if (_activeFetches > 0) _touched[_touchKey(accountId, kind, id)] = ++_tick;
  }

  SimpleSelectStatement<$CacheRecordsTable, CacheRecordEntry> _select(
    String accountId,
    String kind,
    String? scopeId,
  ) {
    return _db.select(_db.cacheRecords)..where(
      (t) =>
          t.accountId.equals(accountId) &
          t.recordKind.equals(kind) &
          (scopeId == null ? const Constant(true) : t.scopeId.equals(scopeId)),
    );
  }

  static List<T> _decode<T>(
    List<CacheRecordEntry> rows,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final result = <T>[];
    for (final row in rows) {
      try {
        result.add(fromJson(jsonDecode(row.json) as Map<String, dynamic>));
      } catch (_) {
        // A corrupt cache row is skipped, never fatal.
      }
    }
    return result;
  }

  /// Emits the cached rows of [kind] (optionally of one [scopeId]) on every change.
  Stream<List<T>> watch<T>(
    String accountId,
    String kind,
    T Function(Map<String, dynamic>) fromJson, {
    String? scopeId,
  }) {
    return _select(
      accountId,
      kind,
      scopeId,
    ).watch().map((r) => _decode(r, fromJson));
  }

  Future<List<T>> read<T>(
    String accountId,
    String kind,
    T Function(Map<String, dynamic>) fromJson, {
    String? scopeId,
  }) async {
    return _decode(await _select(accountId, kind, scopeId).get(), fromJson);
  }

  Future<T?> readOne<T>(
    String accountId,
    String kind,
    String id,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final row =
        await (_db.select(_db.cacheRecords)..where(
              (t) =>
                  t.accountId.equals(accountId) &
                  t.recordKind.equals(kind) &
                  t.recordId.equals(id),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return _decode([row], fromJson).firstOrNull;
  }

  /// Replaces the whole collection of [kind] in [scopeId] with [rows]: rows
  /// that are no longer present are dropped, the others inserted or updated.
  /// Running it twice with the same data never duplicates anything.
  Future<void> replaceAll(
    String accountId,
    String kind,
    Iterable<CacheRow> rows, {
    String scopeId = '',
  }) async {
    if (!_isCurrent(accountId)) return;
    final start = Zone.current[_fetchStartKey] as int?;
    bool newer(String id) =>
        start != null &&
        (_touched[_touchKey(accountId, kind, id)] ?? 0) > start;
    await _db.transaction(() async {
      if (!_isCurrent(accountId)) return;
      final keep = rows.map((r) => r.id).toSet();
      final newerIds = start == null
          ? const <String>{}
          : _touched.entries
                .where(
                  (e) =>
                      e.value > start && e.key.startsWith('$accountId|$kind|'),
                )
                .map((e) => e.key.substring('$accountId|$kind|'.length))
                .toSet();
      await (_db.delete(_db.cacheRecords)..where(
            (t) =>
                t.accountId.equals(accountId) &
                t.recordKind.equals(kind) &
                t.scopeId.equals(scopeId) &
                t.recordId.isNotIn({...keep, ...newerIds}),
          ))
          .go();
      for (final row in rows) {
        if (newer(row.id)) continue;
        await _upsert(accountId, kind, row.id, scopeId, row.json);
      }
      await markRefreshed(accountId, kind, scopeId: scopeId);
    });
  }

  Future<void> upsert(
    String accountId,
    String kind,
    String id,
    Map<String, dynamic> json, {
    String scopeId = '',
  }) async {
    if (!_isCurrent(accountId)) return;
    _touch(accountId, kind, id);
    await _upsert(accountId, kind, id, scopeId, json);
  }

  Future<void> _upsert(
    String accountId,
    String kind,
    String id,
    String scopeId,
    Map<String, dynamic> json,
  ) {
    return _db
        .into(_db.cacheRecords)
        .insertOnConflictUpdate(
          CacheRecordsCompanion.insert(
            accountId: accountId,
            recordKind: kind,
            recordId: id,
            scopeId: Value(scopeId),
            json: jsonEncode(json),
          ),
        );
  }

  Future<void> remove(String accountId, String kind, String id) async {
    if (!_isCurrent(accountId)) return;
    _touch(accountId, kind, id);
    await (_db.delete(_db.cacheRecords)..where(
          (t) =>
              t.accountId.equals(accountId) &
              t.recordKind.equals(kind) &
              t.recordId.equals(id),
        ))
        .go();
  }

  /// Drops everything cached for [scopeId] (an organization the user left,
  /// was removed from, or that is no longer listed).
  Future<void> removeScope(String accountId, String scopeId) async {
    if (!_isCurrent(accountId)) return;
    await _db.transaction(() async {
      await (_db.delete(_db.cacheRecords)..where(
            (t) => t.accountId.equals(accountId) & t.scopeId.equals(scopeId),
          ))
          .go();
      await (_db.delete(_db.cacheRefreshes)..where(
            (t) => t.accountId.equals(accountId) & t.scopeId.equals(scopeId),
          ))
          .go();
    });
  }

  Future<void> markRefreshed(
    String accountId,
    String kind, {
    String scopeId = '',
    DateTime? at,
  }) async {
    if (!_isCurrent(accountId)) return;
    await _db
        .into(_db.cacheRefreshes)
        .insertOnConflictUpdate(
          CacheRefreshesCompanion.insert(
            accountId: accountId,
            recordKind: kind,
            scopeId: Value(scopeId),
            refreshedAt: at ?? DateTime.now(),
          ),
        );
  }

  Future<DateTime?> lastRefreshed(
    String accountId,
    String kind, {
    String scopeId = '',
  }) async {
    final row =
        await (_db.select(_db.cacheRefreshes)..where(
              (t) =>
                  t.accountId.equals(accountId) &
                  t.recordKind.equals(kind) &
                  t.scopeId.equals(scopeId),
            ))
            .getSingleOrNull();
    return row?.refreshedAt;
  }

  /// Deletes the cache of every account except [keepAccountId] (all of them
  /// when it is `null`). Called on sign-out and when the account changes.
  Future<void> clearAllExcept(String? keepAccountId) {
    return _db.transaction(() async {
      await (_db.delete(_db.cacheRecords)..where(
            (t) => keepAccountId == null
                ? const Constant(true)
                : t.accountId.equals(keepAccountId).not(),
          ))
          .go();
      await (_db.delete(_db.cacheRefreshes)..where(
            (t) => keepAccountId == null
                ? const Constant(true)
                : t.accountId.equals(keepAccountId).not(),
          ))
          .go();
    });
  }
}
