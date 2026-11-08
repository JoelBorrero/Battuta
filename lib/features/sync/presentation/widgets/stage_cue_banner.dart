/// Battuta — Live Stage Sync Banner & Director Control Bar.
///
/// High-contrast Anti-Material stage cue banner designed for iPadOS split-screen
/// and macOS prompter displays. Adheres strictly to Battuta visual invariants:
/// - Amber accent (`#E5A93C`) flush 1.5px border
/// - Dark mode (`#121316`) & Light mode (`#F8F9FA` / `#FFFFFF`)
/// - Zero Material drop shadows or elevations
/// - Flexible layout with zero RenderFlex overflow down to 320pt width
/// - >= 44x44 pt interactive touch targets
library;

import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppTheme.obsidian
        : AppTheme.pureWhiteSurface;

    final textColor = isDark ? AppTheme.textOffWhite : AppTheme.charcoalText;

    final barsRemaining =
        (currentMeasure != null && cue.triggerMeasureIndex > currentMeasure!)
        ? cue.triggerMeasureIndex - currentMeasure!
        : null;

    final subtitle = barsRemaining != null
        ? 'in $barsRemaining ${barsRemaining == 1 ? "bar" : "bars"} (Bar ${cue.triggerMeasureIndex})'
        : 'at Bar ${cue.triggerMeasureIndex}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: AppTheme.amberAccent, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Flashing/Amber stage beacon icon
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.amberAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),

          // Cue title & measure subtitle (Flexible to prevent narrow overflows)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cue.nextSectionLabel.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.amberAccent,
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
                    color: textColor.withValues(alpha: 0.75),
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
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              child: TextButton(
                key: const ValueKey('stage_cue_jump_button'),
                onPressed: onJumpNow,
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.amberAccent,
                  foregroundColor: AppTheme.obsidianText,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  minimumSize: const Size(44, 44),
                ),
                child: Text(
                  l10n?.jumpAction ?? 'JUMP',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),

          if (onJumpNow != null && onDismiss != null) const SizedBox(width: 4),

          // Dismiss action (if provided)
          if (onDismiss != null)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              child: IconButton(
                key: const ValueKey('stage_cue_dismiss_button'),
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: isDark ? AppTheme.textMuted : AppTheme.charcoalMuted,
                ),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
        ],
      ),
    );
  }
}

/// Floating Director Control Bar allowing instant stage section transitions and cue triggers.
class DirectorControlBar extends StatelessWidget {
  const DirectorControlBar({
    super.key,
    required this.sections,
    required this.activeSectionId,
    required this.onQueueSection,
    required this.onJumpSection,
    this.onClearQueue,
  });

  final List<String> sections;
  final String? activeSectionId;
  final ValueChanged<String> onQueueSection;
  final ValueChanged<String> onJumpSection;
  final VoidCallback? onClearQueue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppTheme.slateSurface
        : AppTheme.pureWhiteSurface;

    final borderColor = isDark ? AppTheme.slateBorder : AppTheme.pearlBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final section in sections) ...[
              _DirectorSectionChip(
                label: section,
                isActive: section == activeSectionId,
                onQueue: () => onQueueSection(section),
                onJump: () => onJumpSection(section),
              ),
              const SizedBox(width: 8),
            ],
            if (onClearQueue != null)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: TextButton(
                  onPressed: onClearQueue,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? AppTheme.textMuted
                        : AppTheme.charcoalMuted,
                    minimumSize: const Size(44, 44),
                  ),
                  child: Text(l10n?.clearQueueAction ?? 'CLEAR QUEUE'),
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
    required this.onQueue,
    required this.onJump,
  });

  final String label;
  final bool isActive;
  final VoidCallback onQueue;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.amberAccent
            : (isDark
                  ? AppTheme.slateSurfaceLight
                  : AppTheme.pearlSurfaceLight),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive
              ? AppTheme.amberAccent
              : (isDark ? AppTheme.slateBorder : AppTheme.pearlBorder),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onQueue,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isActive
                      ? AppTheme.obsidianText
                      : (isDark
                            ? AppTheme.textOffWhite
                            : AppTheme.charcoalText),
                ),
              ),
            ),
          ),
          InkWell(
            onTap: onJump,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isActive
                        ? AppTheme.obsidianText.withValues(alpha: 0.2)
                        : (isDark
                              ? AppTheme.slateBorder
                              : AppTheme.pearlBorder),
                    width: 1,
                  ),
                ),
              ),
              child: Icon(
                Icons.bolt,
                size: 16,
                color: isActive ? AppTheme.obsidianText : AppTheme.amberAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
