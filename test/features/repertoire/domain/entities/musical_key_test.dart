import 'package:battuta/features/repertoire/domain/entities/musical_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MusicalKey', () {
    group('fromString factory', () {
      test('correctly parses standard major keys', () {
        expect(MusicalKey.fromString('C'), equals(MusicalKey.cMajor));
        expect(MusicalKey.fromString('G'), equals(MusicalKey.gMajor));
        expect(MusicalKey.fromString('D'), equals(MusicalKey.dMajor));
        expect(MusicalKey.fromString('F#'), equals(MusicalKey.fSharpMajor));
        expect(MusicalKey.fromString('Bb'), equals(MusicalKey.bbMajor));
        expect(MusicalKey.fromString('Eb'), equals(MusicalKey.ebMajor));
      });

      test('correctly parses minor keys', () {
        expect(MusicalKey.fromString('Am'), equals(MusicalKey.aMinor));
        expect(MusicalKey.fromString('Em'), equals(MusicalKey.eMinor));
        expect(MusicalKey.fromString('Bm'), equals(MusicalKey.bMinor));
        expect(MusicalKey.fromString('F#m'), equals(MusicalKey.fSharpMinor));
        expect(MusicalKey.fromString('Bbm'), equals(MusicalKey.bbMinor));
      });

      test('handles case-insensitivity and whitespace', () {
        expect(MusicalKey.fromString('  c  '), equals(MusicalKey.cMajor));
        expect(MusicalKey.fromString('am'), equals(MusicalKey.aMinor));
        expect(MusicalKey.fromString('f#M'), equals(MusicalKey.fSharpMinor));
      });

      test('throws ArgumentError on invalid key names', () {
        expect(() => MusicalKey.fromString('H'), throwsArgumentError);
        expect(() => MusicalKey.fromString('Z#'), throwsArgumentError);
        expect(() => MusicalKey.fromString(''), throwsArgumentError);
      });
    });

    group('accidental counts and properties', () {
      test('C Major has 0 accidentals', () {
        expect(MusicalKey.cMajor.accidentalCount, equals(0));
        expect(MusicalKey.cMajor.sharps, equals(0));
        expect(MusicalKey.cMajor.flats, equals(0));
        expect(MusicalKey.cMajor.useSharps, isTrue);
        expect(MusicalKey.cMajor.isMinor, isFalse);
      });

      test('sharp major keys report correct accidental count', () {
        expect(MusicalKey.gMajor.sharps, equals(1));
        expect(MusicalKey.dMajor.sharps, equals(2));
        expect(MusicalKey.aMajor.sharps, equals(3));
        expect(MusicalKey.eMajor.sharps, equals(4));
        expect(MusicalKey.bMajor.sharps, equals(5));
        expect(MusicalKey.fSharpMajor.sharps, equals(6));
        expect(MusicalKey.cSharpMajor.sharps, equals(7));
      });

      test('flat major keys report correct accidental count', () {
        expect(MusicalKey.fMajor.flats, equals(1));
        expect(MusicalKey.bbMajor.flats, equals(2));
        expect(MusicalKey.ebMajor.flats, equals(3));
        expect(MusicalKey.abMajor.flats, equals(4));
        expect(MusicalKey.dbMajor.flats, equals(5));
        expect(MusicalKey.gbMajor.flats, equals(6));
        expect(MusicalKey.cbMajor.flats, equals(7));
      });

      test('A minor has 0 accidentals and isMinor is true', () {
        expect(MusicalKey.aMinor.accidentalCount, equals(0));
        expect(MusicalKey.aMinor.isMinor, isTrue);
        expect(MusicalKey.aMinor.sharps, equals(0));
        expect(MusicalKey.aMinor.flats, equals(0));
      });
    });

    group('transposition', () {
      test('transposing C Major by +7 semitones yields G Major', () {
        final transposed = MusicalKey.cMajor.transpose(7);
        expect(transposed.semitoneIndex, equals(MusicalKey.gMajor.semitoneIndex));
        expect(transposed.isMinor, isFalse);
      });

      test('transposing C Major by +2 semitones yields D Major', () {
        final transposed = MusicalKey.cMajor.transpose(2);
        expect(transposed.semitoneIndex, equals(MusicalKey.dMajor.semitoneIndex));
      });

      test('transposing with negative semitones shifts downwards', () {
        // C - 2 semitones = Bb
        final transposed = MusicalKey.cMajor.transpose(-2);
        expect(transposed.semitoneIndex, equals(MusicalKey.bbMajor.semitoneIndex));
      });

      test('transposing by full octave (12 semitones) preserves pitch class', () {
        final transposed = MusicalKey.eMajor.transpose(12);
        expect(transposed.semitoneIndex, equals(MusicalKey.eMajor.semitoneIndex));
      });

      test('transposing minor keys maintains minor quality', () {
        final transposed = MusicalKey.aMinor.transpose(7);
        expect(transposed.isMinor, isTrue);
        expect(transposed.semitoneIndex, equals(MusicalKey.eMinor.semitoneIndex));
      });
    });

    group('relative and parallel keys', () {
      test('relative of C Major is A Minor', () {
        expect(MusicalKey.cMajor.relative, equals(MusicalKey.aMinor));
      });

      test('relative of A Minor is C Major', () {
        expect(MusicalKey.aMinor.relative, equals(MusicalKey.cMajor));
      });

      test('relative of G Major is E Minor', () {
        expect(MusicalKey.gMajor.relative, equals(MusicalKey.eMinor));
      });

      test('parallel of C Major is C Minor', () {
        expect(MusicalKey.cMajor.parallel, equals(MusicalKey.cMinor));
      });

      test('parallel of C Minor is C Major', () {
        expect(MusicalKey.cMinor.parallel, equals(MusicalKey.cMajor));
      });

      test('parallel of A Minor is A Major', () {
        expect(MusicalKey.aMinor.parallel, equals(MusicalKey.aMajor));
      });
    });

    group('equality and toString', () {
      test('same keys are equal and produce same hashCode', () {
        final key1 = MusicalKey.fromString('G');
        const key2 = MusicalKey.gMajor;
        expect(key1, equals(key2));
        expect(key1.hashCode, equals(key2.hashCode));
      });

      test('major and minor keys with same root are not equal', () {
        expect(MusicalKey.cMajor, isNot(equals(MusicalKey.cMinor)));
      });

      test('toString includes key name', () {
        expect(MusicalKey.cMajor.toString(), equals('MusicalKey(C)'));
        expect(MusicalKey.aMinor.toString(), equals('MusicalKey(Am)'));
      });
    });
  });
}
