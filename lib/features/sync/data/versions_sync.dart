/// Battuta — Sync of song versions (`songs` + `song_versions` + shares).
///
/// A local [SongEntry] is one backend version. Push sends the account's own
/// dirty versions; pull downloads the versions the account can read and keeps
/// offline: its own, those in the repertoire of its organizations and those
/// its setlists point to. Everything else the backend shows (other users'
/// public versions) is fetched online only.
library;

import 'dart:convert';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/repertoire/data/repositories/song_row_mapper.dart';
import 'package:battuta/features/sync/data/sync_context.dart';
import 'package:battuta/features/sync/data/sync_mappers.dart';
import 'package:battuta/features/sync/domain/services/sync_policy.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:uuid/uuid.dart';

/// Whether the backend refused a share for good (row-level security or a
/// constraint), as opposed to a transient failure worth retrying.
bool isRefusedShare(PostgrestException e) {
  final code = e.code ?? '';
  return code == '42501' || code.startsWith('23');
}

class VersionsSync {
  VersionsSync(this.ctx, {this._uuid = const Uuid()});

  final SyncContext ctx;
  final Uuid _uuid;

  AppDatabase get _db => ctx.db;
  String get _me => ctx.accountId;

  // ---- Push ---------------------------------------------------------------

  Future<void> push() async {
    final rows =
        await (_db.select(_db.songs)..where(
              (t) =>
                  t.accountId.equals(_me) &
                  t.ownerId.equals(_me) &
                  t.isDirty.equals(true),
            ))
            .get();
    // A fork is pushed after the version it was made from (its lineage must
    // point at a version that already exists).
    final pending = {for (final row in rows) row.id};
    final ordered = <SongEntry>[];
    var waiting = rows;
    while (waiting.isNotEmpty) {
      final ready = [
        for (final row in waiting)
          if (!pending.contains(row.forkedFromVersionId)) row,
      ];
      // A cycle cannot happen; if it ever does, push the rest as they are.
      final batch = ready.isEmpty ? waiting : ready;
      ordered.addAll(batch);
      pending.removeAll(batch.map((r) => r.id));
      waiting = [
        for (final row in waiting)
          if (!batch.contains(row)) row,
      ];
    }
    for (final row in ordered) {
      if (SyncPolicy.isLocalOnly(row.id) || !SyncPolicy.isUuid(row.id)) {
        continue;
      }
      await ctx.guardRow('song "${row.title}"', () => _pushOne(row));
    }
  }

  Future<void> _pushOne(SongEntry row) async {
    final remote = await ctx.client
        .from('song_versions')
        .select('id, updated_at, edited_at, song_id')
        .eq('id', row.id)
        .maybeSingle();
    final remoteStamp = remote == null
        ? null
        : SyncPolicy.normalizeTimestamp(remote['updated_at']);

    if (row.deletedAt != null) {
      await _pushDelete(row, remote, remoteStamp);
      return;
    }

    String? stamp;
    var workId = row.songWorkId ?? remote?['song_id'] as String?;
    if (remote != null) {
      final decision = SyncPolicy.decidePush(
        localEditedMs: row.editedAtMs,
        knownRemoteUpdatedAt: row.remoteUpdatedAt,
        remoteUpdatedAt: remoteStamp!,
        remoteEditedMs: SyncPolicy.timestampMs(
          remote['edited_at'] ?? remote['updated_at'],
        ),
      );
      if (decision == PushDecision.remoteWins) {
        // Another device edited it later: drop this edit, the pull applies it.
        // A sharing change is a separate decision and still goes out.
        if (row.sharingDirty) {
          await _pushSharing(row);
        }
      } else {
        await _ensureWork(workId!, row);
        await ctx.client
            .from('song_versions')
            .update(versionUpdatePayload(row, withSharing: row.sharingDirty))
            .eq('id', row.id);
        if (row.sharingDirty) await _pushShares(row);
        final updated = await ctx.client
            .from('song_versions')
            .select('updated_at, song_id')
            .eq('id', row.id)
            .single();
        stamp = SyncPolicy.normalizeTimestamp(updated['updated_at']);
        workId = updated['song_id'] as String?;
      }
    } else {
      // A pending edit on a version the backend no longer has (the owner
      // deleted it on another device) creates it again: the edit is kept.
      workId ??= _uuid.v4();
      await _ensureWork(workId, row);
      // No `returning`: the select policy of a version cannot see the row
      // inside the statement that creates it.
      await ctx.client
          .from('song_versions')
          .insert(versionInsertPayload(row, workId: workId, ownerId: _me));
      await _pushShares(row);
      final inserted = await ctx.client
          .from('song_versions')
          .select('updated_at, song_id')
          .eq('id', row.id)
          .single();
      stamp = SyncPolicy.normalizeTimestamp(inserted['updated_at']);
      workId = inserted['song_id'] as String?;
    }

    ctx.ensureCurrent();
    await _db.transaction(() async {
      if (row.sharingDirty) await _clearSharingDirty(row);
      if (stamp != null) {
        await (_db.update(_db.songs)..where((t) => t.id.equals(row.id))).write(
          SongsCompanion(
            remoteUpdatedAt: Value(stamp),
            songWorkId: Value(workId),
          ),
        );
      }
      // The user may have edited the song while the request was in flight (its
      // edit time moved on): then it stays dirty and goes out on the next sync.
      await (_db.update(_db.songs)..where(
            (t) =>
                t.id.equals(row.id) &
                t.editedAtMs.equals(row.editedAtMs) &
                t.sharingDirty.equals(false),
          ))
          .write(const SongsCompanion(isDirty: Value(false)));
      if (remote == null) {
        // Setlists that pointed to this song before it existed remotely must
        // be pushed again so their entries link to the version.
        await (_db.update(_db.setlists)..where(
              (t) =>
                  t.accountId.equals(_me) &
                  t.itemsJson.like('%"songId":"${row.id}"%'),
            ))
            .write(const SetlistsCompanion(isDirty: Value(true)));
      }
    });
    ctx.pushed++;
  }

