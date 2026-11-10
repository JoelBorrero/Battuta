/// Battuta — Repertoire state management provider.
///
/// An [AsyncNotifier] powered by Riverpod code-generation that manages
/// the lifecycle of the song repertoire list. Handles loading, CRUD
/// operations, and search, exposing state as [AsyncValue<List<Song>>]
/// so the UI can react to loading / error / data states declaratively.
library;

import 'package:battuta/core/database/database_providers.dart';
import 'package:battuta/features/repertoire/data/seed/repertoire_seeder.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/repositories/song_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repertoire_provider.g.dart';

/// Provides the active [SongRepository] instance (backed by Drift SQLite).
final songRepositoryProvider = Provider<SongRepository>((ref) {
  return ref.watch(driftSongRepositoryProvider);
});

/// Provides all setlists managed through [SetlistsNotifier].
final setlistsProvider = AsyncNotifierProvider<SetlistsNotifier, List<Setlist>>(
  SetlistsNotifier.new,
);

class SetlistsNotifier extends AsyncNotifier<List<Setlist>> {
  @override
  FutureOr<List<Setlist>> build() async {
    final repo = ref.watch(setlistRepositoryProvider);
    final result = await repo.getAllSetlists();
    return result.fold((failure) => throw failure, (setlists) => setlists);
  }

  Future<void> createSetlist(Setlist setlist) async {
    final repo = ref.read(setlistRepositoryProvider);
    final res = await repo.saveSetlist(setlist);
    res.fold((failure) => throw failure, (_) => ref.invalidateSelf());
  }

  Future<void> deleteSetlist(String id) async {
    final repo = ref.read(setlistRepositoryProvider);
    final res = await repo.deleteSetlist(id);
    res.fold((failure) => throw failure, (_) => ref.invalidateSelf());
  }

  Future<void> updateSetlist(Setlist setlist) async {
    final repo = ref.read(setlistRepositoryProvider);
    final res = await repo.saveSetlist(setlist);
    res.fold((failure) => throw failure, (_) => ref.invalidateSelf());
  }
}

/// Provides a single [Setlist] by its [id].
final setlistByIdProvider = FutureProvider.family<Setlist?, String>((
  ref,
  id,
) async {
  final setlists = ref.watch(setlistsProvider).value;
  if (setlists != null) {
    final cached = setlists.where((s) => s.id == id).firstOrNull;
    if (cached != null) return cached;
  }
  final repository = ref.watch(setlistRepositoryProvider);
  final result = await repository.getSetlistById(id);
  return result.fold((failure) => throw failure, (setlist) => setlist);
});

/// Provides a single [Song] by its [id].
final songByIdProvider = FutureProvider.family<Song?, String>((ref, id) async {
  final repertoire = ref.watch(repertoireProvider).value;
  if (repertoire != null) {
    final cached = repertoire.where((s) => s.id == id).firstOrNull;
    if (cached != null) return cached;
  }
  final repository = ref.watch(songRepositoryProvider);
  final result = await repository.getSongById(id);
  return result.fold((failure) => throw failure, (song) => song);
});

/// Provides the current repertoire list and exposes mutation methods.
///
/// Usage in a widget:
/// ```dart
/// final repertoire = ref.watch(repertoireProvider);
/// repertoire.when(
///   data: (songs) => SongListView(songs: songs),
///   loading: () => const CircularProgressIndicator(),
///   error: (e, st) => ErrorMessage(e),
/// );
/// ```
@riverpod
class Repertoire extends _$Repertoire {
  /// Loads all songs from the repository on first access.
  @override
  Future<List<Song>> build() async {
    final repository = ref.watch(songRepositoryProvider);
    final result = await repository.getAllSongs();
    return result.fold((failure) => throw failure, (songs) => songs);
  }

  /// Adds a new [song] to the repertoire.
  ///
  /// Optimistically updates the local state and rolls back on failure.
  Future<void> addSong(Song song) async {
    final repository = ref.read(songRepositoryProvider);
    final previousState = state;

    // Optimistic update
    state = AsyncData([...?state.value, song]);

    final result = await repository.saveSong(song);
    result.fold(
      (failure) {
        if (ref.mounted) {
          state = previousState; // rollback
          state = AsyncError(failure, StackTrace.current);
        }
      },
      (saved) {
        if (ref.mounted) {
          final current = state.value ?? [];
          state = AsyncData([
            for (final s in current)
              if (s.id == song.id) saved else s,
          ]);
        }
      },
    );
  }

  /// Imports multiple [songs] into the database and refreshes state.
  /// Returns the count of successfully saved songs.
  Future<int> importSongs(List<Song> songs) async {
    final repository = ref.read(songRepositoryProvider);
    final savedSongs = <Song>[];
    for (final song in songs) {
      final res = await repository.saveSong(song);
      res.fold((_) {}, (saved) => savedSongs.add(saved));
    }
    if (ref.mounted) {
      if (state.hasValue) {
        final current = state.value ?? [];
        final currentMap = {for (final s in current) s.id: s};
        for (final s in savedSongs) {
          currentMap[s.id] = s;
        }
        state = AsyncData(currentMap.values.toList());
      } else {
        ref.invalidateSelf();
      }
    }
    return savedSongs.length;
  }

  /// Updates an existing [song] in the repertoire.
  ///
  /// Replaces the song with a matching [Song.id] in the local state.
  Future<void> updateSong(Song song) async {
    final repository = ref.read(songRepositoryProvider);
    final previousState = state;

    // Optimistic update
    state = AsyncData([
      for (final s in state.value ?? [])
        if (s.id == song.id) song else s,
    ]);

    final result = await repository.saveSong(song);
    result.fold(
      (failure) {
        if (ref.mounted) {
          state = previousState; // rollback
          state = AsyncError(failure, StackTrace.current);
        }
      },
      (saved) {
        if (ref.mounted) {
          state = AsyncData([
            for (final s in state.value ?? [])
              if (s.id == song.id) saved else s,
          ]);
        }
      },
    );
  }

  /// Removes the song with the given [songId] from the repertoire.
  Future<void> deleteSong(String songId) async {
    final repository = ref.read(songRepositoryProvider);
    final previousState = state;

    // Optimistic removal
    state = AsyncData([
      for (final s in state.value ?? [])
        if (s.id != songId) s,
    ]);

    final result = await repository.deleteSong(songId);
    result.fold(
      (failure) {
        if (ref.mounted) {
          state = previousState; // rollback
          state = AsyncError(failure, StackTrace.current);
        }
      },
      (_) {
        /* already removed optimistically */
      },
    );
  }

  /// Filters the repertoire by [query], matching title, artist, or tags.
  ///
  /// Replaces the current state with the search results. Pass an empty
  /// string to reload the full list.
  Future<void> searchSongs(String query) async {
    final repository = ref.read(songRepositoryProvider);

    state = const AsyncLoading();

    final result = query.isEmpty
        ? await repository.getAllSongs()
        : await repository.searchSongs(query);

    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      AsyncData.new,
    );
  }

  /// Seeds sample songs and default setlists into the SQLite database.
  Future<void> seedSampleData() async {
    final songRepo = ref.read(songRepositoryProvider);
    final setlistRepo = ref.read(setlistRepositoryProvider);
    await RepertoireSeeder.seedIfEmpty(
      songRepo: songRepo,
      setlistRepo: setlistRepo,
    );
    ref.invalidateSelf();
    ref.invalidate(setlistsProvider);
  }
}
