/// Battuta — Time signature entity.
///
/// Encapsulates meter, beats per measure, beat subdivisions,
/// and maximum measure capacity in MIDI ticks.
library;

import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';

/// Immutable representation of a musical time signature (meter).
///
/// Calculates precise tick capacities for measures based on a standard
/// 480 PPQ quarter-note resolution.
class TimeSignature {
  /// Creates a [TimeSignature] with the given [numerator] and [denominator].
  ///
  /// [numerator] is the count of beats per measure (must be > 0).
  /// [denominator] is the note value representing one beat (must be a power of 2).
  const TimeSignature(this.numerator, this.denominator)
      : assert(numerator > 0, 'Numerator must be greater than zero'),
        assert(denominator > 0, 'Denominator must be greater than zero'),
        assert((denominator & (denominator - 1)) == 0,
            'Denominator must be a power of 2 (1, 2, 4, 8, 16, 32)');

  /// Number of beats per measure (e.g., 4 in 4/4, 3 in 3/4, 6 in 6/8).
  final int numerator;

  /// Beat unit represented as an inverted fraction (e.g., 4 for quarter note, 8 for eighth note).
  final int denominator;

  // ---------------------------------------------------------------------------
  // Common Predefined Meters
  // ---------------------------------------------------------------------------

  /// 4/4 Common Time (1920 ticks).
  static const TimeSignature fourFour = TimeSignature(4, 4);

  /// Common Time alias for 4/4.
  static const TimeSignature commonTime = fourFour;

  /// 3/4 Waltz / Ballad meter (1440 ticks).
  static const TimeSignature threeFour = TimeSignature(3, 4);

  /// 2/4 March meter (960 ticks).
  static const TimeSignature twoFour = TimeSignature(2, 4);

  /// 6/8 Compound duple meter (1440 ticks).
  static const TimeSignature sixEight = TimeSignature(6, 8);

  /// 9/8 Compound triple meter (2160 ticks).
  static const TimeSignature nineEight = TimeSignature(9, 8);

  /// 12/8 Compound quadruple meter (2880 ticks).
  static const TimeSignature twelveEight = TimeSignature(12, 8);

  /// 2/2 Cut time / Alla breve (1920 ticks).
  static const TimeSignature twoTwo = TimeSignature(2, 2);

  /// Cut Time alias for 2/2.
  static const TimeSignature cutTime = twoTwo;

  /// 5/4 Complex / Asymmetric meter (2400 ticks).
  static const TimeSignature fiveFour = TimeSignature(5, 4);

  /// 5/8 Complex / Asymmetric meter (1200 ticks).
  static const TimeSignature fiveEight = TimeSignature(5, 8);

  /// 7/8 Complex / Asymmetric meter (1680 ticks).
  static const TimeSignature sevenEight = TimeSignature(7, 8);

  // ---------------------------------------------------------------------------
  // Capacity & Metric Calculations
  // ---------------------------------------------------------------------------

  /// Maximum capacity of a single measure in MIDI ticks.
  ///
  /// Formula: `numerator * (wholeNoteTicks ~/ denominator)`.
  /// For 4/4: 4 * (1920 ~/ 4) = 1920 ticks.
  /// For 3/4: 3 * (1920 ~/ 4) = 1440 ticks.
  /// For 6/8: 6 * (1920 ~/ 8) = 1440 ticks.
  int get maxTicks =>
      numerator * ((RhythmicValue.ticksPerQuarterNote * 4) ~/ denominator);

  /// Duration of a single denominator beat in MIDI ticks.
  int get ticksPerBeat =>
      (RhythmicValue.ticksPerQuarterNote * 4) ~/ denominator;

  /// Whether this is a compound meter (e.g., 6/8, 9/8, 12/8).
  bool get isCompound =>
      numerator % 3 == 0 && numerator > 3 && denominator == 8;

  /// Number of macro beats in compound meters (e.g. 2 for 6/8, 4 for 12/8)
  /// or simple beats for simple meters.
  int get beatCount => isCompound ? numerator ~/ 3 : numerator;

  /// Duration of a primary macro beat in MIDI ticks.
  ///
  /// In compound meters (e.g. 6/8), a macro beat is 3 eighth notes (720 ticks).
  /// In simple meters, a macro beat equals [ticksPerBeat].
  int get macroBeatTicks => isCompound ? ticksPerBeat * 3 : ticksPerBeat;

  /// Checks whether a given [tickDuration] fits within a single measure of this meter.
  bool canAccommodateTicks(int tickDuration) => tickDuration <= maxTicks;

  /// Parses a string representation such as `"4/4"`, `"3/4"`, `"C"`, or `"cut"`.
  factory TimeSignature.parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Cannot parse empty time signature');
    }

    if (trimmed == 'C' || trimmed == 'c') return fourFour;
    if (trimmed == '¢' ||
        trimmed.toLowerCase() == 'cut' ||
        trimmed.toLowerCase() == 'alla breve') {
      return twoTwo;
    }

    final parts = trimmed.split('/');
    if (parts.length != 2) {
      throw FormatException('Invalid time signature format: "$text"');
    }

    final num = int.tryParse(parts[0].trim());
    final den = int.tryParse(parts[1].trim());

    if (num == null || den == null) {
      throw FormatException(
          'Time signature components must be integers: "$text"');
    }

    return TimeSignature(num, den);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSignature &&
          runtimeType == other.runtimeType &&
          numerator == other.numerator &&
          denominator == other.denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => '$numerator/$denominator';
}
