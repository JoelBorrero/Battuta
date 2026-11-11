/// Battuta — Sync of setlists (personal and organization) and their entries.
///
/// A local setlist row carries its entries as JSON. On the backend an entry
/// links to a song version and keeps a title snapshot; when the version is gone
/// (deleted, unshared, made private) the entry stays as a read-only tombstone.
/// Organization setlists are read by members and written by admins; a push the
/// backend refuses is reported and does not stop the sync.
library;

import 'dart:convert';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/repertoire/data/repositories/setlist_row_mapper.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/sync/data/local_data_claim.dart';
import 'package:battuta/features/sync/data/sync_context.dart';
import 'package:battuta/features/sync/data/sync_mappers.dart';
import 'package:battuta/features/sync/domain/services/sync_policy.dart';
import 'package:drift/drift.dart';

class SetlistsSync {
  SetlistsSync(this.ctx);

  final SyncContext ctx;

  AppDatabase get _db => ctx.db;
  String get _me => ctx.accountId;

  // ---- Push ---------------------------------------------------------------

  Future<void> push() async {
    final rows = await (_db.select(
      _db.setlists,
    )..where((t) => t.accountId.equals(_me) & t.isDirty.equals(true))).get();
    for (final row in rows) {
      if (SyncPolicy.isLocalOnly(row.id)) continue;
      await ctx.guardRow('setlist "${row.title}"', () => _pushOne(row));
    }
  }

