import 'dart:convert';

import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/services/song_import_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SongImportExportService', () {
    late Song testSong;

    setUp(() {
      testSong = Song(
        id: 'test-song-1',
        title: 'Cornerstone',
        artist: 'Hillsong Worship',
        key: 'C',
        tempo: 71,
        timeSignature: (4, 4),
        tags: const ['worship', 'faith'],
        sections: const [
          SongSection(
            id: 'sec-1',
            name: 'Verse 1',
            chords: [
              ChordCell(root: 'C'),
              ChordCell(root: 'F'),
              ChordCell(root: 'G'),
            ],
            lyrics: '[C]My hope is built on [F]nothing less than [G]Jesus blood',
            orderIndex: 0,
          ),
          SongSection(
            id: 'sec-2',
            name: 'Chorus',
            repeatCount: 2,
            chords: [
              ChordCell(root: 'C'),
              ChordCell(root: 'Am'),
              ChordCell(root: 'F'),
              ChordCell(root: 'G'),
            ],
            lyrics: '[C]Christ alone [Am]cornerstone [F]weak made strong in the [G]Savior',
            orderIndex: 1,
          ),
        ],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    });

    test('exports single song to JSON and imports it back losslessly', () {
      final jsonString = SongImportExportService.exportSongToJson(testSong);

      expect(SongImportExportService.isJson(jsonString), isTrue);

      final importedSong = SongImportExportService.parseSong(jsonString);

      expect(importedSong.id, testSong.id);
      expect(importedSong.title, testSong.title);
      expect(importedSong.artist, testSong.artist);
      expect(importedSong.key, testSong.key);
      expect(importedSong.tempo, testSong.tempo);
      expect(importedSong.sections.length, 2);
      expect(importedSong.sections[1].repeatCount, 2);
    });

    test('exports multiple songs to repertoire JSON backup and imports them back', () {
      final secondSong = testSong.copyWith(
        id: 'test-song-2',
        title: 'Build My Life',
        key: 'G',
      );

      final jsonArrayString = SongImportExportService.exportRepertoireToJson([testSong, secondSong]);

      expect(SongImportExportService.isJson(jsonArrayString), isTrue);

      final importedList = SongImportExportService.parseMultipleSongs(jsonArrayString);

      expect(importedList.length, 2);
      expect(importedList[0].title, 'Cornerstone');
      expect(importedList[1].title, 'Build My Life');
      expect(importedList[1].key, 'G');
    });

    test('parses plain text sheet with // comments into Song', () {
      const plainText = '''
// Title: Goodness of God
// Artist: Bethel Music
// Key: Ab
// Tempo: 70
// Time: 4/4

// Verse 1
[Ab]I love You Lord oh Your [Db]mercy never [Ab]fails

// Chorus (2x)
[Db]All my life You have been [Ab]faithful
''';

      expect(SongImportExportService.isJson(plainText), isFalse);

      final song = SongImportExportService.parseSong(plainText);

      expect(song.title, 'Goodness of God');
      expect(song.artist, 'Bethel Music');
      expect(song.key, 'Ab');
      expect(song.tempo, 70);
      expect(song.sections.length, 2);
      expect(song.sections[1].repeatCount, 2);
    });

    test('sanitizes external JSON with missing fields, string time signatures, and no IDs', () {
      final looseJson = jsonEncode({
        'title': 'Imported Hymn',
        'key': 'D',
        'timeSignature': '3/4',
        'sections': [
          {
            'name': 'Verse 1',
            'lyrics': '[D]Come thou fount of every blessing',
          }
        ],
      });

      final song = SongImportExportService.parseSong(looseJson);

      expect(song.title, 'Imported Hymn');
      expect(song.key, 'D');
      expect(song.timeSignature, (3, 4));
      expect(song.id, isNotEmpty);
      expect(song.sections.length, 1);
      expect(song.sections.first.id, isNotEmpty);
      expect(song.sections.first.orderIndex, 0);
    });
  });
}
