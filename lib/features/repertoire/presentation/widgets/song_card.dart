/// Battuta — Song card widget.
///
/// A compact [Card] that displays a song's key metadata — title, artist,
/// musical key, tempo, and tags — in a visually appealing layout. Tapping
/// the card navigates to the song detail/editor page.
library;

import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A Material Design card summarizing a single [Song].
///
/// Displays:
/// - **Title** and **artist** as the primary and secondary text
/// - A **musical key** badge (filled, small)
/// - A **tempo** badge showing BPM
/// - **Tag** chips in a horizontal wrap
///
/// On tap, navigates to the song detail route using GoRouter.
class SongCard extends StatelessWidget {
  /// Creates a [SongCard] for the given [song].
  const SongCard({required this.song, super.key});

  /// The song whose data this card displays.
  final Song song;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/repertoire/${song.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title & artist ──
              Text(
                song.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                song.artist,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // ── Key & tempo badges ──
              Row(
                children: [
                  _Badge(
                    label: song.key,
                    icon: Icons.music_note,
                    color: colorScheme.primaryContainer,
                    textColor: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  _Badge(
                    label: song.tempoLabel,
                    icon: Icons.speed,
                    color: colorScheme.secondaryContainer,
                    textColor: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  _Badge(
                    label: song.timeSignatureLabel,
                    icon: Icons.timer_outlined,
                    color: colorScheme.tertiaryContainer,
                    textColor: colorScheme.onTertiaryContainer,
                  ),
                ],
              ),

              // ── Tags ──
              if (song.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: song.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          labelStyle: theme.textTheme.labelSmall,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

/// A small rounded badge displaying an [icon] and [label].
class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