  /// Pushes label and visibility on their own (the content lost its conflict),
  /// then the shares.
  Future<void> _pushSharing(SongEntry row) async {
    await ctx.client
        .from('song_versions')
        .update(versionSharingPayload(row))
        .eq('id', row.id);
    await _pushShares(row);
  }

  /// Applies the difference between the shares of [row] and the backend's.
  ///
  /// A share the backend refuses (an organization the owner is not a member
  /// of, say) is reported once; the local copy then takes the backend's state
  /// so the change is not retried on every sync. Each organization is added on
  /// its own, so one refused share never drops the others. Any other error
  /// (network, timeout) propagates: the row stays dirty and is retried later
  /// instead of silently reverting the user's change.
  Future<void> _pushShares(SongEntry row) async {
    final wanted = row.visibility == 'organizations'
        ? decodeStringList(row.sharedOrganizationIdsJson).toSet()
        : <String>{};
    final current = {
      for (final r
          in await ctx.client
              .from('version_shares')
              .select('organization_id')
              .eq('version_id', row.id))
        r['organization_id'] as String,
    };
    final remove = current.difference(wanted);
    if (remove.isNotEmpty) {
      await ctx.client
          .from('version_shares')
          .delete()
          .eq('version_id', row.id)
          .inFilter('organization_id', remove.toList());
    }
    var refused = false;
    for (final org in wanted.difference(current)) {
      try {
        await ctx.client.from('version_shares').insert({
          'version_id': row.id,
          'organization_id': org,
        });
      } on PostgrestException catch (e, st) {
        if (!isRefusedShare(e)) rethrow;
        ctx.report('sharing of "${row.title}"', e, st);
        refused = true;
      }
    }
    if (refused) await _adoptRemoteSharing(row);
  }

  /// Replaces the local label, visibility and shares with the backend's.
  Future<void> _adoptRemoteSharing(SongEntry row) async {
    final remote = await ctx.client
        .from('song_versions')
        .select('label, visibility, version_shares(organization_id)')
        .eq('id', row.id)
        .maybeSingle();
    if (remote == null) return;
    ctx.ensureCurrent();
    await (_db.update(_db.songs)..where((t) => t.id.equals(row.id))).write(
      SongsCompanion(
        label: Value(remote['label'] as String? ?? row.label),
        visibility: Value(remote['visibility'] as String? ?? row.visibility),
        sharedOrganizationIdsJson: Value(
          jsonEncode([
            for (final s in (remote['version_shares'] as List?) ?? const [])
              (s as Map)['organization_id'] as String,
          ]),
        ),
        sharingDirty: const Value(false),
      ),
    );
  }

