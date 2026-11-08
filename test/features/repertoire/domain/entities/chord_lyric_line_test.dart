import 'package:battuta/features/repertoire/domain/entities/chord_lyric_line.dart';
import 'package:battuta/features/repertoire/domain/services/song_transposer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChordLyricsParser', () {
    test('hasChordPro detects bracketed chord tags', () {
      expect(ChordLyricsParser.hasChordPro('[G]Amazing grace'), isTrue);
      expect(ChordLyricsParser.hasChordPro('Amazing grace'), isFalse);
      expect(ChordLyricsParser.hasChordPro(''), isFalse);
      expect(ChordLyricsParser.hasChordPro(null), isFalse);
    });

    test('stripChords removes all bracketed chords', () {
      const input = '[G]Amazing [C]grace how [G]sweet the sound';
      expect(
        ChordLyricsParser.stripChords(input),
        equals('Amazing grace how sweet the sound'),
      );
    });

    test('parse parses single line with chords over words', () {
      const input = '[G]Amazing [C]grace how [G]sweet the sound';
      final lines = ChordLyricsParser.parse(input);

      expect(lines.length, equals(1));
      final line = lines.first;
      expect(line.hasChords, isTrue);
      expect(line.tokens.length, equals(6));

      expect(line.tokens[0].word, equals('Amazing'));
      expect(line.tokens[0].chord, equals('G'));

      expect(line.tokens[1].word, equals('grace'));
      expect(line.tokens[1].chord, equals('C'));

      expect(line.tokens[2].word, equals('how'));
      expect(line.tokens[2].chord, isNull);

      expect(line.tokens[3].word, equals('sweet'));
      expect(line.tokens[3].chord, equals('G'));

      expect(line.tokens[4].word, equals('the'));
      expect(line.tokens[4].chord, isNull);

      expect(line.tokens[5].word, equals('sound'));
      expect(line.tokens[5].chord, isNull);
    });

    test('parse parses multi-line ChordPro and reconstructs with toChordPro', () {
      const input =
          '[E]Aquí estás, te vemos [B]mover\n[C#m]Te adoraré, [A]te adoraré';
      final lines = ChordLyricsParser.parse(input);

      expect(lines.length, equals(2));
      expect(lines[0].tokens[0].chord, equals('E'));
      expect(lines[0].tokens[0].word, equals('Aquí'));

      final reconstructed = ChordLyricsParser.toChordPro(lines);
      expect(reconstructed, equals(input));
    });

    test('parse handles plain text lyrics without chords', () {
      const input = 'Amazing grace how sweet the sound\nThat saved a wretch';
      final lines = ChordLyricsParser.parse(input);

      expect(lines.length, equals(2));
      expect(lines[0].hasChords, isFalse);
      expect(lines[0].tokens.first.chord, isNull);
      expect(lines[0].tokens.first.word, equals('Amazing'));
    });

    test('parse handles empty or null input gracefully', () {
      expect(ChordLyricsParser.parse(null), isEmpty);
      expect(ChordLyricsParser.parse(''), isEmpty);
      expect(ChordLyricsParser.parse('   '), isEmpty);
    });

    test('autoDistribute places section chords evenly across words', () {
      const lyrics = 'Amazing grace how sweet the sound that saved a wretch like me';
      final result = ChordLyricsParser.autoDistribute(
        plainLyrics: lyrics,
        chords: ['G', 'C', 'G', 'D'],
      );

      expect(ChordLyricsParser.hasChordPro(result), isTrue);
      expect(result, contains('[G]'));
      expect(result, contains('[C]'));
      expect(result, contains('[D]'));

      final clean = ChordLyricsParser.stripChords(result);
      expect(clean.replaceAll(RegExp(r'\s+'), ' ').trim(), equals(lyrics));
    });
  });

  group('SongTransposer.transposeChordProText', () {
    test('transposes inline chord brackets accurately', () {
      const input = '[G]Amazing [C]grace how [G]sweet the sound\n[D]That saved';
      final transposed = SongTransposer.transposeChordProText(input, 2);

      expect(
        transposed,
        equals('[A]Amazing [D]grace how [A]sweet the sound\n[E]That saved'),
      );
    });

    test('transposes slash chords within brackets', () {
      const input = '[D/F#]Grace so [G]free';
      final transposed = SongTransposer.transposeChordProText(input, 2);

      expect(transposed, equals('[E/G#]Grace so [A]free'));
    });

    test('preserves non-chord bracket annotations like [Intro]', () {
      const input = '[Intro] [G] [C]';
      final transposed = SongTransposer.transposeChordProText(input, 2);

      expect(transposed, equals('[Intro] [A] [D]'));
    });

    test('returns original string when semitones is 0', () {
      const input = '[G]Amazing [C]grace';
      expect(SongTransposer.transposeChordProText(input, 0), equals(input));
    });
  });
}
