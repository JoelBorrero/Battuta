/// Battuta — Brand mark and wordmark.
///
/// **The Ictus.** "A battuta" is the Italian marking that tells musicians to
/// return to strict time, following the conductor's beat. The mark draws a
/// conductor's downbeat gesture: the baton sweeps down, lands on the
/// *ictus* (the exact instant of the beat, shown as the stage-amber dot), and
/// rebounds upward. The same idea drives the motion language — see
/// [BattutaMotion.downbeat].
library;

import 'dart:ui' show PathMetric;

import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/app/theme/battuta_tokens.dart';
import 'package:flutter/material.dart';

/// The Battuta brand mark (baton gesture + ictus dot).
///
/// [progress] (0–1) controls a draw-on animation: the baton stroke traces in,
/// and the amber ictus "lands" with a small rebound when the stroke reaches
/// the bottom of the gesture. Leave at `1` for a static mark.
class BattutaMark extends StatelessWidget {
  const BattutaMark({
    super.key,
    this.size = 32,
    this.progress = 1,
    this.strokeColor,
    this.ictusColor,
  });

  final double size;
  final double progress;

  /// Baton color; defaults to the brand ink for the current brightness.
  final Color? strokeColor;

  /// Ictus (dot) color; defaults to stage amber.
  final Color? ictusColor;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Semantics(
      label: 'Battuta',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: BattutaMarkPainter(
            progress: progress.clamp(0, 1),
            strokeColor: strokeColor ?? brand.ink,
            ictusColor: ictusColor ?? brand.accent,
          ),
        ),
      ),
    );
  }
}

/// Paints the [BattutaMark] in a unit square scaled to the canvas.
class BattutaMarkPainter extends CustomPainter {
  BattutaMarkPainter({
    required this.progress,
    required this.strokeColor,
    required this.ictusColor,
  });

  final double progress;
  final Color strokeColor;
  final Color ictusColor;

  /// Ictus position in unit coordinates.
  static const Offset ictus = Offset(0.46, 0.78);

  /// Fraction of the drawn stroke at which the baton reaches the ictus.
  static const double _ictusAt = 0.58;

  static Path _gesture(double s) {
    return Path()
      // Preparatory lift → downbeat.
      ..moveTo(0.20 * s, 0.16 * s)
      ..cubicTo(
        0.20 * s,
        0.52 * s,
        0.30 * s,
        0.78 * s,
        ictus.dx * s,
        ictus.dy * s,
      )
      // Rebound.
      ..cubicTo(0.62 * s, 0.78 * s, 0.76 * s, 0.62 * s, 0.82 * s, 0.36 * s);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.105
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _gesture(s);
    if (progress >= 1) {
      canvas.drawPath(path, stroke);
    } else if (progress > 0) {
      final drawT = BattutaMotion.downbeat.transform(
        (progress / 0.8).clamp(0.0, 1.0),
      );
      for (final PathMetric metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * drawT), stroke);
      }
    }

    // The ictus lands once the baton reaches the bottom of the gesture.
    final dotT = progress >= 1
        ? 1.0
        : ((progress - _ictusAt * 0.8) / 0.3).clamp(0.0, 1.0);
    if (dotT > 0) {
      final scale = BattutaMotion.rebound.transform(dotT);
      canvas.drawCircle(
        Offset(ictus.dx * s, ictus.dy * s),
        s * 0.13 * scale,
        Paint()..color = ictusColor,
      );
    }
  }

  @override
  bool shouldRepaint(BattutaMarkPainter old) =>
      old.progress != progress ||
      old.strokeColor != strokeColor ||
      old.ictusColor != ictusColor;
}

/// Mark + lowercase "battuta" logotype.
class BattutaWordmark extends StatelessWidget {
  const BattutaWordmark({super.key, this.height = 28, this.progress = 1});

  final double height;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final textT = ((progress - 0.45) / 0.55).clamp(0.0, 1.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BattutaMark(size: height, progress: progress),
        SizedBox(width: height * 0.28),
        Opacity(
          opacity: BattutaMotion.downbeat.transform(textT),
          child: Transform.translate(
            offset: Offset(
              -8 * (1 - BattutaMotion.downbeat.transform(textT)),
              0,
            ),
            child: Text(
              'battuta',
              style: TextStyle(
                fontFamily: AppTheme.primaryFontFamily,
                fontFamilyFallback: AppTheme.fontFamilyFallbacks,
                fontSize: height * 0.78,
                fontWeight: FontWeight.w600,
                letterSpacing: -height * 0.03,
                height: 1,
                color: brand.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
