/// Battuta — Printable Lead Sheet PDF Generator.
///
/// Renders high-contrast, publication-quality printable PDF lead sheets containing:
/// - Song metadata (title, artist, composer, key, meter, tempo, CCLI license)
/// - Section navigation boxes ([VERSE 1], [CHORUS] x 2)
/// - Chord grids positioned with precise metric offsets
/// - Repeat barlines (|: and :|), standard barlines, and final double barlines
/// - 5-line staff melodies with vector treble clef, time signatures, notes,
///   stems, ledger lines, accidentals, rests, and ties
/// - Multi-page pagination formatted for Letter and A4 ready for AirPrint & file sharing.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:battuta/features/score/domain/services/lead_sheet_pdf_service.dart';
import 'package:battuta/features/score/presentation/rendering/staff_pitch_mapper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Implementation of [LeadSheetPdfService] using the `pdf` and `printing` packages.
class PdfLeadSheetGenerator implements LeadSheetPdfService {
  /// Creates a [PdfLeadSheetGenerator].
  const PdfLeadSheetGenerator();

  @override
  Future<Uint8List> generatePdfBytes(
    Score score, {
    PdfLeadSheetOptions options = const PdfLeadSheetOptions(),
  }) async {
    final doc = buildDocument(score, options: options);
    return doc.save();
  }

