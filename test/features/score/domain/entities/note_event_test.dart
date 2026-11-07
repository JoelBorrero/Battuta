import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoteEvent', () {
    test('creates note events and rest events with appropriate flags', () {
      final note = NoteEvent.note(
        id: 'note-1',
        pitch: Pitch.parse('C4'),
        rhythmicValue: RhythmicValue.quarter,
        tickOffset: 480,
        isTied: true,
        lyric: 'A-',
        velocity: 95,
      );

      expect(note.isNote, isTrue);
      expect(note.isRest, isFalse);
      expect(note.pitch?.scientificNotation, equals('C4'));
      expect(note.rhythmicValue, equals(RhythmicValue.quarter));
      expect(note.ticks, equals(480));
      expect(note.tickOffset, equals(480));
      expect(note.isTied, isTrue);
      expect(note.lyric, equals('A-'));
      expect(note.velocity, equals(95));

      const rest = NoteEvent.rest(
        id: 'rest-1',
        rhythmicValue: RhythmicValue.half,
        tickOffset: 960,
      );

      expect(rest.isRest, isTrue);
      expect(rest.isNote, isFalse);
      expect(rest.pitch, isNull);
      expect(rest.ticks, equals(960));
      expect(rest.velocity, equals(0));
    });

    test('copyWith updates properties and clears nullable fields', () {
      final note = NoteEvent.note(
        id: 'n1',
        pitch: Pitch.parse('G4'),
        rhythmicValue: RhythmicValue.quarter,
        lyric: 'Hallelujah',
      );

      final modified = note.copyWith(
        pitch: Pitch.parse('A4'),
        rhythmicValue: RhythmicValue.half,
      );
      expect(modified.pitch?.scientificNotation, equals('A4'));
      expect(modified.rhythmicValue, equals(RhythmicValue.half));
      expect(modified.lyric, equals('Hallelujah'));

      final restCopy = note.copyWith(clearPitch: true, clearLyric: true);
      expect(restCopy.isRest, isTrue);
      expect(restCopy.lyric, isNull);
    });

    test('equality and toString', () {
      final e1 = NoteEvent.note(
        id: 'e1',
        pitch: Pitch.parse('C4'),
        rhythmicValue: RhythmicValue.quarter,
      );
      final e2 = NoteEvent.note(
        id: 'e1',
        pitch: Pitch.parse('C4'),
        rhythmicValue: RhythmicValue.quarter,
      );
      expect(e1, equals(e2));
      expect(e1.hashCode, equals(e2.hashCode));
      expect(e1.toString(), contains('C4'));

      const rest = NoteEvent.rest(
        id: 'r1',
        rhythmicValue: RhythmicValue.quarter,
      );
      expect(rest.toString(), contains('rest'));
    });
  });
}
