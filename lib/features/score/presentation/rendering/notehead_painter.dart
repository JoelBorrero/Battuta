/// Battuta — NoteheadPainter.
///
/// Paints melodic note events, SMuFL noteheads, accidentals, ledger lines,
/// stems, flags, and distinct visual styles for unassigned pitch-only notes,
/// plus Gemini advertencia warning badges on affected measures.
library;

import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/presentation/rendering/rendered_note_box.dart';
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
    String? sectionId,
    SpatialNoteIndex? spatialIndex,
    String? measureWarning,
    int? selectedEventIndex,
    bool isDragging = false,
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
      final isSelected = selectedEventIndex == i;

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
          isSelected: isSelected,
        );
      } else if (event.pitch != null) {
        final noteBox = _paintNote(
          canvas,
          event: event,
          x: noteX,
          staffBottomY: staffBottomY,
          metrics: metrics,
          sectionId: sectionId ?? '',
          measureNumber: measure.number,
          eventIndex: i,
          measureLeft: measureLeft,
          measureRight: measureRight,
          isSelected: isSelected,
          isDragging: isSelected && isDragging,
        );
        if (noteBox != null) {
          spatialIndex?.register(noteBox);
        }
      }
    }
  }

  static RenderedNoteBox? _paintNote(
    Canvas canvas, {
    required NoteEvent event,
    required double x,
    required double staffBottomY,
    required StaffMetrics metrics,
    required String sectionId,
    required int measureNumber,
    required int eventIndex,
    double? measureLeft,
    double? measureRight,
    bool isSelected = false,
    bool isDragging = false,
  }) {
    final pitch = event.pitch!;
    final isUnassigned = event.rhythmicValue.isUnassigned;
    final noteColor = isSelected
        ? metrics.selectedNoteColor
        : (isUnassigned ? unassignedNoteColor : metrics.staffColor);

    final noteY = StaffPitchMapper.yCoordinateForPitch(
      pitch,
      staffBottomY: staffBottomY,
      lineSpacing: metrics.lineSpacing,
    );

    // -------------------------------------------------------------------------
    // Selection Halo & Glowing Border (Behind notehead)
    // -------------------------------------------------------------------------
    if (isSelected) {
      final auraRadius = metrics.lineSpacing * (isDragging ? 1.35 : 1.15);
      final centerOffset = Offset(x, noteY);

      // 1. Soft glowing aura fill
      final selectionFill = Paint()
        ..color = isDragging
            ? metrics.selectedHaloColor.withValues(alpha: 0.5)
            : metrics.selectedHaloColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(centerOffset, auraRadius, selectionFill);

      // 2. High-contrast accent border ring
      final selectionBorder = Paint()
        ..color = isDragging
            ? metrics.selectedNoteColor
            : metrics.selectedBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isDragging ? 2.0 : 1.5;
      canvas.drawCircle(centerOffset, auraRadius, selectionBorder);

      // 3. Subtle outer pulse ring
      final outerRing = Paint()
        ..color = metrics.selectedNoteColor
            .withValues(alpha: isDragging ? 0.35 : 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(centerOffset, auraRadius + 3.0, outerRing);

      // 4. Drag guideline if dragging
      if (isDragging && measureLeft != null && measureRight != null) {
        _paintDragGuideLine(
          canvas,
          y: noteY,
          measureLeft: measureLeft,
          measureRight: measureRight,
          metrics: metrics,
        );
      }
    }

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
        ..color = isSelected
            ? metrics.selectedNoteColor.withValues(alpha: 0.8)
            : metrics.staffColor
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
    if (isUnassigned && !isSelected) {
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
        ..strokeWidth = metrics.lineThickness * (isSelected ? 1.3 : 1.0)
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

    // -------------------------------------------------------------------------
    // Floating Pitch Indicator Badge (When note is selected)
    // -------------------------------------------------------------------------
    if (isSelected) {
      _paintPitchBadge(
        canvas,
        pitch: pitch,
        noteX: x,
        noteY: noteY,
        staffBottomY: staffBottomY,
        metrics: metrics,
        isDragging: isDragging,
      );
    }

    return RenderedNoteBox(
      noteId: event.id,
      sectionId: sectionId,
      measureNumber: measureNumber,
      eventIndex: eventIndex,
      bounds: Rect.fromLTWH(
        noteheadOffset.dx,
        noteheadOffset.dy,
        noteheadPainter.width,
        noteheadPainter.height,
      ),
      center: Offset(x, noteY),
      staffBottomY: staffBottomY,
      lineSpacing: metrics.lineSpacing,
      pitch: pitch,
    );
  }

  static void _paintRest(
    Canvas canvas, {
    required NoteEvent event,
    required double x,
    required double staffBottomY,
    required StaffMetrics metrics,
    bool isSelected = false,
  }) {
    final restGlyph = SmuflGlyphs.glyphForRest(event.rhythmicValue);
    final restColor =
        isSelected ? metrics.selectedNoteColor : metrics.staffColor;
    final restPainter = SmuflGlyphs.createPainter(
      glyph: restGlyph,
      fontSize: metrics.lineSpacing * 2.8,
      color: restColor,
    );

    // Center rest vertically in the staff (around line 3, middle line B4)
    final middleLineY = staffBottomY - (metrics.lineSpacing * 2.0);

    if (isSelected) {
      final auraRadius = metrics.lineSpacing * 1.25;
      final centerOffset = Offset(x, middleLineY);

      final selectionFill = Paint()
        ..color = metrics.selectedHaloColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(centerOffset, auraRadius, selectionFill);

      final selectionBorder = Paint()
        ..color = metrics.selectedBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(centerOffset, auraRadius, selectionBorder);
    }

    restPainter.paint(
      canvas,
      Offset(
        x - (restPainter.width / 2.0),
        middleLineY - (restPainter.height / 2.0),
      ),
    );
  }

  static void _paintPitchBadge(
    Canvas canvas, {
    required Pitch pitch,
    required double noteX,
    required double noteY,
    required double staffBottomY,
    required StaffMetrics metrics,
    required bool isDragging,
  }) {
    final accidentalSymbol = switch (pitch.accidental) {
      1 => '♯',
      -1 => '♭',
      2 => '𝄪',
      -2 => '𝄫',
      _ => '',
    };
    final pitchLabel = '${pitch.step.symbol}$accidentalSymbol${pitch.octave}';

    final textSpan = TextSpan(
      text: pitchLabel,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.bold,
        color: metrics.selectedBadgeTextColor,
        letterSpacing: 0.5,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    const paddingH = 6.0;
    const paddingV = 2.5;
    final badgeWidth = textPainter.width + (paddingH * 2);
    final badgeHeight = textPainter.height + (paddingV * 2);

    final staffTopY = staffBottomY - metrics.staffHeight;
    final highestRefY = noteY < staffTopY ? noteY : staffTopY;
    final badgeTopY =
        highestRefY - metrics.lineSpacing - badgeHeight - 4.0;
    final badgeLeft = noteX - (badgeWidth / 2.0);

    final badgeRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(badgeLeft, badgeTopY, badgeWidth, badgeHeight),
      const Radius.circular(6.0),
    );

    // Badge Background
    final bgPaint = Paint()
      ..color = metrics.selectedBadgeBgColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(badgeRRect, bgPaint);

    // Badge Border
    final borderPaint = Paint()
      ..color = metrics.selectedBorderColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(badgeRRect, borderPaint);

    // Text
    textPainter.paint(
      canvas,
      Offset(badgeLeft + paddingH, badgeTopY + paddingV),
    );

    // Pointer caret
    final pointerPath = Path()
      ..moveTo(noteX - 3.0, badgeTopY + badgeHeight)
      ..lineTo(noteX, badgeTopY + badgeHeight + 3.0)
      ..lineTo(noteX + 3.0, badgeTopY + badgeHeight)
      ..close();
    canvas.drawPath(pointerPath, bgPaint);
    canvas.drawLine(
      Offset(noteX - 3.0, badgeTopY + badgeHeight),
      Offset(noteX, badgeTopY + badgeHeight + 3.0),
      borderPaint,
    );
    canvas.drawLine(
      Offset(noteX, badgeTopY + badgeHeight + 3.0),
      Offset(noteX + 3.0, badgeTopY + badgeHeight),
      borderPaint,
    );
  }

  static void _paintDragGuideLine(
    Canvas canvas, {
    required double y,
    required double measureLeft,
    required double measureRight,
    required StaffMetrics metrics,
  }) {
    final guidePaint = Paint()
      ..color = metrics.selectedNoteColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    var currentX = measureLeft + 4.0;
    final endX = measureRight - 4.0;

    while (currentX < endX) {
      final segEnd =
          (currentX + dashWidth < endX) ? currentX + dashWidth : endX;
      canvas.drawLine(Offset(currentX, y), Offset(segEnd, y), guidePaint);
      currentX += dashWidth + dashSpace;
    }
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
