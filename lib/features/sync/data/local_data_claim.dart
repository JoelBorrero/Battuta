/// Battuta — First sign-in: claiming local-mode data and giving legacy rows
/// backend-compatible ids.
///
/// Both operate on the local Drift database only, so they are unit tested
/// without a backend.
library;

import 'dart:convert';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/sync/domain/services/sync_policy.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// How many local-mode rows an account claimed.
class ClaimResult {
  const ClaimResult({this.songs = 0, this.setlists = 0});

  final int songs;
  final int setlists;
}

/// Assigns the local-mode rows (`accountId == null`) to [accountId].
///
/// Songs become the account's **private** versions labelled "Original" and are
/// marked for upload; setlists become personal setlists. Bundled sample data
/// (`seed-*`) is never claimed, and rows another account already claimed are
/// not touched.
Future<ClaimResult> claimLocalData(AppDatabase db, String accountId) {
  return db.transaction(() async {
    final songRows =
        await (db.select(db.songs)..where(
              (t) =>
                  t.accountId.isNull() &
                  t.ownerId.isNull() &
                  t.deletedAt.isNull(),
            ))
            .get();
    var songs = 0;
    for (final row in songRows) {
      if (!SyncPolicy.isClaimable(row.id)) continue;
      await (db.update(db.songs)..where((t) => t.id.equals(row.id))).write(
        SongsCompanion(
          accountId: Value(accountId),
          ownerId: Value(accountId),
          label: const Value('Original'),
          visibility: const Value('private'),
          sharedOrganizationIdsJson: const Value('[]'),
          isDirty: const Value(true),
          editedAtMs: Value(SyncPolicy.nextEditMs(row.editedAtMs)),
        ),
      );
      songs++;
    }

    final setlistRows = await (db.select(
      db.setlists,
    )..where((t) => t.accountId.isNull() & t.deletedAt.isNull())).get();
    var setlists = 0;
    for (final row in setlistRows) {
      if (!SyncPolicy.isClaimable(row.id)) continue;
      await (db.update(db.setlists)..where((t) => t.id.equals(row.id))).write(
        SetlistsCompanion(
          accountId: Value(accountId),
          organizationId: const Value(null),
          isDirty: const Value(true),
          editedAtMs: Value(SyncPolicy.nextEditMs(row.editedAtMs)),
        ),
      );
      setlists++;
    }
    return ClaimResult(songs: songs, setlists: setlists);
  });
}

/// Replaces the non-UUID ids of the account's songs that never reached the
/// backend (`song_1700000000000`) with UUIDs, and follows the change in the
/// scores and setlist entries that point to them.
///
/// Returns how many songs were renamed.
Future<int> migrateLegacySongIds(
  AppDatabase db,
  String accountId, {
  Uuid uuid = const Uuid(),
}) {
  return db.transaction(() async {
    final rows =
        await (db.select(db.songs)..where(
              (t) =>
                  t.accountId.equals(accountId) &
                  t.ownerId.equals(accountId) &
                  t.remoteUpdatedAt.isNull(),
            ))
            .get();
    final renames = <String, String>{
      for (final row in rows)
        if (!SyncPolicy.isUuid(row.id) && SyncPolicy.isClaimable(row.id))
          row.id: uuid.v4(),
    };
    if (renames.isEmpty) return 0;

    for (final row in rows.where((r) => renames.containsKey(r.id))) {
      final newId = renames[row.id]!;
      await db
          .into(db.songs)
          .insert(row.toCompanion(true).copyWith(id: Value(newId)));
      await (db.delete(db.songs)..where((t) => t.id.equals(row.id))).go();
      await (db.update(db.scores)..where((t) => t.songId.equals(row.id))).write(
        ScoresCompanion(songId: Value(newId), isDirty: const Value(true)),
      );
    }

    // Setlist entries keep pointing to the renamed songs.
    final setlistRows = await db.select(db.setlists).get();
    for (final setlist in setlistRows) {
      if (!renames.keys.any(setlist.itemsJson.contains)) continue;
      final items = (jsonDecode(setlist.itemsJson) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      var changed = false;
      for (final item in items) {
        final target = renames[item['songId']];
        if (target != null) {
          item['songId'] = target;
          changed = true;
        }
      }
      if (!changed) continue;
      await (db.update(
        db.setlists,
      )..where((t) => t.id.equals(setlist.id))).write(
        SetlistsCompanion(
          itemsJson: Value(jsonEncode(items)),
          isDirty: Value(setlist.accountId == accountId),
          editedAtMs: Value(SyncPolicy.nextEditMs(setlist.editedAtMs)),
        ),
      );
    }
    return renames.length;
  });
}

/// A setlist ready to be pushed: UUID ids for the setlist (only while it never
/// reached the backend) and for every entry.
class SetlistIdMigration {
  const SetlistIdMigration({required this.id, required this.itemsJson});

  final String id;
  final String itemsJson;
}

/// Gives the setlist [row] backend-compatible ids, updating the local row.
/// Returns the (possibly new) id and entries JSON.
Future<SetlistIdMigration> migrateSetlistIds(
  AppDatabase db,
  SetlistEntry row, {
  Uuid uuid = const Uuid(),
}) async {
  final items = (jsonDecode(row.itemsJson) as List<dynamic>)
      .cast<Map<String, dynamic>>();
  var itemsChanged = false;
  for (final item in items) {
    final id = item['id'] as String?;
    if (id == null || !SyncPolicy.isUuid(id)) {
      item['id'] = uuid.v4();
      itemsChanged = true;
    }
  }
  final renameSetlist =
      row.remoteUpdatedAt == null && !SyncPolicy.isUuid(row.id);
  if (!itemsChanged && !renameSetlist) {
    return SetlistIdMigration(id: row.id, itemsJson: row.itemsJson);
  }
  final newJson = jsonEncode(items);
  final newId = renameSetlist ? uuid.v4() : row.id;
  await db.transaction(() async {
    if (renameSetlist) {
      await db
          .into(db.setlists)
          .insert(
            row
                .toCompanion(true)
                .copyWith(id: Value(newId), itemsJson: Value(newJson)),
          );
      await (db.delete(db.setlists)..where((t) => t.id.equals(row.id))).go();
    } else {
      await (db.update(db.setlists)..where((t) => t.id.equals(row.id))).write(
        SetlistsCompanion(itemsJson: Value(newJson)),
      );
    }
  });
  return SetlistIdMigration(id: newId, itemsJson: newJson);
}

/// Gives a local score a UUID id (the backend needs one). Returns the id.
Future<String> migrateScoreId(
  AppDatabase db,
  ScoreEntry row, {
  Uuid uuid = const Uuid(),
}) async {
  if (SyncPolicy.isUuid(row.id)) return row.id;
  final newId = uuid.v4();
  await db.transaction(() async {
    await db
        .into(db.scores)
        .insert(row.toCompanion(true).copyWith(id: Value(newId)));
    await (db.delete(db.scores)..where((t) => t.id.equals(row.id))).go();
  });
  return newId;
}
