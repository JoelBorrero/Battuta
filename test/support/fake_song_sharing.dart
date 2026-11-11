import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/sharing/data/song_sharing_remote_data_source.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:battuta/features/sharing/domain/entities/song_suggestion.dart';
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
  List<SongSuggestion> suggestions = [];

  /// `song_versions` rows by id (with `songs` embedded) for fetch and fork.
  final Map<String, Map<String, dynamic>> rows = {};

  /// The row `forkVersion` returns.
  Map<String, dynamic>? forkRow;

  /// When set, every call fails with it.
  Failure? failure;

  /// When set, `forkVersion` makes the fork and then fails to read it back.
  bool forkReadFails = false;

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
  Future<List<SongSuggestion>> searchSongs(
    String query, {
    int limit = 8,
  }) async => _run('songs:$query', () {
    final q = query.toLowerCase();
    return [
      for (final s in suggestions)
        if (q.isEmpty || s.title.toLowerCase().contains(q)) s,
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
    final made = {...row, 'label': ?label};
    if (forkReadFails) throw ForkReadFailed(row: made, cause: offlineFailure());
    return made;
  });
}

/// A scripted [SongSharingRepository] for widget tests.
class FakeSongSharingRepository implements SongSharingRepository {
  List<SongVersionListing> versions = [];
  List<SongVersionListing> publicVersions = [];
  List<SongWork> songs = [];
  List<SongSuggestion> suggestions = [];

  /// When set, every call fails with it.
  Failure? failure;

  /// What `forkVersion` returns (unless [failure] is set).
  ForkedVersion? forked;

  /// What `openVersion` returns.
  Song? opened;

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
  Future<Either<Failure, List<SongSuggestion>>> searchSongs(
    String query, {
    int limit = 8,
  }) async {
    final q = query.toLowerCase();
    return _answer('songs:$query', [
      for (final s in suggestions)
        if (q.isEmpty || s.title.toLowerCase().contains(q)) s,
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
}