  @override
  Future<bool> printLeadSheet(
    Score score, {
    PdfLeadSheetOptions options = const PdfLeadSheetOptions(),
    String? jobName,
  }) async {
    final bytes = await generatePdfBytes(score, options: options);
    return Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: jobName ?? score.title,
      format: options.pageFormat,
    );
  }

  @override
  Future<bool> shareLeadSheet(
    Score score, {
    PdfLeadSheetOptions options = const PdfLeadSheetOptions(),
    String? fileName,
  }) async {
    final bytes = await generatePdfBytes(score, options: options);
    final sanitizedTitle =
        score.title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final actualFileName = fileName ?? '$sanitizedTitle.pdf';
    return Printing.sharePdf(
      bytes: bytes,
      filename: actualFileName,
    );
  }

  /// Builds a complete [pw.Document] tree for [score].
  pw.Document buildDocument(
    Score score, {
    PdfLeadSheetOptions options = const PdfLeadSheetOptions(),
  }) {
    final doc = pw.Document(
      title: score.title,
      author: score.artist ?? score.composer ?? 'Battuta',
      subject: 'Lead Sheet - ${score.keySignature} (${score.tempo} BPM)',
      creator: 'Battuta Worship Companion',
    );

    final font = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();
    final italicFont = pw.Font.helveticaOblique();

    // Available horizontal width inside page margins
    // Letter width = 612, A4 width = 595.28; margins: 36 on each side -> ~523 to ~540
    final printableWidth = options.pageFormat.width - 72.0;

    doc.addPage(
      pw.MultiPage(
        pageFormat: options.pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        header: (context) => _buildPageHeader(
          context,
          score,
          italicFont,
        ),
        footer: (context) => _buildPageFooter(
          context,
          score,
          font,
        ),
        build: (context) => [
          // -------------------------------------------------------------------
          // 1. Song Title & Header Metadata (First Page)
          // -------------------------------------------------------------------
          _buildSongHeader(score, font, boldFont),
          pw.SizedBox(height: options.sectionSpacing),

          // -------------------------------------------------------------------
          // 2. Sections & Staff Systems
          // -------------------------------------------------------------------
          ..._buildSections(
            score: score,
            options: options,
            font: font,
            boldFont: boldFont,
            printableWidth: printableWidth,
          ),
        ],
      ),
    );

    return doc;
  }

  // ===========================================================================
  // Header, Footer & Song Meta
  // ===========================================================================

  pw.Widget _buildPageHeader(
    pw.Context context,
    Score score,
    pw.Font italicFont,
  ) {
    if (context.pageNumber <= 1) {
      return pw.SizedBox.shrink();
    }
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            score.title.toUpperCase(),
            style: pw.TextStyle(
              font: italicFont,
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            'Key of ${score.keySignature} | ${score.timeSignature.numerator}/${score.timeSignature.denominator}',
            style: pw.TextStyle(
              font: italicFont,
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPageFooter(
    pw.Context context,
    Score score,
    pw.Font font,
  ) {
    final ccli = score.metadata['ccli']?.toString();
    final copyright = score.metadata['copyright']?.toString();

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            [
              'Battuta Lead Sheet',
              if (ccli != null) 'CCLI #$ccli',
              ?copyright?.replaceAll('©', '(c)'),
            ].join(' | '),
            style: pw.TextStyle(
              font: font,
              fontSize: 7.5,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              font: font,
              fontSize: 7.5,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSongHeader(
    Score score,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final artistOrComposer = [
      if (score.artist != null && score.artist!.isNotEmpty) score.artist!,
      if (score.composer != null &&
          score.composer!.isNotEmpty &&
          score.composer != score.artist)
        'Arr. ${score.composer!}',
    ].join(' | ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          score.title.toUpperCase(),
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (artistOrComposer.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            artistOrComposer,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey800,
            ),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Key: ${score.keySignature}',
              style: pw.TextStyle(font: boldFont, fontSize: 9.5),
            ),
            pw.Text(
              'Meter: ${score.timeSignature.numerator}/${score.timeSignature.denominator}',
              style: pw.TextStyle(font: boldFont, fontSize: 9.5),
            ),
            pw.Text(
              'Tempo: ${score.tempo} BPM',
              style: pw.TextStyle(font: boldFont, fontSize: 9.5),
            ),
            pw.Text(
              'Bars: ${score.totalMeasures}',
              style: pw.TextStyle(font: font, fontSize: 9.5),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(thickness: 1.2, color: PdfColors.black),
      ],
    );
  }

  // ===========================================================================
  // Section Navigation Box & Systems
  // ===========================================================================

  List<pw.Widget> _buildSections({
    required Score score,
    required PdfLeadSheetOptions options,
    required pw.Font font,
    required pw.Font boldFont,
    required double printableWidth,
  }) {
    final widgets = <pw.Widget>[];
    var isFirstSystemInScore = true;

    for (var sIdx = 0; sIdx < score.sections.length; sIdx++) {
      final section = score.sections[sIdx];

      // Section Navigation Box
      widgets.add(
        _buildSectionHeader(section, boldFont),
      );
      widgets.add(pw.SizedBox(height: 6));

      // Systems for this section
      final measures = section.measures;
      if (measures.isEmpty) {
        widgets.add(pw.SizedBox(height: options.systemSpacing));
        continue;
      }

      final perSys = options.measuresPerSystem;
      for (var mStart = 0; mStart < measures.length; mStart += perSys) {
        final mEnd = math.min(mStart + perSys, measures.length);
        final systemMeasures = measures.sublist(mStart, mEnd);
        final isFirstSystemOfSection = (mStart == 0);
        final isLastSystemOfSection = (mEnd == measures.length);
        final isLastSectionInScore = (sIdx == score.sections.length - 1);

        widgets.add(
          _buildSystem(
            systemMeasures: systemMeasures,
            section: section,
            isFirstSystemInScore: isFirstSystemInScore,
            isFirstSystemOfSection: isFirstSystemOfSection,
            isLastSystemOfSection: isLastSystemOfSection,
            isLastSectionInScore: isLastSectionInScore,
            options: options,
            font: font,
            boldFont: boldFont,
            printableWidth: printableWidth,
          ),
        );

        isFirstSystemInScore = false;
        widgets.add(pw.SizedBox(height: options.systemSpacing));
      }

      // Spacing between sections
      if (sIdx < score.sections.length - 1) {
        widgets.add(pw.SizedBox(height: options.sectionSpacing));
      }
    }

    return widgets;
  }

  pw.Widget _buildSectionHeader(Section section, pw.Font boldFont) {
    final repeatSuffix =
        section.repeatCount > 1 ? ' x ${section.repeatCount}' : '';
    final label = '[${section.name.toUpperCase()}]$repeatSuffix';

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1.2),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            color: PdfColors.grey200,
          ),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        if (section.externalSyncId != null) ...[
          pw.SizedBox(width: 6),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey500, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
            child: pw.Text(
              'Sync: ${section.externalSyncId}',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // System Renderer (5-Line Staff, Clef, Barlines, Chords, Notes)
  // ===========================================================================

  pw.Widget _buildSystem({
    required List<Measure> systemMeasures,
    required Section section,
    required bool isFirstSystemInScore,
    required bool isFirstSystemOfSection,
    required bool isLastSystemOfSection,
    required bool isLastSectionInScore,
    required PdfLeadSheetOptions options,
    required pw.Font font,
    required pw.Font boldFont,
    required double printableWidth,
  }) {
    // Height allocation:
    // Chords row: top 18pt
    // Staff lines: from y = 24.0 to y = 48.0 (4 spaces * 6.0pt = 24pt staff)
    // Bottom area: y = 0.0 to 24.0 (for ledger lines <= C4 and downward stems)
    const systemHeight = 72.0;
    const staffBaseY = 24.0;
    final lineSpacing = options.staffLineSpacing;
    final staffTopY = staffBaseY + (4 * lineSpacing); // 48.0

    // Measure layout calculation
    const clefAreaWidth = 26.0;
    final timeSigAreaWidth = isFirstSystemInScore ? 18.0 : 0.0;
    final systemPrefixWidth = clefAreaWidth + timeSigAreaWidth;
    final measureAreaWidth = printableWidth - systemPrefixWidth;
    final measureWidth = measureAreaWidth / systemMeasures.length;

    // Collect positioned chord widgets
    final chordWidgets = <pw.Widget>[];

    for (var mIdx = 0; mIdx < systemMeasures.length; mIdx++) {
      final measure = systemMeasures[mIdx];
      final measureLeft = systemPrefixWidth + (mIdx * measureWidth);

      // Measure number indicator
      if (options.showMeasureNumbers) {
        chordWidgets.add(
          pw.Positioned(
            left: measureLeft + 3.0,
            top: 14.0,
            child: pw.Text(
              '${measure.number}',
              style: pw.TextStyle(
                font: font,
                fontSize: 6.5,
                color: PdfColors.grey600,
              ),
            ),
          ),
        );
      }

      // Chord symbols
      if (measure.chords.isNotEmpty) {
        final totalTicks = measure.timeSignature.maxTicks > 0
            ? measure.timeSignature.maxTicks
            : 1920;

        for (final chord in measure.chords) {
          final ratio = (chord.tickOffset / totalTicks).clamp(0.0, 0.85);
          final chordX = measureLeft + (ratio * measureWidth) + 4.0;

          chordWidgets.add(
            pw.Positioned(
              left: chordX,
              top: 0.0,
              child: pw.Text(
                chord.text,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );
        }
      }
    }

    return pw.Container(
      height: systemHeight,
      width: printableWidth,
      child: pw.Stack(
        children: [
          // Background Vector Canvas (Staff, Clef, Barlines, Notes)
          pw.CustomPaint(
            size: PdfPoint(printableWidth, systemHeight),
            painter: (PdfGraphics canvas, PdfPoint size) {
              _paintStaffSystem(
                canvas: canvas,
                systemWidth: printableWidth,
                systemMeasures: systemMeasures,
                section: section,
                isFirstSystemInScore: isFirstSystemInScore,
                isFirstSystemOfSection: isFirstSystemOfSection,
                isLastSystemOfSection: isLastSystemOfSection,
                isLastSectionInScore: isLastSectionInScore,
                options: options,
                staffBaseY: staffBaseY,
                staffTopY: staffTopY,
                systemPrefixWidth: systemPrefixWidth,
                clefAreaWidth: clefAreaWidth,
                measureWidth: measureWidth,
              );
            },
          ),
          // Foreground Chords & Measure Number Text
          ...chordWidgets,
        ],
      ),
    );
  }

  // ===========================================================================
  // Vector Painting: Staff Lines, Clef, Barlines, Notes & Rests
  // ===========================================================================

  void _paintStaffSystem({
    required PdfGraphics canvas,
    required double systemWidth,
    required List<Measure> systemMeasures,
    required Section section,
    required bool isFirstSystemInScore,
    required bool isFirstSystemOfSection,
    required bool isLastSystemOfSection,
    required bool isLastSectionInScore,
    required PdfLeadSheetOptions options,
    required double staffBaseY,
    required double staffTopY,
    required double systemPrefixWidth,
    required double clefAreaWidth,
    required double measureWidth,
  }) {
    canvas.setColor(PdfColors.black);
    canvas.setStrokeColor(PdfColors.black);
    canvas.setFillColor(PdfColors.black);

    // -------------------------------------------------------------------------
    // 1. Draw 5 Staff Lines
    // -------------------------------------------------------------------------
    canvas.setLineWidth(0.65);
    for (var i = 0; i < 5; i++) {
      final y = staffBaseY + (i * options.staffLineSpacing);
      canvas.drawLine(0, y, systemWidth, y);
    }
    canvas.strokePath();

    // -------------------------------------------------------------------------
    // 2. Draw Vector Treble Clef
    // -------------------------------------------------------------------------
    _paintTrebleClef(canvas, 4.0, staffBaseY, options.staffLineSpacing);

    // -------------------------------------------------------------------------
    // 3. Draw Time Signature (on first system of score)
    // -------------------------------------------------------------------------
    if (isFirstSystemInScore && systemMeasures.isNotEmpty) {
      final ts = systemMeasures.first.timeSignature;
      _paintTimeSignatureDigits(
        canvas,
        clefAreaWidth + 2.0,
        staffBaseY,
        options.staffLineSpacing,
        ts.numerator,
        ts.denominator,
      );
    }

    // -------------------------------------------------------------------------
    // 4. Measure Barlines & Staff Melodies
    // -------------------------------------------------------------------------
    final measureCount = systemMeasures.length;

    for (var i = 0; i < measureCount; i++) {
      final measure = systemMeasures[i];
      final measureLeft = systemPrefixWidth + (i * measureWidth);
      final measureRight = measureLeft + measureWidth;
      final isFirstMeasureOfSection = (isFirstSystemOfSection && i == 0);
      final isLastMeasureOfSection =
          (isLastSystemOfSection && i == measureCount - 1);
      final isFinalBarline = (isLastSectionInScore && isLastMeasureOfSection);

      // Left Barline
      if (i == 0) {
        if (isFirstMeasureOfSection && section.repeatCount > 1) {
          _paintRepeatBarline(
            canvas,
            systemPrefixWidth,
            staffBaseY,
            staffTopY,
            isLeft: true,
            lineSpacing: options.staffLineSpacing,
          );
        } else {
          canvas.setLineWidth(0.8);
          canvas.drawLine(
              systemPrefixWidth, staffBaseY, systemPrefixWidth, staffTopY);
          canvas.strokePath();
        }
      }

      // Right Barline
      if (isFinalBarline) {
        _paintFinalBarline(canvas, measureRight, staffBaseY, staffTopY);
      } else if (isLastMeasureOfSection && section.repeatCount > 1) {
        _paintRepeatBarline(
          canvas,
          measureRight,
          staffBaseY,
          staffTopY,
          isLeft: false,
          lineSpacing: options.staffLineSpacing,
        );
      } else {
        canvas.setLineWidth(0.8);
        canvas.drawLine(measureRight, staffBaseY, measureRight, staffTopY);
        canvas.strokePath();
      }

      // -----------------------------------------------------------------------
      // 5. Draw Measure Notes and Rests
      // -----------------------------------------------------------------------
      if (options.includeStaffMelodies && measure.events.isNotEmpty) {
        _paintMeasureNotes(
          canvas: canvas,
          measure: measure,
          measureLeft: measureLeft,
          measureWidth: measureWidth,
          staffBaseY: staffBaseY,
          lineSpacing: options.staffLineSpacing,
        );
      }
    }
  }

  // ===========================================================================
  // Treble Clef, Time Signature & Barlines Vectors
  // ===========================================================================

  void _paintTrebleClef(
    PdfGraphics canvas,
    double x,
    double staffBaseY,
    double lineSpacing,
  ) {
    canvas.saveContext();
    canvas.setStrokeColor(PdfColors.black);
    canvas.setFillColor(PdfColors.black);
    canvas.setLineWidth(1.1);

    // G4 line is at staffBaseY + 1 * lineSpacing
    final g4Y = staffBaseY + lineSpacing;

    // Treble Clef vertical spine with bottom curl
    canvas.drawLine(x + 8.0, staffBaseY - 6.0, x + 8.0, staffBaseY + 28.0);
    canvas.strokePath();

    // Bottom teardrop/hook
    canvas.drawEllipse(x + 6.0, staffBaseY - 6.0, 1.8, 1.8);
    canvas.fillPath();

    // Top loop
    canvas.moveTo(x + 8.0, staffBaseY + 28.0);
    canvas.curveTo(
      x + 13.0,
      staffBaseY + 24.0,
      x + 13.0,
      staffBaseY + 18.0,
      x + 8.0,
      staffBaseY + 15.0,
    );
    canvas.strokePath();

    // Middle spiral around G4 (2nd line)
    canvas.moveTo(x + 8.0, staffBaseY + 15.0);
    canvas.curveTo(
      x + 2.0,
      staffBaseY + 14.0,
      x + 2.0,
      g4Y - 3.0,
      x + 8.0,
      g4Y - 3.0,
    );
    canvas.curveTo(
      x + 14.0,
      g4Y - 3.0,
      x + 14.0,
      g4Y + 4.0,
      x + 8.0,
      g4Y + 4.0,
    );
    canvas.strokePath();

    canvas.restoreContext();
  }

  void _paintTimeSignatureDigits(
    PdfGraphics canvas,
    double x,
    double staffBaseY,
    double lineSpacing,
    int numerator,
    int denominator,
  ) {
    canvas.saveContext();
    canvas.setStrokeColor(PdfColors.black);
    canvas.setLineWidth(1.4);

    // Top digit (numerator) centered around line 3 (staffBaseY + 3*lineSpacing)
    final numY = staffBaseY + (2.5 * lineSpacing);
    _paintDigit(canvas, x + 3.0, numY, numerator, lineSpacing * 1.6);

    // Bottom digit (denominator) centered around line 1 (staffBaseY + 1*lineSpacing)
    final denY = staffBaseY + (0.5 * lineSpacing);
    _paintDigit(canvas, x + 3.0, denY, denominator, lineSpacing * 1.6);

    canvas.restoreContext();
  }

  void _paintDigit(
    PdfGraphics canvas,
    double x,
    double y,
    int digit,
    double h,
  ) {
    final w = h * 0.65;
    if (digit == 4) {
      canvas.drawLine(x + w, y, x + w, y + h);
      canvas.drawLine(x, y + (h * 0.35), x + w + 1, y + (h * 0.35));
      canvas.drawLine(x, y + (h * 0.35), x + (w * 0.7), y + h);
      canvas.strokePath();
    } else if (digit == 3) {
      canvas.drawLine(x, y + h, x + w, y + h);
      canvas.drawLine(x + w, y + h, x + (w * 0.4), y + (h * 0.5));
      canvas.drawLine(x + (w * 0.4), y + (h * 0.5), x + w, y + (h * 0.5));
      canvas.drawLine(x + w, y + (h * 0.5), x + w, y);
      canvas.drawLine(x + w, y, x, y);
      canvas.strokePath();
    } else if (digit == 2) {
      canvas.drawLine(x, y + h, x + w, y + h);
      canvas.drawLine(x + w, y + h, x + w, y + (h * 0.6));
      canvas.drawLine(x + w, y + (h * 0.6), x, y);
      canvas.drawLine(x, y, x + w, y);
      canvas.strokePath();
    } else if (digit == 6) {
      canvas.drawLine(x + w, y + h, x, y + (h * 0.5));
      canvas.drawRect(x, y, w, h * 0.5);
      canvas.strokePath();
    } else if (digit == 8) {
      canvas.drawRect(x, y + (h * 0.5), w, h * 0.5);
      canvas.drawRect(x, y, w, h * 0.5);
      canvas.strokePath();
    } else {
      // Default vertical stroke with top serif
      canvas.drawLine(x + (w * 0.5), y, x + (w * 0.5), y + h);
      canvas.strokePath();
    }
  }

  void _paintRepeatBarline(
    PdfGraphics canvas,
    double x,
    double staffBaseY,
    double staffTopY, {
    required bool isLeft,
    required double lineSpacing,
  }) {
    canvas.saveContext();
    canvas.setStrokeColor(PdfColors.black);
    canvas.setFillColor(PdfColors.black);

    const thickWidth = 2.8;
    const thinWidth = 0.8;
    const barSpacing = 2.4;
    const dotRadius = 1.6;

    if (isLeft) {
      // Left Repeat (|:)
      // Heavy thick bar on left
      canvas.setLineWidth(thickWidth);
      canvas.drawLine(x, staffBaseY, x, staffTopY);
      canvas.strokePath();

      // Thin bar
      final thinX = x + thickWidth + barSpacing;
      canvas.setLineWidth(thinWidth);
      canvas.drawLine(thinX, staffBaseY, thinX, staffTopY);
      canvas.strokePath();

      // Repeat dots (in spaces 1 and 2: staffBaseY + 1.5*spacing and + 2.5*spacing)
      final dotX = thinX + barSpacing + 2.0;
      canvas.drawEllipse(dotX, staffBaseY + (1.5 * lineSpacing), dotRadius, dotRadius);
      canvas.drawEllipse(dotX, staffBaseY + (2.5 * lineSpacing), dotRadius, dotRadius);
      canvas.fillPath();
    } else {
      // Right Repeat (:|)
      // Repeat dots
      final dotX = x - thickWidth - barSpacing - 4.0;
      canvas.drawEllipse(dotX, staffBaseY + (1.5 * lineSpacing), dotRadius, dotRadius);
      canvas.drawEllipse(dotX, staffBaseY + (2.5 * lineSpacing), dotRadius, dotRadius);
      canvas.fillPath();

      // Thin bar
      final thinX = x - thickWidth - barSpacing;
      canvas.setLineWidth(thinWidth);
      canvas.drawLine(thinX, staffBaseY, thinX, staffTopY);
      canvas.strokePath();

      // Heavy thick bar on right
      canvas.setLineWidth(thickWidth);
      canvas.drawLine(x, staffBaseY, x, staffTopY);
      canvas.strokePath();
    }

    canvas.restoreContext();
  }

  void _paintFinalBarline(
    PdfGraphics canvas,
    double x,
    double staffBaseY,
    double staffTopY,
  ) {
    canvas.saveContext();
    canvas.setStrokeColor(PdfColors.black);

    // Thin bar
    canvas.setLineWidth(0.8);
    canvas.drawLine(x - 3.5, staffBaseY, x - 3.5, staffTopY);
    canvas.strokePath();

    // Heavy bar
    canvas.setLineWidth(2.8);
    canvas.drawLine(x, staffBaseY, x, staffTopY);
    canvas.strokePath();

    canvas.restoreContext();
  }

  // ===========================================================================
  // Noteheads, Ledger Lines, Stems, Rests & Ties
  // ===========================================================================

  void _paintMeasureNotes({
    required PdfGraphics canvas,
    required Measure measure,
    required double measureLeft,
    required double measureWidth,
    required double staffBaseY,
    required double lineSpacing,
  }) {
    final totalTicks = measure.timeSignature.maxTicks > 0
        ? measure.timeSignature.maxTicks
        : 1920;

    const leftMargin = 8.0;
    final usableWidth = measureWidth - (leftMargin * 2.0);
    final events = measure.events;

    for (var eIdx = 0; eIdx < events.length; eIdx++) {
      final event = events[eIdx];
      final tickRatio = (event.tickOffset / totalTicks).clamp(0.0, 0.95);
      final noteX = measureLeft + leftMargin + (tickRatio * usableWidth);

      if (event.pitch != null) {
        final pitch = event.pitch!;
        final step = StaffPitchMapper.stepFromE4(pitch);
        final pitchY = staffBaseY + (step * (lineSpacing / 2.0));

        // 1. Ledger Lines
        _paintLedgerLines(canvas, noteX, pitch, staffBaseY, lineSpacing);

        // 2. Notehead
        final isHollow = event.rhythmicValue == RhythmicValue.whole ||
            event.rhythmicValue == RhythmicValue.half;

        canvas.saveContext();
        canvas.setStrokeColor(PdfColors.black);
        canvas.setFillColor(PdfColors.black);

        if (isHollow) {
          canvas.setLineWidth(1.2);
          canvas.drawEllipse(noteX, pitchY, 3.8, 2.8);
          canvas.strokePath();
        } else {
          canvas.drawEllipse(noteX, pitchY, 3.8, 2.8);
          canvas.fillPath();
        }

        // 3. Stem (for notes other than whole notes)
        if (event.rhythmicValue != RhythmicValue.whole) {
          _paintNoteStem(
            canvas: canvas,
            noteX: noteX,
            pitchY: pitchY,
            step: step,
            rhythmicValue: event.rhythmicValue,
          );
        }

        // 4. Accidental (# or b)
        if (pitch.accidental != 0) {
          _paintAccidental(canvas, noteX - 7.0, pitchY, pitch.accidental);
        }

        // 5. Tie
        if (event.isTied) {
          final nextX = (eIdx < events.length - 1)
              ? measureLeft +
                  leftMargin +
                  ((events[eIdx + 1].tickOffset / totalTicks)
                          .clamp(0.0, 0.95) *
                      usableWidth)
              : measureLeft + measureWidth;
          _paintTie(canvas, noteX, nextX, pitchY, step < 4);
        }

        canvas.restoreContext();
      } else if (event.isRest) {
        // Rest Symbol
        _paintRest(
          canvas: canvas,
          x: noteX,
          staffBaseY: staffBaseY,
          lineSpacing: lineSpacing,
          rhythmicValue: event.rhythmicValue,
        );
      }
    }
  }

  void _paintLedgerLines(
    PdfGraphics canvas,
    double noteX,
    dynamic pitch,
    double staffBaseY,
    double lineSpacing,
  ) {
    final step = StaffPitchMapper.stepFromE4(pitch);
    final stepHeight = lineSpacing / 2.0;

    canvas.saveContext();
    canvas.setStrokeColor(PdfColors.black);
    canvas.setLineWidth(0.8);

    if (step <= -2) {
      // Bottom ledger lines: <= C4
      final limit = step.isEven ? step : step + 1;
      for (var s = -2; s >= limit; s -= 2) {
        final ly = staffBaseY + (s * stepHeight);
        canvas.drawLine(noteX - 6.0, ly, noteX + 6.0, ly);
      }
      canvas.strokePath();
    } else if (step >= 10) {
      // Top ledger lines: >= A5
      final limit = step.isEven ? step : step - 1;
      for (var s = 10; s <= limit; s += 2) {
        final ly = staffBaseY + (s * stepHeight);
        canvas.drawLine(noteX - 6.0, ly, noteX + 6.0, ly);
      }
      canvas.strokePath();
    }

    canvas.restoreContext();
  }

  void _paintNoteStem({
    required PdfGraphics canvas,
    required double noteX,
    required double pitchY,
    required int step,
    required RhythmicValue rhythmicValue,
  }) {
    canvas.saveContext();
    canvas.setStrokeColor(PdfColors.black);
    canvas.setFillColor(PdfColors.black);
    canvas.setLineWidth(0.85);

    const stemHeight = 18.0;

    if (step < 4) {
      // Upward Stem on Right edge
      final stemX = noteX + 3.4;
      final stemTop = pitchY + stemHeight;
      canvas.drawLine(stemX, pitchY, stemX, stemTop);
      canvas.strokePath();

      // Flag for eighth note
      if (rhythmicValue == RhythmicValue.eighth ||
          rhythmicValue == RhythmicValue.dottedEighth) {
        canvas.drawLine(stemX, stemTop, stemX + 3.8, stemTop - 6.0);
        canvas.strokePath();
      } else if (rhythmicValue == RhythmicValue.sixteenth) {
        canvas.drawLine(stemX, stemTop, stemX + 3.8, stemTop - 6.0);
        canvas.drawLine(stemX, stemTop - 3.5, stemX + 3.8, stemTop - 9.5);
        canvas.strokePath();
      }
    } else {
      // Downward Stem on Left edge
      final stemX = noteX - 3.4;
      final stemBottom = pitchY - stemHeight;
      canvas.drawLine(stemX, pitchY, stemX, stemBottom);
      canvas.strokePath();

      // Flag for eighth note
      if (rhythmicValue == RhythmicValue.eighth ||
          rhythmicValue == RhythmicValue.dottedEighth) {
        canvas.drawLine(stemX, stemBottom, stemX + 3.8, stemBottom + 6.0);
        canvas.strokePath();
      } else if (rhythmicValue == RhythmicValue.sixteenth) {
        canvas.drawLine(stemX, stemBottom, stemX + 3.8, stemBottom + 6.0);
        canvas.drawLine(stemX, stemBottom + 3.5, stemX + 3.8, stemBottom + 9.5);
        canvas.strokePath();
      }
    }

    canvas.restoreContext();
  }

  void _paintAccidental(
    PdfGraphics canvas,
    double x,
    double y,
    int accidental,
  ) {
    canvas.saveContext();
    canvas.setStrokeColor(PdfColors.black);
    canvas.setLineWidth(0.9);

    if (accidental == 1) {
      // Sharp (#)
      canvas.drawLine(x - 2, y - 5, x - 2, y + 5);
      canvas.drawLine(x + 2, y - 5, x + 2, y + 5);
      canvas.drawLine(x - 4, y - 1, x + 4, y + 1);
      canvas.drawLine(x - 4, y + 2, x + 4, y + 4);
      canvas.strokePath();
    } else if (accidental == -1) {
      // Flat (b)
      canvas.drawLine(x - 2, y - 4, x - 2, y + 6);
      canvas.drawEllipse(x, y - 1, 2.0, 2.5);
      canvas.strokePath();
    }

    canvas.restoreContext();
  }

  void _paintTie(
    PdfGraphics canvas,
    double startX,
    double endX,
    double y,
    bool under,
  ) {
    canvas.saveContext();
    canvas.setStrokeColor(PdfColors.black);
    canvas.setLineWidth(0.9);

    final midX = (startX + endX) / 2.0;
    final arcOffset = under ? -4.5 : 4.5;

    canvas.moveTo(startX + 3.0, y);
    canvas.curveTo(midX, y + arcOffset, midX, y + arcOffset, endX - 3.0, y);
    canvas.strokePath();

    canvas.restoreContext();
  }

  void _paintRest({
    required PdfGraphics canvas,
    required double x,
    required double staffBaseY,
    required double lineSpacing,
    required RhythmicValue rhythmicValue,
  }) {
    canvas.saveContext();
    canvas.setStrokeColor(PdfColors.black);
    canvas.setFillColor(PdfColors.black);

    if (rhythmicValue == RhythmicValue.whole) {
      // Whole rest: hanging box below line 3
      final line3Y = staffBaseY + (3 * lineSpacing);
      canvas.drawRect(x - 3.5, line3Y - 3.0, 7.0, 3.0);
      canvas.fillPath();
    } else if (rhythmicValue == RhythmicValue.half ||
        rhythmicValue == RhythmicValue.dottedHalf) {
      // Half rest: sitting box on line 2
      final line2Y = staffBaseY + (2 * lineSpacing);
      canvas.drawRect(x - 3.5, line2Y, 7.0, 3.0);
      canvas.fillPath();
    } else if (rhythmicValue == RhythmicValue.eighth ||
        rhythmicValue == RhythmicValue.dottedEighth) {
      // Eighth rest: diagonal slash with upper-left hook
      final midY = staffBaseY + (2 * lineSpacing);
      canvas.setLineWidth(1.1);
      canvas.drawLine(x + 1.5, midY - 4.0, x - 1.5, midY + 4.0);
      canvas.drawEllipse(x - 3.0, midY + 3.0, 1.2, 1.2);
      canvas.strokePath();
      canvas.fillPath();
    } else {
      // Quarter rest: zigzag vertical glyph centered in staff
      final midY = staffBaseY + (2 * lineSpacing);
      canvas.setLineWidth(1.2);
      canvas.drawLine(x - 2.0, midY + 5.0, x + 2.0, midY + 2.0);
      canvas.drawLine(x + 2.0, midY + 2.0, x - 2.0, midY - 1.0);
      canvas.drawLine(x - 2.0, midY - 1.0, x + 2.0, midY - 4.0);
      canvas.strokePath();
    }

    canvas.restoreContext();
  }
}
