import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _RefusingSongs extends InMemorySongRepository {
  _RefusingSongs({super.initialSongs});

  @override
  Future<Either<Failure, Song>> saveSong(Song song) async =>
      Left(BackendErrorCode.notOwner.failure());

  @override
  Future<Either<Failure, void>> deleteSong(String id) async =>
      Left(BackendErrorCode.notOwner.failure());
}

Song song(String id, {String key = 'G'}) => Song(
  id: id,
  title: 'Song $id',
  artist: 'A',
  key: key,
  tempo: 80,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  test('a refused write keeps the list and hands the failure back', () async {
    final container = ProviderContainer(
      overrides: [
        songRepositoryProvider.overrideWithValue(
          _RefusingSongs(initialSongs: [song('a'), song('b')]),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(repertoireProvider.notifier);
    expect((await container.read(repertoireProvider.future)).length, 2);

    final updated = await notifier.updateSong(song('a', key: 'A'));
    expect(updated?.errorCode, BackendErrorCode.notOwner);
    expect(container.read(repertoireProvider).hasError, isFalse);
    expect(container.read(repertoireProvider).value!.first.key, 'G');

    final added = await notifier.addSong(song('c'));
    expect(added, isNotNull);
    expect(container.read(repertoireProvider).value!.map((s) => s.id), [
      'a',
      'b',
    ]);

    final deleted = await notifier.deleteSong('a');
    expect(deleted, isNotNull);
    expect(container.read(repertoireProvider).value, hasLength(2));
  });
}
