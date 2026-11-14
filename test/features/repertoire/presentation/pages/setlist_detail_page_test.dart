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
import 'package:go_router/go_router.dart';

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
      expect(find.text('John Newton · 72 BPM'), findsOneWidget);
      expect(find.text('Note: Acoustic intro'), findsOneWidget);
      expect(find.byTooltip('Add Song to Setlist'), findsOneWidget);
      // The date stamp shows the month and day of the event.
      expect(find.text('NOV'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      // Stats: one song at 72 BPM.
      expect(find.text('Songs'), findsOneWidget);
      expect(find.text('Avg BPM'), findsOneWidget);
      expect(find.text('72'), findsOneWidget);
      expect(find.text('Drag to reorder'), findsOneWidget);
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
        find.text('Tap + to add songs and build your set.'),
        findsOneWidget,
      );
      // No date: no stamp; no tempo: the average is a dash.
      expect(find.byKey(const ValueKey('setlist_date_stamp')), findsNothing);
      expect(find.text('–'), findsOneWidget);
    });

    testWidgets('Add Song opens bottom sheet and adds available song', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject('setlist-1'));
      await tester.pumpAndSettle();

      // Tap + in the app bar
      await tester.tap(find.byTooltip('Add Song to Setlist'));
      await tester.pumpAndSettle();

      expect(find.text('Way Maker'), findsOneWidget);

      // Tap add icon next to Way Maker
      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pumpAndSettle();

      // Way Maker should now be in the setlist
      expect(find.text('Way Maker'), findsOneWidget);
      expect(find.text('Sinach · 68 BPM'), findsOneWidget);
      // The average tempo of 72 and 68 is 70.
      expect(find.text('70'), findsOneWidget);
    });

    testWidgets('edit setlist dialog updates title and notes', (tester) async {
      await tester.pumpWidget(buildSubject('setlist-1'));
      await tester.pumpAndSettle();

      // Edit sits in the overflow menu
      await tester.tap(find.byKey(const ValueKey('setlist_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit setlist info'));
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

      // Delete sits in the overflow menu
      await tester.tap(find.byKey(const ValueKey('setlist_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete setlist'));
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

    testWidgets('reordering songs persists the new order', (tester) async {
      final two = Setlist(
        id: 'setlist-two',
        title: 'Two songs',
        items: const [
          SetlistItem(id: 'a', songId: 'song-1', orderIndex: 0),
          SetlistItem(id: 'b', songId: 'song-2', orderIndex: 1),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await setlistRepo.saveSetlist(two);
      await tester.pumpWidget(buildSubject('setlist-two'));
      await tester.pumpAndSettle();

      final handle = find.byIcon(Icons.drag_handle).first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(
        const Offset(0, 140),
        timeStamp: const Duration(milliseconds: 200),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final saved = (await setlistRepo.getSetlistById('setlist-two'))
          .getOrElse((_) => throw StateError('missing'));
      expect([for (final i in saved.items) i.id], ['b', 'a']);
      expect([for (final i in saved.items) i.orderIndex], [0, 1]);
    });

    testWidgets('a tombstone row shows its snapshot and the key override', (
      tester,
    ) async {
      final withTomb = Setlist(
        id: 'setlist-tomb',
        title: 'Gone songs',
        items: const [
          SetlistItem(
            id: 't1',
            songId: '',
            orderIndex: 0,
            titleSnapshot: 'Deleted Hymn',
            artistSnapshot: 'Old Author',
            keySnapshot: 'D',
          ),
          SetlistItem(
            id: 't2',
            songId: 'song-2',
            orderIndex: 1,
            keyOverride: 'Bb',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await setlistRepo.saveSetlist(withTomb);
      await tester.pumpWidget(buildSubject('setlist-tomb'));
      await tester.pumpAndSettle();

      expect(find.text('Deleted Hymn'), findsOneWidget);
      expect(find.text('Old Author'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      // The override replaces the song's own key (E).
      expect(find.text('Bb'), findsOneWidget);
      expect(find.text('E'), findsNothing);
    });

    for (final width in [320.0, 1180.0]) {
      testWidgets('lays out without overflow at $width wide', (tester) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        final long = Setlist(
          id: 'setlist-long',
          title: 'A very long setlist title that has to wrap around twice',
          description: 'And a description that is long enough to need clamping',
          eventDate: DateTime(2026, 11, 8, 10),
          items: [
            for (var i = 0; i < 8; i++)
              SetlistItem(
                id: 'x$i',
                songId: i.isEven ? 'song-1' : 'song-2',
                orderIndex: i,
                keyOverride: 'F#m',
                notes: 'A long rehearsal note that wraps onto a second line',
              ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await setlistRepo.saveSetlist(long);
        await tester.pumpWidget(buildSubject('setlist-long'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Songs'), findsOneWidget);
        // The drag handle is a full touch target, so a missed drag never lands
        // on the neighbouring remove button.
        final handle = tester.getSize(
          find.byKey(const ValueKey('setlist_drag_handle_0')),
        );
        expect(handle.width, greaterThanOrEqualTo(44));
        expect(handle.height, greaterThanOrEqualTo(44));
      });
    }

    group('Start live session', () {
      Future<List<String>> pumpWithRouter(
        WidgetTester tester,
        String setlistId,
      ) async {
        final opened = <String>[];
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  SetlistDetailPage(setlistId: setlistId),
            ),
            GoRoute(
              path: '/live/perform',
              builder: (context, state) {
                opened.add(state.uri.toString());
                return const Scaffold(body: Text('performing'));
              },
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              songRepositoryProvider.overrideWithValue(songRepo),
              setlistRepositoryProvider.overrideWithValue(setlistRepo),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        return opened;
      }

      testWidgets('opens the performance of this setlist', (tester) async {
        final opened = await pumpWithRouter(tester, 'setlist-1');

        expect(find.text('Start live session'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('setlist_start_live_hint')),
          findsNothing,
        );
        await tester.tap(find.byKey(const ValueKey('setlist_start_live')));
        await tester.pumpAndSettle();

        expect(opened, ['/live/perform?setlist=setlist-1']);
        expect(find.text('performing'), findsOneWidget);
      });

      testWidgets('is disabled, with a hint, when the setlist is empty', (
        tester,
      ) async {
        await setlistRepo.saveSetlist(
          Setlist(
            id: 'setlist-empty',
            title: 'Empty Service',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final opened = await pumpWithRouter(tester, 'setlist-empty');

        final button = tester.widget<FilledButton>(
          find.byKey(const ValueKey('setlist_start_live')),
        );
        expect(button.onPressed, isNull);
        expect(
          find.byKey(const ValueKey('setlist_start_live_hint')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('setlist_start_live')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        expect(opened, isEmpty);
      });
    });
  });
}
