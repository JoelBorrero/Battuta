/// Battuta — One-shot launch intro.
///
/// Plays the brand "downbeat" once on cold start: the stage light warms up,
/// the baton draws its gesture, the ictus lands, the logotype slides in, and
/// the curtain lifts to reveal the app. ~1.4 s total, non-blocking (pointer
/// events pass through) and skipped entirely when reduced motion is on.
library;

import 'package:battuta/app/design_system/brand/battuta_mark.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/app/theme/battuta_tokens.dart';
import 'package:flutter/material.dart';

/// Wraps [child] and overlays the brand intro the first time it builds.
class BrandIntro extends StatefulWidget {
  const BrandIntro({required this.child, super.key, this.enabled = true});

  final Widget child;

  /// Set to `false` to skip the intro (e.g. tests, deep links).
  final bool enabled;

  @override
  State<BrandIntro> createState() => _BrandIntroState();
}

class _BrandIntroState extends State<BrandIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _done = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.enabled || BattutaMotion.reduced(context)) {
      _done = true;
      return;
    }
    _controller.forward().whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    final brand = BattutaBrand.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        // Sits above the Navigator, so provide a Material ancestor for text.
        IgnorePointer(
          child: Material(
            type: MaterialType.transparency,
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value;
                  final draw = (t / 0.62).clamp(0.0, 1.0);
                  final lift = BattutaMotion.upbeat.transform(
                    ((t - 0.74) / 0.26).clamp(0.0, 1.0),
                  );
                  final glow = BattutaMotion.downbeat.transform(
                    (t / 0.4).clamp(0.0, 1.0),
                  );
                  return Opacity(
                    opacity: 1 - lift,
                    child: ColoredBox(
                      color: brand.canvas,
                      child: Center(
                        child: Transform.scale(
                          scale: 1 + 0.06 * lift,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: glow,
                                child: Container(
                                  width: 320,
                                  height: 320,
                                  decoration: BoxDecoration(
                                    gradient: brand.stageLight,
                                  ),
                                ),
                              ),
                              BattutaWordmark(height: 44, progress: draw),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
