/// Battuta — Offline SQLite score repository implementation.
///
/// Implements [ScoreRepository] backed by Drift embedded database,
/// guaranteeing 100% offline persistence and lossless retrieval of
/// complete Score domain trees (Section, Measure, NoteEvent, ChordSymbol).
library;

import 'dart:convert';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/domain/repositories/account_session.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:battuta/features/score/domain/repositories/score_repository.dart';
import 'package:battuta/features/sync/domain/services/sync_policy.dart';
import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

/// Concrete [ScoreRepository] backed by [AppDatabase].
///
/// A score belongs to the song version named by its `songId`. Scores of
/// versions owned by somebody else are read-only (`not_owner`). Deleting a
/// score that already reached the backend leaves a tombstone until the cloud
/// sync has pushed the deletion.
class DriftScoreRepository implements ScoreRepository {
  /// Creates a [DriftScoreRepository] with the given [AppDatabase].
  DriftScoreRepository(this.db, {this._session});

  /// The underlying Drift SQLite database.
  final AppDatabase db;
  final AccountSession? _session;

  /// Whether the version [songId] belongs to somebody else.
  Future<bool> _isForeignVersion(String? songId) async {
    if (songId == null) return false;
    final song = await (db.select(
      db.songs,
    )..where((t) => t.id.equals(songId))).getSingleOrNull();
    if (song == null) return false;
    final account = _session?.userId;
    return (song.ownerId != null && song.ownerId != account) ||
        (song.accountId != null && song.accountId != account);
  }

  Failure _notOwner(String id) => BackendErrorCode.notOwner.failure(
    message: 'Score "$id" belongs to a version owned by another user.',
  );

  @override
  Future<Either<Failure, Score>> getScoreById(String id) async {
    try {
      final row =
          await (db.select(db.scores)
                ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
              .getSingleOrNull();
      if (row == null) {
        return Left(CacheFailure(message: 'Score with ID "$id" not found.'));
      }
      return Right(_rowToScore(row));
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to retrieve score "$id": $e',
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Score?>> getScoreBySongId(String songId) async {
    try {
      final row =
          await (db.select(db.scores)
                ..where((t) => t.songId.equals(songId) & t.deletedAt.isNull()))
              .getSingleOrNull();
      if (row == null) {
        return const Right(null);
      }
      return Right(_rowToScore(row));
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to retrieve score for song "$songId": $e',
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Score>> saveScore(
    Score score, {
    String? songId,
  }) async {
    try {
      if (await _isForeignVersion(songId)) return Left(_notOwner(score.id));
      final existing = await (db.select(
        db.scores,
      )..where((t) => t.id.equals(score.id))).getSingleOrNull();
      final companion = ScoresCompanion(
        id: Value(score.id),
        songId: Value(songId),
        title: Value(score.title),
        composer: Value(score.composer),
        artist: Value(score.artist),
        timeSignatureJson: Value(jsonEncode(score.timeSignature.toJson())),
        keySignature: Value(score.keySignature),
        tempo: Value(score.tempo),
        sectionsJson: Value(
          jsonEncode(score.sections.map((s) => s.toJson()).toList()),
        ),
        metadataJson: Value(jsonEncode(score.metadata)),
        updatedAt: Value(DateTime.now()),
        isDirty: const Value(true),
        deletedAt: const Value(null),
        remoteUpdatedAt: Value(existing?.remoteUpdatedAt),
        editedAtMs: Value(SyncPolicy.nextEditMs(existing?.editedAtMs)),
      );

      await db.into(db.scores).insertOnConflictUpdate(companion);
      return Right(score);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to save score "${score.id}": $e',
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteScore(String id) async {
    try {
      final row =
          await (db.select(db.scores)
                ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
              .getSingleOrNull();
      if (row == null) {
        return Left(CacheFailure(message: 'Score with ID "$id" not found.'));
      }
      if (await _isForeignVersion(row.songId)) return Left(_notOwner(id));
      if (row.remoteUpdatedAt == null) {
        await (db.delete(db.scores)..where((t) => t.id.equals(id))).go();
      } else {
        await (db.update(db.scores)..where((t) => t.id.equals(id))).write(
          ScoresCompanion(
            deletedAt: Value(DateTime.now()),
            isDirty: const Value(true),
            editedAtMs: Value(SyncPolicy.nextEditMs(row.editedAtMs)),
          ),
        );
      }
      return const Right(null);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to delete score "$id": $e',
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Stream<Score?> watchScore(String id) {
    return (db.select(db.scores)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .watchSingleOrNull()
        .map((row) => row != null ? _rowToScore(row) : null);
  }

  Score _rowToScore(ScoreEntry row) {
    final sectionsList = (jsonDecode(row.sectionsJson) as List<dynamic>)
        .map((s) => Section.fromJson(s as Map<String, dynamic>))
        .toList();

    final timeSignatureMap =
        jsonDecode(row.timeSignatureJson) as Map<String, dynamic>;

    final metadataMap = jsonDecode(row.metadataJson) as Map<String, dynamic>;

    return Score(
      id: row.id,
      title: row.title,
      composer: row.composer,
      artist: row.artist,
      timeSignature: TimeSignature.fromJson(timeSignatureMap),
      keySignature: row.keySignature,
      tempo: row.tempo,
      sections: sectionsList,
      metadata: metadataMap,
    );
  }
}
