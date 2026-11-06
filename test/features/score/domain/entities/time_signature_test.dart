import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeSignature', () {
    test('calculates correct maxTicks for standard meters', () {
      // 4/4 = 4 * 480 = 1920 ticks
      expect(TimeSignature.fourFour.maxTicks, equals(1920));
      expect(TimeSignature.fourFour.ticksPerBeat, equals(480));
      expect(TimeSignature.fourFour.isCompound, isFalse);

      // 3/4 = 3 * 480 = 1440 ticks
      expect(TimeSignature.threeFour.maxTicks, equals(1440));
      expect(TimeSignature.threeFour.ticksPerBeat, equals(480));

      // 2/4 = 2 * 480 = 960 ticks
      expect(TimeSignature.twoFour.maxTicks, equals(960));

      // 6/8 = 6 * 240 = 1440 ticks (compound duple: 2 macro beats)
      expect(TimeSignature.sixEight.maxTicks, equals(1440));
      expect(TimeSignature.sixEight.ticksPerBeat, equals(240));
      expect(TimeSignature.sixEight.isCompound, isTrue);
      expect(TimeSignature.sixEight.beatCount, equals(2));

      // 12/8 = 12 * 240 = 2880 ticks (compound quadruple: 4 macro beats)
      expect(TimeSignature.twelveEight.maxTicks, equals(2880));
      expect(TimeSignature.twelveEight.isCompound, isTrue);
      expect(TimeSignature.twelveEight.beatCount, equals(4));

      // 2/2 = 2 * 960 = 1920 ticks
      expect(TimeSignature.twoTwo.maxTicks, equals(1920));
    });

    test('parse handles fraction strings and common shorthand', () {
      expect(TimeSignature.parse('4/4'), equals(TimeSignature.fourFour));
      expect(TimeSignature.parse('3/4'), equals(TimeSignature.threeFour));
      expect(TimeSignature.parse('6/8'), equals(TimeSignature.sixEight));
      expect(TimeSignature.parse('C'), equals(TimeSignature.fourFour));
      expect(TimeSignature.parse('c'), equals(TimeSignature.fourFour));
      expect(TimeSignature.parse('¢'), equals(TimeSignature.twoTwo));
      expect(TimeSignature.parse('cut'), equals(TimeSignature.twoTwo));
    });

    test('parse throws FormatException on invalid inputs', () {
      expect(() => TimeSignature.parse(''), throwsFormatException);
      expect(() => TimeSignature.parse('invalid'), throwsFormatException);
      expect(() => TimeSignature.parse('4/'), throwsFormatException);
      expect(() => TimeSignature.parse('a/b'), throwsFormatException);
    });

    test('equality and toString', () {
      const ts1 = TimeSignature(4, 4);
      const ts2 = TimeSignature.fourFour;
      expect(ts1, equals(ts2));
      expect(ts1.hashCode, equals(ts2.hashCode));
      expect(ts1.toString(), equals('4/4'));
    });
  });
}
