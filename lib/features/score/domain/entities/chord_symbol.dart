/// Battuta — Musical chord symbol entity.
///
/// Models lead-sheet chord symbols with root, quality, extension,
/// optional slash-chord bass note, and rhythmic measure tick placement.
library;

/// Represents an immutable chord symbol positioned within a measure.
class ChordSymbol {
  /// Creates a [ChordSymbol].
  const ChordSymbol({
    required this.root,
    this.quality = '',
    this.bass,
    this.tickOffset = 0,
  }) : assert(tickOffset >= 0, 'tickOffset cannot be negative');

  /// The root note of the chord (e.g., `"C"`, `"F#"`, `"Bb"`).
  final String root;

  /// The chord quality and extensions (e.g., `""`, `"m"`, `"7"`, `"maj7"`, `"m7"`, `"sus4"`).
  final String quality;

  /// Optional bass note for slash chords (e.g., `"E"` in `"C/E"`, `"F#"` in `"D/F#"`).
  final String? bass;

  /// Start offset within the containing measure in MIDI ticks (0 is measure start).
  final int tickOffset;

  /// Complete chord display string (e.g., `"C#m7"`, `"Bb/D"`, `"G"`).
  String get text => '$root$quality${bass != null ? '/$bass' : ''}';

  /// Converts this [ChordSymbol] to a JSON map.
  Map<String, dynamic> toJson() => {
        'root': root,
        'quality': quality,
        'bass': bass,
        'tickOffset': tickOffset,
      };

  /// Constructs a [ChordSymbol] from a JSON map.
  factory ChordSymbol.fromJson(Map<String, dynamic> json) => ChordSymbol(
        root: json['root'] as String,
        quality: json['quality'] as String? ?? '',
        bass: json['bass'] as String?,
        tickOffset: json['tickOffset'] as int? ?? 0,
      );

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  static final RegExp _chordRegex =
      RegExp(r'^([A-Ga-g][#b♯♭]?)([^/]*)(?:/([A-Ga-g][#b♯♭]?))?$');

  /// Parses a raw chord string such as `"G"`, `"Am"`, `"C#m7"`, or `"D/F#"`.
  ///
  /// Throws [FormatException] if the string does not begin with a valid root note.
  factory ChordSymbol.parse(String chordText, {int tickOffset = 0}) {
    final trimmed = chordText.trim();
    final match = _chordRegex.firstMatch(trimmed);

    if (match == null) {
      throw FormatException('Invalid chord symbol: "$chordText"');
    }

    final rawRoot = match.group(1)!;
    final root = _normalizeRoot(rawRoot);
    final quality = match.group(2)?.trim() ?? '';
    final rawBass = match.group(3)?.trim();
    final bass = rawBass != null && rawBass.isNotEmpty
        ? _normalizeRoot(rawBass)
        : null;

    return ChordSymbol(
      root: root,
      quality: quality,
      bass: bass,
      tickOffset: tickOffset,
    );
  }

  static String _normalizeRoot(String r) {
    if (r.isEmpty) return r;
    final letter = r[0].toUpperCase();
    if (r.length == 1) return letter;
    final acc = r.substring(1).replaceAll('♯', '#').replaceAll('♭', 'b');
    return '$letter$acc';
  }

  /// Creates a copy of this [ChordSymbol] with optional updated fields.
  ChordSymbol copyWith({
    String? root,
    String? quality,
    String? bass,
    int? tickOffset,
  }) {
    return ChordSymbol(
      root: root ?? this.root,
      quality: quality ?? this.quality,
      bass: bass ?? this.bass,
      tickOffset: tickOffset ?? this.tickOffset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChordSymbol &&
          runtimeType == other.runtimeType &&
          root == other.root &&
          quality == other.quality &&
          bass == other.bass &&
          tickOffset == other.tickOffset;

  @override
  int get hashCode => Object.hash(root, quality, bass, tickOffset);

  @override
  String toString() => 'ChordSymbol($text, @${tickOffset}t)';
}

