import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/core/database/database_providers.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/services/device_preferences_storage.dart';
import 'package:battuta/features/audio/presentation/widgets/practice_player_bar.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_setlist_repository.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/presentation/pages/song_detail_page.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/widgets/chord_lyrics_view.dart';
import 'package:battuta/features/repertoire/presentation/widgets/transpose_stepper_card.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../support/memory_storage.dart';

/// Saves a setlist only after a delay, like a slow disk or network.
class _SlowSetlistRepository extends InMemorySetlistRepository {
  _SlowSetlistRepository({super.initialSetlists});

  @override
  Future<Either<Failure, Setlist>> saveSetlist(Setlist setlist) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return super.saveSetlist(setlist);
  }
}

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
          ChordCell(root: 'A', quality: ChordQuality.minor7, beats: 4),
          ChordCell(root: 'D', quality: ChordQuality.minor7, beats: 4),
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

  Widget buildSubject({
    required String songId,
    List<Override> extraOverrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        songRepositoryProvider.overrideWithValue(repository),
        ...extraOverrides,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SongDetailPage(songId: songId),
      ),
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
      expect(find.text('Bart Howard · Original: C (120 BPM)'), findsOneWidget);
      expect(find.text('Song'), findsOneWidget);
      expect(find.text('C'), findsWidgets);
      expect(find.text('120'), findsOneWidget);
      expect(find.text('4/4'), findsOneWidget);
      expect(find.text('jazz'), findsOneWidget);
      expect(find.text('Acoustic bossa style'), findsOneWidget);
      expect(find.text('Intro'), findsOneWidget);
      expect(find.text('Fly'), findsOneWidget);

      // Switching to Lyrics Only view mode displays lyrics without chords
      await tester.tap(find.text('Lyrics Only'));
      await tester.pumpAndSettle();
      expect(
        find.text('Fly me to the moon and let me play among the stars...'),
        findsOneWidget,
      );

      // Switching to Chords Only view mode displays chord cells and hides lyrics
      await tester.tap(find.text('Chords Only'));
      await tester.pumpAndSettle();
      expect(find.text('Am7'), findsOneWidget);
      expect(find.text('Dm7'), findsOneWidget);
      expect(find.text('4 beats'), findsNWidgets(2));
      expect(
        find.text('Fly me to the moon and let me play among the stars...'),
        findsNothing,
      );

      // Switching to Both view mode restores both chords and lyrics
      await tester.tap(find.text('Both'));
      await tester.pumpAndSettle();
      expect(find.text('Fly'), findsOneWidget);
    });

    testWidgets('stepper previews the transposition without saving', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject(songId: 'song-detail-1'));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      await tester.tap(find.byTooltip('Up 1 semitone'));
      await tester.pump();
      await tester.tap(find.byTooltip('Up 1 semitone'));
      await tester.pumpAndSettle();

      expect(find.text('+2'), findsOneWidget);
      // The key tile shows D; the original line still shows C.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('stat_key')),
          matching: find.text('D'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Original: C'), findsOneWidget);
      // Chart is transposed: Am7 -> Bm7.
      await tester.tap(find.text('Chords Only'));
      await tester.pumpAndSettle();
      expect(find.text('Bm7'), findsOneWidget);

      // Nothing was written.
      final stored = (await repository.getSongById('song-detail-1'))
          .fold<Song?>((_) => null, (s) => s);
      expect(stored?.key, 'C');

      // Tapping the value resets; down goes negative.
      await tester.tap(find.byKey(const ValueKey('transpose_value')));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);
      await tester.tap(find.byTooltip('Down 1 semitone'));
      await tester.pumpAndSettle();
      expect(find.text('-1'), findsOneWidget);
    });

    for (final flats in [false, true]) {
      testWidgets('transposing C up 1 spells ${flats ? 'Db' : 'C#'} '
          'with prefer flats ${flats ? 'on' : 'off'}', (tester) async {
        tester.view.physicalSize = const Size(1024, 2048);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildSubject(
            songId: 'song-detail-1',
            extraOverrides: [
              devicePreferencesStorageProvider.overrideWithValue(
                MemoryStorage({'battuta_prefer_flats': flats.toString()}),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Up 1 semitone'));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byKey(const ValueKey('stat_key')),
            matching: find.text(flats ? 'Db' : 'C#'),
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Chords Only'));
        await tester.pumpAndSettle();
        expect(find.text(flats ? 'Bbm7' : 'A#m7'), findsOneWidget);
      });
    }

    testWidgets('the saved chart text size scales the chart', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      Future<double> lyricWidth(String scale) async {
        await tester.pumpWidget(
          buildSubject(
            songId: 'song-detail-1',
            extraOverrides: [
              devicePreferencesStorageProvider.overrideWithValue(
                MemoryStorage({'battuta_chart_text_scale': scale}),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        return tester.getSize(find.text('Fly')).width;
      }

      final base = await lyricWidth('1.0');
      final big = await lyricWidth('1.5');
      expect(big, closeTo(base * 1.5, 1.0));
    });

    test('stepper wraps past 11 semitones', () {
      expect(TransposeStepperCard.step(11, 1), 0);
      expect(TransposeStepperCard.step(-11, -1), 0);
      expect(TransposeStepperCard.step(5, 1), 6);
      expect(TransposeStepperCard.signed(3), '+3');
      expect(TransposeStepperCard.signed(-3), '-3');
      expect(TransposeStepperCard.signed(0), '0');
    });

    testWidgets('menu "Transpose & save" persists the previewed key', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject(songId: 'song-detail-1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('song_menu')));
      await tester.pumpAndSettle();
      // Nothing to save yet.
      final disabled = tester.widget<PopupMenuItem<String>>(
        find.widgetWithText(PopupMenuItem<String>, 'Transpose & save'),
      );
      expect(disabled.enabled, isFalse);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Up 1 semitone'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('song_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transpose & save'));
      await tester.pumpAndSettle();

      final stored = (await repository.getSongById('song-detail-1'))
          .fold<Song?>((_) => null, (s) => s);
      expect(stored?.key, isNot('C'));
      // The preview resets once the key is stored.
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('menu holds notation, exports and delete', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject(songId: 'song-detail-1'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('song_edit')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('song_menu')));
      await tester.pumpAndSettle();
      for (final label in [
        'Transpose & save',
        'Notation Editor',
        'Copy Plain Text / ChordPro',
        'Copy JSON',
        'Export PDF Lead Sheet',
        'Export MIDI File',
        'Delete Song',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('add to setlist sheet lists setlists and adds the song', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      final setlistRepository = InMemorySetlistRepository(
        initialSetlists: [
          Setlist(
            id: 'sl-1',
            title: 'Sunday',
            items: const [],
            createdAt: now,
            updatedAt: now,
          ),
          Setlist(
            id: 'sl-2',
            title: 'Christmas',
            items: const [
              SetlistItem(id: 'i1', songId: 'song-detail-1', orderIndex: 0),
            ],
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      await tester.pumpWidget(
        buildSubject(
          songId: 'song-detail-1',
          extraOverrides: [
            setlistRepositoryProvider.overrideWithValue(setlistRepository),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('add_to_setlist')));
      await tester.pumpAndSettle();
      expect(find.text('Sunday'), findsOneWidget);
      expect(find.text('Christmas'), findsOneWidget);
      expect(find.text('Already added'), findsOneWidget);

      // The setlist that holds the song is inert.
      await tester.tap(
        find.byKey(const ValueKey('add_to_setlist_sl-2')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.text('Sunday'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('add_to_setlist_sl-1')));
      await tester.pumpAndSettle();
      expect(find.text('Added to Sunday'), findsOneWidget);

      final saved = (await setlistRepository.getSetlistById('sl-1'))
          .fold<Setlist?>((_) => null, (s) => s);
      expect(saved?.items.map((i) => i.songId), ['song-detail-1']);
    });

    testWidgets('add to setlist sheet shows an empty state', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject(songId: 'song-detail-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add_to_setlist')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('add_to_setlist_empty')),
        findsOneWidget,
      );
    });

    testWidgets('Add to setlist is the single full-width primary action', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject(songId: 'song-detail-1'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('go_live')), findsNothing);
      expect(find.text('Go live'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(StageActionBar),
          matching: find.byType(FilledButton),
        ),
        findsOneWidget,
      );
      // 400 wide minus the 16 pt gutters of the bar.
      expect(
        tester.getSize(find.byKey(const ValueKey('add_to_setlist'))).width,
        400 - 2 * BattutaSpace.lg,
      );
    });

    testWidgets('practice audio card lines up with the other cards', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject(songId: 'song-detail-1'));
      await tester.pumpAndSettle();
      final stepper = tester.getRect(find.byType(TransposeStepperCard));
      final audio = tester.getRect(
        find.descendant(
          of: find.byType(PracticePlayerBar),
          matching: find.byType(Card),
        ),
      );
      expect(audio.left, stepper.left);
      expect(audio.right, stepper.right);
    });

    testWidgets(
      'alignment cannot be saved while a transposition is previewed',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 2048);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildSubject(songId: 'song-detail-1'));
        await tester.pumpAndSettle();
        ValueChanged<Song>? onUpdated() => tester
            .widget<ChordLyricsView>(find.byType(ChordLyricsView))
            .onSongUpdated;
        expect(onUpdated(), isNotNull);

        await tester.tap(find.byTooltip('Up 1 semitone'));
        await tester.pumpAndSettle();
        expect(onUpdated(), isNull);
        expect(find.text('+1'), findsOneWidget);

        // Back to the stored key: editing is possible again.
        await tester.tap(find.byKey(const ValueKey('transpose_value')));
        await tester.pumpAndSettle();
        expect(onUpdated(), isNotNull);
        final stored = (await repository.getSongById('song-detail-1'))
            .fold<Song?>((_) => null, (s) => s);
        expect(stored?.key, 'C');
      },
    );

    testWidgets('a slow save does not end in an error snackbar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      final slow = _SlowSetlistRepository(
        initialSetlists: [
          Setlist(
            id: 'sl-1',
            title: 'Sunday',
            items: const [],
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      await tester.pumpWidget(
        buildSubject(
          songId: 'song-detail-1',
          extraOverrides: [setlistRepositoryProvider.overrideWithValue(slow)],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add_to_setlist')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add_to_setlist_sl-1')));
      // The sheet is gone long before the save ends.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const ValueKey('add_to_setlist_sl-1')), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Added to Sunday'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    for (final width in [320.0, 1180.0]) {
      testWidgets('lays out without overflow at ${width.toInt()} pt', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildSubject(songId: 'song-detail-1'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Up 1 semitone'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        for (final key in [
          'transpose_down',
          'transpose_up',
          'transpose_value',
        ]) {
          final size = tester.getSize(find.byKey(ValueKey(key)));
          expect(size.height, greaterThanOrEqualTo(44), reason: key);
        }
        expect(
          tester.getSize(find.byKey(const ValueKey('add_to_setlist'))).height,
          greaterThanOrEqualTo(44),
        );
      });
    }

    testWidgets('deletes song with confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject(songId: 'song-detail-1'));
      await tester.pumpAndSettle();

      // Open the menu and pick Delete Song
      await tester.tap(find.byKey(const ValueKey('song_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Song'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Song?'), findsOneWidget);

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
        final staffFinder = find.text('Musical Staff');
        await tester.scrollUntilVisible(
          staffFinder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(staffFinder);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Interactive Notation View'), findsOneWidget);
        expect(find.text('Edit in Notation Editor'), findsOneWidget);
      },
    );
  });
}
