/// Battuta — NoteheadPainter.
///
/// Paints melodic note events, SMuFL noteheads, accidentals, ledger lines,
/// stems, flags, and distinct visual styles for unassigned pitch-only notes,
/// plus Gemini advertencia warning badges on affected measures.
library;

import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/presentation/rendering/smufl_glyphs.dart';
import 'package:battuta/features/score/presentation/rendering/staff_metrics.dart';
import 'package:battuta/features/score/presentation/rendering/staff_pitch_mapper.dart';
import 'package:flutter/material.dart';

/// Helper class for rendering noteheads, stems, ledger lines, and measure warning badges.
abstract final class NoteheadPainter {
  /// Unassigned note accent color (Amber 600) to visually signal pending rhythm input.
  static const Color unassignedNoteColor = Color(0xFFD97706);

  /// Unassigned note highlight halo/background color.
  static const Color unassignedHaloColor = Color(0x33F59E0B);

  /// Measure warning badge color.
  static const Color warningBadgeColor = Color(0xFFD97706);

  /// Paints all note events and annotations for a single [measure].
  static void paintMeasureNotes(
    Canvas canvas, {
    required Measure measure,
    required double measureLeft,
    required double measureRight,
    required double staffBottomY,
    required StaffMetrics metrics,
    String? measureWarning,
  }) {
    // -------------------------------------------------------------------------
    // 1. Draw Gemini Advertencia Warning Badge (if present)
    // -------------------------------------------------------------------------
    if (measureWarning != null && measureWarning.trim().isNotEmpty) {
      _paintWarningBadge(
        canvas,
        x: measureLeft + 6.0,
        y: staffBottomY - metrics.staffHeight - metrics.chordFontSize - 22.0,
        warning: measureWarning,
      );
    }

    final events = measure.events;
    if (events.isEmpty) return;

    final measureWidth = measureRight - measureLeft;
    final noteSpacing = measureWidth / (events.length + 1);

    for (var i = 0; i < events.length; i++) {
      final event = events[i];

      // Calculate horizontal X position
      double noteX;
      if (measure.hasUnassignedEvents || measure.maxTicks == 0) {
        // Distribute unassigned noteheads evenly across the measure
        noteX = measureLeft + ((i + 1) * noteSpacing);
      } else {
        // Proportional placement by tick offset
        final ratio = (event.tickOffset / measure.maxTicks).clamp(0.0, 0.92);
        noteX = measureLeft + 16.0 + ((measureWidth - 32.0) * ratio);
      }

      if (event.isRest) {
        _paintRest(
          canvas,
          event: event,
          x: noteX,
          staffBottomY: staffBottomY,
          metrics: metrics,
        );
      } else if (event.pitch != null) {
        _paintNote(
          canvas,
          event: event,
          x: noteX,
          staffBottomY: staffBottomY,
          metrics: metrics,
        );
      }
    }
  }

  static void _paintNote(
    Canvas canvas, {
    required NoteEvent event,
    required double x,
    required double staffBottomY,
    required StaffMetrics metrics,
  }) {
    final pitch = event.pitch!;
    final isUnassigned = event.rhythmicValue.isUnassigned;
    final noteColor = isUnassigned ? unassignedNoteColor : metrics.staffColor;

    final noteY = StaffPitchMapper.yCoordinateForPitch(
      pitch,
      staffBottomY: staffBottomY,
      lineSpacing: metrics.lineSpacing,
    );

    // -------------------------------------------------------------------------
    // Ledger Lines
    // -------------------------------------------------------------------------
    if (StaffPitchMapper.needsLedgerLines(pitch)) {
      final ledgerOffsets = StaffPitchMapper.calculateLedgerLineYOffsets(
        pitch,
        staffBottomY: staffBottomY,
        lineSpacing: metrics.lineSpacing,
      );

      final ledgerPaint = Paint()
        ..color = metrics.staffColor
        ..strokeWidth = metrics.lineThickness
        ..style = PaintingStyle.stroke;

      const ledgerHalfWidth = 10.0;
      for (final ledgerY in ledgerOffsets) {
        canvas.drawLine(
          Offset(x - ledgerHalfWidth, ledgerY),
          Offset(x + ledgerHalfWidth, ledgerY),
          ledgerPaint,
        );
      }
    }

    // -------------------------------------------------------------------------
    // Accidentals (Sharp, Flat, Natural)
    // -------------------------------------------------------------------------
    if (pitch.accidental != 0) {
      final accidentalStr = switch (pitch.accidental) {
        1 => '#',
        -1 => 'b',
        2 => '##',
        -2 => 'bb',
        _ => null,
      };
      final accidentalGlyph = SmuflGlyphs.glyphForAccidental(accidentalStr);
      if (accidentalGlyph != null) {
        final accPainter = SmuflGlyphs.createPainter(
          glyph: accidentalGlyph,
          fontSize: metrics.lineSpacing * 2.4,
          color: noteColor,
        );
        // Accidental placed to the left of the notehead
        accPainter.paint(
          canvas,
          Offset(x - accPainter.width - 4.0, noteY - (metrics.lineSpacing * 1.1)),
        );
      }
    }

    // -------------------------------------------------------------------------
    // Notehead
    // -------------------------------------------------------------------------
    final noteheadGlyph = SmuflGlyphs.glyphForNotehead(event.rhythmicValue);
    final noteheadPainter = SmuflGlyphs.createPainter(
      glyph: noteheadGlyph,
      fontSize: metrics.lineSpacing * 2.8,
      color: noteColor,
    );

    // Center notehead vertically on line or space
    final noteheadOffset = Offset(
      x - (noteheadPainter.width / 2.0),
      noteY - (noteheadPainter.height / 2.0),
    );

    // Distinct style for unassigned notes: highlight halo and rhythm reminder
    if (isUnassigned) {
      final haloPaint = Paint()
        ..color = unassignedHaloColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x, noteY),
        metrics.lineSpacing * 0.9,
        haloPaint,
      );

