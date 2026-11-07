import 'package:battuta/features/score/domain/entities/chord_symbol.dart';
import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Score Domain Tree Serialization', () {
    test('complete Score tree serializes to and from JSON without loss', () {
      final note1 = NoteEvent.note(
        id: 'n1',
        pitch: Pitch.parse('C#4'),
        rhythmicValue: RhythmicValue.quarter,
        tickOffset: 0,
        isTied: true,
        lyric: 'Glo-',
        velocity: 90,
      );

      const rest = NoteEvent.rest(
        id: 'r1',
        rhythmicValue: RhythmicValue.half,
        tickOffset: 480,
      );

      final note2 = NoteEvent.note(
        id: 'n2',
        pitch: Pitch.parse('Bb4'),
        rhythmicValue: RhythmicValue.quarter,
        tickOffset: 1440,
        lyric: 'ry',
      );

      final chord1 = ChordSymbol.parse('C#m7', tickOffset: 0);
      final chord2 = ChordSymbol.parse('F#/A#', tickOffset: 960);

      final measure = Measure(
        number: 1,
        timeSignature: TimeSignature.fourFour,
        events: [note1, rest, note2],
        chords: [chord1, chord2],
      );

      final section = Section(
        id: 'sec-chorus',
        name: 'Chorus',
        externalSyncId: 'propresenter-uuid-999',
        measures: [measure],
        repeatCount: 2,
        orderIndex: 1,
      );

      final originalScore = Score(
        id: 'score-100',
        title: 'King of Kings',
        composer: 'Brooke Ligertwood',
        artist: 'Hillsong Worship',
        timeSignature: TimeSignature.fourFour,
        keySignature: 'D',
        tempo: 68,
        sections: [section],
        metadata: const {'ccli': 7127647, 'copyright': '2019 Hillsong'},
      );

      final json = originalScore.toJson();
      final reloadedScore = Score.fromJson(json);

      expect(reloadedScore, equals(originalScore));
      expect(
        reloadedScore.sections.first.externalSyncId,
        equals('propresenter-uuid-999'),
      );
      expect(
        reloadedScore.allMeasures.first.events[0].pitch?.scientificNotation,
        equals('C#4'),
      );
      expect(reloadedScore.allMeasures.first.events[0].isTied, isTrue);
      expect(reloadedScore.allMeasures.first.events[0].lyric, equals('Glo-'));
      expect(reloadedScore.allMeasures.first.events[1].isRest, isTrue);
      expect(
        reloadedScore.allMeasures.first.events[2].pitch?.scientificNotation,
        equals('Bb4'),
      );
      expect(reloadedScore.allMeasures.first.chords[1].bass, equals('A#'));
    });
  });
}
