/// Battuta — moves a scroll view by itself, frame by frame, at a speed the
/// caller chooses.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Scrolls [scroll] with a [Ticker], so tests advance it by pumping time.
///
/// [pointsPerSecond] is asked every frame, so the speed can follow the section
/// on screen. [onTick] runs after each move and [onEnd] when the bottom is
/// reached (the ticker stops then).
class AutoScrollController {
  AutoScrollController({
    required TickerProvider vsync,
    required this.scroll,
    required this.pointsPerSecond,
    this.onTick,
    this.onEnd,
  }) {
    _ticker = vsync.createTicker(_onFrame);
  }

  final ScrollController scroll;
  final double Function() pointsPerSecond;
  final VoidCallback? onTick;
  final VoidCallback? onEnd;

  /// Longest time one frame may move the chart for, so a stalled app (or a
  /// backgrounded one) does not leap ahead when frames come back.
  static const double maxFrameSeconds = 1;

  late final Ticker _ticker;
  Duration _last = Duration.zero;

  bool get isRunning => _ticker.isActive;

  void start() {
    if (_ticker.isActive) return;
    _last = Duration.zero;
    _ticker.start();
  }

  void stop() {
    if (_ticker.isActive) _ticker.stop();
  }

  void dispose() => _ticker.dispose();

  void _onFrame(Duration elapsed) {
    final seconds = ((elapsed - _last).inMicroseconds / 1e6).clamp(
      0.0,
      maxFrameSeconds,
    );
    _last = elapsed;
    if (!scroll.hasClients) return;
    final position = scroll.position;
    final speed = pointsPerSecond();
    if (!speed.isFinite || speed <= 0 || seconds == 0) return;
    final target = position.pixels + speed * seconds;
    if (target >= position.maxScrollExtent) {
      if (position.pixels < position.maxScrollExtent) {
        scroll.jumpTo(position.maxScrollExtent);
      }
      stop();
      onTick?.call();
      onEnd?.call();
      return;
    }
    scroll.jumpTo(target);
    onTick?.call();
  }
}
