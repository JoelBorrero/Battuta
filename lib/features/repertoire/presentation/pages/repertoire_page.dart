/// Battuta — Repertoire page.
///
/// The main screen for browsing the user's song library and setlists. Displays
/// a searchable, scrollable list of [SongCard] widgets, a Setlist manager,
/// and provides floating action buttons to create new songs or setlists.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/widgets/inbox_button.dart';
import 'package:battuta/features/profile/presentation/widgets/profile_avatar_button.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_score_mapper.dart';
import 'package:battuta/features/repertoire/domain/services/song_import_export_service.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_scope_providers.dart';
import 'package:battuta/features/repertoire/presentation/widgets/add_to_repertoire_sheet.dart';
import 'package:battuta/features/repertoire/presentation/widgets/org_repertoire_view.dart';
import 'package:battuta/features/repertoire/presentation/widgets/repertoire_scope_bar.dart';
import 'package:battuta/features/repertoire/presentation/widgets/setlist_date_stamp.dart';
import 'package:battuta/features/repertoire/presentation/widgets/song_card.dart';
import 'package:battuta/features/repertoire/presentation/widgets/song_import_modal.dart';
import 'package:battuta/features/scanner/presentation/widgets/scan_flow_modal.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/sharing/presentation/widgets/song_link_sheet.dart';
import 'package:battuta/features/sync/presentation/widgets/cloud_sync_status_indicator.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final l10n = AppLocalizations.of(context);
    final titleController = TextEditingController();
    final descController = TextEditingController();
    // A setlist created while an organization is shown belongs to it.
    final organizationId = ref.read(scopeOrganizationProvider)?.id;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.createNewSetlist ?? 'Create New Setlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: l10n?.setlistTitleField ?? 'Setlist Title *',
                hintText:
                    l10n?.setlistTitleHint ?? 'e.g. Sunday Morning - Easter',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText:
                    l10n?.notesServiceThemeField ?? 'Notes / Service Theme',
                hintText:
                    l10n?.notesServiceThemeHint ??
                    'e.g. Acoustic setup, communion song in D',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
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
                organizationId: organizationId,
              );

              Object? failure;
              try {
                await ref
                    .read(setlistsProvider.notifier)
                    .createSetlist(setlist);
              } catch (e) {
                failure = e;
              }
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              if (failure != null && mounted && l10n != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.setlistCreateFailed(
                        backendErrorMessage(l10n, failure),
                      ),
                    ),
                  ),
                );
                return;
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.createdSetlistSuccess(title) ??
                          'Created setlist "$title"',
                    ),
                  ),
                );
              }
            },
            child: Text(l10n?.createSetlist ?? 'Create Setlist'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSetlist(BuildContext context, Setlist setlist) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.deleteSetlistTitle ?? 'Delete Setlist?'),
        content: Text(
          l10n?.deleteSetlistConfirm(setlist.title) ??
              'Are you sure you want to delete "${setlist.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: BattutaBrand.of(ctx).danger,
            ),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(setlistsProvider.notifier)
                    .deleteSetlist(setlist.id);
              } catch (e) {
                if (mounted && l10n != null) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(backendErrorMessage(l10n, e))),
                  );
                }
                return;
              }
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.deletedSetlistSuccess(setlist.title) ??
                          'Deleted setlist "${setlist.title}"',
                    ),
                  ),
                );
              }
            },
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
  }

  void _openScannerDirect(BuildContext context) {
    ScanFlowModal.show(
      context,
      onScoreExtracted: (Score score) async {
        final linked = await linkSongBeforeSave(context, ref, score.toSong());
        if (linked == null) return;
        final song = linked;
        await ref.read(repertoireProvider.notifier).addSong(song);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: BattutaBrand.of(context).success,
              content: Text('Added "${song.title}" to Repertoire!'),
            ),
          );
          context.push('/repertoire/${song.id}');
        }
      },
    );
  }

  void _showAddSongOptions(BuildContext context) {
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final l10n = AppLocalizations.of(context);

    Widget option({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      Color? tone,
    }) => ListTile(
      leading: StageIconTile(icon: icon, size: 40, tone: tone),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      onTap: onTap,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n?.addSongToRepertoire ?? 'Add Song to Repertoire',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              option(
                icon: Icons.link,
                title: l10n?.importByWebUrl ?? 'Import by Web URL',
                subtitle: l10n?.importByWebUrlSubtitle ?? 'Scrape chords & lyrics from Cifra Club, LaCuerda, or web link',
                onTap: () {
                  Navigator.of(ctx).pop();
                  SongImportModal.show(context, initialTab: SongImportTab.url);
                },
              ),
              option(
                icon: Icons.document_scanner_outlined,
                tone: brand.info,
                title: l10n?.scanWithGemini ?? 'Scan with Gemini AI (OMR)',
                subtitle:
                    l10n?.scanWithGeminiSubtitle ??
                    'Scan printed sheet music from camera or photos',
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openScannerDirect(context);
                },
              ),
              option(
                icon: Icons.edit_note,
                tone: brand.success,
                title: l10n?.writeInSongEditor ?? 'Write in Song Editor',
                subtitle:
                    l10n?.writeInSongEditorSubtitle ??
                    'Create a blank lead sheet and enter sections manually',
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/repertoire/new');
                },
              ),
              option(
                icon: Icons.content_paste,
                tone: brand.warning,
                title: l10n?.pasteTextBackup ?? 'Paste Text / Backup',
                subtitle:
                    l10n?.pasteTextBackupSubtitle ??
                    'Paste ChordPro text, plain lead sheets, or JSON backups',
                onTap: () {
                  Navigator.of(ctx).pop();
                  SongImportModal.show(context, initialTab: SongImportTab.text);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onMenuSelected(String value) async {
    if (value == 'import') {
      SongImportModal.show(context);
    } else if (value == 'scan') {
      _openScannerDirect(context);
    } else if (value == 'export_all') {
      final songs = ref.read(myLibraryProvider).value ?? [];
      if (songs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No songs in repertoire to export')),
        );
        return;
      }
      final jsonStr = SongImportExportService.exportRepertoireToJson(songs);
      await Clipboard.setData(ClipboardData(text: jsonStr));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: BattutaBrand.of(context).success,
            content: Text('Exported ${songs.length} songs to clipboard (JSON)'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final library = ref.watch(myLibraryProvider);
    final setlistsAsync = ref.watch(scopedSetlistsProvider);
    // My library is mine to edit; an organization is curated by its admins.
    final organization = ref.watch(scopeOrganizationProvider);
    final canManage = ref.watch(canManageScopeProvider);
    final signedIn = ref.watch(currentAccountIdProvider) != null;
    final hasOrganizations =
        (ref.watch(myOrganizationsProvider).value ?? const []).isNotEmpty;
    final l10n = AppLocalizations.of(context);

    final songCount = organization == null
        ? (library.value?.length ?? 0)
        : (ref
                  .watch(organizationRepertoireProvider(organization.id))
                  .value
                  ?.length ??
              0);
    final setlistCount = setlistsAsync.value?.length ?? 0;

    return Scaffold(
      appBar: StageAppBar.large(
        title: l10n?.repertoireTitle ?? 'Repertoire',
        actions: [
          if (signedIn)
            IconButton(
              key: const ValueKey('discover_chip'),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: const Icon(Icons.explore_outlined),
              tooltip: l10n?.discoverTooltip ?? 'Discover public songs',
              onPressed: () => context.push(AppRoutes.discover),
            ),
          const InboxButton(),
          const ProfileAvatarButton(),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // The header scrolls with the list, so a short window still
          // reaches every row.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                BattutaSpace.lg,
                BattutaSpace.xs,
                BattutaSpace.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Scope: my library or an organization's repertoire ──
                  if (hasOrganizations) ...[
                    Row(
                      children: [
                        const Expanded(child: RepertoireScopeBar()),
                        if (organization != null)
                          IconButton(
                            key: const ValueKey('org_settings_btn'),
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            icon: const Icon(Icons.tune),
                            tooltip:
                                l10n?.orgSettingsTooltip ??
                                'Organization settings',
                            onPressed: () => context.push(
                              AppRoutes.organizationSettings(organization.id),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: BattutaSpace.sm),
                  ],

                  // ── Search, sync and the import / export menu ──
                  Row(
                    children: [
                      Expanded(
                        child: _SearchField(
                          hint:
                              l10n?.repertoireSearchHint ??
                              'Search title, artist or tag',
                          onTap: () => _showSearch(context, ref, organization),
                        ),
                      ),
                      const CloudSyncStatusIndicator(compact: true),
                      if (organization == null) _buildMoreMenu(l10n),
                    ],
                  ),
                  const SizedBox(height: BattutaSpace.md),

                  // ── View Mode Switcher: Songs vs Setlists ──
                  StageSegmentedControl<int>(
                    segments: [
                      StageSegment(
                        value: 0,
                        label:
                            l10n?.songsTab(songCount) ?? 'Songs ($songCount)',
                      ),
                      StageSegment(
                        value: 1,
                        label:
                            l10n?.setlistsTab(setlistCount) ??
                            'Setlists ($setlistCount)',
                      ),
                    ],
                    selected: _selectedTabIndex,
                    onChanged: (value) =>
                        setState(() => _selectedTabIndex = value),
                  ),
                ],
              ),
            ),
          ),

          // ── Content Area ──
          if (_selectedTabIndex == 0)
            (organization == null
                ? _buildSongsView(library, theme)
                : OrgRepertoireView(organization: organization))
          else
            _buildSetlistsView(
              setlistsAsync,
              theme,
              organization: organization,
              canManage: canManage,
            ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              tooltip: _selectedTabIndex == 0
                  ? (organization == null
                        ? (l10n?.addSong ?? 'Add song')
                        : (l10n?.addToRepertoireAction ?? 'Add to repertoire'))
                  : (l10n?.createSetlist ?? 'Create setlist'),
              onPressed: _selectedTabIndex == 0
                  ? (organization == null
                        ? () => _showAddSongOptions(context)
                        : () => showAddToRepertoireSheet(context, organization))
                  : _showCreateSetlistDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildMoreMenu(AppLocalizations? l10n) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'More options',
      onSelected: _onMenuSelected,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'scan',
          child: Row(
            children: [
              const Icon(Icons.document_scanner_outlined, size: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(l10n?.scanSheetMusicTooltip ?? 'Scan sheet music'),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'import',
          child: Row(
            children: [
              Icon(Icons.file_download_outlined, size: 20),
              SizedBox(width: 10),
              Flexible(child: Text('Import Song / Leadsheet')),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'export_all',
          child: Row(
            children: [
              Icon(Icons.file_upload_outlined, size: 20),
              SizedBox(width: 10),
              Flexible(child: Text('Export Repertoire (JSON Backup)')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSongsView(AsyncValue<List<Song>> repertoire, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
    return repertoire.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: StageEmptyState(
          icon: Icons.error_outline,
          tone: theme.colorScheme.error,
          title: l10n?.failedToLoadRepertoire ?? 'Failed to load repertoire',
          message: error.toString(),
          actions: [
            FilledButton.icon(
              onPressed: () => ref.invalidate(repertoireProvider),
              icon: const Icon(Icons.refresh),
              label: Text(l10n?.retry ?? 'Retry'),
            ),
          ],
        ),
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: StageEmptyState(
              icon: Icons.library_music_outlined,
              title: l10n?.repertoireEmpty ?? 'Your repertoire is empty',
              message:
                  l10n?.repertoireEmptyAdminHint ??
                  'Tap the + button to add your first song',
              actions: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: brand.accent,
                    foregroundColor: brand.onAccent,
                  ),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(l10n?.loadSampleSongs ?? 'Load Sample Songs'),
                  onPressed: () async {
                    await ref
                        .read(repertoireProvider.notifier)
                        .seedSampleData();
                  },
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(l10n?.addSong ?? 'Add Song'),
                  onPressed: () => _showAddSongOptions(context),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.link),
                  label: const Text('Import by URL'),
                  onPressed: () => SongImportModal.show(
                    context,
                    initialTab: SongImportTab.url,
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: Text(l10n?.scanScore ?? 'Scan Score'),
                  onPressed: () => _openScannerDirect(context),
                ),
              ],
            ),
          );
        }

        return SliverPadding(
          padding: _listPadding,
          sliver: SliverList.separated(
            itemCount: songs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => BattutaEntrance(
              index: index,
              child: SongCard(song: songs[index]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSetlistsView(
    AsyncValue<List<Setlist>> setlistsAsync,
    ThemeData theme, {
    required Organization? organization,
    required bool canManage,
  }) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
    return setlistsAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            '${l10n?.failedToLoadRepertoire ?? "Error loading setlists"}: $e',
          ),
        ),
      ),
      data: (setlists) {
        if (setlists.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: StageEmptyState(
              icon: Icons.playlist_play,
              title: l10n?.noSetlistsYet ?? 'No Setlists Yet',
              message: organization != null
                  ? (canManage
                        ? (l10n?.orgSetlistsEmptyAdminHint ??
                              'Create a setlist for this organization.')
                        : (l10n?.orgSetlistsEmptyMemberHint ??
                              'No setlists yet. Your admins publish them here.'))
                  : (l10n?.setlistsEmptyAdminHint ??
                        'Create an ordered setlist for Sunday services or rehearsals.'),
              actions: [
                if (canManage) ...[
                  if (organization == null)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: brand.accent,
                        foregroundColor: brand.onAccent,
                      ),
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(
                        l10n?.loadSampleSetlist ?? 'Load Sample Setlist',
                      ),
                      onPressed: () async {
                        await ref
                            .read(repertoireProvider.notifier)
                            .seedSampleData();
                      },
                    ),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l10n?.createSetlist ?? 'Create Setlist'),
                    onPressed: _showCreateSetlistDialog,
                  ),
                ],
              ],
            ),
          );
        }

        return SliverPadding(
          padding: _listPadding,
          sliver: SliverList.separated(
            itemCount: setlists.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final setlist = setlists[index];
              return BattutaEntrance(
                index: index,
                child: _SetlistCard(
                  setlist: setlist,
                  subtitle:
                      '${l10n?.setlistSongsCount(setlist.songCount) ?? "${setlist.songCount} songs"} • ${setlist.description ?? (l10n?.upcomingService ?? "Upcoming service")}',
                  onTap: () =>
                      context.push(AppRoutes.setlistDetail(setlist.id)),
                  onDelete: canManage
                      ? () => _confirmDeleteSetlist(context, setlist)
                      : null,
                  deleteTooltip: l10n?.deleteSetlistTooltip ?? 'Delete setlist',
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Leaves room under the last row for the add button.
  static const _listPadding = EdgeInsets.fromLTRB(
    BattutaSpace.lg,
    BattutaSpace.md,
    BattutaSpace.lg,
    96,
  );

  /// Opens a search delegate to filter songs by query.
  void _showSearch(
    BuildContext context,
    WidgetRef ref,
    Organization? organization,
  ) {
    showSearch(
      context: context,
      delegate: _SongSearchDelegate(ref, organization),
    );
  }
}

// ---------------------------------------------------------------------------
// Search delegate
// ---------------------------------------------------------------------------

/// A [SearchDelegate] that filters the repertoire as the user types.
class _SongSearchDelegate extends SearchDelegate<String> {
  _SongSearchDelegate(this._ref, this._organization);

  final WidgetRef _ref;

  /// The organization whose repertoire is searched; `null` is my library.
  final Organization? _organization;

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
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (query.trim().isEmpty) {
      return Center(
        child: Text(l10n?.typeToSearchSongs ?? 'Type to search songs…'),
      );
    }

    final organization = _organization;
    if (organization != null) {
      return _buildOrganizationResults(context, organization);
    }
    final repertoire = _ref.watch(myLibraryProvider);

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
          return Center(child: Text(l10n?.noSongsFound ?? 'No songs found'));
        }
        return ListView.builder(
          itemCount: matches.length,
          itemBuilder: (context, index) => SongCard(song: matches[index]),
        );
      },
    );
  }

  Widget _buildOrganizationResults(
    BuildContext context,
    Organization organization,
  ) {
    final l10n = AppLocalizations.of(context);
    final entries = _ref.watch(organizationRepertoireProvider(organization.id));
    return entries.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (all) {
        final q = query.trim().toLowerCase();
        final matches = [
          for (final RepertoireEntry entry in all)
            if (entry.title.toLowerCase().contains(q) ||
                entry.artist.toLowerCase().contains(q))
              entry,
        ];
        if (matches.isEmpty) {
          return Center(child: Text(l10n?.noSongsFound ?? 'No songs found'));
        }
        return ListView.builder(
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final entry = matches[index];
            return ListTile(
              minTileHeight: 56,
              title: Text(entry.title, maxLines: 1),
              subtitle: Text(
                [
                  if (entry.artist.isNotEmpty) entry.artist,
                  entry.key,
                ].join(' · '),
                maxLines: 1,
              ),
              onTap: () => context.push(AppRoutes.songDetail(entry.versionId)),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Setlist card
// ---------------------------------------------------------------------------

/// Stage card for a [Setlist]: a month / day stamp (or a neutral list tile
/// without a date), the title and a meta line.
class _SetlistCard extends StatelessWidget {
  const _SetlistCard({
    required this.setlist,
    required this.subtitle,
    required this.onTap,
    required this.deleteTooltip,
    this.onDelete,
  });

  final Setlist setlist;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final String deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final date = setlist.eventDate;

    return StageCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.only(
        start: BattutaSpace.md,
        top: BattutaSpace.md,
        end: BattutaSpace.xs,
        bottom: BattutaSpace.md,
      ),
      child: Row(
        children: [
          if (date != null)
            SetlistDateStamp(date: date)
          else
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: brand.cardRaised,
                borderRadius: BattutaRadius.smAll,
                border: Border.all(color: brand.border),
              ),
              child: Icon(
                Icons.format_list_bulleted,
                size: 22,
                color: brand.inkMuted,
              ),
            ),
          const SizedBox(width: BattutaSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  setlist.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: brand.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: BattutaSpace.xxs),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: brand.inkMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: Icon(Icons.delete_outline, size: 20, color: brand.danger),
              tooltip: deleteTooltip,
              onPressed: onDelete,
            )
          else
            Padding(
              padding: const EdgeInsetsDirectional.only(end: BattutaSpace.sm),
              child: Icon(Icons.chevron_right, size: 20, color: brand.inkDim),
            ),
        ],
      ),
    );
  }
}

/// The inline search field: a tappable bar that opens the song search.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return BattutaPressable(
      key: const ValueKey('repertoire_search_field'),
      onTap: onTap,
      semanticLabel: hint,
      pressedScale: 0.99,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: brand.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: brand.border),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: brand.inkMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: brand.inkMuted, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
