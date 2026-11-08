import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/pages/repertoire_page.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
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
      expect(find.text('John Newton'), findsOneWidget);
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

    testWidgets('renders song creation FAB for admin user', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('New Song'), findsOneWidget);
    });

    testWidgets(
      'hides song creation FAB and shows guidance for non-admin user',
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

        // No FAB for non-admin user
        expect(find.byType(FloatingActionButton), findsNothing);
        expect(
          find.textContaining('Contact an administrator to add songs'),
          findsOneWidget,
        );
      },
    );
  });
}
