/// Battuta — top of the performance view: where we are in the set and what
/// comes next.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/live_session/domain/performance_plan.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class PerformanceHeader extends StatelessWidget {
  const PerformanceHeader({
    required this.song,
    required this.songNumber,
    required this.songCount,
    required this.nextText,
    required this.onClose,
    super.key,
  });

  final PerformanceSong song;

  /// 1-based position of [song].
  final int songNumber;
  final int songCount;

  /// "Next: Chorus", always visible.
  final String nextText;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
    final title = [
      l10n?.livePerfSongOf(songNumber, songCount) ??
          'Song $songNumber of $songCount',
      if (song.title.isNotEmpty) song.title,
      if (song.key.isNotEmpty) song.key,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('perf_close'),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: l10n?.livePerfClose ?? 'Close',
            icon: Icon(Icons.close, color: brand.ink),
            onPressed: onClose,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  key: const ValueKey('perf_title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: brand.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nextText,
                  key: const ValueKey('perf_next_text'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: brand.accentInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
