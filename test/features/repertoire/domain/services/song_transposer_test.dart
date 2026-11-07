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
