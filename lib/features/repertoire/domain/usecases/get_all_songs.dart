/// Battuta — Get all songs use case.
///
/// Retrieves the complete list of songs from the repertoire.
/// Follows the clean-architecture use-case pattern: a single callable
/// class with no business logic beyond delegating to the repository.
library;

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/usecases/usecase.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/repositories/song_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Fetches every [Song] in the user's repertoire.
///
/// ```dart
/// final result = await getAllSongs(const NoParams());
/// result.fold(
///   (failure) => showError(failure),
///   (songs) => displayList(songs),
/// );
/// ```
class GetAllSongs extends UseCase<List<Song>, NoParams> {
  /// Creates a [GetAllSongs] use case.
  ///
  /// Requires a [SongRepository] implementation to be injected.
  const GetAllSongs(this._repository);

  final SongRepository _repository;

  @override
  Future<Either<Failure, List<Song>>> call(NoParams params) {
    return _repository.getAllSongs();
  }
}
