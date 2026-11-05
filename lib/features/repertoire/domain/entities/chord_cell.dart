/// Battuta — Chord cell entity.
///
/// Represents a single chord in a song section's chord chart. Each cell
/// occupies a number of [beats] and stores the chord's root, quality,
/// optional bass note (for slash chords), and any extensions.
///
/// Uses **freezed** for immutable value semantics and JSON serialization.
library;

import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chord_cell.freezed.dart';
part 'chord_cell.g.dart';

/// A single chord cell within a [SongSection]'s chord chart.
///
/// ```dart
/// final chord = ChordCell(
///   root: 'C',
///   quality: ChordQuality.major7,
///   beats: 4,
/// );
/// print(chord.displayLabel); // "Cmaj7"
/// ```
@freezed
abstract class ChordCell with _$ChordCell {
  /// Creates an immutable [ChordCell].
  const factory ChordCell({
    /// The root note of the chord (e.g., `"C"`, `"F#"`, `"Bb"`).
    required String root,

    /// The harmonic quality of the chord.
    @Default(ChordQuality.major) ChordQuality quality,

    /// Optional bass note for slash chords (e.g., `"E"` in `"C/E"`).
    String? bass,

    /// Additional chord extensions such as `["9", "13"]`.
    @Default([]) List<String> extensions,

    /// Number of beats this chord spans in the bar.
    @Default(4) int beats,

    /// An optional custom label for non-standard chord names.
    ///
    /// When provided and [quality] is [ChordQuality.custom], this label
    /// is used as-is for display instead of computing root + quality symbol.
    String? customLabel,
  }) = _ChordCell;

  const ChordCell._();

  /// Deserializes a [ChordCell] from a JSON map.
  factory ChordCell.fromJson(Map<String, dynamic> json) =>
      _$ChordCellFromJson(json);

  /// A human-readable chord symbol for display in the chord chart.
  ///
  /// Examples: `"C"`, `"F#m7"`, `"Bb/D"`, `"Cadd9"`.
  String get displayLabel {
    if (quality == ChordQuality.custom && customLabel != null) {
      return customLabel!;
    }

    final buffer = StringBuffer(root)..write(quality.symbol);

    if (extensions.isNotEmpty) {
      buffer.write(extensions.join());
    }

    if (bass != null) {
      buffer
        ..write('/')
        ..write(bass);
    }

    return buffer.toString();
  }
}
