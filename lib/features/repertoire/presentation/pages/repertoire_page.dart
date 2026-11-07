/// Battuta — Repertoire page.
///
/// The main screen for browsing the user's song library and setlists. Displays
/// a searchable, scrollable list of [SongCard] widgets, a Setlist manager,
/// and provides floating action buttons to create new songs or setlists.
library;

import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/widgets/song_card.dart';
import 'package:battuta/features/sync/presentation/widgets/cloud_sync_status_indicator.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The primary repertoire and setlists list page.
class RepertoirePage extends ConsumerStatefulWidget {
  /// Creates a [RepertoirePage].
  const RepertoirePage({super.key});

  @override
  ConsumerState<RepertoirePage> createState() => _RepertoirePageState();
}

class _RepertoirePageState extends ConsumerState<RepertoirePage> {
  int _selectedTabIndex = 0; // 0: Songs, 1: Setlists

  void _showCreateSetlistDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Setlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Setlist Title *',
                hintText: 'e.g. Sunday Morning - Easter',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Notes / Service Theme',
                hintText: 'e.g. Acoustic setup, communion song in D',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;

              final setlist = Setlist(
                id: 'setlist_${DateTime.now().millisecondsSinceEpoch}',
                title: title,
                description: descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
                eventDate: DateTime.now().add(const Duration(days: 3)),
                items: const [],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              await ref.read(setlistsProvider.notifier).createSetlist(setlist);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Created setlist "$title"')),
                );
              }
            },
            child: const Text('Create Setlist'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSetlist(BuildContext context, Setlist setlist) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Setlist?'),
        content: Text(
          'Are you sure you want to delete "${setlist.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.stageRed),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              await ref
                  .read(setlistsProvider.notifier)
                  .deleteSetlist(setlist.id);
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Deleted setlist "${setlist.title}"')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repertoire = ref.watch(repertoireProvider);
    final setlistsAsync = ref.watch(setlistsProvider);
    final isAdmin = ref.watch(isCurrentUserAdminProvider);

    final songCount = repertoire.value?.length ?? 0;
    final setlistCount = setlistsAsync.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repertoire'),
        actions: [
          const CloudSyncStatusIndicator(compact: true),
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined),
            tooltip: 'Scan sheet music',
            onPressed: () => context.push('/scanner'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search songs',
            onPressed: () => _showSearch(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── View Mode Switcher: Songs vs Setlists ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  icon: const Icon(Icons.music_note),
                  label: Text('Songs ($songCount)'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: const Icon(Icons.playlist_play),
                  label: Text('Setlists ($setlistCount)'),
                ),
              ],
              selected: {_selectedTabIndex},
              onSelectionChanged: (vals) {
                setState(() => _selectedTabIndex = vals.first);
              },
            ),
          ),

          // ── Content Area ──
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildSongsView(repertoire, theme, isAdmin: isAdmin)
                : _buildSetlistsView(setlistsAsync, theme, isAdmin: isAdmin),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              tooltip: _selectedTabIndex == 0 ? 'Add song' : 'Create setlist',
              onPressed: _selectedTabIndex == 0
                  ? () => context.push('/repertoire/new')
                  : _showCreateSetlistDialog,
              icon: const Icon(Icons.add),
              label: Text(_selectedTabIndex == 0 ? 'New Song' : 'New Setlist'),
            )
          : null,
    );
  }

  Widget _buildSongsView(
    AsyncValue<List<dynamic>> repertoire,
    ThemeData theme, {
    required bool isAdmin,
  }) {
    return repertoire.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load repertoire',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your repertoire is empty',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAdmin
                        ? 'Tap the + button to add your first song'
                        : 'No songs available yet. Contact an administrator to add songs.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      if (isAdmin) ...[
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.amberAccent,
                            foregroundColor: AppTheme.obsidianText,
                          ),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Load Sample Songs'),
                          onPressed: () async {
                            await ref
                                .read(repertoireProvider.notifier)
                                .seedSampleData();
                          },
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Song'),
                          onPressed: () => context.push('/repertoire/new'),
                        ),
                      ],
                      OutlinedButton.icon(
                        icon: const Icon(Icons.document_scanner_outlined),
                        label: const Text('Scan Score'),
                        onPressed: () => context.push('/scanner'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: songs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => SongCard(song: songs[index]),
        );
      },
    );
  }

  Widget _buildSetlistsView(
    AsyncValue<List<Setlist>> setlistsAsync,
    ThemeData theme, {
    required bool isAdmin,
  }) {
    return setlistsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading setlists: $e')),
      data: (setlists) {
        if (setlists.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.playlist_play,
                    size: 72,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text('No Setlists Yet', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    isAdmin
                        ? 'Create an ordered setlist for Sunday services or rehearsals.'
                        : 'No setlists created yet. Setlists will appear here once published by your director.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isAdmin)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.amberAccent,
                            foregroundColor: AppTheme.obsidianText,
                          ),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Load Sample Setlist'),
                          onPressed: () async {
                            await ref
                                .read(repertoireProvider.notifier)
                                .seedSampleData();
                          },
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Create Setlist'),
                          onPressed: _showCreateSetlistDialog,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: setlists.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final setlist = setlists[index];
            final isDark = theme.brightness == Brightness.dark;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? AppTheme.slateBorder : AppTheme.pearlBorder,
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.amberMuted,
                  child: Icon(Icons.playlist_play, color: AppTheme.amberAccent),
                ),
                title: Text(
                  setlist.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${setlist.songCount} songs • ${setlist.description ?? "Upcoming service"}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: isAdmin
                    ? IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: AppTheme.stageRed,
                        ),
                        tooltip: 'Delete setlist',
                        onPressed: () => _confirmDeleteSetlist(context, setlist),
                      )
                    : null,
                onTap: () => context.push(AppRoutes.setlistDetail(setlist.id)),
              ),
            );
          },
        );
      },
    );
  }

  /// Opens a search delegate to filter songs by query.
  void _showSearch(BuildContext context, WidgetRef ref) {
    showSearch(context: context, delegate: _SongSearchDelegate(ref));
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
    if (query.trim().isEmpty) {
      return const Center(child: Text('Type to search songs…'));
    }

    final repertoire = _ref.watch(repertoireProvider);

    return repertoire.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (songs) {
        final q = query.trim().toLowerCase();
        final matches = songs.where((s) {
          return s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q) ||
              s.tags.any((t) => t.toLowerCase().contains(q));
        }).toList();

        if (matches.isEmpty) {
          return const Center(child: Text('No songs found'));
        }
        return ListView.builder(
          itemCount: matches.length,
          itemBuilder: (context, index) => SongCard(song: matches[index]),
        );
      },
    );
  }
}
