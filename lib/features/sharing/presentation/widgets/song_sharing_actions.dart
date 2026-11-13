/// The sharing actions of a song version shown in the viewer: change who sees
/// it (owner), fork it, and move it to another song (owner).
library;

import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/sharing/presentation/widgets/fork_version_flow.dart';
import 'package:battuta/features/sharing/presentation/widgets/move_to_song_sheet.dart';
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
    final canMove = owned && song.songWorkId != null;

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
          // Forking one's own version into one's own library is pointless.
          if (!owned)
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
          if (canMove)
            OutlinedButton.icon(
              key: const ValueKey('move_song_btn'),
              style: style(),
              icon: const Icon(Icons.drive_file_move_outline, size: 18),
              label: Text(l10n.moveToSongButton),
              onPressed: () => showMoveToSongSheet(context, song),
            ),
        ],
      ),
    );
  }
}
