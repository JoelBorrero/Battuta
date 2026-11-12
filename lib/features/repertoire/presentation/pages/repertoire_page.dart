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
            style: FilledButton.styleFrom(backgroundColor: AppTheme.stageRed),
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
              backgroundColor: AppTheme.stageGreen,
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
    final l10n = AppLocalizations.of(context);

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
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x22E5A93C),
                  child: Icon(Icons.link, color: AppTheme.stageAmber),
                ),
                title: Text(
                  l10n?.importByWebUrl ?? 'Import by Web URL',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  l10n?.importByWebUrlSubtitle ?? 'Scrape chords & lyrics from Cifra Club, LaCuerda, or web link',
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  SongImportModal.show(context, initialTab: SongImportTab.url);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x222E86DE),
                  child: Icon(
                    Icons.document_scanner_outlined,
                    color: AppTheme.stageBlue,
                  ),
                ),
                title: Text(
                  l10n?.scanWithGemini ?? 'Scan with Gemini AI (OMR)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  l10n?.scanWithGeminiSubtitle ??
                      'Scan printed sheet music from camera or photos',
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openScannerDirect(context);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x2210B981),
                  child: Icon(Icons.edit_note, color: AppTheme.stageGreen),
                ),
                title: Text(
                  l10n?.writeInSongEditor ?? 'Write in Song Editor',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  l10n?.writeInSongEditorSubtitle ??
                      'Create a blank lead sheet and enter sections manually',
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/repertoire/new');
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x229C27B0),
                  child: Icon(Icons.content_paste, color: Colors.purple),
                ),
                title: Text(
                  l10n?.pasteTextBackup ?? 'Paste Text / Backup',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  l10n?.pasteTextBackupSubtitle ??
                      'Paste ChordPro text, plain lead sheets, or JSON backups',
                ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final library = ref.watch(myLibraryProvider);
    final setlistsAsync = ref.watch(scopedSetlistsProvider);
    // My library is mine to edit; an organization is curated by its admins.
    final organization = ref.watch(scopeOrganizationProvider);
    final canManage = ref.watch(canManageScopeProvider);
    final l10n = AppLocalizations.of(context);

    final songCount = organization == null
        ? (library.value?.length ?? 0)
        : (ref
                  .watch(organizationRepertoireProvider(organization.id))
                  .value
                  ?.length ??
              0);
    final setlistCount = setlistsAsync.value?.length ?? 0;

    final compactBar = MediaQuery.sizeOf(context).width < 480;

    return Scaffold(
      appBar: AppBar(
        // A tab's root page: never a back arrow (it would also squeeze the
        // logo and title).
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (MediaQuery.sizeOf(context).width < BattutaBreakpoints.rail) ...[
              const BattutaMark(size: 22),
              const SizedBox(width: BattutaSpace.sm),
            ],
            Flexible(
              child: Text(
                l10n?.repertoireTitle ?? 'Repertoire',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          const CloudSyncStatusIndicator(compact: true),
          const InboxButton(),
          if (organization != null)
            IconButton(
              key: const ValueKey('org_settings_btn'),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: const Icon(Icons.tune),
              tooltip: l10n?.orgSettingsTooltip ?? 'Organization settings',
              onPressed: () =>
                  context.push(AppRoutes.organizationSettings(organization.id)),
            ),
          // On a phone these two live in the overflow menu: the app bar has
          // to fit the avatar as well.
          if (organization == null && !compactBar) ...[
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'Import song or lead sheet',
              onPressed: () => SongImportModal.show(context),
            ),
            IconButton(
              icon: const Icon(Icons.document_scanner_outlined),
              tooltip: l10n?.scanSheetMusicTooltip ?? 'Scan sheet music',
              onPressed: () => _openScannerDirect(context),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n?.searchSongsTooltip ?? 'Search songs',
            onPressed: () => _showSearch(context, ref, organization),
          ),
          if (organization == null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
              onSelected: (value) async {
                if (value == 'import') {
                  SongImportModal.show(context);
                } else if (value == 'scan') {
                  _openScannerDirect(context);
                } else if (value == 'export_all') {
                  final songs = library.value ?? [];
                  if (songs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No songs in repertoire to export'),
                      ),
                    );
                    return;
                  }
                  final jsonStr =
                      SongImportExportService.exportRepertoireToJson(songs);
                  await Clipboard.setData(ClipboardData(text: jsonStr));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.stageGreen,
                        content: Text(
                          'Exported ${songs.length} songs to clipboard (JSON)',
                        ),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                if (compactBar)
                  PopupMenuItem(
                    value: 'scan',
                    child: Row(
                      children: [
                        const Icon(Icons.document_scanner_outlined, size: 20),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            l10n?.scanSheetMusicTooltip ?? 'Scan sheet music',
                          ),
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
                      Text('Import Song / Leadsheet'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_all',
                  child: Row(
                    children: [
                      Icon(Icons.file_upload_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Export Repertoire (JSON Backup)'),
                    ],
                  ),
                ),
              ],
            ),
          const ProfileAvatarButton(),
        ],
      ),
      body: Column(
        children: [
          // ── Scope: my library or an organization's repertoire ──
          const RepertoireScopeBar(),

          // ── View Mode Switcher: Songs vs Setlists ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  icon: const Icon(Icons.music_note),
                  label: Text(
                    l10n?.songsTab(songCount) ?? 'Songs ($songCount)',
                  ),
                ),
                ButtonSegment(
                  value: 1,
                  icon: const Icon(Icons.playlist_play),
                  label: Text(
                    l10n?.setlistsTab(setlistCount) ??
                        'Setlists ($setlistCount)',
                  ),
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
            child: AnimatedSwitcher(
              duration: BattutaMotion.resolve(context, BattutaMotion.beat),
              switchInCurve: BattutaMotion.downbeat,
              switchOutCurve: BattutaMotion.upbeat,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.015),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_selectedTabIndex),
                child: _selectedTabIndex == 0
                    ? (organization == null
                          ? _buildSongsView(library, theme)
                          : OrgRepertoireView(organization: organization))
                    : _buildSetlistsView(
                        setlistsAsync,
                        theme,
                        organization: organization,
                        canManage: canManage,
                      ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
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
              icon: const Icon(Icons.add),
              label: AnimatedSwitcher(
                duration: BattutaMotion.resolve(context, BattutaMotion.beat),
                switchInCurve: BattutaMotion.downbeat,
                switchOutCurve: BattutaMotion.upbeat,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.horizontal,
                    child: child,
                  ),
                ),
                child: Text(
                  _selectedTabIndex == 0
                      ? (organization == null
                            ? (l10n?.newSong ?? 'New Song')
                            : (l10n?.addToRepertoireAction ??
                                  'Add to repertoire'))
                      : (l10n?.newSetlist ?? 'New Setlist'),
                  key: ValueKey(_selectedTabIndex),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSongsView(AsyncValue<List<Song>> repertoire, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return repertoire.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => StageEmptyState(
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
      data: (songs) {
        if (songs.isEmpty) {
          return StageEmptyState(
            icon: Icons.library_music_outlined,
            title: l10n?.repertoireEmpty ?? 'Your repertoire is empty',
            message:
                l10n?.repertoireEmptyAdminHint ??
                'Tap the + button to add your first song',
            actions: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.amberAccent,
                  foregroundColor: AppTheme.obsidianText,
                ),
                icon: const Icon(Icons.auto_awesome),
                label: Text(l10n?.loadSampleSongs ?? 'Load Sample Songs'),
                onPressed: () async {
                  await ref.read(repertoireProvider.notifier).seedSampleData();
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
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: songs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => BattutaEntrance(
            index: index,
            child: SongCard(song: songs[index]),
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
    return setlistsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          '${l10n?.failedToLoadRepertoire ?? "Error loading setlists"}: $e',
        ),
      ),
      data: (setlists) {
        if (setlists.isEmpty) {
          return StageEmptyState(
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
                      backgroundColor: AppTheme.amberAccent,
                      foregroundColor: AppTheme.obsidianText,
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
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                onTap: () => context.push(AppRoutes.setlistDetail(setlist.id)),
                onDelete: canManage
                    ? () => _confirmDeleteSetlist(context, setlist)
                    : null,
                deleteTooltip: l10n?.deleteSetlistTooltip ?? 'Delete setlist',
              ),
            );
          },
        );
      },
    );
  }

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

/// Stage card for a [Setlist], matching the [SongCard] visual language.
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

    return BattutaPressable(
      onTap: onTap,
      builder: (context, pressed) => AnimatedContainer(
        duration: BattutaMotion.resolve(context, BattutaMotion.tick),
        curve: BattutaMotion.downbeat,
        decoration: brand.cardDecoration(pressed: pressed),
        padding: const EdgeInsets.fromLTRB(
          BattutaSpace.md,
          BattutaSpace.md,
          BattutaSpace.xs,
          BattutaSpace.md,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: brand.accentWash,
                borderRadius: BattutaRadius.smAll,
                border: Border.all(color: brand.accent.withValues(alpha: 0.35)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_play, size: 20, color: brand.accentInk),
                  Text(
                    '${setlist.songCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: brand.accentInk,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
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
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: BattutaSpace.xxs),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: brand.inkMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppTheme.stageRed,
                ),
                tooltip: deleteTooltip,
                onPressed: onDelete,
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: BattutaSpace.sm),
                child: Icon(Icons.chevron_right, size: 20, color: brand.inkDim),
              ),
          ],
        ),
      ),
    );
  }
}
