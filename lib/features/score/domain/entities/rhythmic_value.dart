/// Battuta — Rhythmic value representation.
///
/// Implements standard musical rhythm durations backed by MIDI ticks
/// with standard PPQ resolution of 480 ticks per quarter note.
library;

/// Represents an immutable duration for a note or rest in musical notation.
///
/// Standard PPQ (Pulses Per Quarter note) is 480 ticks:
/// - Whole note: 1920 ticks
/// - Half note: 960 ticks
/// - Quarter note: 480 ticks
/// - Eighth note: 240 ticks
/// - Sixteenth note: 120 ticks
/// - Thirty-second note: 60 ticks
///
/// Also provides helper constructors and getters for dotted values (1.5x)
/// and triplet subdivisions (2/3x).
class RhythmicValue implements Comparable<RhythmicValue> {
  const RhythmicValue({
    required this.ticks,
    required this.name,
    this.isDotted = false,
    this.isTriplet = false,
  }) : assert(ticks >= 0, 'Ticks cannot be negative');

  /// Creates a custom rhythmic value with the specified tick count.
  const RhythmicValue.custom({
    required int ticks,
    String? name,
    bool isDotted = false,
    bool isTriplet = false,
  }) : this(
         ticks: ticks,
         name: name ?? 'Custom(${ticks}t)',
         isDotted: isDotted,
         isTriplet: isTriplet,
       );

  /// Standard PPQ resolution: 480 ticks per quarter note.
  static const int ticksPerQuarterNote = 480;

  /// Duration in MIDI ticks.
  final int ticks;

  /// Human-readable name of the duration.
  final String name;

  /// Whether this duration is dotted (150% of the base duration).
  final bool isDotted;

  /// Whether this duration represents a triplet subdivision (2/3 of normal duration).
  final bool isTriplet;

  /// Converts this [RhythmicValue] to a JSON map.
  Map<String, dynamic> toJson() => {
    'ticks': ticks,
    'name': name,
    'isDotted': isDotted,
    'isTriplet': isTriplet,
  };

  /// Constructs a [RhythmicValue] from a JSON map.
  factory RhythmicValue.fromJson(Map<String, dynamic> json) => RhythmicValue(
    ticks: json['ticks'] as int,
    name: json['name'] as String,
    isDotted: json['isDotted'] as bool? ?? false,
    isTriplet: json['isTriplet'] as bool? ?? false,
  );

  // ---------------------------------------------------------------------------
  // Standard Note Durations
  // ---------------------------------------------------------------------------

  /// Unassigned duration (0 ticks), used for raw pitch events before rhythm quantization.
  static const RhythmicValue unassigned = RhythmicValue(
    ticks: 0,
    name: 'Unassigned',
  );

  /// Thirty-second note (1/32) — 60 ticks.
  static const RhythmicValue thirtySecond = RhythmicValue(
    ticks: 60,
    name: '32nd',
  );

  /// Sixteenth note (1/16) — 120 ticks.
  static const RhythmicValue sixteenth = RhythmicValue(
    ticks: 120,
    name: '16th',
  );

  /// Eighth note (1/8) — 240 ticks.
  static const RhythmicValue eighth = RhythmicValue(ticks: 240, name: '8th');

  /// Quarter note (1/4) — 480 ticks.
  static const RhythmicValue quarter = RhythmicValue(
    ticks: ticksPerQuarterNote,
    name: 'Quarter',
  );

  /// Half note (1/2) — 960 ticks.
  static const RhythmicValue half = RhythmicValue(
    ticks: ticksPerQuarterNote * 2,
    name: 'Half',
  );

  /// Whole note (1) — 1920 ticks.
  static const RhythmicValue whole = RhythmicValue(
    ticks: ticksPerQuarterNote * 4,
    name: 'Whole',
  );

  /// Double whole note (Breve) — 3840 ticks.
  static const RhythmicValue doubleWhole = RhythmicValue(
    ticks: ticksPerQuarterNote * 8,
    name: 'Double Whole',
  );

  // ---------------------------------------------------------------------------
  // Standard Dotted Durations
  // ---------------------------------------------------------------------------

  /// Dotted sixteenth note — 180 ticks.
  static const RhythmicValue dottedSixteenth = RhythmicValue(
    ticks: 180,
    name: 'Dotted 16th',
    isDotted: true,
  );

  /// Dotted eighth note — 360 ticks.
  static const RhythmicValue dottedEighth = RhythmicValue(
    ticks: 360,
    name: 'Dotted 8th',
    isDotted: true,
  );

  /// Dotted quarter note — 720 ticks.
  static const RhythmicValue dottedQuarter = RhythmicValue(
    ticks: 720,
    name: 'Dotted Quarter',
    isDotted: true,
  );

  /// Dotted half note — 1440 ticks.
  static const RhythmicValue dottedHalf = RhythmicValue(
    ticks: 1440,
    name: 'Dotted Half',
    isDotted: true,
  );

  /// Dotted whole note — 2880 ticks.
  static const RhythmicValue dottedWhole = RhythmicValue(
    ticks: 2880,
    name: 'Dotted Whole',
    isDotted: true,
  );

  // ---------------------------------------------------------------------------
  // Standard Triplet Durations
  // ---------------------------------------------------------------------------

  /// Sixteenth note triplet — 80 ticks.
  static const RhythmicValue sixteenthTriplet = RhythmicValue(
    ticks: 80,
    name: '16th Triplet',
    isTriplet: true,
  );

  /// Eighth note triplet — 160 ticks.
  static const RhythmicValue eighthTriplet = RhythmicValue(
    ticks: 160,
    name: '8th Triplet',
    isTriplet: true,
  );

  /// Quarter note triplet — 320 ticks.
  static const RhythmicValue quarterTriplet = RhythmicValue(
    ticks: 320,
    name: 'Quarter Triplet',
    isTriplet: true,
  );

  /// Half note triplet — 640 ticks.
  static const RhythmicValue halfTriplet = RhythmicValue(
    ticks: 640,
    name: 'Half Triplet',
    isTriplet: true,
  );

  // ---------------------------------------------------------------------------
  // Transformation & Convenience
  // ---------------------------------------------------------------------------

  /// Returns `true` if this duration is neutral/unassigned (0 ticks).
  bool get isUnassigned => ticks == 0;

  /// Returns a dotted equivalent duration (1.5x ticks).
  RhythmicValue get dotted {
    if (ticks == 0) return this;
    return RhythmicValue(
      ticks: ticks + (ticks ~/ 2),
      name: 'Dotted $name',
      isDotted: true,
      isTriplet: false,
    );
  }

  /// Returns a triplet equivalent duration (2/3x ticks).
  RhythmicValue get triplet {
    if (ticks == 0) return this;
    return RhythmicValue(
      ticks: (ticks * 2) ~/ 3,
      name: '$name Triplet',
      isDotted: false,
      isTriplet: true,
    );
  }

  /// Converts the tick duration to musical quarter-note beats.
  double toBeats([int beatUnitTicks = ticksPerQuarterNote]) {
    if (beatUnitTicks == 0) return 0.0;
    return ticks / beatUnitTicks;
  }

  @override
  int compareTo(RhythmicValue other) => ticks.compareTo(other.ticks);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RhythmicValue &&
          runtimeType == other.runtimeType &&
          ticks == other.ticks &&
          isDotted == other.isDotted &&
          isTriplet == other.isTriplet;

  @override
  int get hashCode => Object.hash(ticks, isDotted, isTriplet);

  @override
  String toString() => 'RhythmicValue($name, ${ticks}t)';
}
