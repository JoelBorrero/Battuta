import 'package:battuta/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'v1 -> v3 keeps songs, setlists and scores and adds the cache tables',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            // The exact v1 schema (before the backend cache tables existed).
            raw.execute('''
            CREATE TABLE songs (
              id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, artist TEXT NOT NULL,
              "key" TEXT NOT NULL, tempo INTEGER NOT NULL,
              time_signature_beats INTEGER NOT NULL DEFAULT 4,
              time_signature_beat_value INTEGER NOT NULL DEFAULT 4,
              sections_json TEXT NOT NULL DEFAULT '[]', tags_json TEXT NOT NULL DEFAULT '[]',
              cover_image_path TEXT NULL, notes TEXT NULL,
              created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
            raw.execute('''
            CREATE TABLE setlists (
              id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, description TEXT NULL,
              event_date INTEGER NULL, items_json TEXT NOT NULL DEFAULT '[]',
              tags_json TEXT NOT NULL DEFAULT '[]',
              created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
            raw.execute('''
            CREATE TABLE scores (
              id TEXT NOT NULL PRIMARY KEY, song_id TEXT NULL, title TEXT NOT NULL,
              composer TEXT NULL, artist TEXT NULL, time_signature_json TEXT NOT NULL,
              key_signature TEXT NOT NULL, tempo INTEGER NOT NULL,
              sections_json TEXT NOT NULL, metadata_json TEXT NOT NULL DEFAULT '{}',
              updated_at INTEGER NOT NULL)''');
            raw.execute(
              'INSERT INTO songs (id, title, artist, "key", tempo, created_at, updated_at) '
              'VALUES (?, ?, ?, ?, ?, ?, ?)',
              [
                's1',
                'Amazing Grace',
                'Newton',
                'G',
                80,
                1700000000,
                1700000000,
              ],
            );
            raw.execute(
              'INSERT INTO setlists (id, title, created_at, updated_at) VALUES (?, ?, ?, ?)',
              ['l1', 'Sunday', 1700000000, 1700000000],
            );
            raw.execute(
              'INSERT INTO scores (id, title, time_signature_json, key_signature, tempo, sections_json, updated_at) '
              'VALUES (?, ?, ?, ?, ?, ?, ?)',
              ['c1', 'Chart', '{}', 'G', 80, '[]', 1700000000],
            );
            raw.execute('PRAGMA user_version = 1');
          },
        ),
      );
      addTearDown(db.close);

      final songs = await db.select(db.songs).get();
      final setlists = await db.select(db.setlists).get();
      final scores = await db.select(db.scores).get();
      expect(songs.single.title, 'Amazing Grace');
      expect(setlists.single.title, 'Sunday');
      expect(scores.single.id, 'c1');

      // New tables exist and work.
      await db
          .into(db.cacheRecords)
          .insert(
            CacheRecordsCompanion.insert(
              accountId: 'u1',
              recordKind: 'organization',
              recordId: 'o1',
              json: '{}',
            ),
          );
      expect(await db.select(db.cacheRecords).get(), hasLength(1));
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), 3);
    },
  );

  test('a fresh database is created at v3 with every table', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(await db.select(db.songs).get(), isEmpty);
    expect(await db.select(db.cacheRecords).get(), isEmpty);
    expect(await db.select(db.cacheRefreshes).get(), isEmpty);
  });

  test(
    'v2 -> v3 keeps songs, setlists, scores and the cache, adding sync columns',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            // The exact v2 schema.
            raw.execute('''
            CREATE TABLE songs (
              id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, artist TEXT NOT NULL,
              "key" TEXT NOT NULL, tempo INTEGER NOT NULL,
              time_signature_beats INTEGER NOT NULL DEFAULT 4,
              time_signature_beat_value INTEGER NOT NULL DEFAULT 4,
              sections_json TEXT NOT NULL DEFAULT '[]', tags_json TEXT NOT NULL DEFAULT '[]',
              cover_image_path TEXT NULL, notes TEXT NULL,
              created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
            raw.execute('''
            CREATE TABLE setlists (
              id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, description TEXT NULL,
              event_date INTEGER NULL, items_json TEXT NOT NULL DEFAULT '[]',
              tags_json TEXT NOT NULL DEFAULT '[]',
              created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
            raw.execute('''
            CREATE TABLE scores (
              id TEXT NOT NULL PRIMARY KEY, song_id TEXT NULL, title TEXT NOT NULL,
              composer TEXT NULL, artist TEXT NULL, time_signature_json TEXT NOT NULL,
              key_signature TEXT NOT NULL, tempo INTEGER NOT NULL,
              sections_json TEXT NOT NULL, metadata_json TEXT NOT NULL DEFAULT '{}',
              updated_at INTEGER NOT NULL)''');
            raw.execute('''
            CREATE TABLE cache_records (
              account_id TEXT NOT NULL, record_kind TEXT NOT NULL, record_id TEXT NOT NULL,
              scope_id TEXT NOT NULL DEFAULT '', json TEXT NOT NULL,
              PRIMARY KEY (account_id, record_kind, record_id))''');
            raw.execute('''
            CREATE TABLE cache_refreshes (
              account_id TEXT NOT NULL, record_kind TEXT NOT NULL,
              scope_id TEXT NOT NULL DEFAULT '', refreshed_at INTEGER NOT NULL,
              PRIMARY KEY (account_id, record_kind, scope_id))''');
            raw.execute(
              'INSERT INTO songs (id, title, artist, "key", tempo, created_at, updated_at) '
              'VALUES (?, ?, ?, ?, ?, ?, ?)',
              [
                'song_1700000000000',
                'Amazing Grace',
                'Newton',
                'G',
                80,
                1700000000,
                1700000000,
              ],
            );
            raw.execute(
              'INSERT INTO setlists (id, title, items_json, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
              [
                'setlist_1',
                'Sunday',
                '[{"id":"i1","songId":"song_1700000000000","orderIndex":0}]',
                1700000000,
                1700000000,
              ],
            );
            raw.execute(
              'INSERT INTO scores (id, song_id, title, time_signature_json, key_signature, tempo, sections_json, updated_at) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
              [
                'c1',
                'song_1700000000000',
                'Chart',
                '{}',
                'G',
                80,
                '[]',
                1700000000,
              ],
            );
            raw.execute(
              'INSERT INTO cache_records (account_id, record_kind, record_id, json) VALUES (?, ?, ?, ?)',
              ['u1', 'organization', 'o1', '{"id":"o1"}'],
            );
            raw.execute('PRAGMA user_version = 2');
          },
        ),
      );
      addTearDown(db.close);

      final song = (await db.select(db.songs).get()).single;
      expect(song.title, 'Amazing Grace');
      // Existing rows are local-mode data: unowned, unclaimed, never synced.
      expect(song.songWorkId, isNull);
      expect(song.ownerId, isNull);
      expect(song.accountId, isNull);
      expect(song.label, 'Original');
      expect(song.visibility, 'private');
      expect(song.sharedOrganizationIdsJson, '[]');
      expect(song.isDirty, isFalse);
      expect(song.deletedAt, isNull);
      expect(song.remoteUpdatedAt, isNull);
      // The edit time starts at the last update (Drift stores seconds).
      expect(song.editedAtMs, 1700000000000);
      expect(song.sharingDirty, isFalse);

      final setlist = (await db.select(db.setlists).get()).single;
      expect(setlist.title, 'Sunday');
      expect(setlist.itemsJson, contains('song_1700000000000'));
      expect(setlist.organizationId, isNull);
      expect(setlist.accountId, isNull);
      expect(setlist.isDirty, isFalse);
      expect(setlist.editedAtMs, 1700000000000);

      final score = (await db.select(db.scores).get()).single;
      expect(score.songId, 'song_1700000000000');
      expect(score.isDirty, isFalse);
      expect(score.remoteUpdatedAt, isNull);
      expect(score.editedAtMs, 1700000000000);

      // The 003 cache survives.
      final cached = (await db.select(db.cacheRecords).get()).single;
      expect(cached.recordId, 'o1');

      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), 3);
    },
  );
}
