/// Battuta — Song to Score Domain Tree Mapper.
///
/// Bridges Repertoire [Song] entities with deep musical [Score] domain trees,
/// allowing any song created in the editor to be rendered via StaffCanvas,
/// printed via PdfLeadSheetGenerator, or exported via MidiFileExporter.
library;

import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/score/domain/entities/chord_symbol.dart';
import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';

/// Extension adding [toScore] mapping capability to [Song].
extension SongScoreMapper on Song {
  /// Converts this [Song] to a full musical [Score] representation.
  Score toScore() {
    final meter = TimeSignature(timeSignature.$1, timeSignature.$2);
    final scoreSections = <Section>[];
    var globalMeasureIndex = 1;

    for (var sIdx = 0; sIdx < sections.length; sIdx++) {
      final section = sections[sIdx];
      final sectionMeasures = <Measure>[];

      if (section.chords.isEmpty) {
        // Empty section: create single empty measure
        sectionMeasures.add(
          Measure(
            number: globalMeasureIndex++,
            timeSignature: meter,
            events: [
              NoteEvent.rest(
                id: 'rest-${section.id}-$globalMeasureIndex',
                rhythmicValue: RhythmicValue.whole,
              ),
            ],
          ),
        );
      } else {
        // Group chords by measure based on beats capacity
        final beatsPerMeasure = meter.numerator;
        final ticksPerBeat = meter.ticksPerBeat;

        var currentMeasureChords = <ChordSymbol>[];
        var currentMeasureEvents = <NoteEvent>[];
        var currentMeasureBeats = 0;

        for (final cell in section.chords) {
          final cellBeats = cell.beats > 0 ? cell.beats : beatsPerMeasure;

          // If adding this chord exceeds the bar, flush current measure
          if (currentMeasureBeats + cellBeats > beatsPerMeasure &&
              currentMeasureBeats > 0) {
            sectionMeasures.add(
              Measure(
                number: globalMeasureIndex++,
                timeSignature: meter,
                chords: currentMeasureChords,
                events: currentMeasureEvents,
              ),
            );
            currentMeasureChords = [];
            currentMeasureEvents = [];
            currentMeasureBeats = 0;
          }

          final tickOffset = currentMeasureBeats * ticksPerBeat;
          final chordSymbol = ChordSymbol(
            root: cell.root,
            quality: cell.quality.symbol,
            bass: cell.bass,
            tickOffset: tickOffset,
          );
          currentMeasureChords.add(chordSymbol);

          // Add guide note event for the chord duration
          final chordDurationTicks = cellBeats * ticksPerBeat;
          final rhythmicVal = RhythmicValue.custom(ticks: chordDurationTicks);
          final guidePitch = _parseRootPitch(cell.root);

          currentMeasureEvents.add(
            NoteEvent.note(
              id: 'note-${section.id}-$globalMeasureIndex-$currentMeasureBeats',
              pitch: guidePitch,
              rhythmicValue: rhythmicVal,
              tickOffset: tickOffset,
            ),
          );

          currentMeasureBeats += cellBeats;
        }

        // Flush remaining measure
        if (currentMeasureChords.isNotEmpty || currentMeasureBeats > 0) {
          sectionMeasures.add(
            Measure(
              number: globalMeasureIndex++,
              timeSignature: meter,
              chords: currentMeasureChords,
              events: currentMeasureEvents,
            ),
          );
        }
      }

      scoreSections.add(
        Section(
          id: section.id,
          name: section.name,
          repeatCount: section.repeatCount,
          orderIndex: sIdx,
          measures: sectionMeasures,
        ),
      );
    }

    return Score(
      id: id,
      title: title,
      artist: artist,
      composer: artist,
      keySignature: key,
      tempo: tempo,
      timeSignature: meter,
      sections: scoreSections,
      metadata: {
        'notes': ?notes,
        'tags': tags,
      },
    );
  }

  static Pitch _parseRootPitch(String root) {
    try {
      final sanitized = root.replaceAll(RegExp(r'[^A-Ga-g#b]'), '');
      if (sanitized.isEmpty) return Pitch.middleC;
      return Pitch.parse('${sanitized}4');
    } catch (_) {
      return Pitch.middleC;
    }
  }
}