  /// Clears the sharing flag unless label, visibility or shares changed again
  /// while the push was running.
  Future<void> _clearSharingDirty(SongEntry row) async {
    await (_db.update(_db.songs)..where(
          (t) =>
              t.id.equals(row.id) &
              t.label.equals(row.label) &
              t.visibility.equals(row.visibility) &
              t.sharedOrganizationIdsJson.equals(row.sharedOrganizationIdsJson),
        ))
        .write(const SongsCompanion(sharingDirty: Value(false)));
  }

  /// Creates the work on first push; its creator keeps title and artist in sync.
  Future<void> _ensureWork(String workId, SongEntry row) async {
    final work = await ctx.client
        .from('songs')
        .select('id, created_by, title, artist')
        .eq('id', workId)
        .maybeSingle();
    if (work == null) {
      await ctx.client.from('songs').insert({
        'id': workId,
        'title': row.title,
        'artist': row.artist,
        'created_by': _me,
      });
    } else if (work['created_by'] == _me &&
        (work['title'] != row.title || work['artist'] != row.artist)) {
      await ctx.client
          .from('songs')
          .update({'title': row.title, 'artist': row.artist})
          .eq('id', workId);
    }
  }

  Future<void> _pushDelete(
    SongEntry row,
    Map<String, dynamic>? remote,
    String? remoteStamp,
  ) async {
    var deleteRemote = remoteStamp != null;
    if (remoteStamp != null) {
      deleteRemote =
          SyncPolicy.decideDelete(
            deletedAtMs: row.editedAtMs,
            knownRemoteUpdatedAt: row.remoteUpdatedAt,
            remoteUpdatedAt: remoteStamp,
            remoteEditedMs: SyncPolicy.timestampMs(
              remote!['edited_at'] ?? remote['updated_at'],
            ),
          ) ==
          DeleteDecision.deleteRemote;
    }
    ctx.ensureCurrent();
    if (remoteStamp != null && !deleteRemote) {
      // Edited elsewhere after the deletion: the edit wins, the pull restores it.
      await (_db.update(_db.songs)..where((t) => t.id.equals(row.id))).write(
        const SongsCompanion(isDirty: Value(false), deletedAt: Value(null)),
      );
      return;
    }
    if (remoteStamp != null) {
      await ctx.client.from('song_versions').delete().eq('id', row.id);
      ctx.pushed++;
    }
    await removeLocal([row.id]);
  }

  // ---- Pull ---------------------------------------------------------------

  /// Downloads changed versions and removes the ones the account can no longer
  /// see. Returns the ids of every version the backend showed.
  Future<Set<String>> pull() async {
    final orgs = await ctx.client.rpc('my_organizations');
    final orgIds = [
      for (final o in (orgs as List<dynamic>)) (o as Map)['id'] as String,
    ];

    final stamps = <String, String>{};
    final mine = await ctx.fetchAll(
      (from, to) => ctx.client
          .from('song_versions')
          .select('id, updated_at')
          .eq('owner_id', _me)
          .order('id')
          .range(from, to),
    );
    for (final row in mine) {
      stamps[row['id'] as String] = SyncPolicy.normalizeTimestamp(
        row['updated_at'],
      );
    }

    final candidates = <String>{};
    if (orgIds.isNotEmpty) {
      final repertoire = await ctx.fetchAll(
        (from, to) => ctx.client
            .from('organization_repertoire')
            .select('version_id')
            .inFilter('organization_id', orgIds)
            .order('version_id')
            .range(from, to),
      );
      candidates.addAll([
        for (final r in repertoire) r['version_id'] as String,
      ]);
    }
    final referenced = await ctx.fetchAll(
      (from, to) => ctx.client
          .from('setlist_items')
          .select('version_id')
          .not('version_id', 'is', null)
          .order('id')
          .range(from, to),
    );
    candidates.addAll([for (final r in referenced) r['version_id'] as String]);
    candidates.removeAll(stamps.keys);

    // The backend only returns the candidates this account can read.
    for (final chunk in SyncPolicy.chunk(
      candidates.toList(),
      SyncContext.idChunkSize,
    )) {
      final rows = await ctx.client
          .from('song_versions')
          .select('id, updated_at')
          .inFilter('id', chunk);
      for (final row in rows) {
        stamps[row['id'] as String] = SyncPolicy.normalizeTimestamp(
          row['updated_at'],
        );
      }
    }

    final local = await _localRows();
    final changed = [
      for (final entry in stamps.entries)
        if (SyncPolicy.shouldApplyRemote(
          local: local[entry.key] == null ? null : _syncRow(local[entry.key]!),
          remoteUpdatedAt: entry.value,
        ))
          entry.key,
    ];
    for (final chunk in SyncPolicy.chunk(changed, SyncContext.rowChunkSize)) {
      final rows = await ctx.client
          .from('song_versions')
          .select(
            '*, songs(id, title, artist), version_shares(organization_id)',
          )
          .inFilter('id', chunk);
      ctx.ensureCurrent();
      await _db.transaction(() async {
        for (final row in rows) {
          final companion = songCompanionFromRemote(row, accountId: _me);
          final current = await (_db.select(
            _db.songs,
          )..where((t) => t.id.equals(row['id'] as String))).getSingleOrNull();
          // A local edit made while the download ran stays.
          if (current != null &&
              (current.isDirty || current.deletedAt != null)) {
            continue;
          }
          await _db.into(_db.songs).insertOnConflictUpdate(companion);
          ctx.pulled++;
        }
      });
    }

    final stale = SyncPolicy.staleIds(
      local: [
        for (final row in local.values)
          if (row.accountId == _me) _syncRow(row),
      ],
      visibleIds: stamps.keys.toSet(),
    );
    if (stale.isNotEmpty) {
      ctx.ensureCurrent();
      await removeLocal(stale);
      ctx.pulled += stale.length;
    }

    await _refreshWorks();
    return stamps.keys.toSet();
  }

