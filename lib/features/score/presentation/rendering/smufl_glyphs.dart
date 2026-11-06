/// Battuta — Standard Music Font Layout (SMuFL) glyph constants & utilities.
///
/// Maps Unicode codepoints in the Private Use Area (PUA) according to the
/// Steinberg SMuFL v1.4+ specification used by the bundled Bravura font.
///
/// Enables crisp vector rendering via [TextPainter] across Retina iPad
/// and Mac displays at any arbitrary scale factor.
library;

import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:flutter/material.dart';

/// Standard SMuFL glyph codepoint constants and rendering helpers for Bravura.
abstract final class SmuflGlyphs {
  /// Font family registered in pubspec.yaml.
  static const String fontFamily = 'Bravura';

  // ---------------------------------------------------------------------------
  // Clefs (U+E050 - U+E07F)
  // ---------------------------------------------------------------------------

  /// Standard G-Clef (Treble Clef, \uE050).
  static const String gClef = '\uE050';

  /// Standard F-Clef (Bass Clef, \uE062).
  static const String fClef = '\uE062';

  /// Standard C-Clef (Alto/Tenor Clef, \uE05C).
  static const String cClef = '\uE05C';

  // ---------------------------------------------------------------------------
  // Noteheads (U+E0A0 - U+E0FF)
  // ---------------------------------------------------------------------------

  /// Double whole (breve) notehead (\uE0A0).
  static const String noteheadDoubleWhole = '\uE0A0';

  /// Whole (semibreve) notehead (\uE0A2).
  static const String noteheadWhole = '\uE0A2';

  /// Half (minim) notehead (\uE0A3).
  static const String noteheadHalf = '\uE0A3';

  /// Black notehead for quarter, eighth, sixteenth, and shorter notes (\uE0A4).
  static const String noteheadBlack = '\uE0A4';

  /// X-shaped notehead for ghost notes or percussive hits (\uE0A9).
  static const String noteheadXBlack = '\uE0A9';

  /// Diamond notehead for harmonics (\uE0DB).
  static const String noteheadDiamondBlack = '\uE0DB';

  // ---------------------------------------------------------------------------
  // Stems & Flags (U+E210 - U+E25F)
  // ---------------------------------------------------------------------------

  /// Standard stem glyph (\uE210).
  static const String stem = '\uE210';

  /// Eighth note flag up (\uE240).
  static const String flag8thUp = '\uE240';

  /// Eighth note flag down (\uE241).
  static const String flag8thDown = '\uE241';

  /// Sixteenth note flag up (\uE242).
  static const String flag16thUp = '\uE242';

  /// Sixteenth note flag down (\uE243).
  static const String flag16thDown = '\uE243';

  /// Thirty-second note flag up (\uE244).
  static const String flag32ndUp = '\uE244';

  /// Thirty-second note flag down (\uE245).
  static const String flag32ndDown = '\uE245';

  // ---------------------------------------------------------------------------
  // Accidentals (Standard SMuFL U+E260 - U+E26F)
  // ---------------------------------------------------------------------------

  /// Flat sign ♭ (\uE260).
  static const String accidentalFlat = '\uE260';

  /// Natural sign ♮ (\uE261).
  static const String accidentalNatural = '\uE261';

  /// Sharp sign ♯ (\uE262).
  static const String accidentalSharp = '\uE262';

  /// Double sharp sign 𝄪 (\uE263).
  static const String accidentalDoubleSharp = '\uE263';

  /// Double flat sign 𝄫 (\uE264).
  static const String accidentalDoubleFlat = '\uE264';

  // ---------------------------------------------------------------------------
  // Rests (U+E4E0 - U+E4FF)
  // ---------------------------------------------------------------------------

  /// Whole measure rest (\uE4E3).
  static const String restWhole = '\uE4E3';

  /// Half rest (\uE4E4).
  static const String restHalf = '\uE4E4';

  /// Quarter rest (\uE4E5).
  static const String restQuarter = '\uE4E5';

  /// Eighth rest (\uE4E6).
  static const String rest8th = '\uE4E6';

  /// Sixteenth rest (\uE4E7).
  static const String rest16th = '\uE4E7';

  /// Thirty-second rest (\uE4E8).
  static const String rest32nd = '\uE4E8';

  // ---------------------------------------------------------------------------
  // Barlines & Repeats (U+E030 - U+E04F)
  // ---------------------------------------------------------------------------

  /// Single thin barline (\uE030).
  static const String barlineSingle = '\uE030';

  /// Double barline (\uE031).
  static const String barlineDouble = '\uE031';

  /// Final barline (thin-thick, \uE032).
  static const String barlineFinal = '\uE032';

  /// Reverse final barline (\uE033).
  static const String barlineReverseFinal = '\uE033';

  /// Repeat left (begin repeat, \uE040).
  static const String repeatLeft = '\uE040';

  /// Repeat right (end repeat, \uE041).
  static const String repeatRight = '\uE041';

  /// Repeat both sides (\uE042).
  static const String repeatRightLeft = '\uE042';

  /// Colon repeat dots (\uE044).
  static const String repeatDots = '\uE044';

  // ---------------------------------------------------------------------------
  // Articulations & Fermatas (U+E4A0 - U+E4DF)
  // ---------------------------------------------------------------------------

