/// Abstract use-case contracts using fpdart's [Either] for error handling.
///
/// Two variants are provided:
///
/// - `UseCase<T, Params>` — requires parameters.
/// - `NoParamsUseCase<T>` — takes no parameters.
///
/// Both return `Future<Either<Failure, T>>` so that callers can handle
/// success and failure through pattern matching rather than try/catch.
///
/// ```dart
/// class GetSongById extends UseCase<Song, String> {
///   const GetSongById(this._repo);
///   final SongRepository _repo;
///
///   @override
///   Future<Either<Failure, Song>> call(String songId) =>
///       _repo.getSongById(songId);
/// }
/// ```
library;

import 'package:battuta/core/errors/failures.dart';
import 'package:fpdart/fpdart.dart';

/// A use case that requires [Params] and produces [T] on success.
///
/// Implement [call] in concrete subclasses to encapsulate a single
/// piece of application business logic.
abstract class UseCase<T, Params> {
  const UseCase();

  /// Executes the use case with the given [params].
  ///
  /// Returns [Right] with the result on success, or [Left] with a
  /// [Failure] describing what went wrong.
  Future<Either<Failure, T>> call(Params params);
}

/// A use case that takes no parameters and produces [T] on success.
///
/// Useful for queries like "get all songs" or "fetch current user".
abstract class NoParamsUseCase<T> {
  const NoParamsUseCase();

  /// Executes the use case.
  ///
  /// Returns [Right] with the result on success, or [Left] with a
  /// [Failure] describing what went wrong.
  Future<Either<Failure, T>> call();
}

/// Parameter type representing void / absence of parameters.
final class NoParams {
  const NoParams();
}
