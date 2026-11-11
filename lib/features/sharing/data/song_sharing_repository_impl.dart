/// [SongSharingRepository] on top of the backend, with the local database as
/// the cache the viewer and editor read from.
///
/// A version fetched from the backend (to open it, or because it was just
/// forked) is stored like any other cached version: owned by its owner,
/// read-only for everybody else, and removed by the next sync when it is no
/// longer in reach of the account.
library;

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/data/backend_gateway.dart';
import 'package:battuta/features/organizations/domain/repositories/account_session.dart';
import 'package:battuta/features/repertoire/data/repositories/song_row_mapper.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/repositories/song_repository.dart';
import 'package:battuta/features/score/domain/repositories/score_repository.dart';
import 'package:battuta/features/sharing/data/song_sharing_remote_data_source.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:battuta/features/sharing/domain/repositories/song_sharing_repository.dart';
import 'package:battuta/features/sync/data/sync_mappers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

class SongSharingRepositoryImpl implements SongSharingRepository {
  SongSharingRepositoryImpl({
    required this._remote,
    required this._db,
    required this._session,
    required this._songs,
    required this._scores,
    this._uuid = const Uuid(),
  });

  final SongSharingRemoteDataSource _remote;
  final AppDatabase _db;
  final AccountSession _session;
  final SongRepository _songs;
  final ScoreRepository _scores;
  final Uuid _uuid;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (e, st) {
      return Left(mapBackendError(e, st));
    }
  }

  @override
  Future<Either<Failure, List<SongVersionListing>>> fetchVersionsOfSong(
    String songWorkId,
  ) => _guard(() => _remote.fetchVersionsOfSong(songWorkId));

  @override
  Future<Either<Failure, List<SongVersionListing>>> searchPublicVersions(
    String query, {
    int limit = 30,
    int offset = 0,
  }) => _guard(
    () => _remote.searchPublicVersions(query, limit: limit, offset: offset),
  );

  @override
  Future<Either<Failure, SongWork>> fetchSong(String songId) =>
      _guard(() => _remote.fetchSong(songId));

  @override
  Future<Either<Failure, List<SongWork>>> searchSongs(
    String query, {
    bool onlyMine = false,
    int limit = 20,
  }) => _guard(
    () => _remote.searchSongs(query, onlyMine: onlyMine, limit: limit),
  );

  @override
  Future<Either<Failure, Song>> openVersion(String versionId) =>
      _guard(() async {
        final me = _requireAccount();
        final row = await _remote.fetchVersionRow(versionId);
        return _cache(row, me);
      });

  @override
  Future<Either<Failure, ForkedVersion>> forkVersion(
    String versionId, {
    String? label,
    Song? cachedSource,
  }) async {
    final me = _session.userId;
    final cleanLabel = label?.trim();
    if (me != null) {
      try {
        final row = await _remote.forkVersion(
          versionId,
          label: cleanLabel == null || cleanLabel.isEmpty ? null : cleanLabel,
        );
        return Right(ForkedVersion(await _cache(row, me)));
      } catch (e, st) {
        final failure = mapBackendError(e, st);
        if (cachedSource == null || !_isOfflineLike(failure)) {
          return Left(failure);
        }
      }
    }
    if (cachedSource == null) {
      return Left(
        BackendErrorCode.offline.failure(
          message: 'Forking this version needs a connection.',
        ),
      );
    }
    return _forkLocally(cachedSource, cleanLabel, me);
  }

  /// No connection, no session, or a source the backend does not know (yet).
  bool _isOfflineLike(Failure failure) => switch (failure.errorCode) {
    BackendErrorCode.offline ||
    BackendErrorCode.notSignedIn ||
    BackendErrorCode.versionNotFound => true,
    _ => false,
  };

  Future<Either<Failure, ForkedVersion>> _forkLocally(
    Song source,
    String? label,
    String? me,
  ) async {
    final now = DateTime.now();
    final fork = Song(
      id: _uuid.v4(),
      title: source.title,
      artist: source.artist,
      key: source.key,
      tempo: source.tempo,
      timeSignature: source.timeSignature,
      sections: source.sections,
      tags: source.tags,
      coverImagePath: source.coverImagePath,
      notes: source.notes,
      createdAt: now,
      updatedAt: now,
      songWorkId: source.songWorkId,
      label: label == null || label.isEmpty ? '${source.label} (copy)' : label,
      forkedFromVersionId: source.id,
      // The fork lives under the same song, created by the same person.
      songCreatorId: source.canEditTitleBy(me) ? me : source.songCreatorId,
    );
    final saved = await _songs.saveSong(fork);
    if (saved case Left(value: final failure)) return Left(failure);
    final song = (saved as Right<Failure, Song>).value;
    final score = await _scores.getScoreBySongId(source.id);
    final copy = score.fold((_) => null, (value) => value);
    if (copy != null) {
      await _scores.saveScore(copy.copyWith(id: _uuid.v4()), songId: song.id);
    }
    return Right(ForkedVersion(song, madeOffline: true));
  }

  @override
  Future<Either<Failure, SongMergeRequest>> requestMerge({
    required String sourceSongId,
    required String targetSongId,
  }) => _guard(() => _remote.requestMerge(sourceSongId, targetSongId));

  @override
  Future<Either<Failure, SongMergeRequest>> respondToMerge(
    String requestId, {
    required bool accept,
  }) => _guard(() => _remote.respondToMerge(requestId, accept: accept));

  @override
  Future<Either<Failure, SongMergeRequest>> fetchMergeRequest(
    String requestId,
  ) => _guard(() => _remote.fetchMergeRequest(requestId));

  @override
  Future<Either<Failure, List<SongMergeRequest>>> pendingMergeRequests() =>
      _guard(_remote.pendingMergeRequests);

  String _requireAccount() {
    final me = _session.userId;
    if (me == null) {
      throw BackendErrorCode.notSignedIn.failure(message: 'Sign in first.');
    }
    return me;
  }

  /// Stores [row] as a cached version of [account] and returns it. A local
  /// edit or tombstone of the same version is never overwritten.
  Future<Song> _cache(Map<String, dynamic> row, String account) async {
    final id = row['id'] as String;
    final current = await (_db.select(
      _db.songs,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    final keep =
        current != null &&
        (current.isDirty ||
            current.deletedAt != null ||
            (current.accountId != null && current.accountId != account));
    if (!keep) {
      await _db
          .into(_db.songs)
          .insertOnConflictUpdate(
            songCompanionFromRemote(row, accountId: account),
          );
    }
    final stored = await (_db.select(
      _db.songs,
    )..where((t) => t.id.equals(id))).getSingle();
    return songFromRow(stored);
  }
}
