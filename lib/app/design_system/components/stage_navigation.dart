/// Battuta — Stage navigation (adaptive bottom bar / side rail).
///
/// A flush, border-delineated navigation surface with a single amber
/// "spotlight" pill that glides between destinations on the downbeat curve.
/// Icons swap outline → filled with a small rebound, labels sharpen on
/// selection, and a selection haptic fires on change.
///
/// - [StageNavigationBar]: compact widths (iPhone, iPad portrait splits).
/// - [StageNavigationRail]: wide windows (iPad landscape, macOS) with the
///   brand mark at the top.
library;

import 'package:battuta/app/design_system/brand/battuta_mark.dart';
import 'package:battuta/app/design_system/motion/pressable.dart';
import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/app/theme/battuta_tokens.dart';
import 'package:flutter/material.dart';

/// A single navigation destination.
@immutable
class StageDestination {
  const StageDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const double _pillWidth = 56;
const double _pillHeight = 32;

/// Bottom navigation bar for compact layouts.
class StageNavigationBar extends StatelessWidget {
  const StageNavigationBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<StageDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final duration = BattutaMotion.resolve(context, BattutaMotion.bar);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.canvas,
        border: Border(top: BorderSide(color: brand.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / destinations.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: duration,
                    curve: BattutaMotion.downbeat,
                    left:
                        itemWidth * selectedIndex +
                        (itemWidth - _pillWidth) / 2,
                    top: 7,
                    width: _pillWidth,
                    height: _pillHeight,
                    child: _Spotlight(brand: brand),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        Expanded(
                          child: _StageItem(
                            destination: destinations[i],
                            selected: i == selectedIndex,
                            onTap: () => onSelected(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Side navigation rail for wide layouts.
class StageNavigationRail extends StatelessWidget {
  const StageNavigationRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<StageDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double width = 88;
  static const double _itemHeight = 68;
  static const double _headerHeight = 76;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final duration = BattutaMotion.resolve(context, BattutaMotion.bar);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.canvas,
        border: Border(right: BorderSide(color: brand.border)),
      ),
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: width,
          child: SingleChildScrollView(
            child: SizedBox(
              height: _headerHeight + _itemHeight * destinations.length,
              child: Stack(
                children: [
                  const Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Center(child: BattutaMark(size: 30)),
                  ),
                  AnimatedPositioned(
                    duration: duration,
                    curve: BattutaMotion.downbeat,
                    top: _headerHeight + _itemHeight * selectedIndex + 7,
                    left: (width - _pillWidth) / 2,
                    width: _pillWidth,
                    height: _pillHeight,
                    child: _Spotlight(brand: brand),
                  ),
                  Positioned(
                    top: _headerHeight,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        for (var i = 0; i < destinations.length; i++)
                          SizedBox(
                            height: _itemHeight,
                            child: _StageItem(
                              destination: destinations[i],
                              selected: i == selectedIndex,
                              onTap: () => onSelected(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The amber wash that marks the active destination.
class _Spotlight extends StatelessWidget {
  const _Spotlight({required this.brand});

  final BattutaBrand brand;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.accentWash,
        borderRadius: BorderRadius.circular(BattutaRadius.pill),
      ),
    );
  }
}

class _StageItem extends StatelessWidget {
  const _StageItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final StageDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final color = selected ? brand.accentInk : brand.inkMuted;
    final tick = BattutaMotion.resolve(context, BattutaMotion.beat);

    return Semantics(
      selected: selected,
      child: BattutaPressable(
        onTap: onTap,
        pressedScale: 0.92,
        semanticLabel: destination.label,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: _pillHeight,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: tick,
                    switchInCurve: BattutaMotion.rebound,
                    switchOutCurve: BattutaMotion.upbeat,
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.7,
                        end: 1,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      key: ValueKey(selected),
                      size: 22,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: tick,
                curve: BattutaMotion.downbeat,
                style: TextStyle(
                  fontFamily: AppTheme.primaryFontFamily,
                  fontFamilyFallback: AppTheme.fontFamilyFallbacks,
                  fontSize: 11,
                  height: 1.2,
                  letterSpacing: 0.1,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
                child: Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
