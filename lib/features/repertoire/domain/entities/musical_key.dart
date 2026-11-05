/// Battuta — Musical key value object.
///
/// A comprehensive representation of musical keys covering all 30 standard
/// keys (15 major + 15 minor, including enharmonic equivalents). Built on
/// the circle of fifths for correct transposition, relative/parallel key
/// lookups, and accidental counting.
///
/// This is a pure Dart value object — no Flutter or code-generation
/// dependencies.
library;

/// An immutable value object representing a musical key.
///
/// Provides:
/// - [transpose] — shift by any number of semitones
/// - [relative] — the relative major or minor key
/// - [parallel] — the parallel major or minor key
/// - [accidentals] — count of sharps (+) or flats (−) in the key signature
/// - Factory [fromString] with validation
///
/// ```dart
/// final key = MusicalKey.cMajor;
/// print(key.transpose(7)); // G Major
/// print(key.relative);     // A Minor
/// ```
class MusicalKey {
  /// Creates a [MusicalKey].
  ///
  /// Prefer the named constants (e.g., [MusicalKey.cMajor]) or the
  /// [MusicalKey.fromString] factory for validated construction.
  const MusicalKey._({
    required this.name,
    required this.isMinor,
    required this.semitoneIndex,
    required this.accidentalCount,
  });

  /// The display name of this key (e.g., `"C"`, `"F#"`, `"Bbm"`).
  final String name;

  /// Whether this is a minor key.
  final bool isMinor;

  /// Semitone offset from C (0–11), used internally for transposition.
  final int semitoneIndex;

  /// Number of accidentals in the key signature.
  ///
  /// Positive values are sharps, negative values are flats.
  final int accidentalCount;

  // ---------------------------------------------------------------------------
  // Major keys
  // ---------------------------------------------------------------------------

  /// C Major — no accidentals.
  static const cMajor = MusicalKey._(
    name: 'C',
    isMinor: false,
    semitoneIndex: 0,
    accidentalCount: 0,
  );

  /// G Major — 1 sharp.
  static const gMajor = MusicalKey._(
    name: 'G',
    isMinor: false,
    semitoneIndex: 7,
    accidentalCount: 1,
  );

  /// D Major — 2 sharps.
  static const dMajor = MusicalKey._(
    name: 'D',
    isMinor: false,
    semitoneIndex: 2,
    accidentalCount: 2,
  );

  /// A Major — 3 sharps.
  static const aMajor = MusicalKey._(
    name: 'A',
    isMinor: false,
    semitoneIndex: 9,
    accidentalCount: 3,
  );

  /// E Major — 4 sharps.
  static const eMajor = MusicalKey._(
    name: 'E',
    isMinor: false,
    semitoneIndex: 4,
    accidentalCount: 4,
  );

  /// B Major — 5 sharps.
  static const bMajor = MusicalKey._(
    name: 'B',
    isMinor: false,
    semitoneIndex: 11,
    accidentalCount: 5,
  );

  /// F# Major — 6 sharps.
  static const fSharpMajor = MusicalKey._(
    name: 'F#',
    isMinor: false,
    semitoneIndex: 6,
    accidentalCount: 6,
  );

  /// C# Major — 7 sharps.
  static const cSharpMajor = MusicalKey._(
    name: 'C#',
    isMinor: false,
    semitoneIndex: 1,
    accidentalCount: 7,
  );

  /// F Major — 1 flat.
  static const fMajor = MusicalKey._(
    name: 'F',
    isMinor: false,
    semitoneIndex: 5,
    accidentalCount: -1,
  );

  /// Bb Major — 2 flats.
  static const bbMajor = MusicalKey._(
    name: 'Bb',
    isMinor: false,
    semitoneIndex: 10,
    accidentalCount: -2,
  );

  /// Eb Major — 3 flats.
  static const ebMajor = MusicalKey._(
    name: 'Eb',
    isMinor: false,
    semitoneIndex: 3,
    accidentalCount: -3,
  );

  /// Ab Major — 4 flats.
  static const abMajor = MusicalKey._(
    name: 'Ab',
    isMinor: false,
    semitoneIndex: 8,
    accidentalCount: -4,
  );

  /// Db Major — 5 flats.
  static const dbMajor = MusicalKey._(
    name: 'Db',
    isMinor: false,
    semitoneIndex: 1,
    accidentalCount: -5,
  );

  /// Gb Major — 6 flats.
  static const gbMajor = MusicalKey._(
    name: 'Gb',
    isMinor: false,
    semitoneIndex: 6,
    accidentalCount: -6,
  );

