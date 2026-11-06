import 'package:battuta/core/errors/exceptions.dart';
import 'package:battuta/features/score/domain/entities/chord_symbol.dart';
import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Measure', () {
    test('calculates duration metrics correctly', () {
      final measure = Measure(
        number: 1,
        timeSignature: TimeSignature.fourFour,
        events: [
          NoteEvent.note(
            id: 'e1',
            pitch: Pitch.parse('C4'),
            rhythmicValue: RhythmicValue.quarter,
          ),
          NoteEvent.note(
            id: 'e2',
            pitch: Pitch.parse('D4'),
            rhythmicValue: RhythmicValue.quarter,
          ),
        ],
      );

      // 480 + 480 = 960 ticks out of 1920
      expect(measure.totalTicks, equals(960));
      expect(measure.maxTicks, equals(1920));
      expect(measure.remainingTicks, equals(960));
      expect(measure.isComplete, isFalse);
      expect(measure.hasOverflow, isFalse);
      expect(measure.isEmpty, isFalse);
    });

    test('Measure.fromGeminiPitchList initializes with unassigned 0-tick rhythms', () {
      final pitches = ['C4', 'E4', 'G4', 'C5'];
      final measure = Measure.fromGeminiPitchList(
        pitches,
        number: 1,
        timeSignature: TimeSignature.fourFour,
      );

      expect(measure.events.length, equals(4));
      expect(measure.totalTicks, equals(0));
      expect(measure.remainingTicks, equals(1920));
      for (final event in measure.events) {
        expect(event.rhythmicValue, equals(RhythmicValue.unassigned));
        expect(event.ticks, equals(0));
      }
      expect(measure.events[0].pitch?.scientificNotation, equals('C4'));
      expect(measure.events[1].pitch?.scientificNotation, equals('E4'));
      expect(measure.events[2].pitch?.scientificNotation, equals('G4'));
      expect(measure.events[3].pitch?.scientificNotation, equals('C5'));
    });

    test('assignRhythmAt updates duration and recalculates contiguous offsets', () {
      final raw = Measure.fromGeminiPitchList(['C4', 'D4', 'E4']);
      final m1 = raw.assignRhythmAt(0, RhythmicValue.quarter);
      expect(m1.events[0].rhythmicValue, equals(RhythmicValue.quarter));
      expect(m1.events[0].tickOffset, equals(0));
      expect(m1.totalTicks, equals(480));

      final m2 = m1.assignRhythmAt(1, RhythmicValue.half);
      expect(m2.events[1].rhythmicValue, equals(RhythmicValue.half));
      expect(m2.events[1].tickOffset, equals(480));
      expect(m2.totalTicks, equals(1440)); // 480 + 960

      final m3 = m2.assignRhythmAt(2, RhythmicValue.quarter);
      expect(m3.events[2].tickOffset, equals(1440));
      expect(m3.totalTicks, equals(1920));
      expect(m3.isComplete, isTrue);
    });

    test('assignRhythmAt throws MeasureOverflowException if maxTicks exceeded', () {
      final raw = Measure.fromGeminiPitchList(['C4', 'D4']);
      final m1 = raw.assignRhythmAt(0, RhythmicValue.whole); // 1920 ticks (fills measure)
      expect(m1.totalTicks, equals(1920));

      // Attempting to assign quarter (480 ticks) to second event would exceed 1920
      expect(
        () => m1.assignRhythmAt(1, RhythmicValue.quarter),
        throwsA(isA<MeasureOverflowException>().having(
          (e) => e.attemptedTicks,
          'attemptedTicks',
          equals(2400),
        )),
      );
    });

    test('addEvent appends event and checks capacity when requested', () {
      var measure = const Measure(number: 1, timeSignature: TimeSignature.fourFour);
      measure = measure.addEvent(
        NoteEvent.note(
          id: 'n1',
          pitch: Pitch.parse('C4'),
          rhythmicValue: RhythmicValue.half,
        ),
      );
      expect(measure.events.length, equals(1));
      expect(measure.totalTicks, equals(960));

      // With validateCapacity: true, adding a whole note (1920 ticks) overflows 960 + 1920 = 2880 > 1920
      expect(
        () => measure.addEvent(
          NoteEvent.note(
            id: 'n2',
            pitch: Pitch.parse('D4'),
            rhythmicValue: RhythmicValue.whole,
          ),
          validateCapacity: true,
        ),
        throwsA(isA<MeasureOverflowException>()),
      );
    });

    test('addChord appends chord symbols', () {
      final measure = const Measure(number: 1).addChord(ChordSymbol.parse('C'));
      expect(measure.chords.length, equals(1));
      expect(measure.chords.first.root, equals('C'));
    });

    test('canFitRhythmAt and canFitDuration helper validations', () {
      final raw = Measure.fromGeminiPitchList(['C4', 'E4']);
      expect(raw.canFitRhythmAt(0, RhythmicValue.whole), isTrue); // 1920 ticks fits
      expect(raw.canFitRhythmAt(0, RhythmicValue.doubleWhole), isFalse); // 3840 ticks > 1920
      expect(raw.canFitRhythmAt(5, RhythmicValue.quarter), isFalse); // index out of bounds

      final m1 = raw.assignRhythmAt(0, RhythmicValue.half); // 960 ticks
      expect(m1.canFitRhythmAt(1, RhythmicValue.half), isTrue); // 960 + 960 = 1920 fits
      expect(m1.canFitRhythmAt(1, RhythmicValue.whole), isFalse); // 960 + 1920 = 2880 > 1920

      expect(m1.canFitDuration(960), isTrue);
      expect(m1.canFitDuration(961), isFalse);
    });

    test('tracks unassigned events and fillRatio metrics', () {
      final measure = Measure.fromGeminiPitchList(['C4', 'D4', 'E4', 'F4']);
      expect(measure.unassignedCount, equals(4));
      expect(measure.hasUnassignedEvents, isTrue);
      expect(measure.fillRatio, equals(0.0));

      final halfFilled = measure
          .assignRhythmAt(0, RhythmicValue.quarter)
          .assignRhythmAt(1, RhythmicValue.quarter);
      expect(halfFilled.unassignedCount, equals(2));
      expect(halfFilled.hasUnassignedEvents, isTrue);
      expect(halfFilled.fillRatio, equals(0.5)); // 960 / 1920 = 0.5
    });

    test('validateMeasureCapacity throws MeasureOverflowException only on overflow', () {
      const normal = Measure(number: 1, timeSignature: TimeSignature.fourFour);
      expect(() => normal.validateMeasureCapacity(), returnsNormally);

      final overflowMeasure = Measure(
        number: 2,
        timeSignature: TimeSignature.fourFour,
        events: [
          NoteEvent.note(
            id: 'e1',
            pitch: Pitch.parse('C4'),
            rhythmicValue: RhythmicValue.doubleWhole, // 3840 ticks > 1920
          ),
        ],
      );
      expect(overflowMeasure.hasOverflow, isTrue);
      expect(
        () => overflowMeasure.validateMeasureCapacity(),
        throwsA(isA<MeasureOverflowException>().having(
          (e) => e.attemptedTicks,
          'attemptedTicks',
          equals(3840),
        )),
      );
    });

    test('equality and toString', () {
      const m1 = Measure(number: 1, timeSignature: TimeSignature.fourFour);
      const m2 = Measure(number: 1, timeSignature: TimeSignature.fourFour);
      expect(m1, equals(m2));
      expect(m1.hashCode, equals(m2.hashCode));
      expect(m1.toString(), contains('Measure #1'));
    });
  });
}
