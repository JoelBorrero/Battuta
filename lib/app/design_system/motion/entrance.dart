/// Battuta — Entrance choreography.
///
/// [BattutaEntrance] fades and lifts content into place on first build using
/// the signature [BattutaMotion.downbeat] curve. Pass an [index] to stagger
/// list items "in tempo" — each item lands one [BattutaMotion.stagger] after
/// the previous, capped at [BattutaMotion.maxStaggeredItems] so long lists
/// never feel slow. Animations run once and are skipped under reduced motion.
library;

import 'package:battuta/app/theme/battuta_tokens.dart';
import 'package:flutter/widgets.dart';

class BattutaEntrance extends StatefulWidget {
  const BattutaEntrance({
    required this.child,
    super.key,
    this.index = 0,
    this.offset = const Offset(0, 12),
    this.duration = BattutaMotion.bar,
  });

  final Widget child;

  /// Position within a staggered group.
  final int index;

  /// Starting translation in logical pixels.
  final Offset offset;

  final Duration duration;

  @override
  State<BattutaEntrance> createState() => _BattutaEntranceState();
}

class _BattutaEntranceState extends State<BattutaEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final steps = widget.index.clamp(0, BattutaMotion.maxStaggeredItems);
    final delay = BattutaMotion.stagger * steps;
    final total = widget.duration + delay;
    _controller = AnimationController(vsync: this, duration: total);
    final start = total.inMicroseconds == 0
        ? 0.0
        : delay.inMicroseconds / total.inMicroseconds;
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: BattutaMotion.downbeat),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    if (BattutaMotion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: widget.offset * (1 - t),
            child: child,
          ),
        );
      },
    );
  }
}
