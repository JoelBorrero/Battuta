/// Battuta — Live Stage Sync Banner & Director Control Bar.
///
/// High-contrast stage cue banner designed for iPadOS split-screen and macOS
/// prompter displays, built from the Battuta Screens design language:
/// - Flush card surface with an amber 1.5px border and a one-shot arrival flare
/// - Section chips: active solid amber, queued amber outline, others muted
/// - Zero Material drop shadows, elevations or ink ripples
/// - Flexible layout with zero RenderFlex overflow down to 320pt width
/// - >= 44x44 pt interactive touch targets
library;

import 'package:battuta/app/design_system/motion/pressable.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/app/theme/battuta_tokens.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../domain/models/sync_cue_payload.dart';

class StageCueBanner extends StatelessWidget {
  const StageCueBanner({
    super.key,
    required this.cue,
    this.currentMeasure,
    this.onDismiss,
    this.onJumpNow,
    this.isDirector = false,
  });

  /// The active sync cue payload to display.
  final SyncCuePayload cue;

  /// Current performing measure index (if known), used to render remaining bar countdown.
  final int? currentMeasure;

  /// Optional callback invoked when the banner is dismissed.
  final VoidCallback? onDismiss;

  /// Optional callback to force immediate jump to the cued section.
  final VoidCallback? onJumpNow;

  /// Whether current device is operating in director mode.
  final bool isDirector;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);

    final barsRemaining =
        (currentMeasure != null && cue.triggerMeasureIndex > currentMeasure!)
        ? cue.triggerMeasureIndex - currentMeasure!
        : null;

    final subtitle = barsRemaining != null
        ? 'in $barsRemaining ${barsRemaining == 1 ? "bar" : "bars"} (Bar ${cue.triggerMeasureIndex})'
        : 'at Bar ${cue.triggerMeasureIndex}';

    // One-shot arrival flare: the surface starts as an amber wash and settles
    // onto the card colour. Finite, and instant under Reduce Motion.
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: brand.accentWash, end: brand.card),
      duration: BattutaMotion.resolve(context, BattutaMotion.phrase),
      curve: BattutaMotion.downbeat,
      builder: (context, surface, child) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: brand.accent, width: 1.5),
          borderRadius: BattutaRadius.mdAll,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: child,
      ),
      child: Row(
        children: [
          // Stage beacon.
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: brand.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),

          // Cue title & measure subtitle (Expanded to prevent narrow overflows)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cue.nextSectionLabel.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: brand.accentInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: brand.inkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Jump Now action (if provided)
          if (onJumpNow != null)
            BattutaPressable(
              key: const ValueKey('stage_cue_jump_button'),
              onTap: onJumpNow,
              semanticLabel: l10n?.jumpAction ?? 'JUMP',
              child: Container(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: brand.accent,
                  borderRadius: BorderRadius.circular(BattutaRadius.sm),
                ),
                child: Text(
                  l10n?.jumpAction ?? 'JUMP',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.6,
                    color: brand.onAccent,
                  ),
                ),
              ),
            ),

          if (onJumpNow != null && onDismiss != null) const SizedBox(width: 4),

          // Dismiss action (if provided)
          if (onDismiss != null)
            BattutaPressable(
              key: const ValueKey('stage_cue_dismiss_button'),
              onTap: onDismiss,
              semanticLabel: MaterialLocalizations.of(context)
                  .closeButtonTooltip,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.close, size: 20, color: brand.inkMuted),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pinned Director Control Bar: section chips for instant stage transitions.
///
/// Chips read as uppercase labels. The active section is solid amber, the
/// queued one an amber outline followed by "· NEXT", the rest muted. Tapping a
/// chip queues it; the bolt jumps to it now.
class DirectorControlBar extends StatelessWidget {
  const DirectorControlBar({
    super.key,
    required this.sections,
    required this.activeSectionId,
    required this.onQueueSection,
    required this.onJumpSection,
    this.queuedSectionId,
    this.onClearQueue,
  });

  final List<String> sections;
  final String? activeSectionId;

  /// The section waiting to go live next, matched case-insensitively.
  final String? queuedSectionId;
  final ValueChanged<String> onQueueSection;
  final ValueChanged<String> onJumpSection;
  final VoidCallback? onClearQueue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
    final queued = queuedSectionId?.toLowerCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: brand.card,
        border: Border(top: BorderSide(color: brand.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final section in sections) ...[
              _DirectorSectionChip(
                label: section,
                isActive: section == activeSectionId,
                isQueued:
                    section != activeSectionId &&
                    queued != null &&
                    section.toLowerCase() == queued,
                nextLabel: l10n?.sectionChipNext ?? 'NEXT',
                onQueue: () => onQueueSection(section),
                onJump: () => onJumpSection(section),
              ),
              const SizedBox(width: 8),
            ],
            if (onClearQueue != null)
              BattutaPressable(
                onTap: onClearQueue,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  child: Text(
                    l10n?.clearQueueAction ?? 'CLEAR QUEUE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: brand.inkMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DirectorSectionChip extends StatelessWidget {
  const _DirectorSectionChip({
    required this.label,
    required this.isActive,
    required this.isQueued,
    required this.nextLabel,
    required this.onQueue,
    required this.onJump,
  });

  final String label;
  final bool isActive;
  final bool isQueued;
  final String nextLabel;
  final VoidCallback onQueue;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final textColor = isActive
        ? brand.onAccent
        : (isQueued ? brand.accentInk : brand.inkMuted);
    final text = isQueued
        ? '${label.toUpperCase()} · $nextLabel'
        : label.toUpperCase();

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: isActive ? brand.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive || isQueued ? brand.accent : brand.border,
          width: isQueued ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BattutaPressable(
            onTap: onQueue,
            semanticLabel: label,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.6,
                  color: textColor,
                ),
              ),
            ),
          ),
          BattutaPressable(
            onTap: onJump,
            child: Container(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isActive
                        ? brand.onAccent.withValues(alpha: 0.2)
                        : brand.border,
                  ),
                ),
              ),
              child: Icon(
                Icons.bolt,
                size: 16,
                color: isActive ? brand.onAccent : brand.accentInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
