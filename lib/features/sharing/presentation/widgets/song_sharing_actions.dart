/// The sharing actions of a song version shown in the viewer: change who sees
/// it (owner), fork it, and propose a merge with another copy of the song.
library;

import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/sharing/presentation/widgets/fork_version_flow.dart';
import 'package:battuta/features/sharing/presentation/widgets/merge_request_sheet.dart';
import 'package:battuta/features/sharing/presentation/widgets/sharing_sheet.dart';
import 'package:battuta/features/sharing/presentation/widgets/visibility_text.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SongSharingActions extends ConsumerWidget {
  const SongSharingActions({required this.song, super.key});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final me = ref.watch(currentAccountIdProvider);
    final signedIn = me != null;
    // Local-mode songs have no owner yet: nothing to share until sign-in.
    final owned = signedIn && song.ownerId == me;
    final canMerge =
        signedIn && song.ownerId != null && song.songWorkId != null;
    final createdByMe = song.canEditTitleBy(me);

    ButtonStyle style() =>
        OutlinedButton.styleFrom(minimumSize: const Size(44, 44));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        key: const ValueKey('song_sharing_actions'),
        spacing: 8,
        runSpacing: 8,
        children: [
          if (owned)
            OutlinedButton.icon(
              key: const ValueKey('sharing_btn'),
              style: style(),
              icon: Icon(visibilityIcon(song.visibility), size: 18),
              label: Text(
                '${l10n.sharingButton} · '
                '${visibilityBadgeText(l10n, song.visibility)}',
              ),
              onPressed: () => showSharingSheet(context, ref, song.id),
            ),
          OutlinedButton.icon(
            key: const ValueKey('fork_btn'),
            style: style(),
            icon: const Icon(Icons.call_split, size: 18),
            label: Text(l10n.forkButton),
            onPressed: () => forkVersionFlow(
              context,
              ref,
              versionId: song.id,
              sourceLabel: song.label,
              cachedSource: song,
            ),
          ),
          if (canMerge)
            OutlinedButton.icon(
              key: const ValueKey('merge_btn'),
              style: style(),
              icon: const Icon(Icons.merge_type, size: 18),
              label: Text(
                createdByMe
                    ? l10n.mergeSameSongButton
                    : l10n.mergeSuggestButton,
              ),
              onPressed: () => showMergeRequestSheet(
                context,
                songWorkId: song.songWorkId!,
                title: song.title,
                createdByMe: createdByMe,
              ),
            ),
        ],
      ),
    );
  }
}