  /// Cb Major — 7 flats.
  static const cbMajor = MusicalKey._(
    name: 'Cb',
    isMinor: false,
    semitoneIndex: 11,
    accidentalCount: -7,
  );

  // ---------------------------------------------------------------------------
  // Minor keys
  // ---------------------------------------------------------------------------

  /// A Minor — no accidentals.
  static const aMinor = MusicalKey._(
    name: 'Am',
    isMinor: true,
    semitoneIndex: 9,
    accidentalCount: 0,
  );

  /// E Minor — 1 sharp.
  static const eMinor = MusicalKey._(
    name: 'Em',
    isMinor: true,
    semitoneIndex: 4,
    accidentalCount: 1,
  );

  /// B Minor — 2 sharps.
  static const bMinor = MusicalKey._(
    name: 'Bm',
    isMinor: true,
    semitoneIndex: 11,
    accidentalCount: 2,
  );

  /// F# Minor — 3 sharps.
  static const fSharpMinor = MusicalKey._(
    name: 'F#m',
    isMinor: true,
    semitoneIndex: 6,
    accidentalCount: 3,
  );

  /// C# Minor — 4 sharps.
  static const cSharpMinor = MusicalKey._(
    name: 'C#m',
    isMinor: true,
    semitoneIndex: 1,
    accidentalCount: 4,
  );

  /// G# Minor — 5 sharps.
  static const gSharpMinor = MusicalKey._(
    name: 'G#m',
    isMinor: true,
    semitoneIndex: 8,
    accidentalCount: 5,
  );

  /// D# Minor — 6 sharps.
  static const dSharpMinor = MusicalKey._(
    name: 'D#m',
    isMinor: true,
    semitoneIndex: 3,
    accidentalCount: 6,
  );

  /// A# Minor — 7 sharps.
  static const aSharpMinor = MusicalKey._(
    name: 'A#m',
    isMinor: true,
    semitoneIndex: 10,
    accidentalCount: 7,
  );

  /// D Minor — 1 flat.
  static const dMinor = MusicalKey._(
    name: 'Dm',
    isMinor: true,
    semitoneIndex: 2,
    accidentalCount: -1,
  );

  /// G Minor — 2 flats.
  static const gMinor = MusicalKey._(
    name: 'Gm',
    isMinor: true,
    semitoneIndex: 7,
    accidentalCount: -2,
  );

  /// C Minor — 3 flats.
  static const cMinor = MusicalKey._(
    name: 'Cm',
    isMinor: true,
    semitoneIndex: 0,
    accidentalCount: -3,
  );

  /// F Minor — 4 flats.
  static const fMinor = MusicalKey._(
    name: 'Fm',
    isMinor: true,
    semitoneIndex: 5,
    accidentalCount: -4,
  );

  /// Bb Minor — 5 flats.
  static const bbMinor = MusicalKey._(
    name: 'Bbm',
    isMinor: true,
    semitoneIndex: 10,
    accidentalCount: -5,
  );

  /// Eb Minor — 6 flats.
  static const ebMinor = MusicalKey._(
    name: 'Ebm',
    isMinor: true,
    semitoneIndex: 3,
    accidentalCount: -6,
  );

  /// Ab Minor — 7 flats.
  static const abMinor = MusicalKey._(
    name: 'Abm',
    isMinor: true,
    semitoneIndex: 8,
    accidentalCount: -7,
  );

  // ---------------------------------------------------------------------------
  // Collections
  // ---------------------------------------------------------------------------

  /// All 15 major keys in circle-of-fifths order (C → sharps, then flats).
  static const List<MusicalKey> majorKeys = [
    cMajor,
    gMajor,
    dMajor,
    aMajor,
    eMajor,
    bMajor,
    fSharpMajor,
    cSharpMajor,
    fMajor,
    bbMajor,
    ebMajor,
    abMajor,
    dbMajor,
    gbMajor,
    cbMajor,
  ];

  /// All 15 minor keys in circle-of-fifths order (Am → sharps, then flats).
  static const List<MusicalKey> minorKeys = [
    aMinor,
    eMinor,
    bMinor,
    fSharpMinor,
    cSharpMinor,
    gSharpMinor,
    dSharpMinor,
    aSharpMinor,
    dMinor,
    gMinor,
    cMinor,
    fMinor,
    bbMinor,
    ebMinor,
    abMinor,
  ];

  /// All 30 keys (major + minor).
  static const List<MusicalKey> allKeys = [...majorKeys, ...minorKeys];

