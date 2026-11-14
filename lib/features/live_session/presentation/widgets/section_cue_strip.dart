/// Battuta — the sections of the song on stage as a row of chips: the current
/// one filled, the next one outlined.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/live_session/domain/performance_plan.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class SectionCueStrip extends StatefulWidget {
  const SectionCueStrip({
    required this.song,
    required this.cueIndex,
    required this.onSelect,
    super.key,
  });

  final PerformanceSong song;
  final int cueIndex;
  final ValueChanged<int> onSelect;

  @override
  State<SectionCueStrip> createState() => _SectionCueStripState();
}

class _SectionCueStripState extends State<SectionCueStrip> {
  final _keys = <int, GlobalKey>{};

  @override
  void didUpdateWidget(SectionCueStrip old) {
    super.didUpdateWidget(old);
    if (old.cueIndex != widget.cueIndex || old.song != widget.song) {
      // Keep the current chip in view when there are more than fit.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _keys[widget.cueIndex]?.currentContext;
        if (!mounted || context == null) return;
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: BattutaMotion.resolve(context, BattutaMotion.bar),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cues = widget.song.cues;
    if (cues.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: l10n?.livePerfSectionsLabel ?? 'Sections',
      child: SingleChildScrollView(
        key: const ValueKey('perf_cue_strip'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (var i = 0; i < cues.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _CueChip(
                key: _keys.putIfAbsent(i, GlobalKey.new),
                label: cues[i].isWholeSong
                    ? (l10n?.livePerfWholeSong ?? 'Whole song')
                    : cues[i].label,
                current: i == widget.cueIndex,
                next: i == widget.cueIndex + 1,
                onTap: () => widget.onSelect(i),
                chipKey: ValueKey('perf_chip_$i'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CueChip extends StatelessWidget {
  const _CueChip({
    required this.label,
    required this.current,
    required this.next,
    required this.onTap,
    required this.chipKey,
    super.key,
  });

  final String label;
  final bool current;
  final bool next;
  final VoidCallback onTap;
  final Key chipKey;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final background = current ? brand.accent : brand.card;
    final foreground = current
        ? brand.onAccent
        : (next ? brand.accentInk : brand.ink);
    final border = current
        ? brand.accent
        : (next ? brand.accent : brand.border);
    return BattutaPressable(
      key: chipKey,
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(BattutaRadius.pill),
          border: Border.all(color: border, width: next ? 2 : 1),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 14,
            fontWeight: current || next ? FontWeight.w700 : FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
