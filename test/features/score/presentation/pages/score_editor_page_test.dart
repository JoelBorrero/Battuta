import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/score/presentation/pages/score_editor_page.dart';
import 'package:battuta/features/score/presentation/widgets/rhythm_toolbar.dart';
import 'package:battuta/features/score/presentation/widgets/staff_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemorySongRepository repository;

  final sampleSong = Song(
    id: 'score-song-1',
    title: 'Holy, Holy, Holy',
    artist: 'Reginald Heber',
    key: 'D',
    tempo: 96,
    timeSignature: (4, 4),
    tags: const ['Hymn', 'Classic'],
    sections: const [
      SongSection(
        id: 'sec-chorus',
        name: 'Chorus',
        repeatCount: 1,
        orderIndex: 0,
        chords: [
          ChordCell(root: 'D', quality: ChordQuality.major, beats: 4),
          ChordCell(root: 'A', quality: ChordQuality.major, beats: 4),
        ],
        lyrics: 'Holy, holy, holy! Lord God Almighty!',
      ),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    repository = InMemorySongRepository(initialSongs: [sampleSong]);
  });

  Widget buildSubject({required String songId}) {
    return ProviderScope(
      overrides: [
        songRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: ScoreEditorPage(songId: songId),
      ),
    );
  }

  group('ScoreEditorPage', () {
    testWidgets('renders score title, hint banner, StaffCanvas, and RhythmToolbar',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject(songId: 'score-song-1'));
      await tester.pumpAndSettle();

      expect(find.text('Holy, Holy, Holy (Notation)'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(
        find.textContaining('Drag noteheads vertically to change pitch'),
        findsOneWidget,
      );
      expect(find.byType(StaffCanvas), findsOneWidget);
      expect(find.byType(RhythmToolbar), findsOneWidget);
    });

    testWidgets('shows song not found for non-existent songId', (tester) async {
      await tester.pumpWidget(buildSubject(songId: 'non-existent-id'));
      await tester.pumpAndSettle();

      expect(find.textContaining('not found'), findsOneWidget);
    });

    testWidgets('tapping Save button saves updated notation to repository',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject(songId: 'score-song-1'));
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Notation changes saved to Song!'), findsOneWidget);
    });
  });
}