  /// Fermata above note or barline (\uE4C0).
  static const String fermataAbove = '\uE4C0';

  /// Fermata below note or barline (\uE4C1).
  static const String fermataBelow = '\uE4C1';

  /// Augmentation dot for dotted rhythms (\uE1E7).
  static const String augmentationDot = '\uE1E7';

  /// Staccato dot above note (\uE4A2).
  static const String articStaccatoAbove = '\uE4A2';

  /// Tenuto mark above note (\uE4A4).
  static const String articTenutoAbove = '\uE4A4';

  /// Accent mark above note (\uE4A0).
  static const String articAccentAbove = '\uE4A0';

  // ---------------------------------------------------------------------------
  // Time Signature Digits (U+E080 - U+E09F)
  // ---------------------------------------------------------------------------

  /// Time signature digit 0 (\uE080).
  static const String timeSig0 = '\uE080';

  /// Time signature digit 1 (\uE081).
  static const String timeSig1 = '\uE081';

  /// Time signature digit 2 (\uE082).
  static const String timeSig2 = '\uE082';

  /// Time signature digit 3 (\uE083).
  static const String timeSig3 = '\uE083';

  /// Time signature digit 4 (\uE084).
  static const String timeSig4 = '\uE084';

  /// Time signature digit 5 (\uE085).
  static const String timeSig5 = '\uE085';

  /// Time signature digit 6 (\uE086).
  static const String timeSig6 = '\uE086';

  /// Time signature digit 7 (\uE087).
  static const String timeSig7 = '\uE087';

  /// Time signature digit 8 (\uE088).
  static const String timeSig8 = '\uE088';

  /// Time signature digit 9 (\uE089).
  static const String timeSig9 = '\uE089';

  /// Common time symbol C (\uE08A).
  static const String timeSigCommon = '\uE08A';

  /// Cut time symbol 𝄵 (\uE08B).
  static const String timeSigCutCommon = '\uE08B';

  // ---------------------------------------------------------------------------
  // Mapping Helpers
  // ---------------------------------------------------------------------------

  /// Returns the SMuFL notehead glyph corresponding to [rhythm].
  static String glyphForNotehead(RhythmicValue rhythm) {
    if (rhythm.ticks >= RhythmicValue.whole.ticks) {
      return noteheadWhole;
    } else if (rhythm.ticks >= RhythmicValue.half.ticks) {
      return noteheadHalf;
    } else {
      return noteheadBlack;
    }
  }

  /// Returns the SMuFL rest glyph corresponding to [rhythm].
  static String glyphForRest(RhythmicValue rhythm) {
    if (rhythm.ticks >= RhythmicValue.whole.ticks) {
      return restWhole;
    } else if (rhythm.ticks >= RhythmicValue.half.ticks) {
      return restHalf;
    } else if (rhythm.ticks >= RhythmicValue.quarter.ticks) {
      return restQuarter;
    } else if (rhythm.ticks >= RhythmicValue.eighth.ticks) {
      return rest8th;
    } else {
      return rest16th;
    }
  }

  /// Returns the accidental glyph for pitch modifier symbols ('#', 'b', 'n', etc.).
  static String? glyphForAccidental(String? accidental) {
    if (accidental == null) return null;
    return switch (accidental.trim().toLowerCase()) {
      '#' || 'sharp' || '♯' => accidentalSharp,
      'b' || 'flat' || '♭' => accidentalFlat,
      'n' || 'natural' || '♮' => accidentalNatural,
      '##' || 'x' || 'doublesharp' || '𝄪' => accidentalDoubleSharp,
      'bb' || 'doubleflat' || '𝄫' => accidentalDoubleFlat,
      _ => null,
    };
  }

  /// Returns the SMuFL time signature digit glyph for [digit] (0-9).
  static String glyphForTimeSigDigit(int digit) {
    return switch (digit) {
      0 => timeSig0,
      1 => timeSig1,
      2 => timeSig2,
      3 => timeSig3,
      4 => timeSig4,
      5 => timeSig5,
      6 => timeSig6,
      7 => timeSig7,
      8 => timeSig8,
      9 => timeSig9,
      _ => throw ArgumentError('Digit must be between 0 and 9, got $digit'),
    };
  }

  // ---------------------------------------------------------------------------
  // Flutter Rendering Helpers (TextPainter)
  // ---------------------------------------------------------------------------

  /// Creates a configured [TextPainter] for a SMuFL glyph.
  ///
  /// Guarantees crisp rendering across any scale factor on Retina displays.
  static TextPainter createPainter({
    required String glyph,
    required double fontSize,
    Color color = Colors.black,
    TextScaler textScaler = TextScaler.noScaling,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          color: color,
          height: 1.0,
        ),
      ),
      textDirection: textDirection,
      textScaler: textScaler,
    );
    textPainter.layout();
    return textPainter;
  }

  /// Paints a SMuFL glyph directly onto a [canvas] at the target [offset].
  static void paintGlyph(
    Canvas canvas,
    Offset offset, {
    required String glyph,
    required double fontSize,
    Color color = Colors.black,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final painter = createPainter(
      glyph: glyph,
      fontSize: fontSize,
      color: color,
      textScaler: textScaler,
    );
    painter.paint(canvas, offset);
  }
}
