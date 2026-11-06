/// Battuta — Score repository interface.
///
/// Defines the contract for offline Score tree persistence, retrieval,
/// and live streaming.
library;

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:fpdart/fpdart.dart';

/// Abstract contract for score CRUD and song-linked storage.
abstract class ScoreRepository {
  /// Retrieves a Score by its [id].
  Future<Either<Failure, Score>> getScoreById(String id);

  /// Retrieves the Score associated with a specific [songId].
  Future<Either<Failure, Score?>> getScoreBySongId(String songId);

  /// Persists a [score], optionally linking it to [songId].
  Future<Either<Failure, Score>> saveScore(Score score, {String? songId});

  /// Deletes a Score identified by [id].
  Future<Either<Failure, void>> deleteScore(String id);

  /// Emits updates for the Score identified by [id].
  Stream<Score?> watchScore(String id);
}
