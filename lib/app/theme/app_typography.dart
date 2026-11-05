/// Typography configuration for the Battuta music app.
///
/// Defines named [TextStyle]s for every textual role in the app — from
/// page titles down to tiny captions — plus music-specific styles for
/// chord symbols, lyrics, and staff annotations.
///
/// Styles are returned via [AppTypography.textTheme] (for wiring into
/// [ThemeData]) and via static accessors for music-domain styles that
/// don't map onto Material's [TextTheme] slots.
library;

import 'package:flutter/material.dart';

/// Central typography definitions.
///
/// Usage:
/// ```dart
/// // Material text theme (wired into ThemeData automatically):
/// final textTheme = AppTypography.textTheme;
///
/// // Music-specific styles:
/// Text('Am7', style: AppTypography.chordSymbol);
/// ```
final class AppTypography {
  const AppTypography._();

  // ── Font families ─────────────────────────────────────────────────────

  /// Primary font family for headings and body text.
  ///
  /// "Inter" is a clean, highly legible sans-serif with excellent
  /// weight range. Falls back to the platform default.
  static const String _primaryFamily = 'Inter';

  /// Monospaced font family used for chord symbols and tablature so that
  /// characters align vertically across lines.
  static const String _monoFamily = 'JetBrains Mono';

  /// Serif font family for lyric text, giving it a warm, printed feel.
  static const String _serifFamily = 'Merriweather';

  // ── Material TextTheme ────────────────────────────────────────────────

  /// A complete [TextTheme] that can be passed to [ThemeData.textTheme].
  ///
  /// The theme follows Material 3 type-scale naming.
  static TextTheme get textTheme => const TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: _primaryFamily,
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontFamily: _primaryFamily,
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontFamily: _primaryFamily,
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.22,
    ),

    // Headline — used for page titles and section headers.
    headlineLarge: TextStyle(
      fontFamily: _primaryFamily,
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontFamily: _primaryFamily,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontFamily: _primaryFamily,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.33,
    ),

    // Title — used for card titles, dialog titles.
    titleLarge: TextStyle(
      fontFamily: _primaryFamily,
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontFamily: _primaryFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.50,
    ),
    titleSmall: TextStyle(
      fontFamily: _primaryFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),

    // Body
    bodyLarge: TextStyle(
      fontFamily: _primaryFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.50,
    ),
    bodyMedium: TextStyle(
      fontFamily: _primaryFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontFamily: _primaryFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
    ),

    // Label
    labelLarge: TextStyle(
      fontFamily: _primaryFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontFamily: _primaryFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontFamily: _primaryFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
    ),
  );

  // ── Music-domain styles ───────────────────────────────────────────────

  /// Style for chord symbols displayed above lyrics (e.g. `Am7`, `D/F#`).
  ///
  /// Uses a monospaced font so chords align vertically when stacked
  /// above lyric syllables.
  static const TextStyle chordSymbol = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    height: 1.4,
  );

  /// Style for lyric text rendered in lead sheets.
  ///
  /// A serif font gives the lyrics a warm, songbook-like quality.
  static const TextStyle lyrics = TextStyle(
    fontFamily: _serifFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.6,
  );

  /// Style for section headers within a song (Verse, Chorus, Bridge…).
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: _primaryFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    height: 1.4,
  );

  /// Small annotations placed near the staff — dynamics, tempo markings,
  /// rehearsal letters, etc.
  static const TextStyle staffAnnotation = TextStyle(
    fontFamily: _serifFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    letterSpacing: 0.2,
    height: 1.3,
  );

  /// Tiny caption style for metadata, timestamps, and footnotes.
  static const TextStyle caption = TextStyle(
    fontFamily: _primaryFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.5,
  );

  /// BPM / tempo display in the live-session and metronome screens.
  static const TextStyle tempoDisplay = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 48,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.0,
    height: 1.1,
  );
}
