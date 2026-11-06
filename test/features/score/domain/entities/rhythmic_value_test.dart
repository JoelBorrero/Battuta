import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RhythmicValue', () {
    test('standard durations have correct MIDI tick values (PPQ 480)', () {
      expect(RhythmicValue.ticksPerQuarterNote, equals(480));
      expect(RhythmicValue.unassigned.ticks, equals(0));
      expect(RhythmicValue.unassigned.isUnassigned, isTrue);

      expect(RhythmicValue.thirtySecond.ticks, equals(60));
      expect(RhythmicValue.sixteenth.ticks, equals(120));
      expect(RhythmicValue.eighth.ticks, equals(240));
      expect(RhythmicValue.quarter.ticks, equals(480));
      expect(RhythmicValue.half.ticks, equals(960));
      expect(RhythmicValue.whole.ticks, equals(1920));
      expect(RhythmicValue.doubleWhole.ticks, equals(3840));
    });

    test('dotted modifiers calculate 150% tick value', () {
      expect(RhythmicValue.quarter.dotted.ticks, equals(720));
      expect(RhythmicValue.quarter.dotted.isDotted, isTrue);
      expect(RhythmicValue.half.dotted.ticks, equals(1440));
      expect(RhythmicValue.eighth.dotted.ticks, equals(360));
      expect(RhythmicValue.sixteenth.dotted.ticks, equals(180));

      // Dotted unassigned remains 0 ticks
      expect(RhythmicValue.unassigned.dotted.ticks, equals(0));
    });

    test('triplet modifiers calculate 2/3 tick value', () {
      expect(RhythmicValue.quarter.triplet.ticks, equals(320));
      expect(RhythmicValue.quarter.triplet.isTriplet, isTrue);
      expect(RhythmicValue.eighth.triplet.ticks, equals(160));
      expect(RhythmicValue.half.triplet.ticks, equals(640));

      // Triplet unassigned remains 0 ticks
      expect(RhythmicValue.unassigned.triplet.ticks, equals(0));
    });

    test('toBeats converts ticks to quarter note beats accurately', () {
      expect(RhythmicValue.quarter.toBeats(), equals(1.0));
      expect(RhythmicValue.half.toBeats(), equals(2.0));
      expect(RhythmicValue.whole.toBeats(), equals(4.0));
      expect(RhythmicValue.eighth.toBeats(), equals(0.5));
      expect(RhythmicValue.dottedQuarter.toBeats(), equals(1.5));
    });

    test('custom values can be created and compared', () {
      const custom = RhythmicValue.custom(ticks: 500, name: 'Quint');
      expect(custom.ticks, equals(500));
      expect(custom.name, equals('Quint'));
      expect(custom.compareTo(RhythmicValue.quarter), isPositive);
      expect(RhythmicValue.eighth.compareTo(custom), isNegative);
    });

    test('equality and hashCode match on tick duration and modifiers', () {
      const q1 = RhythmicValue.quarter;
      const q2 = RhythmicValue(ticks: 480, name: 'Quarter');
      expect(q1, equals(q2));
      expect(q1.hashCode, equals(q2.hashCode));
      expect(q1.toString(), contains('480t'));
    });
  });
}
