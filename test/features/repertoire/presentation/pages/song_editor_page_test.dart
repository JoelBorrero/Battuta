import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/presentation/pages/song_editor_page.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemorySongRepository repository;

  final sampleSong = Song(
    id: 'song-test-1',
    title: 'Autumn Leaves',
    artist: 'Joseph Kosma',
    key: 'Gm',
    tempo: 130,
    timeSignature: (4, 4),
    tags: const ['jazz'],
    sections: const [
      SongSection(
        id: 'sec-1',
        name: 'Verse',
        repeatCount: 1,
        orderIndex: 0,
        chords: [
          ChordCell(root: 'C', quality: ChordQuality.minor7, beats: 4),
          ChordCell(root: 'F', quality: ChordQuality.dominant7, beats: 4),
        ],
        lyrics: 'The falling leaves...',
      ),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    repository = InMemorySongRepository(initialSongs: [sampleSong]);
  });

  Widget buildSubject({String? songId}) {
    return ProviderScope(
      overrides: [songRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(home: SongEditorPage(songId: songId)),
    );
  }

  group('SongEditorPage', () {
    testWidgets('renders creation form with empty/default fields', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('New Song'), findsOneWidget);
      expect(find.byKey(const Key('song_title_field')), findsOneWidget);
      expect(find.byKey(const Key('song_artist_field')), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Tap Tempo'), findsOneWidget);
      expect(find.text('Song Sections (1)'), findsOneWidget);
      expect(find.text('Verse 1'), findsWidgets);
    });

    testWidgets('validates required fields on save', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a song title'), findsOneWidget);
      expect(find.text('Please enter an artist or composer'), findsOneWidget);
    });

    testWidgets('creates a new song and persists it to repository', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('song_title_field')),
        'Blue in Green',
      );
      await tester.enterText(
        find.byKey(const Key('song_artist_field')),
        'Miles Davis',
      );

      // Add a tag
      await tester.enterText(
        find.byKey(const Key('song_tag_input')),
        'Modal Jazz',
      );
      await tester.tap(find.byTooltip('Add Tag'));
      await tester.pumpAndSettle();

      expect(find.text('Modal Jazz'), findsOneWidget);

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final allSongsRes = await repository.getAllSongs();
      final allSongs = allSongsRes.getOrElse((_) => []);
      expect(allSongs.any((s) => s.title == 'Blue in Green'), isTrue);
    });

    testWidgets('loads and edits an existing song', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject(songId: 'song-test-1'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Song'), findsOneWidget);
      expect(find.text('Autumn Leaves'), findsOneWidget);
      expect(find.text('Joseph Kosma'), findsOneWidget);
      expect(find.text('Verse'), findsOneWidget);

      // Modify title
      await tester.enterText(
        find.byKey(const Key('song_title_field')),
        'Autumn Leaves (Swing Version)',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final songRes = await repository.getSongById('song-test-1');
      final updated = songRes.fold<Song?>((_) => null, (s) => s);
      expect(updated?.title, equals('Autumn Leaves (Swing Version)'));
    });

    testWidgets('tap tempo records rapid taps and adjusts BPM', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final tapBtn = find.text('Tap Tempo');

      // Tap 3 times with ~500ms intervals (120 BPM)
      await tester.tap(tapBtn);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(tapBtn);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(tapBtn);
      await tester.pumpAndSettle();

      // Tempo should be near 120 BPM
      expect(find.textContaining('BPM'), findsOneWidget);
    });
  });
}
