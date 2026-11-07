/// Battuta — Pitch-Only mapper.
///
/// Deterministically transforms Gemini OMR Schema B JSON responses into
/// [PitchOnlyResult] domain entities, automatically populating [Measure]
/// objects via [Measure.fromGeminiPitchList].
library;

import 'package:battuta/features/scanner/domain/entities/pitch_only_result.dart';
import 'package:battuta/features/score/domain/entities/chord_symbol.dart';
import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';

/// Mapper transforming Schema B JSON payloads into [PitchOnlyResult].
class PitchOnlyMapper {
  PitchOnlyMapper._();

  /// Maps a parsed Gemini Schema B JSON response into [PitchOnlyResult].
  ///
  /// Uses [Measure.fromGeminiPitchList] to instantiate note events with
  /// [RhythmicValue.unassigned] for immediate tap-first rhythmic editing.
  static PitchOnlyResult mapToResult(
    Map<String, dynamic> json, {
    TimeSignature timeSignature = TimeSignature.fourFour,
  }) {
    final sectionName =
        (json['seccion'] as String?)?.trim() ?? 'Extracted Section';
    final assumedClef =
        (json['clave_asumida'] as String?)?.trim() ?? 'G4 (Treble Clef)';
    final sectionWarning = json['advertencia'] as String?;

    final rawCompases = json['compases'] as List<dynamic>? ?? const [];
    final measures = <Measure>[];
    final measureWarnings = <int, String>{};

    for (var i = 0; i < rawCompases.length; i++) {
      final compasJson = rawCompases[i];
      if (compasJson is! Map<String, dynamic>) continue;

      final measureNumber = compasJson['numero'] as int? ?? (i + 1);

      // Extract raw pitch sequence
      final rawNotes =
          compasJson['secuencia_notas'] as List<dynamic>? ?? const [];
      final pitchStrings = <String>[];
      for (final note in rawNotes) {
        if (note is String && note.trim().isNotEmpty) {
          pitchStrings.add(note.trim());
        }
      }

      // Automatically construct Measure via Measure.fromGeminiPitchList
      var measure = Measure.fromGeminiPitchList(
        pitchStrings,
        number: measureNumber,
        timeSignature: timeSignature,
      );

      // Extract chords if present
      final rawChords = compasJson['acordes'] as List<dynamic>? ?? const [];
      final chords = <ChordSymbol>[];
      for (var chordIdx = 0; chordIdx < rawChords.length; chordIdx++) {
        final chordItem = rawChords[chordIdx];
        if (chordItem is String && chordItem.trim().isNotEmpty) {
          final trimmed = chordItem.trim();
          final tickOffset =
              chordIdx *
              (timeSignature.maxTicks ~/
                  (rawChords.length > 1 ? rawChords.length : 1));
          try {
            chords.add(ChordSymbol.parse(trimmed, tickOffset: tickOffset));
          } catch (_) {
            chords.add(ChordSymbol(root: trimmed, tickOffset: tickOffset));
          }
        } else if (chordItem is Map<String, dynamic>) {
          final symbol =
              chordItem['cifrado'] as String? ??
              chordItem['symbol'] as String? ??
              '';
          if (symbol.trim().isNotEmpty) {
            final trimmed = symbol.trim();
            var tickOffset = 0;
            if (chordItem['tick_offset'] != null) {
              tickOffset = (chordItem['tick_offset'] as num).toInt();
            } else if (chordItem['posicion_pulso'] != null) {
              final beat = (chordItem['posicion_pulso'] as num).toDouble();
              tickOffset = ((beat - 1.0) * timeSignature.ticksPerBeat)
                  .round()
                  .clamp(0, timeSignature.maxTicks);
            }
            try {
              chords.add(ChordSymbol.parse(trimmed, tickOffset: tickOffset));
            } catch (_) {
              chords.add(ChordSymbol(root: trimmed, tickOffset: tickOffset));
            }
          }
        }
      }

      if (chords.isNotEmpty) {
        measure = measure.copyWith(chords: List.unmodifiable(chords));
      }

      // Extract measure-level warning
      final warning = compasJson['advertencia'] as String?;
      if (warning != null && warning.trim().isNotEmpty) {
        measureWarnings[measureNumber] = warning.trim();
      }

      measures.add(measure);
    }

    return PitchOnlyResult(
      sectionName: sectionName.isNotEmpty ? sectionName : 'Extracted Section',
      assumedClef: assumedClef.isNotEmpty ? assumedClef : 'G4 (Treble Clef)',
      measures: List.unmodifiable(measures),
      warning: sectionWarning,
      measureWarnings: Map.unmodifiable(measureWarnings),
    );
  }
}
