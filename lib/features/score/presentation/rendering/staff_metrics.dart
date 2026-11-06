/// Battuta — Staff canvas metrics and styling configurations.
///
/// Encapsulates geometric and typographic parameters for rendering 5-line
/// staves, chords, barlines, navigation boxes, and volta brackets.
library;

import 'package:flutter/material.dart';

/// Configuration parameters for music notation canvas rendering.
class StaffMetrics {
  /// Creates a [StaffMetrics] configuration.
  const StaffMetrics({
    this.lineSpacing = 10.0,
    this.lineThickness = 1.2,
    this.staffColor = const Color(0xFF1E293B),
    this.barlineThickness = 1.5,
    this.heavyBarlineThickness = 3.5,
    this.systemSpacing = 42.0,
    this.headerSpacing = 28.0,
    this.measuresPerSystem = 4,
    this.leftPadding = 16.0,
    this.rightPadding = 16.0,
    this.topPadding = 16.0,
    this.bottomPadding = 24.0,
    this.clefFontSize = 36.0,
    this.timeSigFontSize = 26.0,
    this.chordFontSize = 14.0,
    this.sectionHeaderFontSize = 13.0,
    this.voltaHeight = 20.0,
    this.headerBadgeColor = const Color(0xFFE2E8F0),
    this.headerBadgeBorderColor = const Color(0xFF94A3B8),
    this.headerTextColor = const Color(0xFF0F172A),
    this.chordColor = const Color(0xFF0F766E),
    this.selectedNoteColor = const Color(0xFFE5A93C),
    this.selectedHaloColor = const Color(0x38E5A93C),
    this.selectedBorderColor = const Color(0xFFE5A93C),
    this.selectedBadgeBgColor = const Color(0xFF1A1C20),
    this.selectedBadgeTextColor = const Color(0xFFE5A93C),
  });

  /// Factory creating [StaffMetrics] styled for the active [ThemeData] (Dark / Light mode).
  factory StaffMetrics.fromTheme(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return StaffMetrics(
      staffColor: isDark ? const Color(0xFFCAC4D0) : const Color(0xFF24272C),
      headerBadgeColor:
          isDark ? const Color(0xFF2D3138) : const Color(0xFFF1F3F5),
      headerBadgeBorderColor:
          isDark ? const Color(0xFF3A3D44) : const Color(0xFFE1E4E8),
      headerTextColor:
          isDark ? const Color(0xFFF2F2F2) : const Color(0xFF1A1C20),
      chordColor:
          isDark ? const Color(0xFFFFB800) : const Color(0xFF0F766E),
      selectedNoteColor: const Color(0xFFE5A93C),
      selectedHaloColor: const Color(0x38E5A93C),
      selectedBorderColor: const Color(0xFFE5A93C),
      selectedBadgeBgColor:
          isDark ? const Color(0xFF24272C) : const Color(0xFFFFFFFF),
      selectedBadgeTextColor:
          isDark ? const Color(0xFFE5A93C) : const Color(0xFFC7831C),
    );
  }

  /// Distance in logical pixels between adjacent lines of a 5-line staff.
  final double lineSpacing;

  /// Stroke width of staff lines.
  final double lineThickness;

  /// Primary color for staff lines and standard barlines.
  final Color staffColor;

  /// Stroke width of standard single barlines.
  final double barlineThickness;

  /// Stroke width of heavy / final / repeat barlines.
  final double heavyBarlineThickness;

  /// Vertical gap between consecutive staff systems.
  final double systemSpacing;

  /// Vertical margin between section header and the first staff system.
  final double headerSpacing;

  /// Default number of measures to render per horizontal system line.
  final int measuresPerSystem;

  /// Horizontal inset from the left canvas edge.
  final double leftPadding;

  /// Horizontal inset from the right canvas edge.
  final double rightPadding;

  /// Top padding of the entire score canvas.
  final double topPadding;

  /// Bottom padding of the entire score canvas.
  final double bottomPadding;

  /// Font size for SMuFL clef glyphs.
  final double clefFontSize;

  /// Font size for SMuFL time signature digits.
  final double timeSigFontSize;

  /// Font size for chord symbols drawn above the staff.
  final double chordFontSize;

  /// Font size for section navigation blocks (e.g. [CORO]).
  final double sectionHeaderFontSize;

  /// Height of volta brackets / repeat endings (casillas).
  final double voltaHeight;

  /// Fill color for section header badges.
  final Color headerBadgeColor;

  /// Border color for section header badges.
  final Color headerBadgeBorderColor;

  /// Text color for section header navigation boxes.
  final Color headerTextColor;

  /// Text color for chord symbols.
  final Color chordColor;

  /// Accent color for the selected notehead, stems, accidentals, and flags.
  final Color selectedNoteColor;

  /// Soft glowing aura fill color behind the selected notehead.
  final Color selectedHaloColor;

  /// High-contrast border outline for the selected note ring.
  final Color selectedBorderColor;

  /// Background color for the floating pitch tooltip badge.
  final Color selectedBadgeBgColor;

  /// Text color for the floating pitch tooltip badge.
  final Color selectedBadgeTextColor;

  /// Height of the 5-line staff (4 inter-line spaces).
  double get staffHeight => lineSpacing * 4.0;

