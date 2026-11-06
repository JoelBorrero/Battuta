/// Battuta — Offline SQLite song repository implementation.
///
/// Implements [SongRepository] backed by Drift embedded database,
/// guaranteeing 100% offline functionality in Airplane Mode.
library;

import 'dart:convert';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/repositories/song_repository.dart';
import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

/// Concrete [SongRepository] backed by [AppDatabase].
class DriftSongRepository implements SongRepository {
  /// Creates a [DriftSongRepository] with the given [AppDatabase].
  DriftSongRepository(this.db);

  /// The underlying Drift SQLite database.
  final AppDatabase db;

  @override
  Future<Either<Failure, List<Song>>> getAllSongs() async {
    try {
      final rows = await (db.select(db.songs)
            ..orderBy([(t) => OrderingTerm.asc(t.title)]))
          .get();
      return Right(rows.map(_rowToSong).toList());
    } catch (e, st) {
      return Left(CacheFailure(
        message: 'Failed to retrieve songs: $e',
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Either<Failure, Song>> getSongById(String id) async {
    try {
      final row = await (db.select(db.songs)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row == null) {
        return Left(CacheFailure(message: 'Song with ID "$id" not found.'));
      }
      return Right(_rowToSong(row));
    } catch (e, st) {
      return Left(CacheFailure(
        message: 'Failed to retrieve song "$id": $e',
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Either<Failure, Song>> saveSong(Song song) async {
    try {
      final companion = SongsCompanion(
        id: Value(song.id),
        title: Value(song.title),
        artist: Value(song.artist),
        key: Value(song.key),
        tempo: Value(song.tempo),
        timeSignatureBeats: Value(song.timeSignature.$1),
        timeSignatureBeatValue: Value(song.timeSignature.$2),
        sectionsJson: Value(
          jsonEncode(song.sections.map((s) => s.toJson()).toList()),
        ),
        tagsJson: Value(jsonEncode(song.tags)),
        coverImagePath: Value(song.coverImagePath),
        notes: Value(song.notes),
        createdAt: Value(song.createdAt),
        updatedAt: Value(song.updatedAt),
      );

      await db.into(db.songs).insertOnConflictUpdate(companion);
      return Right(song);
    } catch (e, st) {
      return Left(CacheFailure(
        message: 'Failed to save song "${song.id}": $e',
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSong(String id) async {
    try {
      final rowsAffected =
          await (db.delete(db.songs)..where((t) => t.id.equals(id))).go();
      if (rowsAffected == 0) {
        return Left(CacheFailure(message: 'Song with ID "$id" not found.'));
      }
      return const Right(null);
    } catch (e, st) {
      return Left(CacheFailure(
        message: 'Failed to delete song "$id": $e',
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Either<Failure, List<Song>>> searchSongs(String query) async {
    try {
      final cleanQuery = query.trim().toLowerCase();
      if (cleanQuery.isEmpty) {
        return await getAllSongs();
      }

      final rows = await (db.select(db.songs)
            ..where((t) =>
                t.title.lower().contains(cleanQuery) |
                t.artist.lower().contains(cleanQuery) |
                t.tagsJson.lower().contains(cleanQuery)))
          .get();

      return Right(rows.map(_rowToSong).toList());
    } catch (e, st) {
      return Left(CacheFailure(
        message: 'Search failed for query "$query": $e',
        stackTrace: st,
      ));
    }
  }

  @override
  Stream<List<Song>> watchAllSongs() {
    return (db.select(db.songs)..orderBy([(t) => OrderingTerm.asc(t.title)]))
        .watch()
        .map((rows) => rows.map(_rowToSong).toList());
  }

  Song _rowToSong(SongEntry row) {
    final sectionsList = (jsonDecode(row.sectionsJson) as List<dynamic>)
        .map((s) => SongSection.fromJson(s as Map<String, dynamic>))
        .toList();

    final tagsList = (jsonDecode(row.tagsJson) as List<dynamic>)
        .map((t) => t as String)
        .toList();

    return Song(
      id: row.id,
      title: row.title,
      artist: row.artist,
      key: row.key,
      tempo: row.tempo,
      timeSignature: (row.timeSignatureBeats, row.timeSignatureBeatValue),
      sections: sectionsList,
      tags: tagsList,
      coverImagePath: row.coverImagePath,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
