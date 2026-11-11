/// Battuta — Sync of scores (notation) per song version.
///
/// A score belongs to the version named by its local `songId`. Only the owner
/// of a version pushes its scores; deletions are sent as `deleted_at` so other
/// devices learn about them.
library;

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/sync/data/local_data_claim.dart';
import 'package:battuta/features/sync/data/sync_context.dart';
import 'package:battuta/features/sync/data/sync_mappers.dart';
import 'package:battuta/features/sync/domain/services/sync_policy.dart';
import 'package:drift/drift.dart';

class ScoresSync {
  ScoresSync(this.ctx);

  final SyncContext ctx;

  AppDatabase get _db => ctx.db;
  String get _me => ctx.accountId;

  // ---- Push ---------------------------------------------------------------

  Future<void> push() async {
    // Scores of versions this account owns and that exist remotely.
    final owned =
        await (_db.select(_db.songs)..where(
              (t) =>
                  t.accountId.equals(_me) &
                  t.ownerId.equals(_me) &
                  t.remoteUpdatedAt.isNotNull() &
                  t.deletedAt.isNull(),
            ))
            .get();
    final ownedIds = {for (final s in owned) s.id};
    if (ownedIds.isEmpty) return;

    final rows =
        await (_db.select(_db.scores)..where(
              (t) =>
                  t.songId.isIn(ownedIds) &
                  (t.isDirty.equals(true) | t.remoteUpdatedAt.isNull()),
            ))
            .get();
    for (final row in rows) {
      await ctx.guardRow('score "${row.title}"', () => _pushOne(row));
    }
  }

  Future<void> _pushOne(ScoreEntry original) async {
    ctx.ensureCurrent();
    var row = original;
    final versionId = row.songId!;

    if (row.deletedAt != null) {
      if (row.remoteUpdatedAt != null && SyncPolicy.isUuid(row.id)) {
        await ctx.client
            .from('scores')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', row.id);
        ctx.pushed++;
      }
      ctx.ensureCurrent();
      await (_db.delete(_db.scores)..where((t) => t.id.equals(row.id))).go();
      return;
    }

    final newId = await migrateScoreId(_db, row);
    if (newId != row.id) {
      row = await (_db.select(
        _db.scores,
      )..where((t) => t.id.equals(newId))).getSingle();
    }

    final remote = await ctx.client
        .from('scores')
        .select('id, updated_at, edited_at')
        .eq('id', row.id)
        .maybeSingle();
    if (remote != null) {
      final decision = SyncPolicy.decidePush(
        localEditedMs: row.editedAtMs,
        knownRemoteUpdatedAt: row.remoteUpdatedAt,
        remoteUpdatedAt: SyncPolicy.normalizeTimestamp(remote['updated_at']),
        remoteEditedMs: SyncPolicy.timestampMs(
          remote['edited_at'] ?? remote['updated_at'],
        ),
      );
      if (decision == PushDecision.remoteWins) {
        ctx.ensureCurrent();
        await (_db.update(_db.scores)..where((t) => t.id.equals(row.id))).write(
          const ScoresCompanion(isDirty: Value(false)),
        );
        return;
      }
    }

    final saved = await ctx.client
        .from('scores')
        .upsert(scorePayload(row, versionId))
        .select('updated_at')
        .single();
    final stamp = SyncPolicy.normalizeTimestamp(saved['updated_at']);
    ctx.ensureCurrent();
    await _db.transaction(() async {
      await (_db.update(_db.scores)..where((t) => t.id.equals(row.id))).write(
        ScoresCompanion(remoteUpdatedAt: Value(stamp)),
      );
      // Edited again while the request ran (its edit time moved on): it stays
      // dirty and goes out on the next sync.
      await (_db.update(_db.scores)..where(
            (t) => t.id.equals(row.id) & t.editedAtMs.equals(row.editedAtMs),
          ))
          .write(const ScoresCompanion(isDirty: Value(false)));
    });
    ctx.pushed++;
  }

  // ---- Pull ---------------------------------------------------------------

  /// Downloads the scores of every cached version.
  Future<void> pull() async {
    final versions =
        await (_db.select(_db.songs)..where(
              (t) =>
                  t.accountId.equals(_me) &
                  t.deletedAt.isNull() &
                  t.remoteUpdatedAt.isNotNull(),
            ))
            .get();
    final versionIds = [for (final v in versions) v.id];

    // The newest active score of each version, and the ids of every score the
    // backend still has active.
    final active = <String, Map<String, dynamic>>{};
    for (final chunk in SyncPolicy.chunk(versionIds, SyncContext.idChunkSize)) {
      final rows = await ctx.client
          .from('scores')
          .select('id, version_id, updated_at, deleted_at')
          .inFilter('version_id', chunk);
      for (final row in rows) {
        if (row['deleted_at'] != null) continue;
        final version = row['version_id'] as String;
        final best = active[version];
        if (best == null ||
            SyncPolicy.normalizeTimestamp(
                  row['updated_at'],
                ).compareTo(SyncPolicy.normalizeTimestamp(best['updated_at'])) >
                0) {
          active[version] = row;
        }
      }
    }
    final activeIds = {for (final r in active.values) r['id'] as String};

    final local = await (_db.select(
      _db.scores,
    )..where((t) => t.songId.isIn(versionIds))).get();
    final localById = {for (final s in local) s.id: s};

    final changed = <String>[];
    for (final row in active.values) {
      final id = row['id'] as String;
      final existing = localById[id];
      final stamp = SyncPolicy.normalizeTimestamp(row['updated_at']);
      if (SyncPolicy.shouldApplyRemote(
        local: existing == null
            ? null
            : SyncRow(
                id: id,
                isDirty: existing.isDirty,
                remoteUpdatedAt: existing.remoteUpdatedAt,
                deletedAt: existing.deletedAt,
              ),
        remoteUpdatedAt: stamp,
      )) {
        changed.add(id);
      }
    }

    // A version has one score: a clean synced copy the backend dropped or
    // replaced goes away.
    final stale = [
      for (final s in local)
        if (s.remoteUpdatedAt != null &&
            !s.isDirty &&
            s.deletedAt == null &&
            !activeIds.contains(s.id))
          s.id,
    ];

    for (final chunk in SyncPolicy.chunk(changed, SyncContext.rowChunkSize)) {
      final rows = await ctx.client
          .from('scores')
          .select()
          .inFilter('id', chunk);
      ctx.ensureCurrent();
      await _db.transaction(() async {
        for (final row in rows) {
          final id = row['id'] as String;
          final current = await (_db.select(
            _db.scores,
          )..where((t) => t.id.equals(id))).getSingleOrNull();
          if (current != null &&
              (current.isDirty || current.deletedAt != null)) {
            continue;
          }
          // Replace the previous score of the same version, if any.
          await (_db.delete(_db.scores)..where(
                (t) =>
                    t.songId.equals(row['version_id'] as String) &
                    t.id.equals(id).not() &
                    t.isDirty.equals(false),
              ))
              .go();
          await _db
              .into(_db.scores)
              .insertOnConflictUpdate(scoreCompanionFromRemote(row));
          ctx.pulled++;
        }
      });
    }
    if (stale.isNotEmpty) {
      ctx.ensureCurrent();
      await (_db.delete(_db.scores)..where((t) => t.id.isIn(stale))).go();
      ctx.pulled += stale.length;
    }
  }
}