  /// Keeps title and artist of cached versions in step with their work, and
  /// follows works that were merged into another one.
  Future<void> _refreshWorks() async {
    final rows =
        await (_db.select(_db.songs)..where(
              (t) =>
                  t.accountId.equals(_me) &
                  t.isDirty.equals(false) &
                  t.deletedAt.isNull() &
                  t.songWorkId.isNotNull(),
            ))
            .get();
    final byWork = <String, List<SongEntry>>{};
    for (final row in rows) {
      byWork.putIfAbsent(row.songWorkId!, () => []).add(row);
    }
    for (final chunk in SyncPolicy.chunk(
      byWork.keys.toList(),
      SyncContext.idChunkSize,
    )) {
      final works = await ctx.client
          .from('songs')
          .select('id, title, artist, merged_into_id')
          .inFilter('id', chunk);
      for (final work in works) {
        var survivor = work;
        if (work['merged_into_id'] != null) {
          final resolved = await ctx.client.rpc(
            'resolve_song',
            params: {'p_song': work['id']},
          );
          if (resolved is String && resolved != work['id']) {
            final target = await ctx.client
                .from('songs')
                .select('id, title, artist, merged_into_id')
                .eq('id', resolved)
                .maybeSingle();
            if (target != null) survivor = target;
          }
        }
        for (final row in byWork[work['id']] ?? const <SongEntry>[]) {
          final title = survivor['title'] as String;
          final artist = survivor['artist'] as String? ?? '';
          final workId = survivor['id'] as String;
          if (row.title == title &&
              row.artist == artist &&
              row.songWorkId == workId) {
            continue;
          }
          ctx.ensureCurrent();
          await (_db.update(
            _db.songs,
          )..where((t) => t.id.equals(row.id) & t.isDirty.equals(false))).write(
            SongsCompanion(
              title: Value(title),
              artist: Value(artist),
              songWorkId: Value(workId),
            ),
          );
          ctx.pulled++;
        }
      }
    }
  }

  // ---- Helpers ------------------------------------------------------------

  Future<Map<String, SongEntry>> _localRows() async {
    final rows = await (_db.select(
      _db.songs,
    )..where((t) => t.accountId.equals(_me))).get();
    return {for (final row in rows) row.id: row};
  }

  SyncRow _syncRow(SongEntry row) => SyncRow(
    id: row.id,
    isDirty: row.isDirty,
    remoteUpdatedAt: row.remoteUpdatedAt,
    deletedAt: row.deletedAt,
  );

  /// Deletes versions (and their scores) from the device.
  Future<void> removeLocal(List<String> ids) async {
    await _db.transaction(() async {
      await (_db.delete(_db.scores)..where((t) => t.songId.isIn(ids))).go();
      await (_db.delete(_db.songs)..where((t) => t.id.isIn(ids))).go();
    });
  }
}
