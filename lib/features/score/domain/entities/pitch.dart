/// Battuta — Musical pitch entity.
///
/// Models scientific pitch notation, diatonic and chromatic transposition,
/// MIDI note numbers, and acoustic frequency calculations.
library;

import 'dart:math' as math;

/// The diatonic pitch letters in Western music theory (C, D, E, F, G, A, B).
enum PitchStep {
  c('C', 0, 0),
  d('D', 1, 2),
  e('E', 2, 4),
  f('F', 3, 5),
  g('G', 4, 7),
  a('A', 5, 9),
  b('B', 6, 11);

  const PitchStep(this.symbol, this.stepIndex, this.semitoneOffset);

  /// Letter symbol (uppercase 'C', 'D', etc.).
  final String symbol;

  /// Zero-based diatonic step index within an octave (0 for C through 6 for B).
  final int stepIndex;

  /// Semitone offset from C in equal temperament (C=0, D=2, E=4, F=5, G=7, A=9, B=11).
  final int semitoneOffset;

  /// Retrieves a [PitchStep] from a diatonic step index (wrapping via modulo 7).
  static PitchStep fromIndex(int index) {
    final normalized = ((index % 7) + 7) % 7;
    return PitchStep.values[normalized];
  }

  /// Parses a letter string into a [PitchStep].
  static PitchStep fromSymbol(String s) {
    final upper = s.toUpperCase();
    for (final step in values) {
      if (step.symbol == upper) return step;
    }
    throw FormatException('Invalid pitch step symbol: "$s"');
  }
}

/// An immutable representation of an exact musical pitch.
///
/// Combines a diatonic [step] (C through B), an [accidental] offset (-2 to +2
/// semitones), and an [octave] integer (e.g. 4 for Middle C).
///
/// Supports parsing scientific pitch strings such as `'F5'`, `'C#4'`, and `'Bb4'`,
/// diatonic transposition preserving accidental structure across octave boundaries,
/// chromatic transposition, and standard MIDI / frequency queries.
class Pitch implements Comparable<Pitch> {
  /// Creates an immutable [Pitch].
  const Pitch({
    required this.step,
    this.accidental = 0,
    required this.octave,
  }) : assert(accidental >= -2 && accidental <= 2,
            'Accidental must be between -2 (double flat) and 2 (double sharp)');

  /// Creates a Middle C (C4) instance.
  static const Pitch middleC = Pitch(step: PitchStep.c, octave: 4);

  /// Creates Concert Pitch A4 (440 Hz, MIDI 69).
  static const Pitch concertA = Pitch(step: PitchStep.a, octave: 4);

  /// Diatonic letter name (C, D, E, F, G, A, B).
  final PitchStep step;

  /// Accidental modifier in semitones:
  /// - +2: Double sharp (## / x)
  /// - +1: Sharp (# / ♯)
  /// -  0: Natural
  /// - -1: Flat (b / ♭)
  /// - -2: Double flat (bb / 𝄫)
  final int accidental;

  /// Scientific pitch octave (e.g., 4 for C4).
  final int octave;

  // ---------------------------------------------------------------------------
  // Scientific Pitch String Parsing
  // ---------------------------------------------------------------------------

  static final RegExp _pitchRegex =
      RegExp(r'^([A-Ga-g])([#b♯♭x𝄪𝄫]*)(-?\d+)$');

  /// Parses a scientific pitch notation string (e.g., `'F5'`, `'C#4'`, `'Bb4'`).
  ///
  /// Throws [FormatException] if the string does not conform to valid scientific notation.
  factory Pitch.parse(String text) {
    final trimmed = text.trim();
    final match = _pitchRegex.firstMatch(trimmed);

    if (match == null) {
      throw FormatException(
        'Invalid scientific pitch notation: "$text". Expected format like "C4", "C#4", "Bb5".',
      );
    }

    final step = PitchStep.fromSymbol(match.group(1)!);
    final accidentalStr = match.group(2) ?? '';
    final octave = int.parse(match.group(3)!);

    return Pitch(
      step: step,
      accidental: _parseAccidental(accidentalStr),
      octave: octave,
    );
  }

  static int _parseAccidental(String str) {
    if (str.isEmpty) return 0;
    if (str == '#' || str == '♯') return 1;
    if (str == '##' || str == 'x' || str == '𝄪') return 2;
    if (str == 'b' || str == '♭') return -1;
    if (str == 'bb' || str == '𝄫') return -2;

    var acc = 0;
    for (final char in str.split('')) {
      if (char == '#' || char == '♯') {
        acc++;
      } else if (char == 'b' || char == '♭') {
        acc--;
      }
    }
    if (acc < -2 || acc > 2) {
      throw FormatException('Accidental out of range [-2, +2]: "$str"');
    }
    return acc;
  }

  // ---------------------------------------------------------------------------
  // Calculations & Accessors
  // ---------------------------------------------------------------------------

  /// Standard MIDI note number (C4 = 60, A4 = 69).
  int get midiNumber =>
      (octave + 1) * 12 + step.semitoneOffset + accidental;

