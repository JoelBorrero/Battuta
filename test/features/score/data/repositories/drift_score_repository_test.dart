import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/score/data/repositories/drift_score_repository.dart';
import 'package:battuta/features/score/domain/entities/chord_symbol.dart';
import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftScoreRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftScoreRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group(
    'DriftScoreRepository (Checklist: Lossless Score Tree Persistence)',
    () {
      test('Saving and reloading a Score preserves all Section, Measure, NoteEvent, and ChordSymbol properties without data loss', () async {
        // 1. Build detailed NoteEvents including pitches, rests, lyrics, ties, velocity
        final note1 = NoteEvent.note(
          id: 'n1',
          pitch: Pitch.parse('C#4'),
          rhythmicValue: RhythmicValue.quarter,
          tickOffset: 0,
          isTied: true,
          lyric: 'Gra-',
          velocity: 95,
        );

        const rest = NoteEvent.rest(
          id: 'r1',
          rhythmicValue: RhythmicValue.eighth,
          tickOffset: 480,
        );

        final note2 = NoteEvent.note(
          id: 'n2',
          pitch: Pitch.parse('Bb4'),
          rhythmicValue: RhythmicValue.eighth,
          tickOffset: 720,
          lyric: 'cious',
          velocity: 85,
        );

        final note3 = NoteEvent.note(
          id: 'n3',
          pitch: Pitch.parse('F5'),
          rhythmicValue: RhythmicValue.half,
          tickOffset: 960,
          lyric: 'Lord',
        );

        // 2. Build ChordSymbols with roots, qualities, bass notes, tick offsets
        final chord1 = ChordSymbol.parse('C#m7', tickOffset: 0);
        final chord2 = ChordSymbol.parse('F#/A#', tickOffset: 960);

        // 3. Build Measures
        final measure1 = Measure(
          number: 1,
          timeSignature: TimeSignature.fourFour,
          events: [note1, rest, note2, note3],
          chords: [chord1, chord2],
        );

        final measure2 = Measure(
          number: 2,
          timeSignature: TimeSignature.fourFour,
          events: [
            NoteEvent.note(
              id: 'n4',
              pitch: Pitch.parse('G#4'),
              rhythmicValue: RhythmicValue.whole,
              tickOffset: 0,
              lyric: 'Amen',
            ),
          ],
          chords: [ChordSymbol.parse('G#sus4')],
        );

        // 4. Build Sections with externalSyncId for v1.1 sync
        final sectionVerse = Section(
          id: 'sec-verse-1',
          name: 'Verse 1',
          externalSyncId: 'propresenter-uuid-verse-1234',
          measures: [measure1],
          repeatCount: 1,
          orderIndex: 0,
        );

        final sectionChorus = Section(
          id: 'sec-chorus',
          name: 'Chorus',
          externalSyncId: 'propresenter-uuid-chorus-5678',
          measures: [measure2],
          repeatCount: 2,
          orderIndex: 1,
        );

        // 5. Build Score
        final originalScore = Score(
          id: 'score-777',
          title: 'Amazing Grace (My Chains Are Gone)',
          composer: 'Chris Tomlin & Louie Giglio',
          artist: 'Chris Tomlin',
          timeSignature: TimeSignature.fourFour,
          keySignature: 'E',
          tempo: 65,
          sections: [sectionVerse, sectionChorus],
          metadata: const {
            'ccli': 4768151,
            'copyright': '2006 worshiptogether.com songs',
          },
        );

        // 6. Save Score to offline database
        final saveResult = await repository.saveScore(
          originalScore,
          songId: 'song-grace-1',
        );
        expect(saveResult.isRight(), isTrue);

        // 7. Reload Score from offline database
        final getResult = await repository.getScoreById('score-777');
        expect(getResult.isRight(), isTrue);

        final reloadedScore = getResult.getOrElse((_) => throw 'Failed');

        // 8. Verify exact equality of Score tree
        expect(reloadedScore, equals(originalScore));

        // 9. Deep verification of Section properties & externalSyncId
        expect(reloadedScore.sections.length, equals(2));
        final reloadedVerse = reloadedScore.sections[0];
        expect(reloadedVerse.id, equals('sec-verse-1'));
        expect(reloadedVerse.name, equals('Verse 1'));
        expect(
          reloadedVerse.externalSyncId,
          equals('propresenter-uuid-verse-1234'),
        );
        expect(reloadedVerse.repeatCount, equals(1));
        expect(reloadedVerse.orderIndex, equals(0));

        final reloadedChorus = reloadedScore.sections[1];
        expect(
          reloadedChorus.externalSyncId,
          equals('propresenter-uuid-chorus-5678'),
        );
        expect(reloadedChorus.repeatCount, equals(2));

        // 10. Deep verification of Measure properties
        expect(reloadedVerse.measures.length, equals(1));
        final m1 = reloadedVerse.measures[0];
        expect(m1.number, equals(1));
        expect(m1.timeSignature, equals(TimeSignature.fourFour));
        expect(m1.totalTicks, equals(1920));
        expect(m1.isComplete, isTrue);

        // 11. Deep verification of NoteEvents (pitches, rests, ties, lyrics, velocities)
        expect(m1.events.length, equals(4));

        // Event 0: C#4 tied note
        expect(m1.events[0].id, equals('n1'));
        expect(m1.events[0].isNote, isTrue);
        expect(m1.events[0].pitch?.scientificNotation, equals('C#4'));
        expect(m1.events[0].rhythmicValue, equals(RhythmicValue.quarter));
        expect(m1.events[0].tickOffset, equals(0));
        expect(m1.events[0].isTied, isTrue);
        expect(m1.events[0].lyric, equals('Gra-'));
        expect(m1.events[0].velocity, equals(95));

        // Event 1: Rest
        expect(m1.events[1].id, equals('r1'));
        expect(m1.events[1].isRest, isTrue);
        expect(m1.events[1].pitch, isNull);
        expect(m1.events[1].rhythmicValue, equals(RhythmicValue.eighth));
        expect(m1.events[1].tickOffset, equals(480));

        // Event 2: Bb4 note
        expect(m1.events[2].pitch?.scientificNotation, equals('Bb4'));
        expect(m1.events[2].rhythmicValue, equals(RhythmicValue.eighth));
        expect(m1.events[2].tickOffset, equals(720));
        expect(m1.events[2].lyric, equals('cious'));

        // Event 3: F5 note
        expect(m1.events[3].pitch?.scientificNotation, equals('F5'));
        expect(m1.events[3].rhythmicValue, equals(RhythmicValue.half));
        expect(m1.events[3].tickOffset, equals(960));
        expect(m1.events[3].lyric, equals('Lord'));

        // 12. Deep verification of ChordSymbols (roots, qualities, bass notes, offsets)
        expect(m1.chords.length, equals(2));
        expect(m1.chords[0].root, equals('C#'));
        expect(m1.chords[0].quality, equals('m7'));
        expect(m1.chords[0].bass, isNull);
        expect(m1.chords[0].tickOffset, equals(0));

        expect(m1.chords[1].root, equals('F#'));
        expect(m1.chords[1].bass, equals('A#'));
        expect(m1.chords[1].tickOffset, equals(960));
        expect(m1.chords[1].text, equals('F#/A#'));

        // 13. Query by SongId
        final songScoreResult = await repository.getScoreBySongId(
          'song-grace-1',
        );
        expect(songScoreResult.isRight(), isTrue);
        expect(songScoreResult.getOrElse((_) => null), equals(originalScore));
      });

      test('deleteScore removes score from database', () async {
        const score = Score(
          id: 's-to-delete',
          title: 'Temporary Score',
          sections: [],
        );

        await repository.saveScore(score);
        final deleteResult = await repository.deleteScore('s-to-delete');
        expect(deleteResult.isRight(), isTrue);

        final getResult = await repository.getScoreById('s-to-delete');
        expect(getResult.isLeft(), isTrue);
      });

      test('watchScore streams score updates', () async {
        final stream = repository.watchScore('watched-score');
        final emissions = <Score?>[];
        final sub = stream.listen(emissions.add);

        await pumpEventQueue();
        expect(emissions.last, isNull);

        const score = Score(
          id: 'watched-score',
          title: 'Watched Song',
          sections: [],
        );
        await repository.saveScore(score);

        await pumpEventQueue();
        expect(emissions.last?.title, equals('Watched Song'));

        await sub.cancel();
      });
    },
  );
}