  // ---------------------------------------------------------------------------
  // Chromatic note tables (used for transposition)
  // ---------------------------------------------------------------------------

  /// Sharp-preferring chromatic scale.
  static const _sharpNotes = [
    'C', 'C#', 'D', 'D#', 'E', 'F',
    'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  /// Flat-preferring chromatic scale.
  static const _flatNotes = [
    'C', 'Db', 'D', 'Eb', 'E', 'F',
    'Gb', 'G', 'Ab', 'A', 'Bb', 'B',
  ];

  // ---------------------------------------------------------------------------
  // Lookup map (built lazily)
  // ---------------------------------------------------------------------------

  static final Map<String, MusicalKey> _byName = {
    for (final key in allKeys) key.name.toLowerCase(): key,
  };

  // ---------------------------------------------------------------------------
  // Factory
  // ---------------------------------------------------------------------------

  /// Parses a key string such as `"C"`, `"F#"`, `"Bbm"`, or `"G#m"`.
  ///
  /// Throws [ArgumentError] if [value] does not match any known key.
  factory MusicalKey.fromString(String value) {
    final normalized = value.trim().toLowerCase();
    final result = _byName[normalized];
    if (result == null) {
      throw ArgumentError.value(
        value,
        'value',
        'Unknown musical key. Valid keys: '
            '${allKeys.map((k) => k.name).join(", ")}',
      );
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  /// Whether this key uses sharps in its key signature.
  bool get useSharps => accidentalCount >= 0;

  /// The number of sharps in this key signature (0 if the key uses flats).
  int get sharps => accidentalCount > 0 ? accidentalCount : 0;

  /// The number of flats in this key signature (0 if the key uses sharps).
  int get flats => accidentalCount < 0 ? -accidentalCount : 0;

  /// The relative major (if this is minor) or relative minor (if major).
  ///
  /// E.g., C Major ↔ A Minor, G Major ↔ E Minor.
  MusicalKey get relative {
    if (isMinor) {
      // Relative major is 3 semitones up from the minor root.
      final targetIndex = (semitoneIndex + 3) % 12;
      return majorKeys.firstWhere(
        (k) => k.semitoneIndex == targetIndex,
        orElse: () => _buildTransposed(targetIndex, false),
      );
    } else {
      // Relative minor is 3 semitones down from the major root.
      final targetIndex = (semitoneIndex + 9) % 12; // +9 ≡ −3 mod 12
      return minorKeys.firstWhere(
        (k) => k.semitoneIndex == targetIndex,
        orElse: () => _buildTransposed(targetIndex, true),
      );
    }
  }

  /// The parallel major (if this is minor) or parallel minor (if major).
  ///
  /// E.g., C Major ↔ C Minor, A Minor ↔ A Major.
  MusicalKey get parallel {
    final targetMinor = !isMinor;
    final keys = targetMinor ? minorKeys : majorKeys;
    return keys.firstWhere(
      (k) => k.semitoneIndex == semitoneIndex,
      orElse: () => _buildTransposed(semitoneIndex, targetMinor),
    );
  }

  // ---------------------------------------------------------------------------
  // Transposition
  // ---------------------------------------------------------------------------

  /// Returns the key transposed by [semitones] (positive = up, negative = down).
  ///
  /// ```dart
  /// MusicalKey.cMajor.transpose(7); // G Major
  /// MusicalKey.aMinor.transpose(-2); // G Minor
  /// ```
  MusicalKey transpose(int semitones) {
    final targetIndex = (semitoneIndex + semitones % 12 + 12) % 12;
    final keys = isMinor ? minorKeys : majorKeys;

    return keys.firstWhere(
      (k) => k.semitoneIndex == targetIndex,
      orElse: () => _buildTransposed(targetIndex, isMinor),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Builds a [MusicalKey] for [targetIndex] when no predefined constant
  /// matches (shouldn't happen with the full 30-key set, but keeps the code
  /// robust).
  MusicalKey _buildTransposed(int targetIndex, bool minor) {
    final notes = useSharps ? _sharpNotes : _flatNotes;
    final rootName = notes[targetIndex];
    return MusicalKey._(
      name: minor ? '${rootName}m' : rootName,
      isMinor: minor,
      semitoneIndex: targetIndex,
      accidentalCount: 0, // best-effort; won't occur with standard keys
    );
  }

  // ---------------------------------------------------------------------------
  // Object overrides
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusicalKey &&
          other.name == name &&
          other.isMinor == isMinor;

  @override
  int get hashCode => Object.hash(name, isMinor);

  @override
  String toString() => 'MusicalKey($name)';
}
