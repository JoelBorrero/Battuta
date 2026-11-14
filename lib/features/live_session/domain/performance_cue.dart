/// Battuta — one step of a performance: a section the band plays through.
library;

import 'package:battuta/features/repertoire/domain/entities/song_section.dart';

/// A section in performance order. A section that repeats ("Chorus ×2") gives
/// one cue per pass.
class PerformanceCue {
  const PerformanceCue({
    required this.section,
    this.repeat = 1,
    this.repeatCount = 1,
    this.isWholeSong = false,
  });

  /// The section played in this cue.
  final SongSection section;

  /// Which pass this is, from 1.
  final int repeat;

  /// How many passes the section has in all.
  final int repeatCount;

  /// Whether this stands in for a song that has no sections.
  final bool isWholeSong;

  /// The section name, with the pass when it repeats: `Chorus (2/2)`.
  String get label =>
      repeatCount > 1 ? '${section.name} ($repeat/$repeatCount)' : section.name;

  /// Unique within a song, even for repeated passes.
  String get id => repeatCount > 1 ? '${section.id}#$repeat' : section.id;

  /// The cue of a song that has no sections: a stand-in for "the whole song".
  /// [isWholeSong] is true and its [label] is empty (the page names it).
  static PerformanceCue wholeSong(String songId) => PerformanceCue(
    section: SongSection(id: 'whole-$songId', name: '', orderIndex: 0),
    isWholeSong: true,
  );

  @override
  bool operator ==(Object other) =>
      other is PerformanceCue &&
      other.section == section &&
      other.repeat == repeat &&
      other.repeatCount == repeatCount &&
      other.isWholeSong == isWholeSong;

  @override
  int get hashCode => Object.hash(section, repeat, repeatCount, isWholeSong);

  @override
  String toString() => 'PerformanceCue($label)';
}
