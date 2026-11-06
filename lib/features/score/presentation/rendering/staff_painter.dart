/// Battuta — StaffCanvas CustomPainter.
///
/// Renders 5-line staves, SMuFL clefs, time signatures, barlines
/// (single, double, repeat |: :|, final), volta endings (casillas),
/// chord boxes (| F | C/E |), and navigation blocks ([INTERLUDIO] x 2).
library;

import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:battuta/features/score/presentation/rendering/notehead_painter.dart';
import 'package:battuta/features/score/presentation/rendering/section_layout_index.dart';
import 'package:battuta/features/score/presentation/rendering/smufl_glyphs.dart';
import 'package:battuta/features/score/presentation/rendering/staff_metrics.dart';
import 'package:flutter/material.dart';

/// [CustomPainter] that renders the complete score layout onto a 2D canvas.
class StaffPainter extends CustomPainter {
  StaffPainter({
    required this.score,
    this.metrics = const StaffMetrics(),
    this.layoutIndex,
    this.measureWarnings,
  });

  /// The score domain tree containing sections and measures to paint.
  final Score score;

  /// Geometric and styling metrics.
  final StaffMetrics metrics;

  /// Optional layout index to register section Y-offsets for instant scrolling.
  final SectionLayoutIndex? layoutIndex;

  /// Optional map of measure numbers to Gemini advertencia warnings.
  final Map<int, String>? measureWarnings;

  @override
  void paint(Canvas canvas, Size size) {
    if (score.sections.isEmpty) return;

    final staffPaint = Paint()
      ..color = metrics.staffColor
      ..strokeWidth = metrics.lineThickness
      ..style = PaintingStyle.stroke;

    final barlinePaint = Paint()
      ..color = metrics.staffColor
      ..strokeWidth = metrics.barlineThickness
      ..style = PaintingStyle.stroke;

    final heavyBarlinePaint = Paint()
      ..color = metrics.staffColor
      ..strokeWidth = metrics.heavyBarlineThickness
      ..style = PaintingStyle.stroke;

    var currentY = metrics.topPadding;
    final contentWidth = size.width - metrics.leftPadding - metrics.rightPadding;
    if (contentWidth <= 0) return;

    var isFirstSystemInScore = true;

    for (final section in score.sections) {
      // -----------------------------------------------------------------------
      // 1. Paint Section Navigation Box / Header
      // -----------------------------------------------------------------------
      layoutIndex?.register(
        sectionId: section.id,
        yOffset: currentY,
        externalSyncId: section.externalSyncId,
        name: section.name,
      );

      _paintSectionHeader(canvas, section, currentY, metrics.leftPadding);
      currentY += metrics.headerSpacing;

      // Group section measures into systems
      final measures = section.measures;
      if (measures.isEmpty) {
        currentY += metrics.systemSpacing;
        continue;
      }

      final measuresPerSys = metrics.measuresPerSystem > 0
          ? metrics.measuresPerSystem
          : 4;

      for (var mStart = 0; mStart < measures.length; mStart += measuresPerSys) {
        final mEnd = (mStart + measuresPerSys < measures.length)
            ? mStart + measuresPerSys
            : measures.length;
        final systemMeasures = measures.sublist(mStart, mEnd);

        final systemTop = currentY;
        final staffTop = systemTop + metrics.spaceAboveStaff;
        final staffBottom = staffTop + metrics.staffHeight;
        final systemStartX = metrics.leftPadding;
        final systemEndX = size.width - metrics.rightPadding;

        // ---------------------------------------------------------------------
        // 2. Draw 5-Line Staff
        // ---------------------------------------------------------------------
        for (var line = 0; line < 5; line++) {
          final lineY = staffTop + (line * metrics.lineSpacing);
          canvas.drawLine(
            Offset(systemStartX, lineY),
            Offset(systemEndX, lineY),
            staffPaint,
          );
        }

        // ---------------------------------------------------------------------
        // 3. Draw Clef (and Time Signature on first system)
        // ---------------------------------------------------------------------
        var measureAreaStartX = systemStartX;

        // Draw G-Clef at the start of the system
        final clefPainter = SmuflGlyphs.createPainter(
          glyph: SmuflGlyphs.gClef,
          fontSize: metrics.clefFontSize,
          color: metrics.staffColor,
        );
        // Position G-clef vertically so the spiral aligns with G4 (2nd line from bottom)
        final clefY = staffTop - (metrics.lineSpacing * 0.8);
        clefPainter.paint(canvas, Offset(systemStartX + 4.0, clefY));
        measureAreaStartX += clefPainter.width + 12.0;

        // Time Signature on first system of score
        if (isFirstSystemInScore) {
          final timeSig = systemMeasures.first.timeSignature;
          measureAreaStartX = _paintTimeSignature(
            canvas,
            timeSig.numerator,
            timeSig.denominator,
            measureAreaStartX,
            staffTop,
          );
          isFirstSystemInScore = false;
        }

        // ---------------------------------------------------------------------
        // 4. Measure Layout & Barlines
        // ---------------------------------------------------------------------
        final availableMeasureWidth = systemEndX - measureAreaStartX;
        final measureWidth = systemMeasures.isNotEmpty
            ? availableMeasureWidth / systemMeasures.length
            : availableMeasureWidth;

        for (var i = 0; i < systemMeasures.length; i++) {
          final measure = systemMeasures[i];
          final measureLeft = measureAreaStartX + (i * measureWidth);
          final measureRight = measureLeft + measureWidth;
          final isFirstMeasureInSection = (mStart + i == 0);
          final isLastMeasureInSection = (mStart + i == measures.length - 1);
          final isLastMeasureInScore =
              (section == score.sections.last && isLastMeasureInSection);

          // Left barline of measure
          if (i == 0) {
            if (isFirstMeasureInSection && section.repeatCount > 1) {
              _paintRepeatBarline(
                canvas,
                measureAreaStartX,
                staffTop,
                staffBottom,
                isLeft: true,
                heavyPaint: heavyBarlinePaint,
                thinPaint: barlinePaint,
              );
            } else {
              canvas.drawLine(
                Offset(measureAreaStartX, staffTop),
                Offset(measureAreaStartX, staffBottom),
                barlinePaint,
              );
            }
          }

          // Right barline of measure
          if (isLastMeasureInScore) {
            _paintFinalBarline(
              canvas,
              measureRight,
              staffTop,
              staffBottom,
              heavyPaint: heavyBarlinePaint,
              thinPaint: barlinePaint,
            );
          } else if (isLastMeasureInSection && section.repeatCount > 1) {
            _paintRepeatBarline(
              canvas,
              measureRight,
              staffTop,
              staffBottom,
              isLeft: false,
              heavyPaint: heavyBarlinePaint,
              thinPaint: barlinePaint,
            );
          } else {
            canvas.drawLine(
              Offset(measureRight, staffTop),
              Offset(measureRight, staffBottom),
              barlinePaint,
            );
          }

          // Measure number indicator
          _paintMeasureNumber(canvas, measure.number, measureLeft, staffTop);

          // -------------------------------------------------------------------
          // 5. Chords & Volta Repeat Endings
          // -------------------------------------------------------------------
          _paintChords(canvas, measure, measureLeft, measureWidth, staffTop);

          // -------------------------------------------------------------------
          // 6. Notes, Stems, Ledger Lines & Warning Badges
          // -------------------------------------------------------------------
          NoteheadPainter.paintMeasureNotes(
            canvas,
            measure: measure,
            measureLeft: measureLeft,
            measureRight: measureRight,
            staffBottomY: staffBottom,
            metrics: metrics,
            measureWarning: measureWarnings?[measure.number],
          );
        }

        currentY += metrics.systemRowHeight;
      }
    }
  }

