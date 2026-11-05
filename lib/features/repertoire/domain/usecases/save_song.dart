/// Battuta — Save song use case.
///
/// Persists a new or updated [Song] to the repository. Handles both
/// creation and update — the repository decides which operation to
/// perform based on the song's [Song.id].
library;

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/usecases/usecase.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/repositories/song_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Saves (creates or updates) a [Song] in the repertoire.
///
/// ```dart
/// final result = await saveSong(song);
/// result.fold(
///   (failure) => showError(failure),
///   (saved) => showSuccess('Saved "${saved.title}"'),
/// );
/// ```
class SaveSong extends UseCase<Song, Song> {
  /// Creates a [SaveSong] use case.
  ///
  /// Requires a [SongRepository] implementation to be injected.
  const SaveSong(this._repository);

  final SongRepository _repository;

  @override
  Future<Either<Failure, Song>> call(Song params) {
    return _repository.saveSong(params);
  }
}
