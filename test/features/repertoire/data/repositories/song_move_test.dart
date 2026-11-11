import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/repertoire/data/repositories/drift_song_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_account_session.dart';

void main() {
  late AppDatabase db;
  late DriftSongRepository songs;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    songs = DriftSongRepository(db, session: FakeAccountSession('u-me'));
  });
  tearDown(() => db.close());

  Future<void> insert(
    String id, {
    String owner = 'u-me',
    String? remote = '2026-11-01T10:00:00.000Z',
  }) => db
      .into(db.songs)
      .insert(
        SongsCompanion.insert(
          id: id,
          title: 'Way Maker (wrong)',
          artist: 'Nobody',
          key: 'E',
          tempo: 68,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          songWorkId: const Value('work-wrong'),
          ownerId: Value(owner),
          accountId: const Value('u-me'),
          remoteUpdatedAt: Value(remote),
          songCreatorId: const Value('u-me'),
        ),
      );

  Future<SongEntry> row(String id) =>
      (db.select(db.songs)..where((t) => t.id.equals(id))).getSingle();

  group('moveToSong', () {
    test('queues the move and takes the new song title', () async {
      await insert('v1');
      final moved = (await songs.moveToSong(
        'v1',
        songWorkId: 'work-right',
        title: 'Way Maker',
        artist: 'Sinach',
        songCreatorId: 'u-x',
      )).getOrElse((_) => throw 'x');
      expect(moved.songWorkId, 'work-right');
      expect(moved.title, 'Way Maker');
      expect(moved.artist, 'Sinach');
      expect(moved.songCreatorId, 'u-x');
      // The creator is somebody else now: the title is no longer editable.
      expect(moved.canEditTitleBy('u-me'), isFalse);
      final stored = await row('v1');
      expect(stored.isDirty, isTrue);
      expect(stored.moveDirty, isTrue);
      expect(stored.key, 'E', reason: 'the content is untouched');
    });

    test('a version the backend never saw needs no move call', () async {
      await insert('v1', remote: null);
      await songs.moveToSong(
        'v1',
        songWorkId: 'work-right',
        title: 'Way Maker',
        artist: 'Sinach',
      );
      final stored = await row('v1');
      expect(stored.isDirty, isTrue);
      expect(stored.moveDirty, isFalse);
    });

    test('moving to the song it already has changes nothing', () async {
      await insert('v1');
      await songs.moveToSong(
        'v1',
        songWorkId: 'work-wrong',
        title: 'x',
        artist: 'y',
      );
      final stored = await row('v1');
      expect(stored.isDirty, isFalse);
      expect(stored.title, 'Way Maker (wrong)');
    });

    test('only the owner can move a version', () async {
      await insert('v1', owner: 'u-x');
      final result = await songs.moveToSong(
        'v1',
        songWorkId: 'work-right',
        title: 'Way Maker',
        artist: 'Sinach',
      );
      expect(
        result.swap().getOrElse((_) => throw 'expected failure').errorCode,
        BackendErrorCode.notOwner,
      );
      expect((await row('v1')).songWorkId, 'work-wrong');
    });

    test('an unknown version is a failure', () async {
      final result = await songs.moveToSong(
        'nope',
        songWorkId: 'w',
        title: 't',
        artist: 'a',
      );
      expect(result.isLeft(), isTrue);
    });
  });

  test('a missing version is reported as not found', () async {
    final result = await songs.getSongById('gone');
    expect(
      result.swap().getOrElse((_) => throw 'x').errorCode,
      BackendErrorCode.versionNotFound,
    );
  });
}
