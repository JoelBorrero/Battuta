/// Battuta — Setlist repository interface.
///
/// Defines the contract for offline setlist persistence and operations.
library;

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:fpdart/fpdart.dart';

/// Abstract contract for setlist CRUD and queries.
abstract class SetlistRepository {
  /// Returns all persisted setlists.
  Future<Either<Failure, List<Setlist>>> getAllSetlists();

  /// Retrieves a setlist by its [id].
  Future<Either<Failure, Setlist>> getSetlistById(String id);

  /// Saves a [setlist], creating or updating as needed.
  Future<Either<Failure, Setlist>> saveSetlist(Setlist setlist);

  /// Deletes the setlist identified by [id].
  Future<Either<Failure, void>> deleteSetlist(String id);

  /// Emits the updated setlist list whenever changes occur.
  Stream<List<Setlist>> watchAllSetlists();
}
