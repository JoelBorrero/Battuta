/// Links a song that is about to be saved without going through the editor
/// (a scan, an imported link or text) to a song that already exists.
///
/// Looks for songs with that name on this device and, online, on the backend.
/// With none, nothing is asked. With some, the user picks one or keeps a new
/// song; the backend still joins exact duplicates when the version is pushed.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/sharing/domain/entities/song_suggestion.dart';
import 'package:battuta/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:battuta/features/sharing/presentation/widgets/song_suggestion_tile.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The songs that look like [song], from the cache and (signed in) online.
Future<List<SongSuggestion>> findSongMatches(WidgetRef ref, Song song) async {
  final query = song.title.trim();
  if (!isSearchableSongQuery(query)) return const [];
  var known = const <Song>[];
  try {
    known = await ref.read(repertoireProvider.future);
  } catch (_) {
    // No readable repertoire: only the backend can suggest.
  }
  final cached = suggestionsFromCache(known, query);
  var remote = const <SongSuggestion>[];
  if (ref.read(currentAccountIdProvider) != null) {
    try {
      final result = await ref
          .read(songSharingRepositoryProvider)
          .searchSongs(query);
      remote = result.getOrElse((_) => const []);
    } catch (_) {
      // Offline or not reachable: the cache is enough.
    }
  }
  return mergeSuggestions(cached, remote, query);
}

/// Asks which existing song [song] is, when there are candidates, and returns
/// it attached to the pick (or unchanged for "new song"). `null` means the
/// user dismissed the question: nothing should be saved.
Future<Song?> linkSongBeforeSave(
  BuildContext context,
  WidgetRef ref,
  Song song,
) async {
  final matches = await findSongMatches(ref, song);
  if (matches.isEmpty || !context.mounted) return song;
  final choice = await showModalBottomSheet<_LinkChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _SongLinkSheet(title: song.title, matches: matches),
  );
  if (choice == null) return null;
  final picked = choice.song;
  return picked == null ? song : song.linkedTo(picked);
}

class _LinkChoice {
  const _LinkChoice(this.song);

  /// `null`: keep it as a new song.
  final SongSuggestion? song;
}

class _SongLinkSheet extends StatelessWidget {
  const _SongLinkSheet({required this.title, required this.matches});

  final String title;
  final List<SongSuggestion> matches;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.songLinkSheetTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                l10n.songLinkSheetBody(title),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: brand.inkMuted,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: matches.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final match = matches[index];
                  return SongSuggestionTile(
                    key: ValueKey('song_link_option_${match.songWorkId}'),
                    suggestion: match,
                    onTap: () => Navigator.of(context).pop(_LinkChoice(match)),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                key: const ValueKey('song_link_new'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 48),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.songLinkNewSongSubtitle(title)),
                onPressed: () =>
                    Navigator.of(context).pop(const _LinkChoice(null)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
