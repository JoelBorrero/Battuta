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
    testWidgets('opens modal and displays header and import mode options', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Import Song / Lead Sheet'), findsOneWidget);
      expect(find.text('By URL'), findsOneWidget);
      expect(find.text('Gemini Scan'), findsOneWidget);
      expect(find.text('Text / JSON'), findsOneWidget);
      expect(find.byKey(const ValueKey('song_import_url_field')), findsOneWidget);
      expect(find.text('Cifra Club'), findsOneWidget);
      expect(find.text('LaCuerda'), findsOneWidget);
    });

    testWidgets('switches to Gemini Scan tab and displays camera & gallery action buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gemini Scan'));
      await tester.pumpAndSettle();

      expect(find.text('Read Sheet Music with Gemini AI'), findsOneWidget);
      expect(find.text('Capture with Camera'), findsOneWidget);
      expect(find.text('Select from Photo Library'), findsOneWidget);
    });

    testWidgets('typing plain text on Text tab updates preview and sections live', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Text / JSON'));
      await tester.pumpAndSettle();

      expect(find.text('Paste Clipboard'), findsOneWidget);
      expect(find.text('Load Sample'), findsOneWidget);
      expect(find.text('How to Format Your Lead Sheet'), findsOneWidget);

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
      expect(find.text('Key: Eb'), findsOneWidget);
      expect(find.text('Plain Text Lead Sheet (with // comments)'), findsOneWidget);
      expect(find.text('2 sections • 72 BPM'), findsOneWidget);
    });

    testWidgets('tapping Load Sample on Text tab populates template and saves to repository', (tester) async {
      final repo = InMemorySongRepository();
      await tester.pumpWidget(buildTestWidget(repo: repo));

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Text / JSON'));
      await tester.pumpAndSettle();

      // Tap Load Sample
      await tester.tap(find.text('Load Sample'));
      await tester.pumpAndSettle();

      expect(find.text('Amazing Grace'), findsOneWidget);
      expect(find.text('John Newton'), findsOneWidget);
      expect(find.text('Key: G'), findsOneWidget);
      expect(find.text('2 sections • 72 BPM'), findsOneWidget);

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

      await tester.tap(find.text('Text / JSON'));
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
      expect(find.text('Key: D'), findsOneWidget);
      expect(find.text('JSON Backup (1 song)'), findsOneWidget);
      expect(find.text('1 section • 68 BPM'), findsOneWidget);

      await tester.tap(find.text('Import Song'));
      await tester.pumpAndSettle();

      final songsResult = await repo.getAllSongs();
      final songs = songsResult.fold((_) => [], (s) => s);
      expect(songs.any((s) => s.title == 'King of Kings'), isTrue);
    });
  });
}
