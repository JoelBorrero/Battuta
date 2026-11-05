import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/usecases/usecase.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/repositories/song_repository.dart';
import 'package:battuta/features/repertoire/domain/usecases/get_all_songs.dart';
import 'package:battuta/features/repertoire/domain/usecases/save_song.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSongRepository extends Mock implements SongRepository {}

void main() {
  late MockSongRepository mockRepository;

  setUp(() {
    mockRepository = MockSongRepository();
  });

  final now = DateTime(2026, 11, 5);
  final testSong = Song(
    id: 'test-1',
    title: 'Test Song',
    artist: 'Test Artist',
    key: 'C',
    tempo: 120,
    createdAt: now,
    updatedAt: now,
  );

  group('GetAllSongs UseCase', () {
    late GetAllSongs useCase;

    setUp(() {
      useCase = GetAllSongs(mockRepository);
    });

    test('returns Right(List<Song>) when repository succeeds', () async {
      when(() => mockRepository.getAllSongs())
          .thenAnswer((_) async => Right([testSong]));

      final result = await useCase(const NoParams());

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => []), equals([testSong]));
      verify(() => mockRepository.getAllSongs()).called(1);
    });

    test('returns Left(Failure) when repository fails', () async {
      const failure = ServerFailure(message: 'Database unavailable');
      when(() => mockRepository.getAllSongs())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(const NoParams());

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, equals(failure)),
        (_) => fail('Expected Left'),
      );
      verify(() => mockRepository.getAllSongs()).called(1);
    });
  });

  group('SaveSong UseCase', () {
    late SaveSong useCase;

    setUp(() {
      useCase = SaveSong(mockRepository);
    });

    test('returns Right(Song) when repository succeeds', () async {
      when(() => mockRepository.saveSong(testSong))
          .thenAnswer((_) async => Right(testSong));

      final result = await useCase(testSong);

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => throw 'error'), equals(testSong));
      verify(() => mockRepository.saveSong(testSong)).called(1);
    });

    test('returns Left(Failure) when repository fails', () async {
      const failure = CacheFailure(message: 'Disk write failed');
      when(() => mockRepository.saveSong(testSong))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(testSong);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, equals(failure)),
        (_) => fail('Expected Left'),
      );
      verify(() => mockRepository.saveSong(testSong)).called(1);
    });
  });
}
