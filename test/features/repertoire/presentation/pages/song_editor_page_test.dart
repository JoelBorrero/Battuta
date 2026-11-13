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

      final tapBtn = find.byKey(const Key('song_tap_tempo_button'));

      // Tap 3 times with ~500ms intervals (120 BPM)
      await tester.tap(tapBtn);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(tapBtn);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(tapBtn);
      await tester.pumpAndSettle();

      // Taps moved the tempo off its 120 BPM default (the test clock is real,
      // so the exact value depends on tap spacing).
      expect(find.textContaining('BPM'), findsOneWidget);
      expect(find.text('120 BPM'), findsNothing);
    });

    for (final width in [320.0, 1180.0]) {
      testWidgets('lays out without overflow at ${width.toInt()} wide', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(buildSubject(songId: 'song-test-1'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        for (final tooltip in [
          'Duplicate section',
          'Delete Section',
          'Increase repeats',
          'Decrease BPM',
        ]) {
          final size = tester.getSize(find.byTooltip(tooltip));
          expect(size.width, greaterThanOrEqualTo(44), reason: tooltip);
          expect(size.height, greaterThanOrEqualTo(44), reason: tooltip);
        }
        expect(
          tester.getSize(find.byKey(const Key('song_tap_tempo_button'))),
          const Size(72, 72),
        );
      });
    }

    testWidgets(
      'inserting section with matching name pre-loads chords and lyrics from previous section',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 2048);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // 1. Rename default section to "Intro"
        final sectionNameFields = find.widgetWithText(
          TextFormField,
          'Section Name',
        );
        expect(sectionNameFields, findsOneWidget);
        await tester.enterText(sectionNameFields.first, 'Intro');
        await tester.pumpAndSettle();

        // 2. Set chords for Intro
        final chordFields = find.widgetWithText(
          TextField,
          'Type chord symbols separated by spaces or bars',
        );
        await tester.enterText(chordFields.first, 'G C D');
        await tester.tap(find.byTooltip('Apply chords text').first);
        await tester.pumpAndSettle();

        // 3. Set lyrics for Intro
        final lyricsFields = find.widgetWithText(
          TextFormField,
          'Enter lyrics line by line...',
        );
        await tester.enterText(lyricsFields.first, 'Intro lyrics line');
        await tester.pumpAndSettle();

        expect(find.text('G C D'), findsOneWidget);

        // 4. Tap Quick add: Intro ActionChip to insert another Intro
        final quickIntroChip = find.widgetWithText(ActionChip, 'Intro');
        expect(quickIntroChip, findsOneWidget);
        await tester.tap(quickIntroChip);
        await tester.pumpAndSettle();

        // 5. Verify 2 sections now exist
        expect(find.text('Song Sections (2)'), findsOneWidget);

        // Chords 'G C D' and lyrics 'Intro lyrics line' should now appear twice (pre-loaded!)
        expect(find.text('G C D'), findsNWidgets(2));
        expect(find.text('Intro lyrics line'), findsNWidgets(2));
        expect(
          find.text('Pre-loaded chords and lyrics from previous Intro'),
          findsOneWidget,
        );
      },
    );

    testWidgets('duplicating a section creates an exact clone right below it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject(songId: 'song-test-1'));
      await tester.pumpAndSettle();

      expect(find.text('Song Sections (1)'), findsOneWidget);
      expect(find.text('The falling leaves...'), findsOneWidget);

      // Tap Duplicate section icon
      final duplicateBtn = find.byTooltip('Duplicate section');
      expect(duplicateBtn, findsOneWidget);
      await tester.tap(duplicateBtn);
      await tester.pumpAndSettle();

      // Verify section was cloned
      expect(find.text('Song Sections (2)'), findsOneWidget);
      expect(find.text('The falling leaves...'), findsNWidgets(2));
      expect(find.text('Duplicated Verse'), findsOneWidget);
    });

    testWidgets(
      'pre-load chip appears when renaming empty section to match existing section',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 2048);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildSubject(songId: 'song-test-1'));
        await tester.pumpAndSettle();

        // Add a new empty section
        await tester.tap(find.text('Add Section'));
        await tester.pumpAndSettle();

        expect(find.text('Song Sections (2)'), findsOneWidget);

        // The second section name field: rename it to "Verse" (matching section 1)
        final sectionNameFields = find.widgetWithText(
          TextFormField,
          'Section Name',
        );
        expect(sectionNameFields, findsNWidgets(2));
        await tester.enterText(sectionNameFields.at(1), 'Verse');
        await tester.pumpAndSettle();

        // Pre-load ActionChip appears
        final preloadChip = find.widgetWithText(
          ActionChip,
          'Pre-load from previous Verse',
        );
        expect(preloadChip, findsOneWidget);

        // Tap pre-load chip
        await tester.tap(preloadChip);
        await tester.pumpAndSettle();

        // Chords and lyrics are now populated in the second section!
        expect(find.text('The falling leaves...'), findsNWidgets(2));
      },
    );
  });
}
