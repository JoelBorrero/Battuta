/// Battuta — bottom of the performance view: previous, play / pause and next,
/// and the scroll speed.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/live_session/domain/scroll_pace.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class PerformanceTransportBar extends StatelessWidget {
  const PerformanceTransportBar({
    required this.playing,
    required this.speed,
    required this.bpm,
    required this.nextLabel,
    required this.nextIsPrimary,
    required this.canGoBack,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePlay,
    required this.onSlower,
    required this.onFaster,
    super.key,
  });

  final bool playing;

  /// The player's speed adjustment (1.0 = the song's tempo).
  final double speed;
  final int bpm;

  /// "Next", "Next song" or "Finish".
  final String nextLabel;

  /// Whether Next is the main action (the chart reached its end).
  final bool nextIsPrimary;
  final bool canGoBack;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTogglePlay;
  final VoidCallback onSlower;
  final VoidCallback onFaster;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
    final percent = (speed * 100).round();
    final playStyle = FilledButton.styleFrom(
      backgroundColor: nextIsPrimary ? brand.card : brand.accent,
      foregroundColor: nextIsPrimary ? brand.ink : brand.onAccent,
      // Same width for Play and Pause, so the bar does not shift.
      minimumSize: const Size(120, 52),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      side: nextIsPrimary ? BorderSide(color: brand.border) : null,
    );
    final nextStyle = nextIsPrimary
        ? FilledButton.styleFrom(
            backgroundColor: brand.accent,
            foregroundColor: brand.onAccent,
            minimumSize: const Size(44, 52),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: brand.ink,
            side: BorderSide(color: brand.border),
            minimumSize: const Size(44, 52),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          );
    final nextChild = Text(
      nextLabel,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.canvas,
        border: Border(top: BorderSide(color: brand.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    key: const ValueKey('perf_speed_down'),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    tooltip: l10n?.livePerfSlower ?? 'Slower',
                    icon: const Icon(Icons.remove),
                    onPressed: speed > ScrollPace.minAdjustment
                        ? onSlower
                        : null,
                  ),
                  Flexible(
                    child: Text(
                      l10n?.livePerfPace(bpm, percent) ?? '♩ $bpm · $percent%',
                      key: const ValueKey('perf_pace'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.monoFontFamily,
                        fontFamilyFallback: AppTheme.monoFontFallbacks,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: brand.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('perf_speed_up'),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    tooltip: l10n?.livePerfFaster ?? 'Faster',
                    icon: const Icon(Icons.add),
                    onPressed: speed < ScrollPace.maxAdjustment
                        ? onFaster
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // The buttons take the width of their label, so no label is
              // cut short in any language.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    key: const ValueKey('perf_prev'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brand.ink,
                      side: BorderSide(color: brand.border),
                      minimumSize: const Size(48, 52),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: canGoBack ? onPrevious : null,
                    child: Tooltip(
                      message: l10n?.livePerfPrevious ?? 'Previous',
                      child: const Icon(Icons.chevron_left),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 5,
                    child: FilledButton.icon(
                      key: const ValueKey('perf_play'),
                      style: playStyle,
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                      label: Text(
                        playing
                            ? (l10n?.livePerfPause ?? 'Pause')
                            : (l10n?.livePerfPlay ?? 'Play'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: onTogglePlay,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 4,
                    child: nextIsPrimary
                        ? FilledButton(
                            key: const ValueKey('perf_next'),
                            style: nextStyle,
                            onPressed: onNext,
                            child: nextChild,
                          )
                        : OutlinedButton(
                            key: const ValueKey('perf_next'),
                            style: nextStyle,
                            onPressed: onNext,
                            child: nextChild,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
