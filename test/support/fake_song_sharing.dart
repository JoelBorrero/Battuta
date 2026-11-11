import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/sharing/data/song_sharing_remote_data_source.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:battuta/features/sharing/domain/repositories/song_sharing_repository.dart';
import 'package:fpdart/fpdart.dart';

Failure offlineFailure() =>
    BackendErrorCode.offline.failure(message: 'No connection.');

/// A scripted [SongSharingRemoteDataSource]: no network, no retries.
class FakeSongSharingRemote implements SongSharingRemoteDataSource {
  /// The versions of any song.
  List<SongVersionListing> versions = [];
  List<SongVersionListing> publicVersions = [];
  List<SongWork> songs = [];
  List<SongMergeRequest> pending = [];

  /// `song_versions` rows by id (with `songs` embedded) for fetch and fork.
  final Map<String, Map<String, dynamic>> rows = {};

  /// The row `forkVersion` returns.
  Map<String, dynamic>? forkRow;

  /// When set, every call fails with it.
  Failure? failure;

  /// The status the next `requestMerge` answers with.
  MergeRequestStatus mergeStatus = MergeRequestStatus.pending;

  final List<String> calls = [];

  T _run<T>(String call, T Function() body) {
    calls.add(call);
    final f = failure;
    if (f != null) throw f;
    return body();
  }

  @override
  Future<List<SongVersionListing>> fetchVersionsOfSong(
    String songWorkId,
  ) async => _run('versions:$songWorkId', () => versions);

  @override
  Future<List<SongVersionListing>> searchPublicVersions(
    String query, {
    int limit = 30,
    int offset = 0,
  }) async => _run('public:$query:$offset', () {
    final q = query.toLowerCase();
    final all = [
      for (final v in publicVersions)
        if (q.isEmpty ||
            v.title.toLowerCase().contains(q) ||
            v.artist.toLowerCase().contains(q))
          v,
    ];
    return all.skip(offset).take(limit).toList();
  });

  @override
  Future<SongWork> fetchSong(String songId) async => _run('song:$songId', () {
    for (final s in songs) {
      if (s.id == songId) return s;
    }
    throw BackendErrorCode.songNotFound.failure(message: 'no song');
  });

  @override
  Future<List<SongWork>> searchSongs(
    String query, {
    bool onlyMine = false,
    int limit = 20,
  }) async => _run('songs:$query:mine=$onlyMine', () {
    final q = query.toLowerCase();
    return [
      for (final s in songs)
        if (s.mergedIntoId == null &&
            (!onlyMine || s.createdBy == 'u-me') &&
            (q.isEmpty ||
                s.title.toLowerCase().contains(q) ||
                s.artist.toLowerCase().contains(q)))
          s,
    ];
  });

  @override
  Future<Map<String, dynamic>> fetchVersionRow(String versionId) async =>
      _run('row:$versionId', () {
        final row = rows[versionId];
        if (row == null) {
          throw BackendErrorCode.versionNotFound.failure(message: 'none');
        }
        return row;
      });

  @override
  Future<Map<String, dynamic>> forkVersion(
    String versionId, {
    String? label,
  }) async => _run('fork:$versionId:$label', () {
    final row = forkRow;
    if (row == null) {
      throw BackendErrorCode.versionNotFound.failure(message: 'none');
    }
    return {...row, 'label': ?label};
  });

  @override
  Future<SongMergeRequest> requestMerge(
    String sourceSongId,
    String targetSongId,
  ) async => _run(
    'merge:$sourceSongId>$targetSongId',
    () => SongMergeRequest(
      id: 'req-new',
      sourceSongId: sourceSongId,
      targetSongId: targetSongId,
      sourceTitle: 'Source',
      targetTitle: 'Target',
      status: mergeStatus,
    ),
  );

  @override
  Future<SongMergeRequest> respondToMerge(
    String requestId, {
    required bool accept,
  }) async => _run(
    'respond:$requestId:$accept',
    () => SongMergeRequest(
      id: requestId,
      sourceSongId: 'song-a',
      targetSongId: 'song-b',
      sourceTitle: 'A',
      targetTitle: 'B',
      status: accept
          ? MergeRequestStatus.accepted
          : MergeRequestStatus.declined,
    ),
  );

  @override
  Future<SongMergeRequest> fetchMergeRequest(String requestId) async =>
      _run('request:$requestId', () {
        for (final r in pending) {
          if (r.id == requestId) return r;
        }
        throw BackendErrorCode.mergeRequestNotFound.failure(message: 'none');
      });

  @override
  Future<List<SongMergeRequest>> pendingMergeRequests() async =>
      _run('pending', () => pending);
}

