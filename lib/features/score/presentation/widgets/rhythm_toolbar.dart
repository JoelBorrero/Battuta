/// Battuta — 'Tap-First' Rhythm Editor Toolbar.
///
/// Bottom-docked or floating toolbar providing SMuFL duration buttons,
/// measure progress bar, and cursor controls, automatically disabling buttons
/// exceeding remaining measure tick capacity.
library;

import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/presentation/providers/rhythm_editor_controller.dart';
import 'package:battuta/features/score/presentation/rendering/smufl_glyphs.dart';
import 'package:battuta/features/score/presentation/widgets/measure_progress_bar.dart';
import 'package:flutter/material.dart';

/// Rhythm input toolbar with SMuFL duration buttons and measure capacity validation.
class RhythmToolbar extends StatelessWidget {
  const RhythmToolbar({required this.controller, super.key});

  /// The active [RhythmEditorController] orchestrating editing actions.
  final RhythmEditorController controller;

  static const List<RhythmicValue> standardDurations = [
    RhythmicValue.whole,
    RhythmicValue.dottedHalf,
    RhythmicValue.half,
    RhythmicValue.dottedQuarter,
    RhythmicValue.quarter,
    RhythmicValue.dottedEighth,
    RhythmicValue.eighth,
    RhythmicValue.sixteenth,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        final activeEvent = state.activeEvent;
        final hasCursor = state.cursor != null;

        return Card(
          elevation: 6,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -------------------------------------------------------------
                // Measure Progress Bar
                // -------------------------------------------------------------
                MeasureProgressBar(measure: state.activeMeasure),
                const SizedBox(height: 10),

                // -------------------------------------------------------------
                // Duration & Editing Buttons Row
                // -------------------------------------------------------------
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Navigation: Previous Note
                      IconButton(
                        key: const Key('rhythm_prev_btn'),
                        icon: const Icon(Icons.chevron_left),
                        tooltip: 'Previous Note',
                        onPressed: hasCursor
                            ? () => controller.previousNote()
                            : null,
                      ),
                      const SizedBox(width: 4),

                      // Duration Buttons
                      for (final duration in standardDurations) ...[
                        _buildDurationButton(
                          context,
                          duration: duration,
                          canFit: hasCursor && state.canFitRhythm(duration),
                          isSelected: activeEvent?.rhythmicValue == duration,
                        ),
                        const SizedBox(width: 4),
                      ],

                      // Rest Button
                      IconButton.filledTonal(
                        key: const Key('rhythm_rest_btn'),
                        icon: Text(
                          SmuflGlyphs.restQuarter,
                          style: TextStyle(
                            fontFamily: SmuflGlyphs.fontFamily,
                            fontSize: 22,
                            color: activeEvent?.isRest == true
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        tooltip: 'Toggle Rest',
                        isSelected: activeEvent?.isRest == true,
                        onPressed: hasCursor
                            ? () => controller.toggleRest()
                            : null,
                      ),
                      const SizedBox(width: 4),

                      // Tie Button
                      IconButton.filledTonal(
                        key: const Key('rhythm_tie_btn'),
                        icon: Icon(
                          Icons.link,
                          color: activeEvent?.isTied == true
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        tooltip: 'Toggle Tie',
                        isSelected: activeEvent?.isTied == true,
                        onPressed: hasCursor
                            ? () => controller.toggleTie()
                            : null,
                      ),
                      const SizedBox(width: 4),

                      // Navigation: Next Note
                      IconButton(
                        key: const Key('rhythm_next_btn'),
                        icon: const Icon(Icons.chevron_right),
                        tooltip: 'Next Note',
                        onPressed: hasCursor
                            ? () => controller.nextNote()
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDurationButton(
    BuildContext context, {
    required RhythmicValue duration,
    required bool canFit,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final glyph = SmuflGlyphs.glyphForNotehead(duration);

    final String label = switch (duration.name) {
      'Whole' => '1',
      'Dotted Half' => '1/2.',
      'Half' => '1/2',
      'Dotted Quarter' => '1/4.',
      'Quarter' => '1/4',
      'Dotted 8th' => '1/8.',
      '8th' => '1/8',
      '16th' => '1/16',
      _ => duration.name,
    };

    return SizedBox(
      width: 46,
      height: 52,
      child: OutlinedButton(
        key: Key('rhythm_btn_${duration.name}'),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: isSelected
              ? theme.colorScheme.primaryContainer
              : (canFit ? null : Colors.black12.withValues(alpha: 0.05)),
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: canFit ? () => controller.assignDuration(duration) : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              glyph,
              style: TextStyle(
                fontFamily: SmuflGlyphs.fontFamily,
                fontSize: 22,
                color: canFit
                    ? (isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface)
                    : theme.disabledColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: canFit
                    ? (isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant)
                    : theme.disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
