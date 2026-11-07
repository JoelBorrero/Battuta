/// Battuta — Lead Sheet PDF Service Interface.
///
/// Defines the contract and configuration options for generating printable,
/// high-contrast lead sheets in standard Letter and A4 page formats.
library;

import 'dart:typed_data';

import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:pdf/pdf.dart';

/// Configuration options for PDF lead sheet generation.
class PdfLeadSheetOptions {
  /// Creates immutable [PdfLeadSheetOptions].
  const PdfLeadSheetOptions({
    this.pageFormat = PdfPageFormat.letter,
    this.measuresPerSystem = 4,
    this.includeStaffMelodies = true,
    this.showMeasureNumbers = true,
    this.staffLineSpacing = 6.0,
    this.systemSpacing = 16.0,
    this.sectionSpacing = 14.0,
    this.highContrast = true,
  }) : assert(
         measuresPerSystem >= 1 && measuresPerSystem <= 8,
         'measuresPerSystem must be between 1 and 8',
       );

  /// Target paper size (e.g. [PdfPageFormat.letter] or [PdfPageFormat.a4]).
  final PdfPageFormat pageFormat;

  /// Number of measures rendered per horizontal staff system.
  final int measuresPerSystem;

  /// Whether to render full 5-line staff melodies with notes and rests.
  final bool includeStaffMelodies;

  /// Whether to render measure number badges on each measure.
  final bool showMeasureNumbers;

  /// Vertical spacing between adjacent staff lines in points.
  final double staffLineSpacing;

  /// Vertical spacing between consecutive systems in points.
  final double systemSpacing;

  /// Vertical spacing before a new section header in points.
  final double sectionSpacing;

  /// Whether to use high-contrast monochrome styling optimized for print.
  final bool highContrast;

  /// Staff height (4 spaces between 5 lines).
  double get staffHeight => 4 * staffLineSpacing;
}

/// Abstract service contract for generating printable PDF lead sheets.
abstract class LeadSheetPdfService {
  /// Generates the raw PDF bytes for [score] ready for file saving or sharing.
  Future<Uint8List> generatePdfBytes(
    Score score, {
    PdfLeadSheetOptions options = const PdfLeadSheetOptions(),
  });

  /// Sends [score] directly to the native printing system (AirPrint on iPadOS,
  /// CUPS Print Dialog on macOS).
  Future<bool> printLeadSheet(
    Score score, {
    PdfLeadSheetOptions options = const PdfLeadSheetOptions(),
    String? jobName,
  });

  /// Opens the system Share Sheet on iPadOS/macOS for AirDrop, saving to Files,
  /// Mail, or messaging.
  Future<bool> shareLeadSheet(
    Score score, {
    PdfLeadSheetOptions options = const PdfLeadSheetOptions(),
    String? fileName,
  });
}
