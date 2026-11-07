import 'package:battuta/core/database/database_providers.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_setlist_repository.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/pages/setlist_detail_page.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemorySongRepository songRepo;
  late InMemorySetlistRepository setlistRepo;

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
    Song(
      id: 'song-2',
      title: 'Way Maker',
      artist: 'Sinach',
      key: 'E',
      tempo: 68,
      timeSignature: (4, 4),
      tags: const ['Worship'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  final sampleSetlist = Setlist(
    id: 'setlist-1',
    title: 'Sunday Service',
    description: 'Morning praise & worship',
    eventDate: DateTime(2026, 11, 8, 10, 0),
    items: const [
      SetlistItem(
        id: 'item-1',
        songId: 'song-1',
        orderIndex: 0,
        notes: 'Acoustic intro',
      ),
    ],
    tags: const ['Sunday', 'Morning'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    songRepo = InMemorySongRepository(initialSongs: sampleSongs);
    setlistRepo = InMemorySetlistRepository(initialSetlists: [sampleSetlist]);
  });

  Widget buildSubject(String setlistId) {
    return ProviderScope(
      overrides: [
        songRepositoryProvider.overrideWithValue(songRepo),
        setlistRepositoryProvider.overrideWithValue(setlistRepo),
      ],
      child: MaterialApp(home: SetlistDetailPage(setlistId: setlistId)),
    );
  }

  group('SetlistDetailPage', () {
    testWidgets('renders setlist header, metadata card, and song item', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject('setlist-1'));
      await tester.pumpAndSettle();

      expect(find.text('Sunday Service'), findsWidgets);
      expect(find.text('Morning praise & worship'), findsOneWidget);
      expect(find.text('Amazing Grace'), findsOneWidget);
      expect(find.text('John Newton • Original: G (72 BPM)'), findsOneWidget);
      expect(find.text('Note: Acoustic intro'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Add Song to Setlist'),
        findsOneWidget,
      );
    });

    testWidgets('renders empty state when setlist has no songs', (
      tester,
    ) async {
      final emptySetlist = Setlist(
        id: 'setlist-empty',
        title: 'Empty Service',
        items: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await setlistRepo.saveSetlist(emptySetlist);

      await tester.pumpWidget(buildSubject('setlist-empty'));
      await tester.pumpAndSettle();

      expect(find.text('Empty Service'), findsWidgets);
      expect(find.text('This setlist has no songs yet.'), findsOneWidget);
      expect(
        find.text('Tap "Add Song" below to build your set.'),
        findsOneWidget,
      );
    });

    testWidgets('Add Song opens bottom sheet and adds available song', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject('setlist-1'));
      await tester.pumpAndSettle();

      // Tap Add Song to Setlist button
      await tester.tap(
        find.widgetWithText(FilledButton, 'Add Song to Setlist'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Way Maker'), findsOneWidget);

      // Tap add icon next to Way Maker
      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pumpAndSettle();

      // Way Maker should now be in the setlist
      expect(find.text('Way Maker'), findsOneWidget);
      expect(find.text('Sinach • Original: E (68 BPM)'), findsOneWidget);
    });

    testWidgets('edit setlist dialog updates title and notes', (tester) async {
      await tester.pumpWidget(buildSubject('setlist-1'));
      await tester.pumpAndSettle();

      // Tap edit button in AppBar
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Setlist'), findsOneWidget);

      // Enter new title
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'Updated Sunday Service');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Updated Sunday Service'), findsWidgets);
    });

    testWidgets('delete setlist shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildSubject('setlist-1'));
      await tester.pumpAndSettle();

      // Tap delete button in AppBar
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Setlist?'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete "Sunday Service"? This action cannot be undone.',
        ),
        findsOneWidget,
      );

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Setlist?'), findsNothing);
      expect(find.text('Sunday Service'), findsWidgets);
    });
  });
}
