/// Battuta — Stage controls: segmented control and status pill.
library;

import 'package:battuta/app/design_system/motion/pressable.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/app/theme/battuta_tokens.dart';
import 'package:flutter/material.dart';

/// One option of a [StageSegmentedControl].
@immutable
class StageSegment<T> {
  const StageSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// A segmented control with a solid amber thumb that glides to the selected
/// option on the downbeat curve. Use for mutually exclusive *modes* (e.g.
/// Director / Follower). For filters and settings that use Material's
/// `SegmentedButton`, the theme already applies Battuta styling.
class StageSegmentedControl<T> extends StatelessWidget {
  const StageSegmentedControl({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<StageSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  static const double height = 48;

  /// Inner thumb height per the designs (38pt) is height - 2 * 4 - 2.

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final selectedIndex = segments
        .indexWhere((s) => s.value == selected)
        .clamp(0, segments.length - 1);
    final duration = BattutaMotion.resolve(context, BattutaMotion.bar);

    return Container(
      height: height,
      padding: const EdgeInsets.all(BattutaSpace.xs),
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brand.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / segments.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: duration,
                curve: BattutaMotion.downbeat,
                left: width * selectedIndex,
                top: 0,
                bottom: 0,
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: brand.accent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < segments.length; i++)
                    Expanded(
                      child: _SegmentLabel(
                        segment: segments[i],
                        selected: i == selectedIndex,
                        onTap: () => onChanged(segments[i].value),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentLabel<T> extends StatelessWidget {
  const _SegmentLabel({
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  final StageSegment<T> segment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final color = selected ? brand.onAccent : brand.inkMuted;
    final duration = BattutaMotion.resolve(context, BattutaMotion.beat);

    return Semantics(
      selected: selected,
      child: BattutaPressable(
        onTap: onTap,
        pressedScale: 0.96,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: BattutaSpace.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (segment.icon != null) ...[
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: color),
                    duration: duration,
                    builder: (context, c, _) =>
                        Icon(segment.icon, size: 18, color: c),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: duration,
                    curve: BattutaMotion.downbeat,
                    style: Theme.of(context).textTheme.labelLarge!
                        .copyWith(color: color, fontWeight: FontWeight.w600),
                    child: Text(
                      segment.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact status pill with a colored dot. When [active] flips to true the
/// dot emits a single ring "ping", which reads as "we're live" without a
/// distracting infinite pulse.
class StageStatusPill extends StatelessWidget {
  const StageStatusPill({
    required this.label,
    super.key,
    this.tone,
    this.active = false,
  });

  final String label;

  /// Color when [active]; defaults to `brand.success`.
  final Color? tone;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final color = active ? (tone ?? brand.success) : brand.inkMuted;
    final duration = BattutaMotion.resolve(context, BattutaMotion.beat);

    return AnimatedContainer(
      duration: duration,
      curve: BattutaMotion.downbeat,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? brand.wash(color) : brand.cardRaised,
        borderRadius: BorderRadius.circular(BattutaRadius.pill),
        border: Border.all(
          color: active ? color.withValues(alpha: 0.6) : brand.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 8,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (active)
                  TweenAnimationBuilder<double>(
                    key: const ValueKey('ping'),
                    tween: Tween(begin: 0, end: 1),
                    duration: BattutaMotion.resolve(
                      context,
                      BattutaMotion.phrase,
                    ),
                    curve: BattutaMotion.downbeat,
                    builder: (context, t, _) => Opacity(
                      opacity: (1 - t) * 0.6,
                      child: Transform.scale(
                        scale: 1 + 1.6 * t,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                          child: const SizedBox.square(dimension: 8),
                        ),
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: duration,
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          AnimatedDefaultTextStyle(
            duration: duration,
            // Built from the theme so the brand font is kept (an
            // AnimatedDefaultTextStyle replaces, not merges, the inherited
            // style).
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: color,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

/// Filter pill from the Battuta Screens designs: card surface with a 1px
/// border, amber outline + wash + amber label when selected. Wraps freely,
/// so it suits option sets too long for a segmented control.
class StageFilterPill extends StatelessWidget {
  const StageFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dot,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Semantics(
      selected: selected,
      child: BattutaPressable(
        onTap: onTap,
        pressedScale: 0.95,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: BattutaMotion.resolve(context, BattutaMotion.beat),
          curve: BattutaMotion.downbeat,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? brand.accentWash : brand.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? brand.accent : brand.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? brand.accentInk : brand.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
