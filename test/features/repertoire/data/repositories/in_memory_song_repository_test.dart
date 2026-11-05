import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemorySongRepository', () {
    late InMemorySongRepository repository;

    setUp(() {
      repository = InMemorySongRepository();
    });

    test('initializes with default seed songs', () async {
      final result = await repository.getAllSongs();

      expect(result.isRight(), isTrue);
      final songs = result.getOrElse((_) => []);
      expect(songs.length, equals(3));
      expect(songs.any((s) => s.title == 'Amazing Grace'), isTrue);
      expect(songs.any((s) => s.title == 'Way Maker'), isTrue);
    });

    test('initializes with custom initial songs when provided', () async {
      final customSong = Song(
        id: 'custom-1',
        title: 'Custom Hymn',
        artist: 'Author',
        key: 'D',
        tempo: 80,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customRepo = InMemorySongRepository(initialSongs: [customSong]);
      final result = await customRepo.getAllSongs();

      expect(result.isRight(), isTrue);
      final songs = result.getOrElse((_) => []);
      expect(songs.length, equals(1));
      expect(songs.first.id, equals('custom-1'));
    });

    test('getSongById returns song when found', () async {
      final result = await repository.getSongById('song-1');

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected right, got failure: $failure'),
        (song) => expect(song.title, equals('Amazing Grace')),
      );
    });

    test('getSongById returns CacheFailure when song is not found', () async {
      final result = await repository.getSongById('non-existent-id');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.message, contains('non-existent-id'));
        },
        (_) => fail('Expected left failure'),
      );
    });

    test('saveSong creates new song and updates existing song', () async {
      final now = DateTime.now();
      final newSong = Song(
        id: 'new-song',
        title: 'Build My Life',
        artist: 'Housefires',
        key: 'G',
        tempo: 70,
        createdAt: now,
        updatedAt: now,
      );

      // 1. Create
      final createResult = await repository.saveSong(newSong);
      expect(createResult.isRight(), isTrue);

      final getResult = await repository.getSongById('new-song');
      expect(getResult.isRight(), isTrue);
      expect(getResult.getOrElse((_) => throw 'error').title, equals('Build My Life'));

      // 2. Update
      final updatedSong = newSong.copyWith(title: 'Build My Life (Updated)');
      final updateResult = await repository.saveSong(updatedSong);
      expect(updateResult.isRight(), isTrue);

      final reGetResult = await repository.getSongById('new-song');
      expect(reGetResult.getOrElse((_) => throw 'error').title, equals('Build My Life (Updated)'));
    });

    test('deleteSong removes song from repository', () async {
      final deleteResult = await repository.deleteSong('song-1');
      expect(deleteResult.isRight(), isTrue);

      final getResult = await repository.getSongById('song-1');
      expect(getResult.isLeft(), isTrue);

      final allResult = await repository.getAllSongs();
      final songs = allResult.getOrElse((_) => []);
      expect(songs.any((s) => s.id == 'song-1'), isFalse);
    });

    group('searchSongs', () {
      test('matches songs by title case-insensitively', () async {
        final result = await repository.searchSongs('amazing');
        final songs = result.getOrElse((_) => []);
        expect(songs.length, equals(1));
        expect(songs.first.id, equals('song-1'));
      });

      test('matches songs by artist', () async {
        final result = await repository.searchSongs('sinach');
        final songs = result.getOrElse((_) => []);
        expect(songs.length, equals(1));
        expect(songs.first.id, equals('song-2'));
      });

      test('matches songs by tag', () async {
        final result = await repository.searchSongs('worship');
        final songs = result.getOrElse((_) => []);
        expect(songs.length, equals(2));
      });

      test('returns all songs for empty search query', () async {
        final result = await repository.searchSongs('');
        final songs = result.getOrElse((_) => []);
        expect(songs.length, equals(3));
      });

      test('returns empty list when no matches found', () async {
        final result = await repository.searchSongs('xyz-not-found');
        final songs = result.getOrElse((_) => []);
        expect(songs, isEmpty);
      });
    });

    test('watchAllSongs emits initial list and updates on mutations', () async {
      final stream = repository.watchAllSongs();

      final emittedLists = <List<Song>>[];
      final subscription = stream.listen(emittedLists.add);

      // Allow initial yield
      await Future<void>.delayed(Duration.zero);

      final now = DateTime.now();
      await repository.saveSong(
        Song(
          id: 'song-stream-test',
          title: 'Stream Song',
          artist: 'Artist',
          key: 'C',
          tempo: 100,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(emittedLists.length, greaterThanOrEqualTo(2));
      expect(emittedLists.last.any((s) => s.id == 'song-stream-test'), isTrue);

      await subscription.cancel();
    });
  });
}
