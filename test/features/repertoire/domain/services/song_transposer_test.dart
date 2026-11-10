import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/services/song_transposer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SongTransposer', () {
    test('transposeNote correctly transposes sharps and flats', () {
      expect(SongTransposer.transposeNote('C', 2), equals('D'));
      expect(SongTransposer.transposeNote('C', 7), equals('G'));
      expect(
        SongTransposer.transposeNote('C', -1, preferSharps: true),
        equals('B'),
      );
      expect(
        SongTransposer.transposeNote('G', 2, preferSharps: true),
        equals('A'),
      );
      expect(
        SongTransposer.transposeNote('F', 1, preferSharps: true),
        equals('F#'),
      );
      expect(
        SongTransposer.transposeNote('F', 1, preferSharps: false),
        equals('Gb'),
      );
    });

    test('transposeChord transposes root and bass while preserving quality and beats', () {
      const chord = ChordCell(
        root: 'C',
        quality: ChordQuality.minor7,
        bass: 'E',
        beats: 4,
      );

      final transposed = SongTransposer.transposeChord(
        chord,
        2,
        preferSharps: true,
      );

      expect(transposed.root, equals('D'));
      expect(transposed.bass, equals('F#'));
      expect(transposed.quality, equals(ChordQuality.minor7));
      expect(transposed.beats, equals(4));
    });

    test('transposeSong shifts song key and all section chords', () {
      final song = Song(
        id: 'test-song',
        title: 'Stand by Me',
        artist: 'Ben E. King',
        key: 'A',
        tempo: 118,
        sections: [
          const SongSection(
            id: 'sec-1',
            name: 'Verse',
            orderIndex: 0,
            chords: [
              ChordCell(root: 'A', quality: ChordQuality.major, beats: 4),
              ChordCell(root: 'F#', quality: ChordQuality.minor, beats: 4),
              ChordCell(root: 'D', quality: ChordQuality.major, beats: 2),
              ChordCell(root: 'E', quality: ChordQuality.dominant7, beats: 2),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Transpose +3 semitones: A -> C
      final transposed = SongTransposer.transposeSong(song, 3);

      expect(transposed.key, equals('C'));
      expect(transposed.sections.first.chords[0].root, equals('C'));
      expect(transposed.sections.first.chords[1].root, equals('A'));
      expect(
        transposed.sections.first.chords[1].quality,
        equals(ChordQuality.minor),
      );
      expect(transposed.sections.first.chords[2].root, equals('F'));
      expect(transposed.sections.first.chords[3].root, equals('G'));
      expect(
        transposed.sections.first.chords[3].quality,
        equals(ChordQuality.dominant7),
      );
    });
  });

  group('SongTransposer hardening', () {
    Song songWith({
      required String key,
      List<ChordCell> chords = const [],
      String? lyrics,
    }) {
      return Song(
        id: 's',
        title: 't',
        artist: 'a',
        key: key,
        tempo: 100,
        sections: [
          SongSection(
            id: 'sec',
            name: 'Verse',
            orderIndex: 0,
            chords: chords,
            lyrics: lyrics,
          ),
        ],
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
    }

    test('custom chord keeps its suffix when transposed', () {
      expect(SongTransposer.transposeChordString('Cmaj7#11', 2), 'Dmaj7#11');
    });

    test('custom chord with slash bass transposes root and bass', () {
      expect(SongTransposer.transposeChordString('C7sus4/G', 2), 'D7sus4/A');
    });

    test('custom ChordCell label is rebuilt on transposeChord', () {
      final cell = ChordParser.parseChord('Cmaj7#11')!;
      final t = SongTransposer.transposeChord(cell, 2, preferSharps: true);
      expect(t.displayLabel, 'Dmaj7#11');
      expect(t.root, 'D');
    });

    test('lowercase custom root is normalised to upper case', () {
      expect(SongTransposer.transposeChordString('cmaj7#11', 2), 'Dmaj7#11');
    });

    test('custom label not starting with root is left unchanged', () {
      for (final label in ['N.C.', 'Riff']) {
        final cell = ChordCell(
          root: 'C',
          quality: ChordQuality.custom,
          customLabel: label,
        );
        final t = SongTransposer.transposeChord(cell, 2, preferSharps: true);
        expect(t, cell);
        expect(t.displayLabel, label);
      }
    });

    test('slash chord with non-note bass does not throw', () {
      expect(SongTransposer.transposeChordString('C/9', 2), 'D/9');
    });

    test('enharmonic roots Fb E# Cb B# follow preferSharps', () {
      expect(SongTransposer.transposeNote('Fb', 1, preferSharps: true), 'F');
      expect(SongTransposer.transposeNote('E#', 1, preferSharps: true), 'F#');
      expect(SongTransposer.transposeNote('E#', 1, preferSharps: false), 'Gb');
      expect(SongTransposer.transposeNote('Cb', 1, preferSharps: false), 'C');
      expect(SongTransposer.transposeNote('B#', 1, preferSharps: true), 'C#');
      expect(SongTransposer.transposeNote('B#', 1, preferSharps: false), 'Db');
      expect(SongTransposer.transposeNote('Cb', 0, preferSharps: true), 'B');
    });

    test('negative and large semitones wrap', () {
      expect(SongTransposer.transposeNote('C', -1), 'B');
      expect(SongTransposer.transposeNote('C', -13), 'B');
      expect(SongTransposer.transposeNote('C', 25), 'C#');
      expect(SongTransposer.transposeChordString('Am7', -13), 'G#m7');
      expect(SongTransposer.transposeChordString('Am7', 12), 'Am7');
    });

    test('non-chord bracket tags are untouched, chords transposed', () {
      const input =
          '[Intro] [Chorus] [x2] [Verse 1] [Bridge] [Am] [Em] '
          '[am] [en] word';
      final out = SongTransposer.transposeChordProText(input, 2);
      expect(
        out,
        '[Intro] [Chorus] [x2] [Verse 1] [Bridge] [Bm] [F#m] [am] [en] word',
      );
    });

    test('transposeSong survives unparseable keys', () {
      for (final key in ['', 'D minor', 'am', 'Dm', 'garbage']) {
        final t = SongTransposer.transposeSong(
          songWith(
            key: key,
            chords: const [ChordCell(root: 'D', quality: ChordQuality.minor)],
          ),
          2,
        );
        expect(t.sections.first.chords.first.root, 'E');
      }
      expect(SongTransposer.transposeSong(songWith(key: 'Dm'), 2).key, 'Em');
      expect(SongTransposer.transposeSong(songWith(key: 'am'), 2).key, 'Bm');
      expect(SongTransposer.transposeSong(songWith(key: ''), 2).key, '');
      expect(
        SongTransposer.transposeSong(songWith(key: 'D minor'), 2).key,
        'E minor',
      );
    });

    test('round trip +N then -N restores sharp-only and flat-only songs', () {
      const sharpChords = [
        ChordCell(root: 'C'),
        ChordCell(root: 'F#', quality: ChordQuality.minor7, bass: 'C#'),
        ChordCell(root: 'G', quality: ChordQuality.dominant7),
      ];
      const flatChords = [
        ChordCell(root: 'Bb'),
        ChordCell(root: 'Eb', quality: ChordQuality.minor7, bass: 'Ab'),
        ChordCell(root: 'F', quality: ChordQuality.dominant7),
      ];
      for (final n in [1, 2, 5, 7, 11]) {
        final up = SongTransposer.transposeSong(
          songWith(key: 'C', chords: sharpChords),
          n,
        );
        final back = SongTransposer.transposeSong(up, -n);
        expect(back.sections.first.chords.map((c) => c.root).toList(), [
          'C',
          'F#',
          'G',
        ], reason: 'sharp song +$n/-$n');
        expect(back.sections.first.chords[1].bass, 'C#');
      }
      for (final n in [1, 2, 5, 7, 11]) {
        final up = SongTransposer.transposeSong(
          songWith(key: 'F', chords: flatChords),
          n,
        );
        final back = SongTransposer.transposeSong(up, -n);
        expect(back.sections.first.chords.map((c) => c.root).toList(), [
          'Bb',
          'Eb',
          'F',
        ], reason: 'flat song +$n/-$n');
        expect(back.sections.first.chords[1].bass, 'Ab');
      }
    });
  });

  group('ChordParser', () {
    test('parses whitespace and bar separated progressions', () {
      final chords = ChordParser.parseProgression('C | G/B | Am7 | Fmaj7');

      expect(chords.length, equals(4));
      expect(chords[0].root, equals('C'));
      expect(chords[0].quality, equals(ChordQuality.major));

      expect(chords[1].root, equals('G'));
      expect(chords[1].bass, equals('B'));

      expect(chords[2].root, equals('A'));
      expect(chords[2].quality, equals(ChordQuality.minor7));

      expect(chords[3].root, equals('F'));
      expect(chords[3].quality, equals(ChordQuality.major7));
    });

    test('parses suspended, diminished, and augmented chords', () {
      final chords = ChordParser.parseProgression('Dsus4 Edim Aaug Cadd9');

      expect(chords[0].quality, equals(ChordQuality.sus4));
      expect(chords[1].quality, equals(ChordQuality.diminished));
      expect(chords[2].quality, equals(ChordQuality.augmented));
      expect(chords[3].quality, equals(ChordQuality.add9));
    });

    test('returns empty list for blank or invalid strings', () {
      expect(ChordParser.parseProgression(''), isEmpty);
      expect(ChordParser.parseProgression('   | | - / '), isEmpty);
    });
  });
}
