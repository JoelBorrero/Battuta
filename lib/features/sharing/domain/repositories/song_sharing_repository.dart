/// Online side of song sharing: other people's versions, public songs, song
/// search and forks. Everything here needs the backend except the offline
/// fork, which falls back to a local copy.
library;

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:battuta/features/sharing/domain/entities/song_suggestion.dart';
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

  /// The song [songId].
  Future<Either<Failure, SongWork>> fetchSong(String songId);

  /// Songs the account can see that match [query] (accent and case
  /// insensitive, typos tolerated), with how many versions it can see.
  Future<Either<Failure, List<SongSuggestion>>> searchSongs(
    String query, {
    int limit = 8,
  });

  /// Downloads version [versionId] into the local cache (read-only unless it
  /// is mine) so the viewer can open it.
  Future<Either<Failure, Song>> openVersion(String versionId);

  /// Copies a version into a new private version owned by the account, under
  /// the same song. Online it uses the backend (which copies the score and
  /// notifies the owner). Without a connection, and when [cachedSource] is
  /// known, a local copy with the lineage is made and pushed later. Once the
  /// backend has made the fork it is never copied locally again.
  Future<Either<Failure, ForkedVersion>> forkVersion(
    String versionId, {
    String? label,
    Song? cachedSource,
  });
}