      final haloBorder = Paint()
        ..color = unassignedNoteColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(
        Offset(x, noteY),
        metrics.lineSpacing * 0.9,
        haloBorder,
      );
    }

    noteheadPainter.paint(canvas, noteheadOffset);

    // -------------------------------------------------------------------------
    // Stems & Flags (only for assigned rhythm notes)
    // -------------------------------------------------------------------------
    if (!isUnassigned && event.rhythmicValue.ticks < 1920) {
      // Whole notes have no stems
      final step = StaffPitchMapper.stepFromE4(pitch);
      final stemUp = step < 4; // Below B4: stem up. B4 or higher: stem down.

      final stemLength = metrics.lineSpacing * 3.5;
      final stemPaint = Paint()
        ..color = noteColor
        ..strokeWidth = metrics.lineThickness
        ..style = PaintingStyle.stroke;

      final stemX =
          stemUp ? x + (noteheadPainter.width * 0.42) : x - (noteheadPainter.width * 0.42);
      final stemStartY = noteY;
      final stemEndY = stemUp ? noteY - stemLength : noteY + stemLength;

      canvas.drawLine(
        Offset(stemX, stemStartY),
        Offset(stemX, stemEndY),
        stemPaint,
      );

      // Flags for 8th and 16th notes
      if (event.rhythmicValue.ticks <= 240) {
        // Sixteenth note flag
        final flagGlyph =
            stemUp ? SmuflGlyphs.flag16thUp : SmuflGlyphs.flag16thDown;
        final flagPainter = SmuflGlyphs.createPainter(
          glyph: flagGlyph,
          fontSize: metrics.lineSpacing * 2.8,
          color: noteColor,
        );
        flagPainter.paint(
          canvas,
          Offset(stemX, stemUp ? stemEndY : stemEndY - flagPainter.height),
        );
      } else if (event.rhythmicValue.ticks <= 480 &&
          event.rhythmicValue.ticks < 960) {
        // Eighth note flag
        final flagGlyph =
            stemUp ? SmuflGlyphs.flag8thUp : SmuflGlyphs.flag8thDown;
        final flagPainter = SmuflGlyphs.createPainter(
          glyph: flagGlyph,
          fontSize: metrics.lineSpacing * 2.8,
          color: noteColor,
        );
        flagPainter.paint(
          canvas,
          Offset(stemX, stemUp ? stemEndY : stemEndY - flagPainter.height),
        );
      }
    }

    // -------------------------------------------------------------------------
    // Augmentation Dot (for dotted rhythms)
    // -------------------------------------------------------------------------
    if (event.rhythmicValue.isDotted) {
      final dotPainter = SmuflGlyphs.createPainter(
        glyph: SmuflGlyphs.augmentationDot,
        fontSize: metrics.lineSpacing * 2.0,
        color: noteColor,
      );
      final dotY = (StaffPitchMapper.stepFromE4(pitch).isEven)
          ? noteY - (metrics.lineSpacing / 2.0)
          : noteY;
      dotPainter.paint(
        canvas,
        Offset(x + (noteheadPainter.width / 2.0) + 4.0, dotY - (dotPainter.height / 2.0)),
      );
    }

    // -------------------------------------------------------------------------
    // Lyrics
    // -------------------------------------------------------------------------
    if (event.lyric != null && event.lyric!.isNotEmpty) {
      final lyricPainter = TextPainter(
        text: TextSpan(
          text: event.lyric,
          style: TextStyle(
            fontSize: 11.0,
            color: metrics.staffColor.withValues(alpha: 0.85),
            fontStyle: FontStyle.italic,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      lyricPainter.paint(
        canvas,
        Offset(x - (lyricPainter.width / 2.0), staffBottomY + 14.0),
      );
    }
  }

  static void _paintRest(
    Canvas canvas, {
    required NoteEvent event,
    required double x,
    required double staffBottomY,
    required StaffMetrics metrics,
  }) {
    final restGlyph = SmuflGlyphs.glyphForRest(event.rhythmicValue);
    final restPainter = SmuflGlyphs.createPainter(
      glyph: restGlyph,
      fontSize: metrics.lineSpacing * 2.8,
      color: metrics.staffColor,
    );

    // Center rest vertically in the staff (around line 3, middle line B4)
    final middleLineY = staffBottomY - (metrics.lineSpacing * 2.0);
    restPainter.paint(
      canvas,
      Offset(
        x - (restPainter.width / 2.0),
        middleLineY - (restPainter.height / 2.0),
      ),
    );
  }

  static void _paintWarningBadge(
    Canvas canvas, {
    required double x,
    required double y,
    required String warning,
  }) {
    final badgePainter = TextPainter(
      text: TextSpan(
        children: [
          const TextSpan(
            text: '⚠ ',
            style: TextStyle(
              fontSize: 10.0,
              color: warningBadgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: warning,
            style: const TextStyle(
              fontSize: 9.0,
              color: warningBadgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: 160.0);

    const padH = 6.0;
    const padV = 2.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        x,
        y,
        badgePainter.width + (padH * 2),
        badgePainter.height + (padV * 2),
      ),
      const Radius.circular(3.0),
    );

    final bgPaint = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);
    badgePainter.paint(canvas, Offset(x + padH, y + padV));
  }
}
