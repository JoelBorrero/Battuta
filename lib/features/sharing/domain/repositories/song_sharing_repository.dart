/// Online side of song sharing: other people's versions, public songs, forks
/// and merge requests. Everything here needs the backend except the offline
/// fork, which falls back to a local copy.
library;

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class SongSharingRepository {
  /// The versions of song [songWorkId] the account can see (its own, shared
  /// with its organizations, public), newest first.
  Future<Either<Failure, List<SongVersionListing>>> fetchVersionsOfSong(
    String songWorkId,
  );

  /// One page of public versions whose title or artist match [query]. A page
  /// shorter than [limit] is the last one.
  Future<Either<Failure, List<SongVersionListing>>> searchPublicVersions(
    String query, {
    int limit = 30,
    int offset = 0,
  });

  /// The surviving song of [songId] (following merges).
  Future<Either<Failure, SongWork>> fetchSong(String songId);

  /// Songs visible to the account whose title or artist match [query];
  /// [onlyMine] keeps the ones the account created. Songs merged away are
  /// left out.
  Future<Either<Failure, List<SongWork>>> searchSongs(
    String query, {
    bool onlyMine = false,
    int limit = 20,
  });

  /// Downloads version [versionId] into the local cache (read-only unless it
  /// is mine) so the viewer can open it.
  Future<Either<Failure, Song>> openVersion(String versionId);

  /// Copies a version into a new private version owned by the account, under
  /// the same song. Online it uses the backend (which copies the score and
  /// notifies the owner). Without a connection, and when [cachedSource] is
  /// known, a local copy with the lineage is made and pushed later.
  Future<Either<Failure, ForkedVersion>> forkVersion(
    String versionId, {
    String? label,
    Song? cachedSource,
  });

  /// Asks to merge [sourceSongId] into [targetSongId].
  Future<Either<Failure, SongMergeRequest>> requestMerge({
    required String sourceSongId,
    required String targetSongId,
  });

  /// Answers a merge request addressed to the account.
  Future<Either<Failure, SongMergeRequest>> respondToMerge(
    String requestId, {
    required bool accept,
  });

  /// One merge request the account is a party of.
  Future<Either<Failure, SongMergeRequest>> fetchMergeRequest(String requestId);

  /// The pending merge requests the account sent or has to answer.
  Future<Either<Failure, List<SongMergeRequest>>> pendingMergeRequests();
}
