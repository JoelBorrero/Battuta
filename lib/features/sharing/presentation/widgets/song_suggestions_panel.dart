/// Suggestions shown under the title and artist fields of a new version: the
/// songs that already exist with that name (from this device and, online, from
/// the backend). Picking one attaches the version to it; "New song" keeps what
/// was typed (the backend still joins exact duplicates).
library;

import 'dart:async';

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/sharing/domain/entities/song_suggestion.dart';
import 'package:battuta/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:battuta/features/sharing/presentation/widgets/song_suggestion_tile.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SongSuggestionsPanel extends ConsumerStatefulWidget {
  const SongSuggestionsPanel({
    required this.titleController,
    required this.selected,
    required this.onSelected,
    this.debounce = const Duration(milliseconds: 300),
    super.key,
  });

  /// The title being typed (the text suggestions are searched for).
  final TextEditingController titleController;

  /// The song the version is attached to, if the user picked one.
  final SongSuggestion? selected;

  /// Called with the picked song, or `null` to go back to a new song.
  final ValueChanged<SongSuggestion?> onSelected;

  final Duration debounce;

  @override
  ConsumerState<SongSuggestionsPanel> createState() =>
      _SongSuggestionsPanelState();
}

class _SongSuggestionsPanelState extends ConsumerState<SongSuggestionsPanel> {
  Timer? _timer;
  late String _query = widget.titleController.text.trim();

  @override
  void initState() {
    super.initState();
    widget.titleController.addListener(_onTitleChanged);
  }

  @override
  void didUpdateWidget(SongSuggestionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.titleController != widget.titleController) {
      oldWidget.titleController.removeListener(_onTitleChanged);
      widget.titleController.addListener(_onTitleChanged);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.titleController.removeListener(_onTitleChanged);
    super.dispose();
  }

  void _onTitleChanged() {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () {
      final text = widget.titleController.text.trim();
      if (mounted && text != _query) setState(() => _query = text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Hosts without localizations (bare test shells) show no suggestions.
    if (l10n == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final selected = widget.selected;

    if (selected != null) {
      return Container(
        key: const ValueKey('song_link_selected'),
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.only(left: 12),
        decoration: brand.cardDecoration(selected: true),
        child: Row(
          children: [
            Icon(Icons.link, size: 18, color: brand.accentInk),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.songLinkLinkedTo(selected.title),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(
              key: const ValueKey('song_link_change'),
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              onPressed: () => widget.onSelected(null),
              child: Text(l10n.songLinkChange),
            ),
          ],
        ),
      );
    }

    if (!isSearchableSongQuery(_query)) return const SizedBox.shrink();
    final state = ref.watch(songSuggestionsProvider(_query));
    if (state.items.isEmpty) return const SizedBox.shrink();
    final offline = state.failure?.errorCode == BackendErrorCode.offline;

    return Column(
      key: const ValueKey('song_suggestions'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.songLinkSuggestionsTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.songLinkSuggestionsHint,
          style: theme.textTheme.bodySmall?.copyWith(color: brand.inkMuted),
        ),
        if (offline)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.songLinkOfflineNote,
              key: const ValueKey('song_suggestions_offline'),
              style: theme.textTheme.bodySmall?.copyWith(color: brand.inkDim),
            ),
          ),
        const SizedBox(height: 8),
        for (final suggestion in state.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SongSuggestionTile(
              key: ValueKey('song_suggestion_${suggestion.songWorkId}'),
              suggestion: suggestion,
              onTap: () => widget.onSelected(suggestion),
            ),
          ),
        // The current choice while no suggestion is picked: a selected option
        // (radio marker), not a button, so it has no tap action.
        Semantics(
          selected: true,
          child: Container(
            key: const ValueKey('song_suggestion_new'),
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: brand.cardDecoration(selected: true),
            child: Row(
              children: [
                Icon(
                  Icons.radio_button_checked,
                  size: 18,
                  color: brand.accentInk,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.songLinkNewSongSubtitle(_query),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
