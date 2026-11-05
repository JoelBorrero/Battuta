/// Battuta — Song repository interface.
///
/// Defines the contract for song persistence operations. Concrete
/// implementations (e.g., local database, remote API) live in the
/// `data` layer and are injected via Riverpod.
///
/// All fallible operations return `Either<Failure, T>` from **fpdart**
/// for explicit, composable error handling.
library;

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:fpdart/fpdart.dart';

/// Abstract interface for song CRUD and query operations.
///
/// Implementations must handle mapping between domain entities and
/// their persistence representation (DTOs, database rows, etc.).
abstract class SongRepository {
  /// Returns every song in the repertoire.
  ///
  /// On failure, the [Left] side contains a [Failure] describing the error.
  Future<Either<Failure, List<Song>>> getAllSongs();

  /// Retrieves a single song by its unique [id].
  ///
  /// Returns [Left] with a [NotFoundFailure] if no song matches.
  Future<Either<Failure, Song>> getSongById(String id);

  /// Persists [song], creating or updating as appropriate.
  ///
  /// Returns the saved [Song] (which may include server-assigned fields)
  /// on success.
  Future<Either<Failure, Song>> saveSong(Song song);

  /// Permanently deletes the song identified by [id].
  Future<Either<Failure, void>> deleteSong(String id);

  /// Searches songs by [query] matching title, artist, or tags.
  Future<Either<Failure, List<Song>>> searchSongs(String query);

  /// Emits the full song list whenever it changes.
  ///
  /// Useful for reactive UI updates without manual refresh.
  Stream<List<Song>> watchAllSongs();
}