  void _paintSectionHeader(
    Canvas canvas,
    Section section,
    double y,
    double x,
  ) {
    final repeatSuffix =
        section.repeatCount > 1 ? ' x ${section.repeatCount}' : '';
    final labelText = '[${section.name.toUpperCase()}]$repeatSuffix';

    final textSpan = TextSpan(
      text: labelText,
      style: TextStyle(
        fontSize: metrics.sectionHeaderFontSize,
        fontWeight: FontWeight.bold,
        color: metrics.headerTextColor,
        letterSpacing: 0.8,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    const paddingH = 8.0;
    const paddingV = 4.0;
    final badgeWidth = textPainter.width + (paddingH * 2);
    final badgeHeight = textPainter.height + (paddingV * 2);

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, badgeWidth, badgeHeight),
      const Radius.circular(4.0),
    );

    // Background fill
    final bgPaint = Paint()
      ..color = metrics.headerBadgeColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(badgeRect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = metrics.headerBadgeBorderColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(badgeRect, borderPaint);

    // Text
    textPainter.paint(canvas, Offset(x + paddingH, y + paddingV));
  }

  double _paintTimeSignature(
    Canvas canvas,
    int numerator,
    int denominator,
    double x,
    double staffTop,
  ) {
    final numGlyph = SmuflGlyphs.glyphForTimeSigDigit(numerator);
    final denGlyph = SmuflGlyphs.glyphForTimeSigDigit(denominator);

    final numPainter = SmuflGlyphs.createPainter(
      glyph: numGlyph,
      fontSize: metrics.timeSigFontSize,
      color: metrics.staffColor,
    );
    final denPainter = SmuflGlyphs.createPainter(
      glyph: denGlyph,
      fontSize: metrics.timeSigFontSize,
      color: metrics.staffColor,
    );

    // Numerator in upper half of staff
    numPainter.paint(canvas, Offset(x, staffTop - 2.0));
    // Denominator in lower half of staff
    denPainter.paint(
      canvas,
      Offset(x, staffTop + (metrics.lineSpacing * 2.0) - 2.0),
    );

    final maxWidth = numPainter.width > denPainter.width
        ? numPainter.width
        : denPainter.width;
    return x + maxWidth + 10.0;
  }

  void _paintMeasureNumber(
    Canvas canvas,
    int measureNumber,
    double x,
    double staffTop,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$measureNumber',
        style: TextStyle(
          fontSize: 9.0,
          color: metrics.staffColor.withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(x + 2.0, staffTop - 12.0));
  }

  void _paintChords(
    Canvas canvas,
    Measure measure,
    double measureLeft,
    double measureWidth,
    double staffTop,
  ) {
    if (measure.chords.isEmpty) return;

    final chordY = staffTop - metrics.chordFontSize - 10.0;

    for (final chord in measure.chords) {
      final tickRatio = measure.maxTicks > 0
          ? (chord.tickOffset / measure.maxTicks).clamp(0.0, 0.9)
          : 0.0;
      final chordX = measureLeft + 6.0 + (measureWidth * tickRatio);

      final textSpan = TextSpan(
        text: chord.text,
        style: TextStyle(
          fontSize: metrics.chordFontSize,
          fontWeight: FontWeight.w800,
          color: metrics.chordColor,
          letterSpacing: 0.5,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(chordX, chordY));
    }
  }

  void _paintRepeatBarline(
    Canvas canvas,
    double x,
    double top,
    double bottom, {
    required bool isLeft,
    required Paint heavyPaint,
    required Paint thinPaint,
  }) {
    if (isLeft) {
      // |: (Heavy, Thin, Dots)
      canvas.drawLine(Offset(x, top), Offset(x, bottom), heavyPaint);
      canvas.drawLine(Offset(x + 5.0, top), Offset(x + 5.0, bottom), thinPaint);

      // Repeat dots (in 2nd and 3rd spaces)
      final dotRadius = metrics.lineSpacing * 0.22;
      final dotPaint = Paint()
        ..color = metrics.staffColor
        ..style = PaintingStyle.fill;
      final dotX = x + 10.0;
      final dotY1 = top + (metrics.lineSpacing * 1.5);
      final dotY2 = top + (metrics.lineSpacing * 2.5);
      canvas.drawCircle(Offset(dotX, dotY1), dotRadius, dotPaint);
      canvas.drawCircle(Offset(dotX, dotY2), dotRadius, dotPaint);
    } else {
      // :| (Dots, Thin, Heavy)
      final dotRadius = metrics.lineSpacing * 0.22;
      final dotPaint = Paint()
        ..color = metrics.staffColor
        ..style = PaintingStyle.fill;
      final dotX = x - 10.0;
      final dotY1 = top + (metrics.lineSpacing * 1.5);
      final dotY2 = top + (metrics.lineSpacing * 2.5);
      canvas.drawCircle(Offset(dotX, dotY1), dotRadius, dotPaint);
      canvas.drawCircle(Offset(dotX, dotY2), dotRadius, dotPaint);

      canvas.drawLine(Offset(x - 5.0, top), Offset(x - 5.0, bottom), thinPaint);
      canvas.drawLine(Offset(x, top), Offset(x, bottom), heavyPaint);
    }
  }

  void _paintFinalBarline(
    Canvas canvas,
    double x,
    double top,
    double bottom, {
    required Paint heavyPaint,
    required Paint thinPaint,
  }) {
    canvas.drawLine(Offset(x - 5.0, top), Offset(x - 5.0, bottom), thinPaint);
    canvas.drawLine(Offset(x, top), Offset(x, bottom), heavyPaint);
  }

  /// Calculates the total required canvas height for [score].
  static double calculateTotalHeight(
    Score score,
    double availableWidth, {
    StaffMetrics metrics = const StaffMetrics(),
  }) {
    if (score.sections.isEmpty) return 100.0;

    var totalHeight = metrics.topPadding + metrics.bottomPadding;
    final measuresPerSys =
        metrics.measuresPerSystem > 0 ? metrics.measuresPerSystem : 4;

    for (final section in score.sections) {
      totalHeight += metrics.headerSpacing;
      final measuresCount = section.measures.length;
      final systemCount = (measuresCount / measuresPerSys).ceil();
      final effectiveSystemCount = systemCount > 0 ? systemCount : 1;
      totalHeight += effectiveSystemCount * metrics.systemRowHeight;
    }

    return totalHeight;
  }

  @override
  bool shouldRepaint(covariant StaffPainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.metrics != metrics ||
        oldDelegate.layoutIndex != layoutIndex ||
        oldDelegate.measureWarnings != measureWarnings;
  }
}