  /// Fundamental acoustic frequency in Hertz (A4 = 440 Hz in equal temperament).
  double get frequencyHz =>
      440.0 * math.pow(2.0, (midiNumber - 69) / 12.0);

  /// String accidental representation (`"#"`, `"b"`, `"##"`, `"bb"`, or `""`).
  String get accidentalString {
    switch (accidental) {
      case 2:
        return '##';
      case 1:
        return '#';
      case -1:
        return 'b';
      case -2:
        return 'bb';
      default:
        return '';
    }
  }

  /// Full scientific pitch string (e.g., `"C#4"`, `"Bb4"`, `"F5"`).
  String get scientificNotation =>
      '${step.symbol}$accidentalString$octave';

  // ---------------------------------------------------------------------------
  // Transposition
  // ---------------------------------------------------------------------------

  /// Transposes this pitch diatonically by [deltaSteps].
  ///
  /// Diatonic transposition moves along the letter names (C, D, E, F, G, A, B)
  /// while preserving the current accidental inflection. Octaves adjust automatically
  /// when crossing the B-C boundary in either direction:
  ///
  /// ```dart
  /// Pitch.parse('F5').transposeDiatonic(1);  // G5
  /// Pitch.parse('F5').transposeDiatonic(-2); // D5
  /// Pitch.parse('C#4').transposeDiatonic(1); // D#4
  /// Pitch.parse('Bb4').transposeDiatonic(-1); // Ab4
  /// Pitch.parse('B4').transposeDiatonic(1);  // C5 (crosses octave boundary)
  /// Pitch.parse('C4').transposeDiatonic(-1); // B3 (crosses octave boundary)
  /// ```
  Pitch transposeDiatonic(int deltaSteps) {
    if (deltaSteps == 0) return this;

    final currentTotalSteps = (octave * 7) + step.stepIndex;
    final targetTotalSteps = currentTotalSteps + deltaSteps;

    final newOctave = (targetTotalSteps / 7).floor();
    final newStep = PitchStep.fromIndex(targetTotalSteps);

    return Pitch(
      step: newStep,
      accidental: accidental,
      octave: newOctave,
    );
  }

  /// Transposes this pitch chromatically by a given number of [semitones].
  ///
  /// When [preferSharps] is true, uses sharp spelling for altered notes;
  /// otherwise uses flat spelling.
  Pitch transposeChromatic(int semitones, {bool preferSharps = true}) {
    if (semitones == 0) return this;
    return Pitch.fromMidi(midiNumber + semitones, preferSharps: preferSharps);
  }

  /// Reconstructs a [Pitch] from a standard [midiNumber].
  factory Pitch.fromMidi(int midiNumber, {bool preferSharps = true}) {
    final octave = (midiNumber ~/ 12) - 1;
    final semitoneInOctave = midiNumber % 12;

    PitchStep step;
    int accidental;

    switch (semitoneInOctave) {
      case 0:
        step = PitchStep.c;
        accidental = 0;
      case 1:
        if (preferSharps) {
          step = PitchStep.c;
          accidental = 1;
        } else {
          step = PitchStep.d;
          accidental = -1;
        }
      case 2:
        step = PitchStep.d;
        accidental = 0;
      case 3:
        if (preferSharps) {
          step = PitchStep.d;
          accidental = 1;
        } else {
          step = PitchStep.e;
          accidental = -1;
        }
      case 4:
        step = PitchStep.e;
        accidental = 0;
      case 5:
        step = PitchStep.f;
        accidental = 0;
      case 6:
        if (preferSharps) {
          step = PitchStep.f;
          accidental = 1;
        } else {
          step = PitchStep.g;
          accidental = -1;
        }
      case 7:
        step = PitchStep.g;
        accidental = 0;
      case 8:
        if (preferSharps) {
          step = PitchStep.g;
          accidental = 1;
        } else {
          step = PitchStep.a;
          accidental = -1;
        }
      case 9:
        step = PitchStep.a;
        accidental = 0;
      case 10:
        if (preferSharps) {
          step = PitchStep.a;
          accidental = 1;
        } else {
          step = PitchStep.b;
          accidental = -1;
        }
      case 11:
        step = PitchStep.b;
        accidental = 0;
      default:
        throw StateError('Invalid semitone calculation: $semitoneInOctave');
    }

    return Pitch(
      step: step,
      accidental: accidental,
      octave: octave,
    );
  }

  @override
  int compareTo(Pitch other) {
    final midiComparison = midiNumber.compareTo(other.midiNumber);
    if (midiComparison != 0) return midiComparison;
    final octComparison = octave.compareTo(other.octave);
    if (octComparison != 0) return octComparison;
    final stepComparison = step.stepIndex.compareTo(other.step.stepIndex);
    if (stepComparison != 0) return stepComparison;
    return accidental.compareTo(other.accidental);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pitch &&
          runtimeType == other.runtimeType &&
          step == other.step &&
          accidental == other.accidental &&
          octave == other.octave;

  @override
  int get hashCode => Object.hash(step, accidental, octave);

  @override
  String toString() => scientificNotation;
}
