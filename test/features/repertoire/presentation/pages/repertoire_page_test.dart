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
      overrides: [
        songRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        home: RepertoirePage(),
      ),
    );
  }

  group('RepertoirePage', () {
    testWidgets('renders repertoire header, search icon, and song list', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Repertoire'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Amazing Grace'), findsOneWidget);
      expect(find.text('John Newton'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('renders empty state when no songs are present', (tester) async {
      repository = InMemorySongRepository(initialSongs: []);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Your repertoire is empty'), findsOneWidget);
      expect(find.text('Tap the + button to add your first song'), findsOneWidget);
    });
  });
}

