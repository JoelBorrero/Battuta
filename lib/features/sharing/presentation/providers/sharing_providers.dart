/// Riverpod wiring of song sharing.
library;

import 'package:battuta/core/database/database_providers.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/sharing/data/song_sharing_remote_data_source.dart';
import 'package:battuta/features/sharing/data/song_sharing_repository_impl.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:battuta/features/sharing/domain/entities/song_version_row.dart';
import 'package:battuta/features/sharing/domain/repositories/song_sharing_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final songSharingRemoteDataSourceProvider =
    Provider<SongSharingRemoteDataSource>((ref) {
      final manager = ref.watch(supabaseClientManagerProvider);
      return SupabaseSongSharingRemoteDataSource(() => manager.client);
    });

final songSharingRepositoryProvider = Provider<SongSharingRepository>(
  (ref) => SongSharingRepositoryImpl(
    remote: ref.watch(songSharingRemoteDataSourceProvider),
    db: ref.watch(appDatabaseProvider),
    session: ref.watch(accountSessionProvider),
    songs: ref.watch(songRepositoryProvider),
    scores: ref.watch(scoreRepositoryProvider),
  ),
);

/// The versions of song [workId] the backend lists for me (fails offline).
final remoteVersionsOfSongProvider = FutureProvider.autoDispose
    .family<List<SongVersionListing>, String>((ref, workId) async {
      if (ref.watch(currentAccountIdProvider) == null) return const [];
      final result = await ref
          .watch(songSharingRepositoryProvider)
          .fetchVersionsOfSong(workId);
      return result.fold((failure) => throw failure, (rows) => rows);
    });

/// What the list of versions of one song shows right now.
class SongVersionsState {
  const SongVersionsState({
    required this.rows,
    this.loading = false,
    this.failure,
  });

  final List<SongVersionRow> rows;

  /// The backend answer is still pending (the cached rows are already shown).
  final bool loading;

  /// Why the backend could not be asked (typically: offline).
  final Failure? failure;
}

/// Cached versions at once, then merged with the backend's when it answers.
final songVersionsProvider = Provider.autoDispose
    .family<SongVersionsState, String>((ref, workId) {
      final me = ref.watch(currentAccountIdProvider);
      final cached = <Song>[
        for (final song
            in ref.watch(repertoireProvider).value ?? const <Song>[])
          if (song.songWorkId == workId) song,
      ];
      final remote = ref.watch(remoteVersionsOfSongProvider(workId));
      return SongVersionsState(
        rows: mergeVersionRows(
          cached: cached,
          remote: remote.value ?? const [],
          accountId: me,
        ),
        loading: remote.isLoading,
        failure: remote.hasError && remote.error is Failure
            ? remote.error! as Failure
            : null,
      );
    });

/// The pending merge requests I sent or have to answer (online only).
final pendingMergeRequestsProvider =
    FutureProvider.autoDispose<List<SongMergeRequest>>((ref) async {
      if (ref.watch(currentAccountIdProvider) == null) return const [];
      final result = await ref
          .watch(songSharingRepositoryProvider)
          .pendingMergeRequests();
      return result.fold((failure) => throw failure, (rows) => rows);
    });

/// One merge request I am a party of.
final mergeRequestProvider = FutureProvider.autoDispose
    .family<SongMergeRequest, String>((ref, requestId) async {
      final result = await ref
          .watch(songSharingRepositoryProvider)
          .fetchMergeRequest(requestId);
      return result.fold((failure) => throw failure, (request) => request);
    });

/// The surviving song of [songId] (following merges); fails offline.
final songWorkProvider = FutureProvider.autoDispose.family<SongWork, String>((
  ref,
  songId,
) async {
  final result = await ref
      .watch(songSharingRepositoryProvider)
      .fetchSong(songId);
  return result.fold((failure) => throw failure, (work) => work);
});
