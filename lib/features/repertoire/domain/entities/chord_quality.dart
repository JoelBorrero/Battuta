/// Battuta — Chord quality enumeration.
///
/// Defines the harmonic quality of a chord (major, minor, diminished, etc.)
/// with human-readable display names and standard music-theory symbols.
///
/// ## Usage
/// ```dart
/// final quality = ChordQuality.minor;
/// print(quality.symbol);      // "m"
/// print(quality.displayName);  // "Minor"
/// ```
library;

/// All supported chord qualities in the Battuta chord vocabulary.
///
/// Each variant carries a [symbol] (the suffix appended to a root note when
/// rendering chord names) and a [displayName] for UI labels and accessibility.
enum ChordQuality {
  /// Major triad — no suffix (e.g., "C").
  major(symbol: '', displayName: 'Major'),

  /// Minor triad — suffix "m" (e.g., "Cm").
  minor(symbol: 'm', displayName: 'Minor'),

  /// Diminished triad — suffix "dim" (e.g., "Cdim").
  diminished(symbol: 'dim', displayName: 'Diminished'),

  /// Augmented triad — suffix "aug" (e.g., "Caug").
  augmented(symbol: 'aug', displayName: 'Augmented'),

  /// Dominant seventh — suffix "7" (e.g., "C7").
  dominant7(symbol: '7', displayName: 'Dominant 7th'),

  /// Major seventh — suffix "maj7" (e.g., "Cmaj7").
  major7(symbol: 'maj7', displayName: 'Major 7th'),

  /// Minor seventh — suffix "m7" (e.g., "Cm7").
  minor7(symbol: 'm7', displayName: 'Minor 7th'),

  /// Suspended second — suffix "sus2" (e.g., "Csus2").
  sus2(symbol: 'sus2', displayName: 'Suspended 2nd'),

  /// Suspended fourth — suffix "sus4" (e.g., "Csus4").
  sus4(symbol: 'sus4', displayName: 'Suspended 4th'),

  /// Add nine — suffix "add9" (e.g., "Cadd9").
  add9(symbol: 'add9', displayName: 'Add 9'),

  /// Custom / non-standard quality — the label is provided externally.
  custom(symbol: '', displayName: 'Custom');

  const ChordQuality({required this.symbol, required this.displayName});

  /// The music-notation suffix appended to the root note (e.g., "m", "7").
  final String symbol;

  /// A human-readable name for display in the UI.
  final String displayName;
}
