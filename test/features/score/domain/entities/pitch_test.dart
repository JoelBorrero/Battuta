import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pitch', () {
    group('parse scientific pitch strings (Checklist Requirement)', () {
      test('parses F5, C#4, and Bb4 correctly', () {
        final f5 = Pitch.parse('F5');
        expect(f5.step, equals(PitchStep.f));
        expect(f5.accidental, equals(0));
        expect(f5.octave, equals(5));
        expect(f5.scientificNotation, equals('F5'));
        expect(f5.midiNumber, equals(77));

        final cSharp4 = Pitch.parse('C#4');
        expect(cSharp4.step, equals(PitchStep.c));
        expect(cSharp4.accidental, equals(1));
        expect(cSharp4.octave, equals(4));
        expect(cSharp4.scientificNotation, equals('C#4'));
        expect(cSharp4.midiNumber, equals(61));

        final bFlat4 = Pitch.parse('Bb4');
        expect(bFlat4.step, equals(PitchStep.b));
        expect(bFlat4.accidental, equals(-1));
        expect(bFlat4.octave, equals(4));
        expect(bFlat4.scientificNotation, equals('Bb4'));
        expect(bFlat4.midiNumber, equals(70));
      });

      test('parses Unicode accidentals and complex accidentals', () {
        final fSharp = Pitch.parse('F♯5');
        expect(fSharp.accidental, equals(1));
        expect(fSharp.scientificNotation, equals('F#5'));

        final eFlat = Pitch.parse('E♭3');
        expect(eFlat.accidental, equals(-1));
        expect(eFlat.scientificNotation, equals('Eb3'));

        final dDoubleFlat = Pitch.parse('Dbb4');
        expect(dDoubleFlat.accidental, equals(-2));
        expect(dDoubleFlat.scientificNotation, equals('Dbb4'));

        final cDoubleSharp = Pitch.parse('C##4');
        expect(cDoubleSharp.accidental, equals(2));
        expect(cDoubleSharp.scientificNotation, equals('C##4'));
      });

      test('throws FormatException on malformed strings', () {
        expect(() => Pitch.parse(''), throwsFormatException);
        expect(() => Pitch.parse('H4'), throwsFormatException);
        expect(() => Pitch.parse('C'), throwsFormatException);
        expect(() => Pitch.parse('4C'), throwsFormatException);
        expect(() => Pitch.parse('C###4'), throwsFormatException);
      });
    });

    group('transposeDiatonic (Checklist Requirement)', () {
      test('transposes F5 by +1 step to G5 and -2 steps to D5', () {
        final f5 = Pitch.parse('F5');
        expect(f5.transposeDiatonic(1).scientificNotation, equals('G5'));
        expect(f5.transposeDiatonic(-2).scientificNotation, equals('D5'));
      });

      test('transposes C#4 by +1 step to D#4 (preserving accidental)', () {
        final cSharp4 = Pitch.parse('C#4');
        final transposed = cSharp4.transposeDiatonic(1);
        expect(transposed.scientificNotation, equals('D#4'));
        expect(transposed.accidental, equals(1));
      });

      test('transposes Bb4 by -1 step to Ab4 (preserving accidental)', () {
        final bFlat4 = Pitch.parse('Bb4');
        final transposed = bFlat4.transposeDiatonic(-1);
        expect(transposed.scientificNotation, equals('Ab4'));
        expect(transposed.accidental, equals(-1));
      });

      test('crosses octave boundary upwards from B to C', () {
        final b4 = Pitch.parse('B4');
        final c5 = b4.transposeDiatonic(1);
        expect(c5.step, equals(PitchStep.c));
        expect(c5.octave, equals(5));
        expect(c5.scientificNotation, equals('C5'));
      });

      test('crosses octave boundary downwards from C to B', () {
        final c4 = Pitch.parse('C4');
        final b3 = c4.transposeDiatonic(-1);
        expect(b3.step, equals(PitchStep.b));
        expect(b3.octave, equals(3));
        expect(b3.scientificNotation, equals('B3'));
      });

      test('transposes full octaves (deltaSteps = 7 and -7)', () {
        final c4 = Pitch.parse('C4');
        expect(c4.transposeDiatonic(7).scientificNotation, equals('C5'));
        expect(c4.transposeDiatonic(-7).scientificNotation, equals('C3'));
        expect(c4.transposeDiatonic(14).scientificNotation, equals('C6'));
        expect(c4.transposeDiatonic(0), equals(c4));
      });
    });

    group('MIDI and Frequency', () {
      test('computes standard MIDI note numbers', () {
        expect(Pitch.middleC.midiNumber, equals(60));
        expect(Pitch.concertA.midiNumber, equals(69));
        expect(Pitch.parse('C0').midiNumber, equals(12));
      });

      test('calculates acoustic frequency in Hz', () {
        expect(Pitch.concertA.frequencyHz, closeTo(440.0, 0.001));
        // A5 is 880 Hz
        expect(Pitch.parse('A5').frequencyHz, closeTo(880.0, 0.001));
      });

      test('reconstructs pitch from MIDI number via Pitch.fromMidi', () {
        final pitch60 = Pitch.fromMidi(60);
        expect(pitch60.scientificNotation, equals('C4'));

        final pitch61Sharp = Pitch.fromMidi(61, preferSharps: true);
        expect(pitch61Sharp.scientificNotation, equals('C#4'));

        final pitch61Flat = Pitch.fromMidi(61, preferSharps: false);
        expect(pitch61Flat.scientificNotation, equals('Db4'));
      });

      test('transposes chromatically by semitones', () {
        final c4 = Pitch.parse('C4');
        expect(
          c4.transposeChromatic(1, preferSharps: true).scientificNotation,
          equals('C#4'),
        );
        expect(c4.transposeChromatic(12).scientificNotation, equals('C5'));
      });
    });

    group('Equality and Comparable', () {
      test('implements Comparable based on pitch height', () {
        final c4 = Pitch.parse('C4');
        final d4 = Pitch.parse('D4');
        final c5 = Pitch.parse('C5');

        expect(c4.compareTo(d4), isNegative);
        expect(d4.compareTo(c4), isPositive);
        expect(c4.compareTo(c5), isNegative);
        expect(c4.compareTo(Pitch.parse('C4')), equals(0));
      });

      test('equals and hashCode evaluate step, accidental, and octave', () {
        final p1 = Pitch.parse('C#4');
        const p2 = Pitch(step: PitchStep.c, accidental: 1, octave: 4);
        expect(p1, equals(p2));
        expect(p1.hashCode, equals(p2.hashCode));
      });
    });
  });
}
