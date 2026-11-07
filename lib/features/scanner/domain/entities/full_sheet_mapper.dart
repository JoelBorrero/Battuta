/// Battuta — Gemini OMR full lead sheet JSON to Score mapper.
///
/// Converts structured JSON responses conforming to [FullSheetSchema]
/// directly into a fully-validated, immutable [Score] domain tree.
library;

import 'package:battuta/features/score/domain/entities/chord_symbol.dart';
import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:uuid/uuid.dart';

/// Utility for mapping Gemini OMR JSON to a domain [Score].
class FullSheetMapper {
  FullSheetMapper._();

  static const _uuid = Uuid();

  /// Converts a JSON payload conforming to [FullSheetSchema] into a [Score].
  static Score mapToScore(Map<String, dynamic> json, {String? scoreId}) {
    final meta = json['metadatos'] as Map<String, dynamic>? ?? {};

    final title = meta['titulo'] as String? ?? 'Untitled Lead Sheet';
    final artist = meta['artista'] as String?;
    final keySignature = meta['tonalidad_indicada'] as String? ?? 'C';
    final rawTempo = meta['tempo_bpm'] as int? ?? 120;
    final tempo = (rawTempo > 0 && rawTempo <= 400) ? rawTempo : 120;

    TimeSignature primaryMeter;
    try {
      final compasStr = meta['compas'] as String? ?? '4/4';
      primaryMeter = TimeSignature.parse(compasStr);
    } catch (_) {
      primaryMeter = TimeSignature.fourFour;
    }

    final metadata = <String, dynamic>{};
    if (meta['copyright'] != null) {
      metadata['copyright'] = meta['copyright'];
    }

    final sectionsJson = json['secciones'] as List<dynamic>? ?? [];
    final sections = <Section>[];

    for (var sIdx = 0; sIdx < sectionsJson.length; sIdx++) {
      final secMap = sectionsJson[sIdx] as Map<String, dynamic>;
      final sectionName = secMap['nombre'] as String? ?? 'Section ${sIdx + 1}';
      final navBox = secMap['caja_navegacion'] as String?;
      final rawRepeat = (secMap['repeticiones'] as num?)?.toInt() ?? 1;
      final repeatCount = (rawRepeat > 0 && rawRepeat <= 16) ? rawRepeat : 1;

      final measuresJson = secMap['compases'] as List<dynamic>? ?? [];
      final measures = <Measure>[];

      for (var mIdx = 0; mIdx < measuresJson.length; mIdx++) {
        final measMap = measuresJson[mIdx] as Map<String, dynamic>;
        final measureNum = measMap['numero'] as int? ?? (mIdx + 1);

        TimeSignature measureMeter;
        if (measMap['compas'] != null) {
          try {
            measureMeter = TimeSignature.parse(measMap['compas'] as String);
          } catch (_) {
            measureMeter = primaryMeter;
          }
        } else {
          measureMeter = primaryMeter;
        }

        // Parse chords
        final chords = <ChordSymbol>[];
        final chordsJson = measMap['acordes'] as List<dynamic>? ?? [];
        for (final chordObj in chordsJson) {
          final cMap = chordObj as Map<String, dynamic>;
          final cifrado = cMap['cifrado'] as String? ?? '';
          if (cifrado.trim().isEmpty) continue;

          int tickOffset = 0;
          if (cMap['tick_offset'] != null) {
            tickOffset = cMap['tick_offset'] as int;
          } else if (cMap['posicion_pulso'] != null) {
            final beat = (cMap['posicion_pulso'] as num).toDouble();
            tickOffset = ((beat - 1.0) * measureMeter.ticksPerBeat)
                .round()
                .clamp(0, measureMeter.maxTicks);
          }

          try {
            chords.add(ChordSymbol.parse(cifrado, tickOffset: tickOffset));
          } catch (_) {
            // If chord fails custom parsing, store with normalized root
            chords.add(ChordSymbol(root: cifrado, tickOffset: tickOffset));
          }
        }

        // Parse notes
        final notes = <NoteEvent>[];
        final notesJson = measMap['notas'] as List<dynamic>? ?? [];
        var cumulativeOffset = 0;

        for (var nIdx = 0; nIdx < notesJson.length; nIdx++) {
          final noteObj = notesJson[nIdx] as Map<String, dynamic>;
          final rawTono = noteObj['tono'] as String? ?? 'rest';
          final letra = noteObj['letra'] as String?;
          final ligadura = noteObj['ligadura'] as bool? ?? false;

          RhythmicValue rhythm;
          if (noteObj['duracion_ticks'] != null) {
            final ticks = noteObj['duracion_ticks'] as int;
            rhythm = RhythmicValue.custom(ticks: ticks);
          } else if (noteObj['duracion'] != null) {
            rhythm = _parseDurationString(noteObj['duracion'] as String);
          } else {
            rhythm = RhythmicValue.unassigned;
          }

          final eventId = 'm$measureNum-e$nIdx';
          if (rawTono.toLowerCase() == 'rest') {
            notes.add(
              NoteEvent.rest(
                id: eventId,
                rhythmicValue: rhythm,
                tickOffset: cumulativeOffset,
              ),
            );
          } else {
            Pitch? pitch;
            try {
              pitch = Pitch.parse(rawTono);
            } catch (_) {
              pitch = null;
            }

            if (pitch != null) {
              notes.add(
                NoteEvent.note(
                  id: eventId,
                  pitch: pitch,
                  rhythmicValue: rhythm,
                  tickOffset: cumulativeOffset,
                  isTied: ligadura,
                  lyric: letra,
                ),
              );
            } else {
              notes.add(
                NoteEvent.rest(
                  id: eventId,
                  rhythmicValue: rhythm,
                  tickOffset: cumulativeOffset,
                ),
              );
            }
          }

          cumulativeOffset += rhythm.ticks;
        }

        measures.add(
          Measure(
            number: measureNum,
            timeSignature: measureMeter,
            events: List.unmodifiable(notes),
            chords: List.unmodifiable(chords),
          ),
        );
      }

      sections.add(
        Section(
          id: navBox != null && navBox.isNotEmpty
              ? 'sec-$navBox'
              : 'sec-${sIdx + 1}',
          name: sectionName,
          measures: List.unmodifiable(measures),
          repeatCount: repeatCount,
          orderIndex: sIdx,
        ),
      );
    }

    return Score(
      id: scoreId ?? _uuid.v4(),
      title: title,
      artist: artist,
      timeSignature: primaryMeter,
      keySignature: keySignature,
      tempo: tempo,
      sections: List.unmodifiable(sections),
      metadata: Map.unmodifiable(metadata),
    );
  }

  static RhythmicValue _parseDurationString(String str) {
    final lower = str.toLowerCase();
    if (lower.contains('whole')) {
      return lower.contains('dotted')
          ? RhythmicValue.dottedWhole
          : RhythmicValue.whole;
    }
    if (lower.contains('half')) {
      return lower.contains('dotted')
          ? RhythmicValue.dottedHalf
          : RhythmicValue.half;
    }
    if (lower.contains('quarter')) {
      return lower.contains('dotted')
          ? RhythmicValue.dottedQuarter
          : RhythmicValue.quarter;
    }
    if (lower.contains('eighth') || lower.contains('8th')) {
      return lower.contains('dotted')
          ? RhythmicValue.dottedEighth
          : RhythmicValue.eighth;
    }
    if (lower.contains('sixteenth') || lower.contains('16th')) {
      return lower.contains('dotted')
          ? RhythmicValue.dottedSixteenth
          : RhythmicValue.sixteenth;
    }
    if (lower.contains('thirty') || lower.contains('32nd')) {
      return RhythmicValue.thirtySecond;
    }
    return RhythmicValue.unassigned;
  }
}
