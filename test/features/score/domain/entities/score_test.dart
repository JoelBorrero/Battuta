import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Score', () {
    test('constructs and computes aggregated score metrics', () {
      final m1 = Measure(
        number: 1,
        events: [
          NoteEvent.note(
            id: 'e1',
            pitch: Pitch.parse('C4'),
            rhythmicValue: RhythmicValue.whole,
          ),
        ],
      );
      final m2 = Measure(
        number: 2,
        events: [
          NoteEvent.note(
            id: 'e2',
            pitch: Pitch.parse('G4'),
            rhythmicValue: RhythmicValue.whole,
          ),
        ],
      );

      final verse = Section(
        id: 'sec-1',
        name: 'Verse 1',
        externalSyncId: 'pp-group-verse-1',
        measures: [m1],
        repeatCount: 1,
      );

      final chorus = Section(
        id: 'sec-2',
        name: 'Chorus',
        externalSyncId: 'pp-group-chorus',
        measures: [m2],
        repeatCount: 2,
      );

      final score = Score(
        id: 'score-1',
        title: 'Way Maker',
        artist: 'Sinach',
        composer: 'Osinachi Kalu Okoro Egbu',
        keySignature: 'E',
        timeSignature: TimeSignature.fourFour,
        tempo: 120, // 120 BPM = 2 beats/sec = 960 ticks/sec
        sections: [verse, chorus],
      );

      expect(score.id, equals('score-1'));
      expect(score.title, equals('Way Maker'));
      expect(score.artist, equals('Sinach'));
      expect(score.keySignature, equals('E'));
      expect(score.tempo, equals(120));

      // Flattened measures
      expect(score.allMeasures.length, equals(2));
      expect(score.totalMeasures, equals(2));

      // Total ticks: verse (1920 * 1) + chorus (1920 * 2) = 1920 + 3840 = 5760 ticks
      expect(score.totalTicks, equals(5760));

      // At 120 BPM: 5760 ticks / 480 ticks per beat = 12 beats. 12 beats / 2 beats per sec = 6 seconds = 6000 ms
      expect(score.estimatedDuration.inSeconds, equals(6));

      // Lookup helpers
      expect(score.findSectionById('sec-1')?.name, equals('Verse 1'));
      expect(score.findSectionById('non-existent'), isNull);

      expect(
        score.findSectionByExternalSyncId('pp-group-chorus')?.name,
        equals('Chorus'),
      );
      expect(score.findSectionByExternalSyncId('invalid-uuid'), isNull);
    });

    test('copyWith modifies attributes properly', () {
      const score = Score(id: 's1', title: 'Original');
      final updated = score.copyWith(title: 'Updated Title', tempo: 140);
      expect(updated.title, equals('Updated Title'));
      expect(updated.tempo, equals(140));
      expect(updated.id, equals('s1'));
    });

    test('equality and toString', () {
      const s1 = Score(id: 's1', title: 'Amazing Grace');
      const s2 = Score(id: 's1', title: 'Amazing Grace');
      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1.toString(), contains('Amazing Grace'));
    });
  });
}
