import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/repertoire/data/repositories/drift_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftSongRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftSongRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Song createSampleSong({
    String id = 'song-1',
    String title = 'Way Maker',
    String artist = 'Sinach',
    String key = 'E',
    List<String> tags = const ['worship', 'miracles'],
  }) {
    final now = DateTime.now();
    return Song(
      id: id,
      title: title,
      artist: artist,
      key: key,
      tempo: 68,
      timeSignature: (4, 4),
      sections: [
        const SongSection(
          id: 'sec-1',
          name: 'Verse 1',
          chords: [
            ChordCell(root: 'E'),
            ChordCell(root: 'B'),
          ],
          lyrics: 'You are here, moving in our midst',
          orderIndex: 0,
        ),
      ],
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('DriftSongRepository (Offline Airplane Mode)', () {
    test('starts with empty song table', () async {
      final result = await repository.getAllSongs();
      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => []), isEmpty);
    });

    test('saves and retrieves song preserving all fields', () async {
      final song = createSampleSong();
      final saveResult = await repository.saveSong(song);
      expect(saveResult.isRight(), isTrue);

      final getResult = await repository.getSongById('song-1');
      expect(getResult.isRight(), isTrue);

      final retrieved = getResult.getOrElse((_) => throw 'Failed');
      expect(retrieved.id, equals(song.id));
      expect(retrieved.title, equals(song.title));
      expect(retrieved.artist, equals(song.artist));
      expect(retrieved.key, equals(song.key));
      expect(retrieved.sections.length, equals(1));
      expect(retrieved.sections.first.lyrics, equals('You are here, moving in our midst'));
      expect(retrieved.tags, equals(['worship', 'miracles']));
    });

    test('updates existing song on conflict', () async {
      final song = createSampleSong();
      await repository.saveSong(song);

      final updated = song.copyWith(
        title: 'Way Maker (Live)',
        tempo: 72,
        tags: ['worship', 'live'],
      );
      await repository.saveSong(updated);

      final getResult = await repository.getSongById('song-1');
      final retrieved = getResult.getOrElse((_) => throw 'Failed');
      expect(retrieved.title, equals('Way Maker (Live)'));
      expect(retrieved.tempo, equals(72));
      expect(retrieved.tags, equals(['worship', 'live']));
    });

    test('deletes song by id', () async {
      final song = createSampleSong();
      await repository.saveSong(song);

      final deleteResult = await repository.deleteSong('song-1');
      expect(deleteResult.isRight(), isTrue);

      final getResult = await repository.getSongById('song-1');
      expect(getResult.isLeft(), isTrue);
    });

    test('searches songs by title, artist, and tags', () async {
      await repository.saveSong(createSampleSong(
        id: 's1',
        title: 'Way Maker',
        artist: 'Sinach',
        tags: ['african', 'gospel'],
      ));
      await repository.saveSong(createSampleSong(
        id: 's2',
        title: 'Goodness of God',
        artist: 'Bethel Music',
        tags: ['faith', 'worship'],
      ));

      final titleSearch = await repository.searchSongs('maker');
      expect(titleSearch.getOrElse((_) => []).length, equals(1));
      expect(titleSearch.getOrElse((_) => []).first.id, equals('s1'));

      final artistSearch = await repository.searchSongs('bethel');
      expect(artistSearch.getOrElse((_) => []).length, equals(1));
      expect(artistSearch.getOrElse((_) => []).first.id, equals('s2'));

      final tagSearch = await repository.searchSongs('gospel');
      expect(tagSearch.getOrElse((_) => []).length, equals(1));
      expect(tagSearch.getOrElse((_) => []).first.id, equals('s1'));
    });

    test('watchAllSongs emits reactive updates on changes', () async {
      final stream = repository.watchAllSongs();
      final emissions = <List<Song>>[];
      final subscription = stream.listen(emissions.add);

      await pumpEventQueue();
      expect(emissions.last, isEmpty);

      final song = createSampleSong();
      await repository.saveSong(song);

      await pumpEventQueue();
      expect(emissions.last.length, equals(1));
      expect(emissions.last.first.title, equals(song.title));

      await subscription.cancel();
    });
  });
}
