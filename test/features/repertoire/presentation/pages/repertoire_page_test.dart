import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/pages/repertoire_page.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemorySongRepository repository;

  final sampleSongs = [
    Song(
      id: 'song-1',
      title: 'Amazing Grace',
      artist: 'John Newton',
      key: 'G',
      tempo: 72,
      timeSignature: (3, 4),
      tags: const ['Hymn'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  setUp(() {
    repository = InMemorySongRepository(initialSongs: sampleSongs);
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [songRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: RepertoirePage()),
    );
  }

  group('RepertoirePage', () {
    testWidgets('renders repertoire header, search icon, and song list', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Repertoire'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Amazing Grace'), findsOneWidget);
      expect(find.text('John Newton · 72 BPM · 3/4'), findsOneWidget);
      expect(find.widgetWithText(StageKeyPill, 'G'), findsOneWidget);
      expect(find.text('Search title, artist or tag'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('renders empty state when no songs are present', (
      tester,
    ) async {
      repository = InMemorySongRepository(initialSongs: []);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Your repertoire is empty'), findsOneWidget);
      expect(
        find.text('Tap the + button to add your first song'),
        findsOneWidget,
      );
    });

    testWidgets('search button opens search, filters songs, and clears back', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('Type to search songs…'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Grace');
      await tester.pumpAndSettle();

      expect(find.text('Amazing Grace'), findsOneWidget);

      // Tap clear
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Type to search songs…'), findsOneWidget);

      // Tap back to return to main page
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Repertoire'), findsOneWidget);
      expect(find.text('Amazing Grace'), findsOneWidget);
    });

    testWidgets(
      'renders song creation FAB for admin user and opens add options sheet',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        // The add button is icon only; its tooltip names it.
        expect(find.byTooltip('Add song'), findsOneWidget);

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.text('Add Song to Repertoire'), findsOneWidget);
        expect(find.text('Import by Web URL'), findsOneWidget);
        expect(find.text('Scan with Gemini AI (OMR)'), findsOneWidget);
        expect(find.text('Write in Song Editor'), findsOneWidget);
        expect(find.text('Paste Text / Backup'), findsOneWidget);
      },
    );

    testWidgets(
      'a plain member still adds songs to their own library (ownership, not '
      'the organization role, decides)',
      (tester) async {
        repository = InMemorySongRepository(initialSongs: []);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              songRepositoryProvider.overrideWithValue(repository),
              isCurrentUserAdminProvider.overrideWithValue(false),
            ],
            child: const MaterialApp(home: RepertoirePage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(
          find.text('Tap the + button to add your first song'),
          findsOneWidget,
        );
      },
    );
  });

  group('layout', () {
    for (final size in [
      const Size(320, 700),
      const Size(375, 700),
      const Size(1180, 820),
    ]) {
      testWidgets('has no overflow at ${size.width.toInt()} x '
          '${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        repository = InMemorySongRepository(
          initialSongs: [
            for (var i = 0; i < 12; i++)
              sampleSongs.first.copyWith(
                id: 'song-$i',
                title: 'A very long song title that has to be ellipsized $i',
                artist: 'An artist with a really rather long name number $i',
                tags: const ['Hymn', 'Classic', 'Communion', 'Slow'],
              ),
          ],
        );

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.textContaining('Setlists ('));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
