import 'dart:convert';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/sync/data/local_data_claim.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _uuid = '3f2b8c4e-1a2b-4c3d-8e9f-0a1b2c3d4e5f';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> song(
    String id, {
    String? account,
    String? owner,
    String? remote,
  }) => db
      .into(db.songs)
      .insert(
        SongsCompanion.insert(
          id: id,
          title: id,
          artist: 'a',
          key: 'C',
          tempo: 100,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          accountId: Value(account),
          ownerId: Value(owner),
          remoteUpdatedAt: Value(remote),
        ),
      );

  Future<void> setlist(String id, String itemsJson, {String? account}) => db
      .into(db.setlists)
      .insert(
        SetlistsCompanion.insert(
          id: id,
          title: id,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          itemsJson: Value(itemsJson),
          accountId: Value(account),
        ),
      );

  group('claimLocalData', () {
    test(
      'claims local-mode songs as private "Original" versions to upload',
      () async {
        await song('song_1');
        await song('song_2');
        final result = await claimLocalData(db, 'u1');
        expect(result.songs, 2);
        final rows = await db.select(db.songs).get();
        for (final row in rows) {
          expect(row.accountId, 'u1');
          expect(row.ownerId, 'u1');
          expect(row.visibility, 'private');
          expect(row.label, 'Original');
          expect(row.isDirty, isTrue);
        }
      },
    );

    test('never claims bundled samples', () async {
      await song('seed-way-maker');
      await setlist('seed-setlist-sunday', '[]');
      final result = await claimLocalData(db, 'u1');
      expect(result.songs, 0);
      expect(result.setlists, 0);
      expect((await db.select(db.songs).getSingle()).accountId, isNull);
      expect((await db.select(db.setlists).getSingle()).accountId, isNull);
    });

    test('does not take rows another account already claimed', () async {
      await song('song_a', account: 'u1', owner: 'u1');
      await song('song_b');
      await setlist('list_a', '[]', account: 'u1');
      final result = await claimLocalData(db, 'u2');
      expect(result.songs, 1);
      expect(result.setlists, 0);
      final byId = {for (final s in await db.select(db.songs).get()) s.id: s};
      expect(byId['song_a']!.ownerId, 'u1');
      expect(byId['song_b']!.ownerId, 'u2');
      expect((await db.select(db.setlists).getSingle()).accountId, 'u1');
    });

    test('claims local setlists as personal ones', () async {
      await setlist('setlist_1', '[]');
      final result = await claimLocalData(db, 'u1');
      expect(result.setlists, 1);
      final row = await db.select(db.setlists).getSingle();
      expect(row.accountId, 'u1');
      expect(row.organizationId, isNull);
      expect(row.isDirty, isTrue);
    });
  });

  group('migrateLegacySongIds', () {
    test(
      'renames unsynced legacy ids and follows scores and setlist entries',
      () async {
        await song('song_1700000000000', account: 'u1', owner: 'u1');
        await song(_uuid, account: 'u1', owner: 'u1');
        await song('song_synced', account: 'u1', owner: 'u1', remote: 'A');
        await db
            .into(db.scores)
            .insert(
              ScoresCompanion.insert(
                id: 's1',
                songId: const Value('song_1700000000000'),
                title: 'c',
                timeSignatureJson: '{}',
                keySignature: 'C',
                tempo: 100,
                sectionsJson: '[]',
                updatedAt: DateTime(2026),
              ),
            );
        await setlist(
          'list',
          jsonEncode([
            {'id': 'i1', 'songId': 'song_1700000000000', 'orderIndex': 0},
            {'id': 'i2', 'songId': 'seed-x', 'orderIndex': 1},
          ]),
          account: 'u1',
        );

        expect(await migrateLegacySongIds(db, 'u1'), 1);

        final ids = (await db.select(db.songs).get()).map((s) => s.id).toSet();
        expect(ids, contains(_uuid));
        expect(ids, contains('song_synced'));
        expect(ids, isNot(contains('song_1700000000000')));
        final newId = ids.firstWhere((i) => i != _uuid && i != 'song_synced');
        expect(RegExp(r'^[0-9a-f-]{36}$').hasMatch(newId), isTrue);

        expect((await db.select(db.scores).getSingle()).songId, newId);
        final items = jsonDecode(
          (await db.select(db.setlists).getSingle()).itemsJson,
        ) as List;
        expect(items[0]['songId'], newId);
        expect(items[1]['songId'], 'seed-x');
        expect((await db.select(db.setlists).getSingle()).isDirty, isTrue);
      },
    );

    test('is a no-op when nothing is legacy', () async {
      await song(_uuid, account: 'u1', owner: 'u1');
      expect(await migrateLegacySongIds(db, 'u1'), 0);
    });

    test('leaves other accounts and unclaimed rows alone', () async {
      await song('song_other', account: 'u2', owner: 'u2');
      await song('song_unclaimed');
      expect(await migrateLegacySongIds(db, 'u1'), 0);
    });
  });

  group('migrateSetlistIds', () {
    test('gives a never-synced setlist and its entries UUIDs', () async {
      await setlist(
        'setlist_1700',
        jsonEncode([
          {'id': 'item_1_0', 'songId': 'a', 'orderIndex': 0},
          {'id': _uuid, 'songId': 'b', 'orderIndex': 1},
        ]),
        account: 'u1',
      );
      final row = await db.select(db.setlists).getSingle();
      final migrated = await migrateSetlistIds(db, row);
      expect(migrated.id, isNot('setlist_1700'));
      final stored = await db.select(db.setlists).getSingle();
      expect(stored.id, migrated.id);
      final items = jsonDecode(stored.itemsJson) as List;
      expect(items[0]['id'], isNot('item_1_0'));
      expect(items[1]['id'], _uuid);
    });

    test('a synced setlist keeps its id but its entries get UUIDs', () async {
      await setlist(
        'setlist_synced',
        jsonEncode([
          {'id': 'item_9', 'songId': 'a', 'orderIndex': 0},
        ]),
        account: 'u1',
      );
      await (db.update(db.setlists))
          .write(const SetlistsCompanion(remoteUpdatedAt: Value('A')));
      final row = await db.select(db.setlists).getSingle();
      final migrated = await migrateSetlistIds(db, row);
      expect(migrated.id, 'setlist_synced');
      final items = jsonDecode(migrated.itemsJson) as List;
      expect(items.single['id'], isNot('item_9'));
    });

    test('already compliant rows are untouched', () async {
      await setlist(
        _uuid,
        jsonEncode([
          {'id': _uuid, 'songId': 'a', 'orderIndex': 0},
        ]),
        account: 'u1',
      );
      final row = await db.select(db.setlists).getSingle();
      final migrated = await migrateSetlistIds(db, row);
      expect(migrated.id, _uuid);
      expect(migrated.itemsJson, row.itemsJson);
    });
  });
}
