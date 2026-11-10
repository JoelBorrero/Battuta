/// Battuta — Song card widget.
///
/// A flush, border-delineated "stage card" summarizing a song: a prominent
/// key tile (the first thing a musician scans for), title and artist, a
/// compact tempo / meter readout, and tags. Tapping dips the card with
/// Battuta's tactile press feedback and opens the song detail page.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A stage card summarizing a single [Song].
///
/// Displays:
/// - A **key tile** showing the song's musical key in stage amber
/// - **Title** and **artist** as the primary and secondary text
/// - **Tempo** (BPM) and **time signature** as a compact readout
/// - **Tag** pills in a wrapping row
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
    final brand = BattutaBrand.of(context);
    final duration = BattutaMotion.resolve(context, BattutaMotion.tick);

    return BattutaPressable(
      onTap: () => context.push('/repertoire/${song.id}'),
      builder: (context, pressed) => AnimatedContainer(
        duration: duration,
        curve: BattutaMotion.downbeat,
        decoration: brand.cardDecoration(pressed: pressed),
        padding: const EdgeInsets.all(BattutaSpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _KeyTile(musicalKey: song.key),
            const SizedBox(width: BattutaSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title & artist ──
                  Text(
                    song.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: brand.ink,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: BattutaSpace.xxs),
                  Text(
                    song.artist,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: brand.inkMuted,
                      fontSize: 12.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: BattutaSpace.sm),

                  // ── Tempo · meter · tags ──
                  Wrap(
                    spacing: BattutaSpace.sm,
                    runSpacing: BattutaSpace.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Readout(icon: Icons.speed, label: song.tempoLabel),
                      _Readout(
                        icon: Icons.timer_outlined,
                        label: song.timeSignatureLabel,
                      ),
                      for (final tag in song.tags) _TagPill(label: tag),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: BattutaSpace.xs),
            Padding(
              padding: const EdgeInsets.only(top: BattutaSpace.md),
              child: Icon(Icons.chevron_right, size: 20, color: brand.inkDim),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

/// The amber key tile — the card's visual anchor.
class _KeyTile extends StatelessWidget {
  const _KeyTile({required this.musicalKey});

  final String musicalKey;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: brand.accentWash,
        borderRadius: BattutaRadius.smAll,
        border: Border.all(color: brand.accent.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BattutaSpace.xs),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            musicalKey,
            maxLines: 1,
            style: TextStyle(
              fontFamily: AppTheme.primaryFontFamily,
              fontFamilyFallback: AppTheme.fontFamilyFallbacks,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: brand.accentInk,
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon + value readout (tempo, meter).
class _Readout extends StatelessWidget {
  const _Readout({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: brand.inkMuted),
        const SizedBox(width: BattutaSpace.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: brand.inkMuted,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
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