/// A scripted [SongSharingRepository] for widget tests.
class FakeSongSharingRepository implements SongSharingRepository {
  List<SongVersionListing> versions = [];
  List<SongVersionListing> publicVersions = [];
  List<SongWork> songs = [];
  List<SongMergeRequest> pending = [];
  final Map<String, SongMergeRequest> requests = {};

  /// When set, every call fails with it.
  Failure? failure;

  /// What `forkVersion` returns (unless [failure] is set).
  ForkedVersion? forked;

  /// What `openVersion` returns.
  Song? opened;

  MergeRequestStatus mergeStatus = MergeRequestStatus.pending;

  final List<String> calls = [];

  Either<Failure, T> _answer<T>(String call, T value) {
    calls.add(call);
    final f = failure;
    return f != null ? Left(f) : Right(value);
  }

  /// Like [_answer], for a value that may be unset when [failure] is.
  Either<Failure, T> _answerOr<T>(String call, T? value) {
    calls.add(call);
    final f = failure;
    return f != null ? Left(f) : Right(value as T);
  }

  @override
  Future<Either<Failure, List<SongVersionListing>>> fetchVersionsOfSong(
    String songWorkId,
  ) async => _answer('versions:$songWorkId', versions);

  @override
  Future<Either<Failure, List<SongVersionListing>>> searchPublicVersions(
    String query, {
    int limit = 30,
    int offset = 0,
  }) async {
    final q = query.toLowerCase();
    final all = [
      for (final v in publicVersions)
        if (q.isEmpty ||
            v.title.toLowerCase().contains(q) ||
            v.artist.toLowerCase().contains(q))
          v,
    ];
    return _answer(
      'public:$query:$offset',
      all.skip(offset).take(limit).toList(),
    );
  }

  @override
  Future<Either<Failure, SongWork>> fetchSong(String songId) async {
    final song = songs.where((s) => s.id == songId).firstOrNull;
    if (song == null && failure == null) {
      calls.add('song:$songId');
      return Left(BackendErrorCode.songNotFound.failure(message: 'none'));
    }
    return _answer('song:$songId', song ?? songs.first);
  }

  @override
  Future<Either<Failure, List<SongWork>>> searchSongs(
    String query, {
    bool onlyMine = false,
    int limit = 20,
  }) async {
    final q = query.toLowerCase();
    return _answer('songs:$query:mine=$onlyMine', [
      for (final s in songs)
        if (s.mergedIntoId == null &&
            (!onlyMine || s.createdBy == 'u-me') &&
            (q.isEmpty || s.title.toLowerCase().contains(q)))
          s,
    ]);
  }

  @override
  Future<Either<Failure, Song>> openVersion(String versionId) async {
    final song = opened;
    if (song == null && failure == null) {
      return Left(BackendErrorCode.versionNotFound.failure(message: 'none'));
    }
    return _answerOr('open:$versionId', song);
  }

  @override
  Future<Either<Failure, ForkedVersion>> forkVersion(
    String versionId, {
    String? label,
    Song? cachedSource,
  }) async {
    final result = forked;
    if (result == null && failure == null) {
      return Left(BackendErrorCode.versionNotFound.failure(message: 'none'));
    }
    return _answerOr('fork:$versionId:$label', result);
  }

  @override
  Future<Either<Failure, SongMergeRequest>> requestMerge({
    required String sourceSongId,
    required String targetSongId,
  }) async => _answer(
    'merge:$sourceSongId>$targetSongId',
    SongMergeRequest(
      id: 'req-new',
      sourceSongId: sourceSongId,
      targetSongId: targetSongId,
      sourceTitle: 'Source',
      targetTitle: 'Target',
      status: mergeStatus,
    ),
  );

  @override
  Future<Either<Failure, SongMergeRequest>> respondToMerge(
    String requestId, {
    required bool accept,
  }) async {
    final request = requests[requestId];
    final answered = SongMergeRequest(
      id: requestId,
      sourceSongId: request?.sourceSongId ?? 'song-a',
      targetSongId: request?.targetSongId ?? 'song-b',
      sourceTitle: request?.sourceTitle ?? 'A',
      targetTitle: request?.targetTitle ?? 'B',
      status: accept
          ? MergeRequestStatus.accepted
          : MergeRequestStatus.declined,
    );
    return _answer('respond:$requestId:$accept', answered);
  }

  @override
  Future<Either<Failure, SongMergeRequest>> fetchMergeRequest(
    String requestId,
  ) async {
    final request = requests[requestId];
    if (request == null && failure == null) {
      return Left(
        BackendErrorCode.mergeRequestNotFound.failure(message: 'none'),
      );
    }
    return _answerOr('request:$requestId', request);
  }

  @override
  Future<Either<Failure, List<SongMergeRequest>>>
  pendingMergeRequests() async => _answer('pending', pending);
}
