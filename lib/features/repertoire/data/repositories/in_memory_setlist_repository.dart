/// Battuta — In-memory implementation of [SetlistRepository].
///
/// Pre-populates sample setlists and provides an in-memory reactive store
/// for testing and preview without touching SQLite.
library;

import 'dart:async';

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/repositories/setlist_repository.dart';
import 'package:fpdart/fpdart.dart';

/// In-memory implementation of [SetlistRepository].
class InMemorySetlistRepository implements SetlistRepository {
  InMemorySetlistRepository({List<Setlist>? initialSetlists}) {
    if (initialSetlists != null) {
      for (final s in initialSetlists) {
        _setlists[s.id] = s;
      }
    }
  }

  final Map<String, Setlist> _setlists = {};
  final _controller = StreamController<List<Setlist>>.broadcast();

  void _notify() {
    _controller.add(_setlists.values.toList());
  }

  @override
  Future<Either<Failure, List<Setlist>>> getAllSetlists() async {
    return Right(_setlists.values.toList());
  }

  @override
  Future<Either<Failure, Setlist>> getSetlistById(String id) async {
    final setlist = _setlists[id];
    if (setlist == null) {
      return Left(CacheFailure(message: 'Setlist with ID "$id" not found.'));
    }
    return Right(setlist);
  }

  @override
  Future<Either<Failure, Setlist>> saveSetlist(Setlist setlist) async {
    _setlists[setlist.id] = setlist;
    _notify();
    return Right(setlist);
  }

  @override
  Future<Either<Failure, void>> deleteSetlist(String id) async {
    if (!_setlists.containsKey(id)) {
      return Left(CacheFailure(message: 'Setlist with ID "$id" not found.'));
    }
    _setlists.remove(id);
    _notify();
    return const Right(null);
  }

  @override
  Stream<List<Setlist>> watchAllSetlists() {
    return _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}
