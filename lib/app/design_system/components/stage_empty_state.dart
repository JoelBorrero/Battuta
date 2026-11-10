/// Battuta — Branded empty / error state.
///
/// Replaces the grey-icon-and-text pattern with a composed moment: a soft
/// stage-light glow, an icon sitting in a flush circular "spot", and copy
/// that rises in tempo. The actions slot accepts any buttons and wraps on
/// narrow widths.
library;

import 'package:battuta/app/design_system/motion/entrance.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/app/theme/battuta_tokens.dart';
import 'package:flutter/material.dart';

class StageEmptyState extends StatelessWidget {
  const StageEmptyState({
    required this.icon,
    required this.title,
    super.key,
    this.message,
    this.actions = const [],
    this.tone,
  });

  final IconData icon;
  final String title;
  final String? message;
  final List<Widget> actions;

  /// Accent for the icon spot; defaults to stage amber.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final theme = Theme.of(context);
    final accent = tone ?? brand.accent;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: BattutaSpace.xxl,
          vertical: BattutaSpace.xl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BattutaEntrance(
                offset: const Offset(0, 8),
                child: SizedBox.square(
                  dimension: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accent.withValues(
                                alpha: brand.isDark ? 0.20 : 0.14,
                              ),
                              accent.withValues(alpha: 0),
                            ],
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: brand.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: brand.border),
                        ),
                        child: Icon(icon, size: 32, color: accent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: BattutaSpace.sm),
              BattutaEntrance(
                index: 1,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: brand.ink,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: BattutaSpace.sm),
                BattutaEntrance(
                  index: 2,
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: brand.inkMuted,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: BattutaSpace.xl),
                BattutaEntrance(
                  index: 3,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: BattutaSpace.md,
                    runSpacing: BattutaSpace.sm,
                    children: actions,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
