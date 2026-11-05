/// Battuta — Repertoire page.
///
/// The main screen for browsing the user's song library. Displays a
/// searchable, scrollable list of [SongCard] widgets and provides a
/// floating action button to create new songs.
library;

import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/widgets/song_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The primary repertoire list page.
///
/// Watches the [repertoireProvider] and renders the appropriate state:
/// - **Loading** — centered progress indicator
/// - **Error** — centered error message with a retry button
/// - **Empty** — friendly empty-state illustration
/// - **Data** — scrollable list of [SongCard]s
class RepertoirePage extends ConsumerWidget {
  /// Creates a [RepertoirePage].
  const RepertoirePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repertoire = ref.watch(repertoireProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repertoire'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search songs',
            onPressed: () => _showSearch(context, ref),
          ),
        ],
      ),
      body: repertoire.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load repertoire',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(repertoireProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (songs) {
          if (songs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.library_music_outlined,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your repertoire is empty',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to add your first song',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: songs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => SongCard(song: songs[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add song',
        onPressed: () {
          // TODO: Navigate to the song editor page.
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Opens a search delegate to filter songs by query.
  void _showSearch(BuildContext context, WidgetRef ref) {
    showSearch(
      context: context,
      delegate: _SongSearchDelegate(ref),
    );
  }
}

// ---------------------------------------------------------------------------
// Search delegate
// ---------------------------------------------------------------------------

/// A [SearchDelegate] that filters the repertoire as the user types.
class _SongSearchDelegate extends SearchDelegate<String> {
  _SongSearchDelegate(this._ref);

  final WidgetRef _ref;

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              query = '';
              showSuggestions(context);
            },
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(
        child: Text('Type to search songs…'),
      );
    }

    // Trigger a search through the provider.
    _ref.read(repertoireProvider.notifier).searchSongs(query);
    final repertoire = _ref.watch(repertoireProvider);

    return repertoire.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(child: Text('No songs found'));
        }
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) => SongCard(song: songs[index]),
        );
      },
    );
  }
}
