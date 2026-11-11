/// Battuta — Setlist Detail & Editor Page.
///
/// Displays an ordered worship/performance setlist with song list,
/// drag-to-reorder, song addition from repertoire, key overrides,
/// rehearsal notes, and confirmed deletion.
library;

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_scope_providers.dart';
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
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final existingSongIds = setlist.items.map((i) => i.songId).toSet();
        final available = allSongs
            .where((s) => !existingSongIds.contains(s.id))
            .toList();

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n?.addSongToSetlist ?? 'Add Song to Setlist',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (available.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          allSongs.isEmpty
                              ? (l10n?.noSongsInRepertoireYet ??
                                  'No songs in repertoire yet. Create or load sample songs.')
                              : (l10n?.allSongsAlreadyInSetlist ??
                                  'All songs are already in this setlist.'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: available.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final song = available[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.amberMuted,
                              child: Text(
                                song.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.amberAccent,
                                ),
                              ),
                            ),
                            title: Text(
                              song.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${song.artist} • ${song.tempo} BPM',
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: AppTheme.amberAccent,
                              ),
                              onPressed: () async {
                                final navigator = Navigator.of(ctx);
                                final newItem = SetlistItem(
                                  id: 'item_${DateTime.now().millisecondsSinceEpoch}_$index',
                                  songId: song.id,
                                  orderIndex: setlist.items.length,
                                );
                                final updated = Setlist(
                                  id: setlist.id,
                                  title: setlist.title,
                                  description: setlist.description,
                                  eventDate: setlist.eventDate,
                                  items: [...setlist.items, newItem],
                                  tags: setlist.tags,
                                  createdAt: setlist.createdAt,
                                  updatedAt: DateTime.now(),
                                  organizationId: setlist.organizationId,
                                );
                                navigator.pop();
                                await _update(updated);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final setlistAsync = ref.watch(setlistByIdProvider(widget.setlistId));
    final repertoire = ref.watch(repertoireProvider).value ?? const [];
    final l10n = AppLocalizations.of(context);

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
            in ref.watch(organizationRepertoireProvider(organizationId)).value ??
                const <RepertoireEntry>[])
          e.versionId,
      };
      return [
        for (final song in repertoire)
          if (inRepertoire.contains(song.id)) song,
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.setlistTitle ?? 'Setlist'),
        actions: [
          setlistAsync.when(
            data: (setlist) {
              if (setlist == null || !canEditSetlist(setlist)) {
                return const SizedBox.shrink();
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: l10n?.editSetlistInfoTooltip ?? 'Edit setlist info',
                    onPressed: () => _showEditInfoDialog(setlist),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.stageRed,
                    ),
                    tooltip: l10n?.deleteSetlistTooltip ?? 'Delete setlist',
                    onPressed: () => _confirmDeleteSetlist(setlist),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: setlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n?.failedToLoadRepertoire ?? "Error loading setlist"}: $e')),
        data: (setlist) {
          if (setlist == null) {
            return Center(child: Text(l10n?.noSetlistsYet ?? 'Setlist not found.'));
          }

          final pickable = pickerSongs(setlist);

          return Column(
            children: [
              // ── Header Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.slateSurface
                      : AppTheme.pureWhiteSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppTheme.slateBorder : AppTheme.pearlBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.playlist_play,
                          color: AppTheme.amberAccent,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            setlist.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (setlist.description != null &&
                        setlist.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        setlist.description!,
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.textMuted
                              : AppTheme.charcoalMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Chip(
                          label: Text(
                            l10n?.setlistSongsCount(setlist.songCount) ??
                                '${setlist.songCount} songs',
                          ),
                          backgroundColor: isDark
                              ? AppTheme.slateSurfaceLight
                              : AppTheme.pearlSurfaceLight,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                        if (setlist.eventDate != null)
                          Chip(
                            avatar: const Icon(Icons.calendar_today, size: 14),
                            label: Text(
                              '${setlist.eventDate!.month}/${setlist.eventDate!.day}/${setlist.eventDate!.year}',
                            ),
                            backgroundColor: isDark
                                ? AppTheme.slateSurfaceLight
                                : AppTheme.pearlSurfaceLight,
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Songs in Setlist List ──
              Expanded(
                child: setlist.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.queue_music,
                              size: 48,
                              color: isDark
                                  ? AppTheme.textDim
                                  : AppTheme.charcoalDim,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n?.setlistEmpty ?? 'This setlist has no songs yet.',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n?.tapAddSongHint ?? 'Tap "Add Song" below to build your set.',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        buildDefaultDragHandles: canEditSetlist(setlist),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: setlist.items.length,
                        onReorderItem: (oldIndex, newIndex) {
                          if (!canEditSetlist(setlist)) return;
                          _reorderSongs(setlist, oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final item = setlist.items[index];
                          final song = songMap[item.songId];

                          return Card(
                            key: ValueKey(item.id),
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isDark
                                    ? AppTheme.slateBorder
                                    : AppTheme.pearlBorder,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.amberMuted,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.amberAccent,
                                  ),
                                ),
                              ),
                              title: Text(
                                song?.title ?? 'Song (${item.songId})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song != null
                                        ? (l10n?.songOriginalMeta(
                                              song.artist,
                                              song.key,
                                              song.tempo,
                                            ) ??
                                            '${song.artist} • Original: ${song.key} (${song.tempo} BPM)')
                                        : (l10n?.unknownArtist ?? 'Unknown artist'),
                                  ),
                                  if (item.notes != null &&
                                      item.notes!.isNotEmpty)
                                    Text(
                                      'Note: ${item.notes}',
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: AppTheme.amberAccent,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: !canEditSetlist(setlist)
                                  ? const Icon(Icons.chevron_right)
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 20,
                                          ),
                                          tooltip:
                                              l10n?.removeFromSetlistTooltip ??
                                              'Remove from setlist',
                                          onPressed: () =>
                                              _removeSongFromSetlist(
                                                setlist,
                                                index,
                                              ),
                                        ),
                                        const Icon(
                                          Icons.drag_handle,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                              onTap: () {
                                if (song != null) {
                                  context.push(AppRoutes.songDetail(song.id));
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),

              // ── Bottom Action Bar ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.slateSurface
                      : AppTheme.pureWhiteSurface,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppTheme.slateBorder
                          : AppTheme.pearlBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: !canEditSetlist(setlist)
                    ? Row(
                        children: [
                          const Icon(Icons.lock_outline, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n?.setlistReadOnlyNotice ??
                                  'Only organization admins can edit this setlist.',
                              key: const ValueKey('setlist_read_only_notice'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      )
                    : Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.amberAccent,
                          foregroundColor: AppTheme.obsidianText,
                          minimumSize: const Size(44, 48),
                        ),
                        icon: const Icon(Icons.add),
                        label: Text(
                          l10n?.addSongToSetlist ?? 'Add Song to Setlist',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _showAddSongDialog(setlist, pickable),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
