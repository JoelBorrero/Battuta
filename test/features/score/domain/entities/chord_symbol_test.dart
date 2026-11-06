import 'package:battuta/features/score/domain/entities/chord_symbol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChordSymbol', () {
    test('parses simple and complex chord symbols correctly', () {
      final g = ChordSymbol.parse('G');
      expect(g.root, equals('G'));
      expect(g.quality, isEmpty);
      expect(g.bass, isNull);
      expect(g.text, equals('G'));

      final am = ChordSymbol.parse('Am');
      expect(am.root, equals('A'));
      expect(am.quality, equals('m'));
      expect(am.bass, isNull);
      expect(am.text, equals('Am'));

      final cSharpMinor7 = ChordSymbol.parse('C#m7');
      expect(cSharpMinor7.root, equals('C#'));
      expect(cSharpMinor7.quality, equals('m7'));
      expect(cSharpMinor7.bass, isNull);
      expect(cSharpMinor7.text, equals('C#m7'));

      final bFlatOverD = ChordSymbol.parse('Bb/D');
      expect(bFlatOverD.root, equals('Bb'));
      expect(bFlatOverD.quality, isEmpty);
      expect(bFlatOverD.bass, equals('D'));
      expect(bFlatOverD.text, equals('Bb/D'));

      final dOverFSharp = ChordSymbol.parse('D/F#');
      expect(dOverFSharp.root, equals('D'));
      expect(dOverFSharp.bass, equals('F#'));
      expect(dOverFSharp.text, equals('D/F#'));

      final sus4 = ChordSymbol.parse('Gsus4', tickOffset: 240);
      expect(sus4.root, equals('G'));
      expect(sus4.quality, equals('sus4'));
      expect(sus4.tickOffset, equals(240));
    });

    test('throws FormatException on invalid chord strings', () {
      expect(() => ChordSymbol.parse(''), throwsFormatException);
      expect(() => ChordSymbol.parse('123'), throwsFormatException);
      expect(() => ChordSymbol.parse('Hmaj7'), throwsFormatException);
    });

    test('copyWith modifies attributes properly', () {
      final base = ChordSymbol.parse('C');
      final updated = base.copyWith(quality: 'maj7', tickOffset: 480);
      expect(updated.text, equals('Cmaj7'));
      expect(updated.tickOffset, equals(480));
    });

    test('equality and toString', () {
      final c1 = ChordSymbol.parse('Am7');
      const c2 = ChordSymbol(root: 'A', quality: 'm7');
      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1.toString(), contains('Am7'));
    });
  });
}