  Future<void> _pushOne(SetlistEntry original) async {
    ctx.ensureCurrent();
    var row = original;

    if (row.deletedAt != null) {
      await _pushDelete(row);
      return;
    }

    final ids = await migrateSetlistIds(_db, row);
    if (ids.id != row.id || ids.itemsJson != row.itemsJson) {
      row = await (_db.select(
        _db.setlists,
      )..where((t) => t.id.equals(ids.id))).getSingle();
    }

    final remote = await ctx.client
        .from('setlists')
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
        await (_db.update(_db.setlists)..where((t) => t.id.equals(row.id)))
            .write(const SetlistsCompanion(isDirty: Value(false)));
        return;
      }
    }

    final fields = {
      'title': row.title,
      'description': row.description,
      'event_date': row.eventDate?.toUtc().toIso8601String(),
      'tags_json': row.tagsJson,
      'edited_at': SyncPolicy.editedAtText(row.editedAtMs),
    };
    if (remote == null) {
      await ctx.client.from('setlists').insert({
        'id': row.id,
        'created_by': _me,
        if (row.organizationId == null)
          'owner_id': _me
        else
          'organization_id': row.organizationId,
        ...fields,
      });
    } else {
      await ctx.client.from('setlists').update(fields).eq('id', row.id);
    }

    await _pushItems(row);

    // Touch the setlist last, so its `updated_at` is later than the entries and
    // another device that sees the new stamp also finds the new entries.
    final touched = await ctx.client
        .from('setlists')
        .update({'title': row.title})
        .eq('id', row.id)
        .select('updated_at')
        .single();
    final stamp = SyncPolicy.normalizeTimestamp(touched['updated_at']);

    ctx.ensureCurrent();
    await _db.transaction(() async {
      await (_db.update(_db.setlists)..where((t) => t.id.equals(row.id))).write(
        SetlistsCompanion(remoteUpdatedAt: Value(stamp)),
      );
      // Edited again while the request ran (its edit time moved on): it stays
      // dirty and goes out on the next sync.
      await (_db.update(_db.setlists)..where(
            (t) =>
                t.id.equals(row.id) &
                t.editedAtMs.equals(row.editedAtMs) &
                t.itemsJson.equals(row.itemsJson),
          ))
          .write(const SetlistsCompanion(isDirty: Value(false)));
    });
    ctx.pushed++;
  }

  Future<void> _pushItems(SetlistEntry row) async {
    final setlist = setlistFromRow(row);
    final songIds = {
      for (final i in setlist.items)
        if (i.songId.isNotEmpty) i.songId,
    };
    final songs = songIds.isEmpty
        ? const <SongEntry>[]
        : await (_db.select(_db.songs)..where((t) => t.id.isIn(songIds))).get();
    final songsById = {for (final s in songs) s.id: s};

    final remoteItems = await ctx.client
        .from('setlist_items')
        .select()
        .eq('setlist_id', row.id);
    final remoteById = {for (final r in remoteItems) r['id'] as String: r};

    final payloads = <Map<String, dynamic>>[];
    for (final local in setlist.items) {
      final song = songsById[local.songId];
      // An entry nobody on this device can describe keeps the snapshot the
      // backend already has.
      final known = remoteById[local.id];
      final item = song == null && local.titleSnapshot == null && known != null
          ? local.copyWith(
              titleSnapshot: known['title_snapshot'] as String?,
              artistSnapshot: known['artist_snapshot'] as String?,
              labelSnapshot: known['label_snapshot'] as String?,
              keySnapshot: known['key_snapshot'] as String?,
            )
          : local;
      // Only versions that exist on the backend can be linked.
      final linkable =
          song != null &&
          song.remoteUpdatedAt != null &&
          song.deletedAt == null;
      payloads.add(
        setlistItemPayload(
          item,
          setlistId: row.id,
          organizationId: row.organizationId,
          versionId: linkable ? item.songId : null,
          info: song == null
              ? null
              : ItemSongInfo(
                  title: song.title,
                  artist: song.artist,
                  label: song.label,
                  key: song.key,
                ),
        ),
      );
    }

    final keep = {for (final p in payloads) p['id'] as String};
    final obsolete = [
      for (final id in remoteById.keys)
        if (!keep.contains(id)) id,
    ];
    if (obsolete.isNotEmpty) {
      await ctx.client.from('setlist_items').delete().inFilter('id', obsolete);
    }
    if (payloads.isNotEmpty) {
      await ctx.client.from('setlist_items').upsert(payloads);
    }
  }

  Future<void> _pushDelete(SetlistEntry row) async {
    if (row.remoteUpdatedAt == null) {
      ctx.ensureCurrent();
      await (_db.delete(_db.setlists)..where((t) => t.id.equals(row.id))).go();
      return;
    }
    final remote = await ctx.client
        .from('setlists')
        .select('id, updated_at, edited_at')
        .eq('id', row.id)
        .maybeSingle();
    ctx.ensureCurrent();
    if (remote != null) {
      final decision = SyncPolicy.decideDelete(
        deletedAtMs: row.editedAtMs,
        knownRemoteUpdatedAt: row.remoteUpdatedAt,
        remoteUpdatedAt: SyncPolicy.normalizeTimestamp(remote['updated_at']),
        remoteEditedMs: SyncPolicy.timestampMs(
          remote['edited_at'] ?? remote['updated_at'],
        ),
      );
      if (decision == DeleteDecision.keepRemote) {
        // Edited on another device after the deletion: the edit wins.
        await (_db.update(
          _db.setlists,
        )..where((t) => t.id.equals(row.id))).write(
          const SetlistsCompanion(
            isDirty: Value(false),
            deletedAt: Value(null),
          ),
        );
        return;
      }
      await ctx.client.from('setlists').delete().eq('id', row.id);
      ctx.pushed++;
    }
    await (_db.delete(_db.setlists)..where((t) => t.id.equals(row.id))).go();
  }

  // ---- Pull ---------------------------------------------------------------

  Future<void> pull() async {
    final remote = await ctx.fetchAll(
      (from, to) => ctx.client
          .from('setlists')
          .select('id, updated_at')
          .order('id')
          .range(from, to),
    );
    final stamps = {
      for (final r in remote)
        r['id'] as String: SyncPolicy.normalizeTimestamp(r['updated_at']),
    };

    final local = {
      for (final row in await (_db.select(
        _db.setlists,
      )..where((t) => t.accountId.equals(_me))).get())
        row.id: row,
    };
    SyncRow? syncRow(String id) {
      final row = local[id];
      return row == null
          ? null
          : SyncRow(
              id: id,
              isDirty: row.isDirty,
              remoteUpdatedAt: row.remoteUpdatedAt,
              deletedAt: row.deletedAt,
            );
    }

    final changed = [
      for (final entry in stamps.entries)
        if (SyncPolicy.shouldApplyRemote(
          local: syncRow(entry.key),
          remoteUpdatedAt: entry.value,
        ))
          entry.key,
    ];

    if (changed.isNotEmpty) {
      // Versions this device can show, and songs that only exist here.
      final songs = await (_db.select(
        _db.songs,
      )..where((t) => t.accountId.equals(_me) & t.deletedAt.isNull())).get();
      final visible = {
        for (final s in songs)
          if (s.remoteUpdatedAt != null) s.id,
      };
      final localOnly = {
        for (final s in songs)
          if (s.remoteUpdatedAt == null) s.id,
      };
      final localOnlyAll = {
        ...localOnly,
        ...(await (_db.select(
          _db.songs,
        )..where((t) => t.accountId.isNull())).get()).map((s) => s.id),
      };

      for (final chunk in SyncPolicy.chunk(changed, 25)) {
        final rows = await ctx.client
            .from('setlists')
            .select('*, setlist_items!setlist_items_setlist_fkey(*)')
            .inFilter('id', chunk);
        ctx.ensureCurrent();
        await _db.transaction(() async {
          for (final row in rows) {
            final id = row['id'] as String;
            final current = await (_db.select(
              _db.setlists,
            )..where((t) => t.id.equals(id))).getSingleOrNull();
            if (current != null &&
                (current.isDirty || current.deletedAt != null)) {
              continue;
            }
            final previous = current == null
                ? const <String, SetlistItem>{}
                : {for (final i in setlistFromRow(current).items) i.id: i};
            final remoteItems =
                ((row['setlist_items'] as List?) ?? const [])
                    .cast<Map<String, dynamic>>()
                  ..sort(
                    (a, b) => ((a['position'] as num?) ?? 0).compareTo(
                      (b['position'] as num?) ?? 0,
                    ),
                  );
            final items = [
              for (var i = 0; i < remoteItems.length; i++)
                setlistItemFromRemote(
                  remoteItems[i],
                  visibleVersionIds: visible,
                  localOnlySongIds: localOnlyAll,
                  local: previous[remoteItems[i]['id']],
                ).copyWith(orderIndex: i),
            ];
            final stamp = SyncPolicy.normalizeTimestamp(row['updated_at']);
            await _db
                .into(_db.setlists)
                .insertOnConflictUpdate(
                  SetlistsCompanion(
                    id: Value(id),
                    title: Value(row['title'] as String? ?? 'Untitled'),
                    description: Value(row['description'] as String?),
                    eventDate: Value(
                      DateTime.tryParse('${row['event_date']}')?.toLocal(),
                    ),
                    itemsJson: Value(
                      jsonEncode([for (final i in items) i.toJson()]),
                    ),
                    tagsJson: Value(row['tags_json'] as String? ?? '[]'),
                    createdAt: Value(
                      DateTime.tryParse('${row['created_at']}') ??
                          DateTime.parse(stamp),
                    ),
                    updatedAt: Value(DateTime.parse(stamp)),
                    organizationId: Value(row['organization_id'] as String?),
                    isDirty: const Value(false),
                    deletedAt: const Value(null),
                    remoteUpdatedAt: Value(stamp),
                    accountId: Value(_me),
                    editedAtMs: Value(
                      SyncPolicy.timestampMs(row['edited_at'] ?? stamp),
                    ),
                  ),
                );
            ctx.pulled++;
          }
        });
      }
    }

    final stale = SyncPolicy.staleIds(
      local: [
        for (final row in local.values)
          SyncRow(
            id: row.id,
            isDirty: row.isDirty,
            remoteUpdatedAt: row.remoteUpdatedAt,
            deletedAt: row.deletedAt,
          ),
      ],
      visibleIds: stamps.keys.toSet(),
    );
    if (stale.isNotEmpty) {
      ctx.ensureCurrent();
      await (_db.delete(_db.setlists)..where((t) => t.id.isIn(stale))).go();
      ctx.pulled += stale.length;
    }
  }
}
