import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_score_mapper.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SongScoreMapper', () {
    test('converts basic Song to valid Score hierarchy', () {
      final song = Song(
        id: 'song-123',
        title: 'Autumn Leaves',
        artist: 'Joseph Kosma',
        key: 'Gm',
        tempo: 140,
        timeSignature: (4, 4),
        tags: const ['jazz', 'standard'],
        notes: 'Play with swing feel',
        sections: [
          const SongSection(
            id: 'sec-a',
            name: 'Section A',
            repeatCount: 2,
            orderIndex: 0,
            chords: [
              ChordCell(root: 'C', quality: ChordQuality.minor7, beats: 4),
              ChordCell(root: 'F', quality: ChordQuality.dominant7, beats: 4),
              ChordCell(root: 'Bb', quality: ChordQuality.major7, beats: 4),
              ChordCell(root: 'Eb', quality: ChordQuality.major7, beats: 4),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final score = song.toScore();

      expect(score.id, equals('song-123'));
      expect(score.title, equals('Autumn Leaves'));
      expect(score.artist, equals('Joseph Kosma'));
      expect(score.keySignature, equals('Gm'));
      expect(score.tempo, equals(140));
      expect(score.timeSignature.numerator, equals(4));
      expect(score.timeSignature.denominator, equals(4));
      expect(score.metadata['notes'], equals('Play with swing feel'));

      expect(score.sections.length, equals(1));
      final section = score.sections.first;
      expect(section.name, equals('Section A'));
      expect(section.repeatCount, equals(2));
      expect(section.measures.length, equals(4));

      // Measure 1: Cm7
      final m1 = section.measures[0];
      expect(m1.chords.length, equals(1));
      expect(m1.chords.first.root, equals('C'));
      expect(m1.chords.first.quality, equals('m7'));
      expect(m1.events.length, equals(1));
    });

    test('handles empty section with rest measure', () {
      final song = Song(
        id: 'empty-song',
        title: 'Empty Song',
        artist: 'Artist',
        key: 'C',
        tempo: 120,
        sections: const [
          SongSection(
            id: 'sec-empty',
            name: 'Intro',
            orderIndex: 0,
            chords: [],
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final score = song.toScore();
      expect(score.sections.first.measures.length, equals(1));
      expect(score.sections.first.measures.first.events.first.isRest, isTrue);
    });
  });
}

