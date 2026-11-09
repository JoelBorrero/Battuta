import 'package:battuta/features/repertoire/domain/services/song_text_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SongTextParser', () {
    test('parses metadata comments and values', () {
      const input = '''
// Title: 10,000 Reasons
// Artist: Matt Redman
// Key: G
// Tempo: 73
// Time: 4/4
// Tags: worship, contemporary

// Verse 1
[G]Bless the [C]Lord oh my [G]soul
''';

      final song = SongTextParser.parse(rawText: input);

      expect(song.title, '10,000 Reasons');
      expect(song.artist, 'Matt Redman');
      expect(song.key, 'G');
      expect(song.tempo, 73);
      expect(song.timeSignature, (4, 4));
      expect(song.tags, containsAll(['worship', 'contemporary']));
      expect(song.sections.length, 1);
      expect(song.sections.first.name, 'Verse 1');
      expect(song.sections.first.lyrics, contains('[G]Bless the [C]Lord'));
    });

    test('splits sections based on // double slash comments and keywords', () {
      const input = '''
// Title: Sample Song

// Intro
G | C | Em | D

// Verse 1
[G]Here is verse one [C]lyrics

// Chorus
[G]This is the chorus [D]part

// Bridge
[Em]And here is the [C]bridge

// Outro
[G]Ending the song
''';

      final song = SongTextParser.parse(rawText: input);

      expect(song.sections.length, 5);
      expect(song.sections[0].name, 'Intro');
      expect(song.sections[1].name, 'Verse 1');
      expect(song.sections[2].name, 'Chorus');
      expect(song.sections[3].name, 'Bridge');
      expect(song.sections[4].name, 'Outro');
    });

    test('recognizes Spanish section keywords (Coro, Puente, Verso)', () {
      const input = '''
// Title: Canción de Ejemplo

// Verso 1
[C]Canto un verso [F]nuevo

// Pre-coro
[Am]Preparando el [G]camino

// Coro
[C]Gloria en las [G]alturas

// Puente
[F]Santo, [G]Santo es el [C]Señor

// Final
[C]Amén
''';

      final song = SongTextParser.parse(rawText: input);

      expect(song.sections.length, 5);
      expect(song.sections[0].name, 'Verse 1');
      expect(song.sections[1].name, 'Pre-Chorus');
      expect(song.sections[2].name, 'Chorus');
      expect(song.sections[3].name, 'Bridge');
      expect(song.sections[4].name, 'Outro');
    });

    test('parses descriptive comment saying "this is a chorus" into Chorus section', () {
      const input = '''
// Title: Flexible Comments

// Verse 1
[D]Beginning of song

// This is a chorus
[G]Singing the chorus loud
''';

      final song = SongTextParser.parse(rawText: input);

      expect(song.sections.length, 2);
      expect(song.sections[0].name, 'Verse 1');
      expect(song.sections[1].name, 'Chorus');
    });

    test('extracts section repeat counts from headers like // Chorus (2x) or // Coro x2', () {
      const input = '''
// Verse 1
[G]Line one

// Chorus (2x)
[C]Repeat this chorus twice

// Bridge x3
[D]Repeat this bridge three times
''';

      final song = SongTextParser.parse(rawText: input);

      expect(song.sections[0].repeatCount, 1);
      expect(song.sections[1].repeatCount, 2);
      expect(song.sections[1].name, 'Chorus');
      expect(song.sections[2].repeatCount, 3);
      expect(song.sections[2].name, 'Bridge');
    });

    test('attaches non-keyword comments inside sections to rehearsalNotes', () {
      const input = '''
// Verse 1
// Note: Acoustic guitar only
[G]Soft acoustic line

// Chorus
// Note: Full band in with strong beat
[C]Loud chorus
''';

      final song = SongTextParser.parse(rawText: input);

      expect(song.sections[0].rehearsalNotes, 'Acoustic guitar only');
      expect(song.sections[1].rehearsalNotes, 'Full band in with strong beat');
    });

    test('merges two-line chords-over-lyrics into ChordPro brackets', () {
      const input = '''
// Title: Two-Line Chart

// Verse 1
G       C        G
Amazing grace how sweet the sound
             D
That saved a wretch like me
''';

      final song = SongTextParser.parse(rawText: input);

      expect(song.sections.length, 1);
      final lyrics = song.sections.first.lyrics!;
      expect(lyrics, contains('[G]Amazing'));
      expect(lyrics, contains('[C]grace'));
      expect(lyrics, contains('[D]wretch'));
      expect(song.sections.first.chords, isNotEmpty);
    });

    test('serializes song to formatted plain text roundtrip', () {
      const input = '''
// Title: Way Maker
// Artist: Sinach
// Key: E
// Tempo: 68
// Time: 4/4
// Tags: praise

// Verse 1
[E]You are here moving in our [B]midst
I worship [C#m]You I worship [A]You

// Chorus (2x)
// Note: Drums build up
[E]Way maker miracle worker [B]promise keeper
''';

      final parsed = SongTextParser.parse(rawText: input);
      final exportedText = SongTextParser.toPlainText(parsed);

      expect(exportedText, contains('// Title: Way Maker'));
      expect(exportedText, contains('// Artist: Sinach'));
      expect(exportedText, contains('// Key: E'));
      expect(exportedText, contains('// Tempo: 68'));
      expect(exportedText, contains('// Time: 4/4'));
      expect(exportedText, contains('// Verse 1'));
      expect(exportedText, contains('// Chorus (2x)'));
      expect(exportedText, contains('// Note: Drums build up'));

      // Roundtrip re-parse
      final reparsed = SongTextParser.parse(rawText: exportedText);
      expect(reparsed.title, 'Way Maker');
      expect(reparsed.artist, 'Sinach');
      expect(reparsed.key, 'E');
      expect(reparsed.sections.length, 2);
      expect(reparsed.sections[1].repeatCount, 2);
      expect(reparsed.sections[1].rehearsalNotes, 'Drums build up');
    });
  });
}
