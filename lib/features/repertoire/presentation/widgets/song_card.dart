/// Battuta — Song card widget.
///
/// A flush, border-delineated "stage card" summarizing a song: title, a muted
/// "artist · BPM · meter" line with the tags, and the key pill the musician
/// scans for on the right. Tapping dips the card with Battuta's tactile press
/// feedback and opens the song detail page.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A stage card summarizing a single [Song].
///
/// Displays:
/// - **Title** as the primary text
/// - A muted **meta line**: artist, tempo and time signature (4/4 is the
///   default and omitted; missing parts are skipped), followed by tag pills
/// - The song's **key** in a [StageKeyPill] on the right
///
/// On tap, navigates to the song detail route using GoRouter.
class SongCard extends StatelessWidget {
  /// Creates a [SongCard] for the given [song].
  const SongCard({required this.song, super.key});

  /// The song whose data this card displays.
  final Song song;

  /// The "artist · 72 BPM · 3/4" line (without tags).
  static String metaLine(Song song) => [
    if (song.artist.trim().isNotEmpty) song.artist.trim(),
    if (song.tempo > 0) song.tempoLabel,
    if (song.timeSignature != (4, 4)) song.timeSignatureLabel,
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final meta = metaLine(song);

    return StageCard(
      onTap: () => context.push('/repertoire/${song.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: BattutaSpace.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: brand.ink,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (meta.isNotEmpty || song.tags.isNotEmpty) ...[
                  const SizedBox(height: BattutaSpace.xxs),
                  Wrap(
                    spacing: BattutaSpace.sm,
                    runSpacing: BattutaSpace.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (meta.isNotEmpty)
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: brand.inkMuted,
                            fontSize: 13,
                          ),
                        ),
                      for (final tag in song.tags) _TagPill(label: tag),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: BattutaSpace.md),
          StageKeyPill(song.key),
        ],
      ),
    );
  }
}

/// Small outlined tag pill.
class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BattutaSpace.sm,
        vertical: BattutaSpace.xxs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BattutaRadius.pill),
        border: Border.all(color: brand.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: brand.inkMuted),
      ),
    );
  }
}
