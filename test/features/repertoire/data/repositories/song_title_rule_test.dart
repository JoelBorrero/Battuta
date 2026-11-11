import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/repertoire/data/repositories/drift_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/features/repertoire/domain/repositories/song_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_account_session.dart';

void main() {
  late AppDatabase db;
  late FakeAccountSession session;
  late SongRepository songs;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    session = FakeAccountSession('u-me');
    songs = DriftSongRepository(db, session: session);
  });
  tearDown(() => db.close());

  Future<void> insert(
    String id, {
    String owner = 'u-me',
    String? creator,
    String title = 'Amazing Grace',
  }) => db
      .into(db.songs)
      .insert(
        SongsCompanion.insert(
          id: id,
          title: title,
          artist: 'Newton',
          key: 'G',
          tempo: 72,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          ownerId: Value(owner),
          accountId: const Value('u-me'),
          songCreatorId: Value(creator),
        ),
      );

  Future<Song> load(String id) async =>
      (await songs.getSongById(id)).getOrElse((_) => throw 'missing $id');

  group('title and artist belong to the song', () {
    test('the creator of the song changes them', () async {
      await insert('v1', creator: 'u-me');
      final saved = (await songs.saveSong(
        (await load('v1')).copyWith(title: 'New title', artist: 'New artist'),
      )).getOrElse((_) => throw 'x');
      expect(saved.title, 'New title');
      expect((await load('v1')).artist, 'New artist');
    });

    test(
      'an owner who did not create the song keeps the shared title',
      () async {
        await insert('v1', creator: 'u-x');
        final saved = (await songs.saveSong(
          (await load('v1'))
              .copyWith(title: 'My own title', artist: 'Somebody', key: 'D'),
        )).getOrElse((_) => throw 'x');
        // The rest of the version is still theirs to edit.
        expect(saved.key, 'D');
        expect(saved.title, 'Amazing Grace');
        expect(saved.artist, 'Newton');
        expect((await load('v1')).title, 'Amazing Grace');
      },
    );

    test('a creator that is not known yet counts as the owner', () async {
      await insert('v1');
      final saved = (await songs.saveSong(
        (await load('v1')).copyWith(title: 'Renamed'),
      )).getOrElse((_) => throw 'x');
      expect(saved.title, 'Renamed');
    });

    test('a new song starts with the title it was given', () async {
      final saved = (await songs.saveSong(
        Song(
          id: 'new',
          title: 'Fresh',
          artist: 'Me',
          key: 'C',
          tempo: 90,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          songCreatorId: 'u-x',
        ),
      )).getOrElse((_) => throw 'x');
      expect(saved.title, 'Fresh');
    });
  });

  group('updateSharing on the interface', () {
    test(
      'changes label, visibility and shares and marks the row for sync',
      () async {
        await insert('v1', creator: 'u-me');
        final updated = (await songs.updateSharing(
          'v1',
          label: ' Acoustic ',
          visibility: SongVisibility.organizations,
          sharedOrganizationIds: const ['org-1', 'org-2'],
        )).getOrElse((_) => throw 'x');

        expect(updated.label, 'Acoustic');
        expect(updated.visibility, SongVisibility.organizations);
        expect(updated.sharedOrganizationIds, ['org-1', 'org-2']);
        final row = await (db.select(db.songs)).getSingle();
        expect(row.sharingDirty, isTrue);
        expect(row.isDirty, isTrue);
      },
    );

    test('going private or public clears the shares', () async {
      await insert('v1');
      await songs.updateSharing(
        'v1',
        visibility: SongVisibility.organizations,
        sharedOrganizationIds: const ['org-1'],
      );
      final publicNow = (await songs.updateSharing(
        'v1',
        visibility: SongVisibility.public,
      )).getOrElse((_) => throw 'x');
      expect(publicNow.sharedOrganizationIds, isEmpty);
    });

    test('is refused on somebody else\'s version', () async {
      await insert('v1', owner: 'u-x');
      final result = await songs.updateSharing(
        'v1',
        visibility: SongVisibility.public,
      );
      expect(result.isLeft(), isTrue);
      expect((await load('v1')).visibility, SongVisibility.private);
    });
  });
}
