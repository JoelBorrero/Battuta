/// Battuta — Song section entity.
///
/// Represents a named section of a song (e.g., "Intro", "Verse 1", "Chorus")
/// containing an ordered list of [ChordCell]s, optional lyrics, and rehearsal
/// notes. Sections are ordered within a [Song] by their [orderIndex].
///
/// Uses **freezed** for immutable value semantics and JSON serialization.
library;

import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'song_section.freezed.dart';
part 'song_section.g.dart';

/// A discrete section within a song's lead sheet.
///
/// ```dart
/// final verse = SongSection(
///   id: 'sec-1',
///   name: 'Verse 1',
///   chords: [ChordCell(root: 'G'), ChordCell(root: 'Em')],
///   lyrics: 'Amazing grace, how sweet the sound…',
///   orderIndex: 0,
/// );
/// ```
@freezed
abstract class SongSection with _$SongSection {
  /// Creates an immutable [SongSection].
  const factory SongSection({
    /// Unique identifier for this section.
    required String id,

    /// Human-readable section name (e.g., `"Intro"`, `"Chorus"`, `"Bridge"`).
    required String name,

    /// Ordered chord cells that make up this section's chord chart.
    @Default([]) List<ChordCell> chords,

    /// Optional lyrics for this section, displayed below or alongside chords.
    String? lyrics,

    /// Private rehearsal notes (e.g., `"Hold last chord for 2 extra beats"`).
    String? rehearsalNotes,

    /// How many times this section repeats during performance.
    @Default(1) int repeatCount,

    /// Zero-based position of this section within the parent song.
    required int orderIndex,
  }) = _SongSection;

  /// Deserializes a [SongSection] from a JSON map.
  factory SongSection.fromJson(Map<String, dynamic> json) =>
      _$SongSectionFromJson(json);
}
