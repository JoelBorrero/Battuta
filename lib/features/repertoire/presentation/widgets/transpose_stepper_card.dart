/// Inline transpose stepper of the song detail page: a label, a − button, the
/// signed semitone count and a + button. Only previews; nothing is saved.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Card with a transpose stepper. [semitones] stays within ±[maxSemitones];
/// stepping past either end wraps to 0 (an octave up or down is the same key).
class TransposeStepperCard extends StatelessWidget {
  const TransposeStepperCard({
    required this.semitones,
    required this.onChanged,
    super.key,
  });

  /// The previewed transposition, in semitones.
  final int semitones;
  final ValueChanged<int> onChanged;

  static const int maxSemitones = 11;

  /// The value after stepping [semitones] by [delta], wrapping past ±11.
  static int step(int semitones, int delta) {
    final next = semitones + delta;
    return next.abs() > maxSemitones ? 0 : next;
  }

  /// "+2", "-3" or "0".
  static String signed(int semitones) =>
      semitones > 0 ? '+$semitones' : '$semitones';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brand = BattutaBrand.of(context);
    return StageCard(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 6, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.transposeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: brand.ink, fontWeight: FontWeight.w600),
            ),
          ),
          _StepButton(
            key: const ValueKey('transpose_down'),
            icon: Icons.remove,
            tooltip: l10n.downOneSemitone,
            onTap: () => onChanged(step(semitones, -1)),
          ),
          // Tapping the value resets the preview.
          BattutaPressable(
            key: const ValueKey('transpose_value'),
            semanticLabel: l10n.reset,
            onTap: semitones == 0 ? null : () => onChanged(0),
            child: SizedBox(
              width: 48,
              height: 44,
              child: Center(
                child: Text(
                  signed(semitones),
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: AppTheme.monoFontFamily,
                    fontFamilyFallback: AppTheme.monoFontFallbacks,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: semitones == 0 ? brand.inkMuted : brand.accentInk,
                  ),
                ),
              ),
            ),
          ),
          _StepButton(
            key: const ValueKey('transpose_up'),
            icon: Icons.add,
            tooltip: l10n.upOneSemitone,
            onTap: () => onChanged(step(semitones, 1)),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Tooltip(
      message: tooltip,
      child: BattutaPressable(
        onTap: onTap,
        semanticLabel: tooltip,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: brand.canvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: brand.border),
          ),
          child: Icon(icon, size: 18, color: brand.ink),
        ),
      ),
    );
  }
}
