import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/widgets/song_import_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestWidget({InMemorySongRepository? repo}) {
    final songRepo = repo ?? InMemorySongRepository();

    return ProviderScope(
      overrides: [
        songRepositoryProvider.overrideWithValue(songRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => SongImportModal.show(context),
              child: const Text('Open Modal'),
            ),
          ),
        ),
      ),
    );
  }

  group('SongImportModal', () {
    testWidgets('opens modal and displays header and formatting instructions', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Import Song / Repertoire'), findsOneWidget);
      expect(find.text('Paste Clipboard'), findsOneWidget);
      expect(find.text('Load Sample'), findsOneWidget);
      expect(find.text('How to Format Your Song'), findsOneWidget);
      expect(find.text('Import Song'), findsOneWidget);
    });

    testWidgets('typing plain text with // comments updates preview and sections live', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      const leadSheet = '''
// Title: Living Hope
// Artist: Phil Wickham
// Key: Eb
// Tempo: 72
// Time: 4/4

// Verse 1
[Eb]How great the chasm that lay between us

// Chorus (2x)
[Ab]Hallelujah praise the one who set me free
''';

      await tester.enterText(
        find.byKey(const ValueKey('song_import_text_field')),
        leadSheet,
      );
      await tester.pumpAndSettle();

      expect(find.text('Living Hope'), findsOneWidget);
      expect(find.text('Phil Wickham'), findsOneWidget);
      expect(find.text('Key Eb'), findsOneWidget);
      expect(find.text('72 BPM'), findsOneWidget);
      expect(find.text('4/4'), findsOneWidget);
      expect(find.text('Plain Text Lead Sheet (with // comments)'), findsOneWidget);
      expect(find.text('SECTIONS DETECTED'), findsOneWidget);
      expect(find.textContaining('Verse 1 ·'), findsOneWidget);
      expect(find.textContaining('Chorus (2x) ·'), findsOneWidget);
    });

    testWidgets('tapping Load Sample populates template and saves to repository', (tester) async {
      final repo = InMemorySongRepository();
      await tester.pumpWidget(buildTestWidget(repo: repo));

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Tap Load Sample
      await tester.tap(find.text('Load Sample'));
      await tester.pumpAndSettle();

      expect(find.text('Amazing Grace'), findsOneWidget);
      expect(find.text('John Newton'), findsOneWidget);
      expect(find.text('Key G'), findsOneWidget);
      expect(find.textContaining('Chorus (2x) ·'), findsOneWidget);

      // Tap Import Song
      await tester.tap(find.widgetWithText(FilledButton, 'Import Song'));
      await tester.pumpAndSettle();

      final songsResult = await repo.getAllSongs();
      final songs = songsResult.fold((_) => [], (s) => s);
      expect(songs.any((s) => s.title == 'Amazing Grace'), isTrue);

      // Modal closed
      expect(find.byType(SongImportModal), findsNothing);
    });

    testWidgets('pasting JSON backup displays JSON badge and imports successfully', (tester) async {
      final repo = InMemorySongRepository();
      await tester.pumpWidget(buildTestWidget(repo: repo));

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      const jsonStr = r'''
{
  "id": "json-song-1",
  "title": "King of Kings",
  "artist": "Hillsong",
  "key": "D",
  "tempo": 68,
  "timeSignature": {"$1": 4, "$2": 4},
  "sections": [
    {
      "id": "sec-1",
      "name": "Verse 1",
      "chords": [],
      "lyrics": "In the darkness we were waiting",
      "repeatCount": 1,
      "orderIndex": 0
    }
  ],
  "tags": ["praise"],
  "createdAt": "2026-01-01T00:00:00.000",
  "updatedAt": "2026-01-01T00:00:00.000"
}
''';

      await tester.enterText(
        find.byKey(const ValueKey('song_import_text_field')),
        jsonStr,
      );
      await tester.pumpAndSettle();

      expect(find.text('King of Kings'), findsOneWidget);
      expect(find.text('Hillsong'), findsOneWidget);
      expect(find.text('Key D'), findsOneWidget);
      expect(find.text('JSON Backup (1 song)'), findsOneWidget);

      await tester.tap(find.text('Import Song'));
      await tester.pumpAndSettle();

      final songsResult = await repo.getAllSongs();
      final songs = songsResult.fold((_) => [], (s) => s);
      expect(songs.any((s) => s.title == 'King of Kings'), isTrue);
    });
  });
}
