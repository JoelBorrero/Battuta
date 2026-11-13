/// Battuta — Setlist Detail & Editor Page.
///
/// Displays an ordered worship/performance setlist with song list,
/// drag-to-reorder, song addition from repertoire, key overrides,
/// rehearsal notes, and confirmed deletion.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_scope_providers.dart';
import 'package:battuta/features/repertoire/presentation/widgets/add_songs_to_setlist_sheet.dart';
import 'package:battuta/features/repertoire/presentation/widgets/setlist_date_stamp.dart';
import 'package:battuta/features/repertoire/presentation/widgets/setlist_item_row.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SetlistDetailPage extends ConsumerStatefulWidget {
  const SetlistDetailPage({required this.setlistId, super.key});

  final String setlistId;

  @override
  ConsumerState<SetlistDetailPage> createState() => _SetlistDetailPageState();
}

class _SetlistDetailPageState extends ConsumerState<SetlistDetailPage> {
  void _confirmDeleteSetlist(Setlist setlist) {
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
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(setlistsProvider.notifier)
                    .deleteSetlist(setlist.id);
              } catch (e) {
                if (l10n != null) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(backendErrorMessage(l10n, e))),
                  );
                }
                return;
              }
              if (mounted) {
                context.pop();
              }
            },
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
  }

  /// Saves [updated]; a refusal (e.g. the role changed while the page was
  /// open) is shown instead of thrown.
  Future<void> _update(Setlist updated) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(setlistsProvider.notifier).updateSetlist(updated);
    } catch (e) {
      if (l10n != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(backendErrorMessage(l10n, e))),
        );
      }
    }
    ref.invalidate(setlistByIdProvider(widget.setlistId));
  }

  void _showEditInfoDialog(Setlist setlist) {
    final l10n = AppLocalizations.of(context);
    final titleController = TextEditingController(text: setlist.title);
    final descController = TextEditingController(
      text: setlist.description ?? '',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.editSetlist ?? 'Edit Setlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: l10n?.setlistTitleField ?? 'Setlist Title',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: l10n?.descriptionNotesField ?? 'Description / Notes',
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
              final newTitle = titleController.text.trim();
              final newDesc = descController.text.trim();
              Navigator.of(ctx).pop();
              if (newTitle.isNotEmpty) {
                final updated = Setlist(
                  id: setlist.id,
                  title: newTitle,
                  description: newDesc.isEmpty ? null : newDesc,
                  eventDate: setlist.eventDate,
                  items: setlist.items,
                  tags: setlist.tags,
                  createdAt: setlist.createdAt,
                  updatedAt: DateTime.now(),
                  organizationId: setlist.organizationId,
                );
                await _update(updated);
              }
            },
            child: Text(l10n?.save ?? 'Save'),
          ),
        ],
      ),
    );
  }

  void _showAddSongDialog(Setlist setlist, List<Song> allSongs) {
    final existingSongIds = setlist.items.map((i) => i.songId).toSet();
    final available = allSongs
        .where((s) => !existingSongIds.contains(s.id))
        .toList();

    showAddSongsToSetlistSheet(
      context,
      available: available,
      libraryIsEmpty: allSongs.isEmpty,
      onPick: (song, index) {
        final newItem = SetlistItem(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}_$index',
          songId: song.id,
          orderIndex: setlist.items.length,
        );
        _update(
          Setlist(
            id: setlist.id,
            title: setlist.title,
            description: setlist.description,
            eventDate: setlist.eventDate,
            items: [...setlist.items, newItem],
            tags: setlist.tags,
            createdAt: setlist.createdAt,
            updatedAt: DateTime.now(),
            organizationId: setlist.organizationId,
          ),
        );
      },
    );
  }

  void _removeSongFromSetlist(Setlist setlist, int index) async {
    final updatedItems = List<SetlistItem>.from(setlist.items)..removeAt(index);
    final reindexed = [
      for (var i = 0; i < updatedItems.length; i++)
        updatedItems[i].copyWith(orderIndex: i),
    ];
    final updated = Setlist(
      id: setlist.id,
      title: setlist.title,
      description: setlist.description,
      eventDate: setlist.eventDate,
      items: reindexed,
      tags: setlist.tags,
      createdAt: setlist.createdAt,
      updatedAt: DateTime.now(),
      organizationId: setlist.organizationId,
    );
    await _update(updated);
  }

  void _reorderSongs(Setlist setlist, int oldIndex, int newIndex) async {
    final items = List<SetlistItem>.from(setlist.items);
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);

    final reindexed = [
      for (var i = 0; i < items.length; i++) items[i].copyWith(orderIndex: i),
    ];
    final updated = Setlist(
      id: setlist.id,
      title: setlist.title,
      description: setlist.description,
      eventDate: setlist.eventDate,
      items: reindexed,
      tags: setlist.tags,
      createdAt: setlist.createdAt,
      updatedAt: DateTime.now(),
      organizationId: setlist.organizationId,
    );
    await _update(updated);
  }

  /// Tempo that counts for [item]: its override, else the song's own.
  static int _tempoOf(SetlistItem item, Song? song) =>
      item.tempoOverride ?? song?.tempo ?? 0;

  /// Average of the known tempos, or `null` when no song has a BPM.
  static int? _averageBpm(Setlist setlist, Map<String, Song> songs) {
    final tempos = [
      for (final item in setlist.items)
        if (_tempoOf(item, songs[item.songId]) > 0)
          _tempoOf(item, songs[item.songId]),
    ];
    if (tempos.isEmpty) return null;
    return (tempos.reduce((a, b) => a + b) / tempos.length).round();
  }

  @override
  Widget build(BuildContext context) {
    final setlistAsync = ref.watch(setlistByIdProvider(widget.setlistId));
    final repertoire = ref.watch(repertoireProvider).value ?? const [];
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);

    final songMap = {for (final s in repertoire) s.id: s};
    final isOrgAdmin = ref.watch(organizationAdminCheckProvider);
    // Personal setlists are mine; an organization's are edited by its admins.
    bool canEditSetlist(Setlist s) =>
        s.organizationId == null || isOrgAdmin(s.organizationId!);
    // Organization setlists are built from the organization's repertoire.
    List<Song> pickerSongs(Setlist s) {
      final organizationId = s.organizationId;
      // Personal setlists draw from my library, not other owners' versions.
      if (organizationId == null) {
        return ref.watch(myLibraryProvider).value ?? const [];
      }
      final inRepertoire = {
        for (final RepertoireEntry e
            in ref
                    .watch(organizationRepertoireProvider(organizationId))
                    .value ??
                const <RepertoireEntry>[])
          e.versionId,
      };
      return [
        for (final song in repertoire)
          if (inRepertoire.contains(song.id)) song,
      ];
    }

    final loaded = setlistAsync.value;
    final canEdit = loaded != null && canEditSetlist(loaded);
    final pickable = loaded == null ? const <Song>[] : pickerSongs(loaded);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.setlistTitle ?? 'Setlist'),
        actions: [
          if (loaded != null && canEdit) ...[
            IconButton(
              key: const ValueKey('setlist_add_songs'),
              icon: const Icon(Icons.add),
              tooltip: l10n?.addSongToSetlist ?? 'Add Song to Setlist',
              onPressed: () => _showAddSongDialog(loaded, pickable),
            ),
            PopupMenuButton<String>(
              key: const ValueKey('setlist_menu'),
              icon: const Icon(Icons.more_vert),
              tooltip: l10n?.moreOptions ?? 'More options',
              onSelected: (value) => switch (value) {
                'edit' => _showEditInfoDialog(loaded),
                'delete' => _confirmDeleteSetlist(loaded),
                _ => null,
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: _MenuRow(
                    icon: Icons.edit_outlined,
                    label: l10n?.editSetlistInfoTooltip ?? 'Edit setlist info',
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: _MenuRow(
                    icon: Icons.delete_outline,
                    label: l10n?.deleteSetlistTooltip ?? 'Delete setlist',
                    color: brand.danger,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      // A bottom action bar (e.g. "Start live session") can take this slot
      // once the live view can open a setlist; until then only the read-only
      // notice lives here.
      bottomNavigationBar: loaded != null && !canEdit
          ? _ReadOnlyBar(
              message:
                  l10n?.setlistReadOnlyNotice ??
                  'Only organization admins can edit this setlist.',
            )
          : null,
      body: setlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            '${l10n?.failedToLoadRepertoire ?? "Error loading setlist"}: $e',
          ),
        ),
        data: (setlist) {
          if (setlist == null) {
            return Center(
              child: Text(l10n?.noSetlistsYet ?? 'Setlist not found.'),
            );
          }

          final items = setlist.items;
          final averageBpm = _averageBpm(setlist, songMap);
          final description = setlist.description?.trim() ?? '';

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  BattutaSpace.lg,
                  BattutaSpace.xs,
                  BattutaSpace.lg,
                  0,
                ),
                sliver: SliverList.list(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (setlist.eventDate != null) ...[
                          SetlistDateStamp(
                            key: const ValueKey('setlist_date_stamp'),
                            date: setlist.eventDate!,
                            large: true,
                          ),
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                setlist.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTheme.primaryFontFamily,
                                  fontFamilyFallback:
                                      AppTheme.fontFamilyFallbacks,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                  height: 1.2,
                                  color: brand.ink,
                                ),
                              ),
                              if (description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: BattutaSpace.xs,
                                  ),
                                  child: Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: brand.inkMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: BattutaSpace.lg),
                    StageStatRow(
                      children: [
                        StageStatTile(
                          key: const ValueKey('setlist_stat_songs'),
                          value: '${items.length}',
                          label: l10n?.setlistStatSongs ?? 'Songs',
                        ),
                        StageStatTile(
                          key: const ValueKey('setlist_stat_bpm'),
                          value: averageBpm?.toString() ?? '–',
                          label: l10n?.setlistStatAvgBpm ?? 'Avg BPM',
                        ),
                      ],
                    ),
                    if (items.isNotEmpty)
                      StageSectionHeader(
                        title: l10n?.setlistOrderHeader ?? 'Order',
                        padding: const EdgeInsets.only(
                          top: BattutaSpace.xl,
                          bottom: BattutaSpace.sm,
                        ),
                        trailing: canEdit
                            ? Text(
                                l10n?.setlistDragHint ?? 'Drag to reorder',
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: brand.inkMuted,
                                ),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
              if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: StageEmptyState(
                    icon: Icons.queue_music,
                    title:
                        l10n?.setlistEmpty ?? 'This setlist has no songs yet.',
                    message: canEdit
                        ? (l10n?.tapAddSongHint ??
                              'Tap + to add songs and build your set.')
                        : null,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    BattutaSpace.lg,
                    0,
                    BattutaSpace.lg,
                    BattutaSpace.xl,
                  ),
                  sliver: SliverReorderableList(
                    itemCount: items.length,
                    proxyDecorator: (child, index, animation) => child,
                    onReorderItem: (oldIndex, newIndex) {
                      if (!canEdit) return;
                      _reorderSongs(setlist, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final song = songMap[item.songId];
                      final row = _buildRow(
                        context,
                        setlist: setlist,
                        index: index,
                        song: song,
                        canEdit: canEdit,
                      );
                      return KeyedSubtree(
                        key: ValueKey(item.id),
                        child: canEdit
                            ? ReorderableDelayedDragStartListener(
                                index: index,
                                child: row,
                              )
                            : row,
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required Setlist setlist,
    required int index,
    required Song? song,
    required bool canEdit,
  }) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
    final item = setlist.items[index];

    final artist = (song?.artist ?? item.artistSnapshot ?? '').trim();
    final tempo = _tempoOf(item, song);
    final meta = [
      if (artist.isNotEmpty) artist,
      if (tempo > 0) '$tempo BPM',
    ].join(' · ');
    final note = item.notes;

    return SetlistItemRow(
      number: index + 1,
      title: song?.title ?? item.titleSnapshot ?? 'Song (${item.songId})',
      meta: meta.isNotEmpty
          ? meta
          : (song == null ? (l10n?.unknownArtist ?? 'Unknown artist') : null),
      note: note != null && note.isNotEmpty
          ? (l10n?.setlistItemNote(note) ?? 'Note: $note')
          : null,
      musicalKey: item.keyOverride ?? song?.key ?? item.keySnapshot,
      isFirst: index == 0,
      isLast: index == setlist.items.length - 1,
      onTap: song == null
          ? null
          : () => context.push(AppRoutes.songDetail(song.id)),
      onRemove: canEdit ? () => _removeSongFromSetlist(setlist, index) : null,
      removeTooltip: l10n?.removeFromSetlistTooltip ?? 'Remove from setlist',
      dragHandle: canEdit
          ? ReorderableDragStartListener(
              index: index,
              child: SizedBox(
                key: ValueKey('setlist_drag_handle_$index'),
                width: BattutaSpace.minTouchTarget,
                height: BattutaSpace.minTouchTarget,
                child: Icon(Icons.drag_handle, size: 20, color: brand.inkMuted),
              ),
            )
          : null,
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Flexible(
          child: Text(label, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}

/// Bottom notice shown instead of actions when the setlist is read-only.
class _ReadOnlyBar extends StatelessWidget {
  const _ReadOnlyBar({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.canvas,
        border: Border(top: BorderSide(color: brand.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(BattutaSpace.lg),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: brand.inkMuted),
              const SizedBox(width: BattutaSpace.sm),
              Expanded(
                child: Text(
                  message,
                  key: const ValueKey('setlist_read_only_notice'),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: brand.inkMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