  /// Vertical space above the staff reserved for chord symbols and volta brackets.
  double get spaceAboveStaff => chordFontSize + voltaHeight + 8.0;

  /// Total height of a single system row.
  double get systemRowHeight => spaceAboveStaff + staffHeight + systemSpacing;

  /// Creates a copy of [StaffMetrics] with overridden values.
  StaffMetrics copyWith({
    double? lineSpacing,
    double? lineThickness,
    Color? staffColor,
    double? barlineThickness,
    double? heavyBarlineThickness,
    double? systemSpacing,
    double? headerSpacing,
    int? measuresPerSystem,
    double? leftPadding,
    double? rightPadding,
    double? topPadding,
    double? bottomPadding,
    double? clefFontSize,
    double? timeSigFontSize,
    double? chordFontSize,
    double? sectionHeaderFontSize,
    double? voltaHeight,
    Color? headerBadgeColor,
    Color? headerBadgeBorderColor,
    Color? headerTextColor,
    Color? chordColor,
    Color? selectedNoteColor,
    Color? selectedHaloColor,
    Color? selectedBorderColor,
    Color? selectedBadgeBgColor,
    Color? selectedBadgeTextColor,
  }) {
    return StaffMetrics(
      lineSpacing: lineSpacing ?? this.lineSpacing,
      lineThickness: lineThickness ?? this.lineThickness,
      staffColor: staffColor ?? this.staffColor,
      barlineThickness: barlineThickness ?? this.barlineThickness,
      heavyBarlineThickness:
          heavyBarlineThickness ?? this.heavyBarlineThickness,
      systemSpacing: systemSpacing ?? this.systemSpacing,
      headerSpacing: headerSpacing ?? this.headerSpacing,
      measuresPerSystem: measuresPerSystem ?? this.measuresPerSystem,
      leftPadding: leftPadding ?? this.leftPadding,
      rightPadding: rightPadding ?? this.rightPadding,
      topPadding: topPadding ?? this.topPadding,
      bottomPadding: bottomPadding ?? this.bottomPadding,
      clefFontSize: clefFontSize ?? this.clefFontSize,
      timeSigFontSize: timeSigFontSize ?? this.timeSigFontSize,
      chordFontSize: chordFontSize ?? this.chordFontSize,
      sectionHeaderFontSize:
          sectionHeaderFontSize ?? this.sectionHeaderFontSize,
      voltaHeight: voltaHeight ?? this.voltaHeight,
      headerBadgeColor: headerBadgeColor ?? this.headerBadgeColor,
      headerBadgeBorderColor:
          headerBadgeBorderColor ?? this.headerBadgeBorderColor,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      chordColor: chordColor ?? this.chordColor,
      selectedNoteColor: selectedNoteColor ?? this.selectedNoteColor,
      selectedHaloColor: selectedHaloColor ?? this.selectedHaloColor,
      selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
      selectedBadgeBgColor: selectedBadgeBgColor ?? this.selectedBadgeBgColor,
      selectedBadgeTextColor:
          selectedBadgeTextColor ?? this.selectedBadgeTextColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffMetrics &&
          runtimeType == other.runtimeType &&
          lineSpacing == other.lineSpacing &&
          lineThickness == other.lineThickness &&
          staffColor == other.staffColor &&
          barlineThickness == other.barlineThickness &&
          heavyBarlineThickness == other.heavyBarlineThickness &&
          systemSpacing == other.systemSpacing &&
          headerSpacing == other.headerSpacing &&
          measuresPerSystem == other.measuresPerSystem &&
          leftPadding == other.leftPadding &&
          rightPadding == other.rightPadding &&
          topPadding == other.topPadding &&
          bottomPadding == other.bottomPadding &&
          clefFontSize == other.clefFontSize &&
          timeSigFontSize == other.timeSigFontSize &&
          chordFontSize == other.chordFontSize &&
          sectionHeaderFontSize == other.sectionHeaderFontSize &&
          voltaHeight == other.voltaHeight &&
          headerBadgeColor == other.headerBadgeColor &&
          headerBadgeBorderColor == other.headerBadgeBorderColor &&
          headerTextColor == other.headerTextColor &&
          chordColor == other.chordColor &&
          selectedNoteColor == other.selectedNoteColor &&
          selectedHaloColor == other.selectedHaloColor &&
          selectedBorderColor == other.selectedBorderColor &&
          selectedBadgeBgColor == other.selectedBadgeBgColor &&
          selectedBadgeTextColor == other.selectedBadgeTextColor;

  @override
  int get hashCode => Object.hashAll([
        lineSpacing,
        lineThickness,
        staffColor,
        barlineThickness,
        heavyBarlineThickness,
        systemSpacing,
        headerSpacing,
        measuresPerSystem,
        leftPadding,
        rightPadding,
        topPadding,
        bottomPadding,
        clefFontSize,
        timeSigFontSize,
        chordFontSize,
        sectionHeaderFontSize,
        voltaHeight,
        headerBadgeColor,
        headerBadgeBorderColor,
        headerTextColor,
        chordColor,
        selectedNoteColor,
        selectedHaloColor,
        selectedBorderColor,
        selectedBadgeBgColor,
        selectedBadgeTextColor,
      ]);
}
