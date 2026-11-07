import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/presentation/pages/song_detail_page.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemorySongRepository repository;

  final sampleSong = Song(
    id: 'song-detail-1',
    title: 'Fly Me to the Moon',
    artist: 'Bart Howard',
    key: 'C',
    tempo: 120,
    timeSignature: (4, 4),
    tags: const ['jazz', 'classic'],
    notes: 'Acoustic bossa style',
    sections: const [
      SongSection(
        id: 'sec-intro',
        name: 'Intro',
        repeatCount: 1,
        orderIndex: 0,
        chords: [
          ChordCell(root: 'Am', quality: ChordQuality.minor7, beats: 4),
          ChordCell(root: 'Dm', quality: ChordQuality.minor7, beats: 4),
        ],
        lyrics: 'Fly me to the moon and let me play among the stars...',
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
      overrides: [songRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(home: SongDetailPage(songId: songId)),
    );
  }

  group('SongDetailPage', () {
    testWidgets('renders full metadata, badges, and chord chart', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject(songId: 'song-detail-1'));
      await tester.pumpAndSettle();

      expect(find.text('Fly Me to the Moon'), findsWidgets);
      expect(find.text('Bart Howard'), findsOneWidget);
      expect(find.text('Key: C'), findsOneWidget);
      expect(find.text('120 BPM'), findsOneWidget);
      expect(find.text('4/4'), findsOneWidget);
      expect(find.text('jazz'), findsOneWidget);
      expect(find.text('Acoustic bossa style'), findsOneWidget);
      expect(find.text('Intro'), findsOneWidget);
      expect(
        find.text('Fly me to the moon and let me play among the stars...'),
        findsOneWidget,
      );
    });

    testWidgets('shows transpose dialog and updates displayed key', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject(songId: 'song-detail-1'));
      await tester.pumpAndSettle();

      // Tap Transpose button
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      expect(find.text('Transpose Song'), findsOneWidget);

      // Tap Up 1 semitone
      await tester.tap(find.byTooltip('Up 1 semitone'));
      await tester.pumpAndSettle();

      // C shifted up 1 semitone -> C# or Db
      expect(find.textContaining('1 semitone'), findsOneWidget);

      // Close modal
      await tester.tap(find.textContaining('Save Transposed Key'));
      await tester.pumpAndSettle();

      // Database should reflect updated key
      final songRes = await repository.getSongById('song-detail-1');
      final updated = songRes.fold<Song?>((_) => null, (s) => s);
      expect(updated?.key, isNot(equals('C')));
    });

    testWidgets('deletes song with confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject(songId: 'song-detail-1'));
      await tester.pumpAndSettle();

      // Tap Delete icon
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Song'), findsOneWidget);

      // Tap confirm Delete
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      final songRes = await repository.getSongById('song-detail-1');
      final found = songRes.fold<Song?>((_) => null, (s) => s);
      expect(found, isNull);
    });

    testWidgets(
      'switches to Musical Staff mode on narrow 360px screen without layout overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildSubject(songId: 'song-detail-1'));
        await tester.pumpAndSettle();

        // Switch to Musical Staff
        await tester.tap(find.text('Musical Staff'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Interactive Notation View'), findsOneWidget);
        expect(find.text('Edit in Notation Editor'), findsOneWidget);
      },
    );
  });
}
