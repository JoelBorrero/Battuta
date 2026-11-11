/// "Move to another song": the owner of a version attaches it to a different
/// song when it was linked wrongly. The version keeps its content, owner,
/// visibility, setlists and repertoire entries; only the song changes, and
/// with it the title and artist it shows. Works offline (the move is queued).
library;

import 'dart:async';

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/sharing/domain/entities/song_suggestion.dart';
import 'package:battuta/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:battuta/features/sharing/presentation/widgets/song_suggestion_tile.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the sheet for [song]; returns the moved version, or `null` when
/// nothing moved.
Future<Song?> showMoveToSongSheet(BuildContext context, Song song) =>
    showModalBottomSheet<Song>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => MoveToSongSheet(song: song),
    );

class MoveToSongSheet extends ConsumerStatefulWidget {
  const MoveToSongSheet({
    required this.song,
    this.debounce = const Duration(milliseconds: 300),
    super.key,
  });

  final Song song;
  final Duration debounce;

  @override
  ConsumerState<MoveToSongSheet> createState() => _MoveToSongSheetState();
}

class _MoveToSongSheetState extends ConsumerState<MoveToSongSheet> {
  late final TextEditingController _query = TextEditingController(
    text: widget.song.title,
  );
  late String _debounced = widget.song.title.trim();
  Timer? _timer;
  String? _error;
  bool _moving = false;

  @override
  void dispose() {
    _timer?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () {
      if (mounted) setState(() => _debounced = value.trim());
    });
  }

  Future<void> _move(SongSuggestion target) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.moveToSongConfirmTitle),
        content: Text(l10n.moveToSongConfirmBody(target.title)),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('move_confirm_btn'),
            style: FilledButton.styleFrom(minimumSize: const Size(44, 44)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.moveToSongAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _moving = true;
      _error = null;
    });
    final result = await ref
        .read(songRepositoryProvider)
        .moveToSong(
          widget.song.id,
          songWorkId: target.songWorkId,
          title: target.title,
          artist: target.artist,
          songCreatorId: target.createdBy,
        );
    if (!mounted) return;
    setState(() => _moving = false);
    result.fold(
      (failure) => setState(() => _error = backendErrorMessage(l10n, failure)),
      (moved) {
        ref.invalidate(repertoireProvider);
        // Applied on the backend by the next sync (at once when online).
        unawaited(ref.read(cloudSyncProvider.notifier).triggerSync());
        navigator.pop(moved);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.moveToSongDone(target.title))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final state = ref.watch(songSuggestionsProvider(_debounced));
    final results = [
      for (final s in state.items)
        if (s.songWorkId != widget.song.songWorkId) s,
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.moveToSongTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  l10n.moveToSongIntro(widget.song.title),
                  key: const ValueKey('move_intro'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: brand.inkMuted,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  key: const ValueKey('move_search_field'),
                  controller: _query,
                  onChanged: _onQueryChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: l10n.moveToSongSearchLabel,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    _error!,
                    key: const ValueKey('move_error'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: state.loading
                            ? const CircularProgressIndicator()
                            : Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  l10n.moveToSongNoResults,
                                  key: const ValueKey('move_empty'),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final song = results[index];
                          return SongSuggestionTile(
                            key: ValueKey('move_candidate_${song.songWorkId}'),
                            suggestion: song,
                            onTap: _moving ? null : () => _move(song),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
