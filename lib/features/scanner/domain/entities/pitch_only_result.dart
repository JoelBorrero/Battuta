/// Battuta — Pitch-only extraction result entity.
///
/// Encapsulates the output of Gemini OMR Schema B, holding populated [Measure]
/// objects populated via [Measure.fromGeminiPitchList].
library;

import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/section.dart';

/// Immutable result of a pitch-only melodic extraction (Schema B).
class PitchOnlyResult {
  /// Creates a [PitchOnlyResult].
  const PitchOnlyResult({
    required this.sectionName,
    required this.assumedClef,
    required this.measures,
    this.warning,
    this.measureWarnings = const {},
  });

  /// Section name or header extracted from the snippet (e.g. "Intro", "Verse 1").
  final String sectionName;

  /// Assumed musical clef (e.g. "G4 (Treble Clef)").
  final String assumedClef;

  /// Populated [Measure] objects initialized via [Measure.fromGeminiPitchList],
  /// containing unassigned rhythm note events ready for the tap-first editor.
  final List<Measure> measures;

  /// Overall or section-level warning (e.g. dense ledger lines, low confidence).
  final String? warning;

  /// Map of measure number to measure-specific warnings.
  final Map<int, String> measureWarnings;

  /// Total count of measures extracted.
  int get totalMeasures => measures.length;

  /// Total count of notes extracted across all measures.
  int get totalNotes =>
      measures.fold(0, (sum, measure) => sum + measure.events.length);

  /// Converts this result into a domain [Section].
  Section toSection({String? id, int orderIndex = 0}) {
    return Section(
      id: id ?? 'sec-${DateTime.now().millisecondsSinceEpoch}',
      name: sectionName.trim().isNotEmpty ? sectionName : 'Extracted Section',
      measures: measures,
      orderIndex: orderIndex,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PitchOnlyResult &&
          runtimeType == other.runtimeType &&
          sectionName == other.sectionName &&
          assumedClef == other.assumedClef &&
          warning == other.warning &&
          _listEquals(measures, other.measures);

  @override
  int get hashCode =>
      Object.hash(sectionName, assumedClef, warning, Object.hashAll(measures));

  @override
  String toString() =>
      'PitchOnlyResult("$sectionName", clef: $assumedClef, ${measures.length} measures, warning: $warning)';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
