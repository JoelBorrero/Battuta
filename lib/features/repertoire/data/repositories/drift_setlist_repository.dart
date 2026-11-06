/// Battuta — Offline SQLite setlist repository implementation.
///
/// Implements [SetlistRepository] backed by Drift embedded database,
/// guaranteeing 100% offline functionality in Airplane Mode.
library;

import 'dart:convert';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/repertoire/domain/repositories/setlist_repository.dart';
import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

/// Concrete [SetlistRepository] backed by [AppDatabase].
class DriftSetlistRepository implements SetlistRepository {
  /// Creates a [DriftSetlistRepository] with the given [AppDatabase].
  DriftSetlistRepository(this.db);

  /// The underlying Drift SQLite database.
  final AppDatabase db;

  @override
  Future<Either<Failure, List<Setlist>>> getAllSetlists() async {
    try {
      final rows = await (db.select(db.setlists)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();
      return Right(rows.map(_rowToSetlist).toList());
    } catch (e, st) {
      return Left(CacheFailure(
        message: 'Failed to retrieve setlists: $e',
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Either<Failure, Setlist>> getSetlistById(String id) async {
    try {
      final row = await (db.select(db.setlists)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row == null) {
        return Left(CacheFailure(message: 'Setlist with ID "$id" not found.'));
      }
      return Right(_rowToSetlist(row));
    } catch (e, st) {
      return Left(CacheFailure(
        message: 'Failed to retrieve setlist "$id": $e',
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Either<Failure, Setlist>> saveSetlist(Setlist setlist) async {
    try {
      final companion = SetlistsCompanion(
        id: Value(setlist.id),
        title: Value(setlist.title),
        description: Value(setlist.description),
        eventDate: Value(setlist.eventDate),
        itemsJson: Value(
          jsonEncode(setlist.items.map((i) => i.toJson()).toList()),
        ),
        tagsJson: Value(jsonEncode(setlist.tags)),
        createdAt: Value(setlist.createdAt),
        updatedAt: Value(setlist.updatedAt),
      );

      await db.into(db.setlists).insertOnConflictUpdate(companion);
      return Right(setlist);
    } catch (e, st) {
      return Left(CacheFailure(
        message: 'Failed to save setlist "${setlist.id}": $e',
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSetlist(String id) async {
    try {
      final rowsAffected =
          await (db.delete(db.setlists)..where((t) => t.id.equals(id))).go();
      if (rowsAffected == 0) {
        return Left(CacheFailure(message: 'Setlist with ID "$id" not found.'));
      }
      return const Right(null);
    } catch (e, st) {
      return Left(CacheFailure(
        message: 'Failed to delete setlist "$id": $e',
        stackTrace: st,
      ));
    }
  }

  @override
  Stream<List<Setlist>> watchAllSetlists() {
    return (db.select(db.setlists)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_rowToSetlist).toList());
  }

  Setlist _rowToSetlist(SetlistEntry row) {
    final itemsList = (jsonDecode(row.itemsJson) as List<dynamic>)
        .map((i) => SetlistItem.fromJson(i as Map<String, dynamic>))
        .toList();

    final tagsList = (jsonDecode(row.tagsJson) as List<dynamic>)
        .map((t) => t as String)
        .toList();

    return Setlist(
      id: row.id,
      title: row.title,
      description: row.description,
      eventDate: row.eventDate,
      items: itemsList,
      tags: tagsList,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
