/// Battuta — the setlist beside the chart on wide screens: every song, the
/// current one highlighted, tap to jump.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/live_session/domain/performance_plan.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class SetlistOutline extends StatelessWidget {
  const SetlistOutline({
    required this.plan,
    required this.songIndex,
    required this.onSelect,
    super.key,
  });

  final PerformancePlan plan;
  final int songIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: brand.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              (l10n?.livePerfOutlineTitle ?? 'Setlist').toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: brand.inkMuted,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              key: const ValueKey('perf_outline'),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                for (var i = 0; i < plan.songs.length; i++)
                  _OutlineRow(
                    number: i + 1,
                    song: plan.songs[i],
                    current: i == songIndex,
                    onTap: () => onSelect(i),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineRow extends StatelessWidget {
  const _OutlineRow({
    required this.number,
    required this.song,
    required this.current,
    required this.onTap,
  });

  final int number;
  final PerformanceSong song;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
    final title = song.title.isNotEmpty
        ? song.title
        : (l10n?.livePerfMissingSong ?? 'Not on this device');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: BattutaPressable(
        key: ValueKey('perf_outline_$number'),
        onTap: onTap,
        semanticLabel: title,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: current ? brand.accentWash : brand.card,
            borderRadius: BorderRadius.circular(BattutaRadius.sm),
            border: Border.all(color: current ? brand.accent : brand.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: current ? brand.accentInk : brand.inkMuted,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                        color: song.isMissing ? brand.inkMuted : brand.ink,
                      ),
                    ),
                    if (song.isMissing)
                      Text(
                        l10n?.livePerfMissingSong ?? 'Not on this device',
                        style: TextStyle(fontSize: 12, color: brand.inkMuted),
                      ),
                  ],
                ),
              ),
              if (song.key.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  song.key,
                  style: TextStyle(
                    fontFamily: AppTheme.monoFontFamily,
                    fontFamilyFallback: AppTheme.monoFontFallbacks,
                    fontWeight: FontWeight.w700,
                    color: brand.accentInk,
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
