import 'package:battuta/core/database/database_providers.dart';
import 'package:battuta/core/platform/screen_wake_lock.dart';
import 'package:battuta/core/services/device_preferences_storage.dart';
import 'package:battuta/features/live_session/presentation/pages/live_performance_page.dart';
import 'package:battuta/features/live_session/presentation/providers/performance_controller.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_setlist_repository.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/widgets/chord_lyrics_view.dart';
import 'package:battuta/features/settings/presentation/providers/stage_preferences_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/device_prefs_fakes.dart';
import '../../../../support/memory_storage.dart';

String lyrics(String tag, int lines) =>
    [for (var i = 0; i < lines; i++) '[E]$tag $i [A]more'].join('\n');

Song songOf(
  String id,
  String title, {
  String key = 'E',
  int tempo = 120,
  List<(String, int, int)> sections = const [],
}) => Song(
  id: id,
  title: title,
  artist: 'Artist',
  key: key,
  tempo: tempo,
  sections: [
    for (var i = 0; i < sections.length; i++)
      SongSection(
        id: '$id-$i',
        name: sections[i].$1,
        orderIndex: i,
        repeatCount: sections[i].$3,
        lyrics: lyrics(sections[i].$1, sections[i].$2),
      ),
  ],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late FakeScreenWakeLock lock;
  late MemoryStorage storage;
  late ProviderContainer container;

  final wayMaker = songOf(
    'a',
    'Way Maker',
    sections: [('Verse', 8, 1), ('Chorus', 8, 2), ('Bridge', 8, 1)],
  );
  final grace = songOf(
    'b',
    'Amazing Grace',
    key: 'G',
    tempo: 72,
    sections: [('Verse', 4, 1)],
  );
  final setlist = Setlist(
    id: 'set',
    title: 'Sunday',
    items: const [
      SetlistItem(id: 'i1', songId: 'a', orderIndex: 0, keyOverride: 'G'),
      SetlistItem(id: 'i2', songId: 'b', orderIndex: 1),
      SetlistItem(
        id: 'i3',
        songId: 'gone',
        orderIndex: 2,
        titleSnapshot: 'Old song',
      ),
    ],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  ProviderContainer makeContainer({Setlist? set}) {
    final c = ProviderContainer(
      // A setlist that is not there is an error; do not retry it on a timer.
      retry: (_, _) => null,
      overrides: [
        songRepositoryProvider.overrideWithValue(
          InMemorySongRepository(initialSongs: [wayMaker, grace]),
        ),
        setlistRepositoryProvider.overrideWithValue(
          InMemorySetlistRepository(initialSetlists: [set ?? setlist]),
        ),
        screenWakeLockProvider.overrideWithValue(lock),
        devicePreferencesStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    lock = FakeScreenWakeLock();
    storage = MemoryStorage();
    container = makeContainer();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    String? setlistId = 'set',
    String? songId,
    Size size = const Size(400, 800),
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: LivePerformancePage(
            setlistId: songId == null ? setlistId : null,
            songId: songId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  PerformanceState state() => container.read(performanceControllerProvider);

  double offset(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byKey(const ValueKey('performance_chart_scroll')),
          matching: find.byType(Scrollable),
        ),
      )
      .position
      .pixels;

  double firstCardHeight(WidgetTester tester) =>
      tester.getSize(find.byType(ChordSectionCard).first).height;

  /// Plays [seconds] in 100 ms frames.
  Future<void> play(WidgetTester tester, double seconds) async {
    for (var i = 0; i < seconds * 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('what is on screen', () {
    testWidgets('header, section chips in order and the next section', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(
        find.text('Song 1 of 3 · Way Maker · G'),
        findsOneWidget,
        reason: 'the key is the setlist override',
      );
      expect(find.text('Next: Chorus (1/2)'), findsOneWidget);
      final chips = [
        for (var i = 0; i < 4; i++)
          tester
              .widget<Text>(
                find.descendant(
                  of: find.byKey(ValueKey('perf_chip_$i')),
                  matching: find.byType(Text),
                ),
              )
              .data,
      ];
      expect(chips, ['Verse', 'Chorus (1/2)', 'Chorus (2/2)', 'Bridge']);
      // E up to G: the chart shows G and C, never the original E and A.
      expect(find.text('G'), findsWidgets);
      expect(find.text('E'), findsNothing);
      expect(find.text('♩ 120 · 100%'), findsOneWidget);
    });

    testWidgets('a song with no sections shows one whole-song cue', (
      tester,
    ) async {
      container = makeContainer();
      await container
          .read(songRepositoryProvider)
          .saveSong(songOf('bare', 'Bare song'));
      await pumpPage(tester, songId: 'bare');

      expect(find.text('Song 1 of 1 · Bare song · E'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('perf_chip_0')),
          matching: find.text('Whole song'),
        ),
        findsOneWidget,
      );
      expect(find.text('Last section of the set'), findsOneWidget);
    });

    testWidgets('a missing song shows a Not on this device card', (
      tester,
    ) async {
      await pumpPage(tester);
      container
          .read(performanceControllerProvider.notifier)
          .jumpToCue(0, songIndex: 2);
      await tester.pumpAndSettle();

      expect(find.text('Not on this device'), findsOneWidget);
      expect(find.textContaining('Old song'), findsWidgets);
      // Next still moves on: the set is over after it.
      await tester.tap(find.byKey(const ValueKey('perf_next')));
      await tester.pumpAndSettle();
      expect(find.text('Set complete'), findsOneWidget);
    });

    testWidgets('a setlist that does not exist says so', (tester) async {
      await pumpPage(tester, setlistId: 'nope');
      expect(find.text('Nothing to play here'), findsOneWidget);
    });

    testWidgets('keeps the screen awake while open', (tester) async {
      await pumpPage(tester);
      expect(lock.held, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(lock.held, isFalse);
    });
  });

  group('navigation', () {
    testWidgets('Next and Previous step through sections and songs', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(find.byKey(const ValueKey('perf_next')));
      await tester.pumpAndSettle();
      expect(state().cueIndex, 1);
      expect(find.text('Next: Chorus (2/2)'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('perf_prev')));
      await tester.pumpAndSettle();
      expect(state().cueIndex, 0);

      // Through the end of song 1 into song 2.
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const ValueKey('perf_next')));
        await tester.pumpAndSettle();
      }
      expect(state().songIndex, 1);
      expect(find.text('Song 2 of 3 · Amazing Grace · G'), findsOneWidget);
      expect(find.text('♩ 72 · 100%'), findsOneWidget);
    });

    testWidgets('tapping a chip jumps there and scrolls the chart', (
      tester,
    ) async {
      await pumpPage(tester);
      expect(offset(tester), 0);

      await tester.ensureVisible(find.byKey(const ValueKey('perf_chip_3')));
      await tester.tap(find.byKey(const ValueKey('perf_chip_3')));
      await tester.pumpAndSettle();

      expect(state().cueIndex, 3);
      expect(offset(tester), greaterThan(300));
      expect(find.text('Next: Chorus (1/2)'), findsNothing);
      expect(find.text('Next song: Amazing Grace'), findsOneWidget);
    });

    testWidgets('reduced motion jumps without animating', (tester) async {
      await pumpPage(tester, reduceMotion: true);

      await tester.ensureVisible(find.byKey(const ValueKey('perf_chip_3')));
      await tester.tap(find.byKey(const ValueKey('perf_chip_3')));
      await tester.pump();
      await tester.pump();

      expect(offset(tester), greaterThan(300));
    });

    testWidgets('the setlist outline sits beside the chart when wide', (
      tester,
    ) async {
      await pumpPage(tester, size: const Size(1180, 800));
      expect(find.byKey(const ValueKey('perf_outline')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('perf_outline_2')));
      await tester.pumpAndSettle();
      expect(state().songIndex, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('there is no outline on a phone', (tester) async {
      await pumpPage(tester);
      expect(find.byKey(const ValueKey('perf_outline')), findsNothing);
    });
  });

  group('auto-scroll', () {
    testWidgets('scrolls at the tempo of the song and pauses', (tester) async {
      await pumpPage(tester);
      expect(offset(tester), 0);

      await tester.tap(find.byKey(const ValueKey('perf_play')));
      await tester.pump();
      await play(tester, 2);
      // 8 lyric lines x 2 bars x 2 s (120 BPM, 4/4) = 32 s for the card.
      // Near the top the reading line moves twice as fast as the chart.
      final perSecond = firstCardHeight(tester) / 32 / 2;
      expect(offset(tester), closeTo(perSecond * 2, perSecond * 0.5));

      await tester.tap(find.byKey(const ValueKey('perf_play')));
      await tester.pump();
      final paused = offset(tester);
      await play(tester, 1);
      expect(offset(tester), paused);
      expect(find.text('Play'), findsOneWidget);
    });

    testWidgets('+ and − change the pace and it is remembered', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byKey(const ValueKey('perf_speed_up')));
      await tester.tap(find.byKey(const ValueKey('perf_speed_up')));
      await tester.pump();
      expect(find.text('♩ 120 · 120%'), findsOneWidget);
      expect(container.read(stagePreferencesProvider).songSpeeds['a'], 1.2);

      await tester.tap(find.byKey(const ValueKey('perf_play')));
      await tester.pump();
      await play(tester, 2);
      final perSecond = firstCardHeight(tester) / 32 * 1.2 / 2;
      expect(offset(tester), closeTo(perSecond * 2, perSecond * 0.5));
      await tester.tap(find.byKey(const ValueKey('perf_play')));
      await tester.pump();
    });

    testWidgets('bars per line changes the speed: 4 bars is half as fast', (
      tester,
    ) async {
      storage = MemoryStorage({StagePreferencesKeys.barsPerLine: '4'});
      container = makeContainer();
      await pumpPage(tester);

      await tester.tap(find.byKey(const ValueKey('perf_play')));
      await tester.pump();
      await play(tester, 4);
      // 64 s for the card instead of 32 s.
      final perSecond = firstCardHeight(tester) / 64 / 2;
      expect(offset(tester), closeTo(perSecond * 4, perSecond * 0.5));
      await tester.tap(find.byKey(const ValueKey('perf_play')));
      await tester.pump();
    });

    testWidgets('Play keeps the first of three short sections current', (
      tester,
    ) async {
      final short = songOf(
        'short',
        'Short',
        sections: [('A', 2, 1), ('B', 2, 1), ('C', 2, 1)],
      );
      await container.read(songRepositoryProvider).saveSong(short);
      await pumpPage(tester, songId: 'short');
      expect(find.text('Next: B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('perf_play')));
      await tester.pump();
      await play(tester, 1);

      expect(state().cueIndex, 0);
      expect(find.text('Next: B'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('perf_play')));
      await tester.pump();
    });

    testWidgets('the current section follows the scroll', (tester) async {
      storage = MemoryStorage({StagePreferencesKeys.barsPerLine: '1'});
      container = makeContainer();
      await pumpPage(tester);
      container.read(performanceControllerProvider.notifier).setSpeed(2.0);
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('perf_play')));
      await tester.pump();
      await play(tester, 14);

      expect(state().cueIndex, greaterThanOrEqualTo(1));
      expect(
        find.text(
          'Next: ${state().currentSong!.cues[state().cueIndex + 1].label}',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('perf_play')));
      await tester.pump();
    });

    testWidgets('dragging the chart pauses the auto-scroll', (tester) async {
      await pumpPage(tester);
      await tester.tap(find.byKey(const ValueKey('perf_play')));
      await tester.pump();
      await play(tester, 1);
      expect(state().isScrolling, isTrue);

      await tester.drag(
        find.byKey(const ValueKey('performance_chart_scroll')),
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();

      expect(state().isScrolling, isFalse);
    });

    testWidgets('a section that fits on screen makes Next the main action', (
      tester,
    ) async {
      // A short one-song set.
      container = makeContainer(
        set: Setlist(
          id: 'set',
          title: 'Short',
          items: const [
            SetlistItem(id: 'i2', songId: 'b', orderIndex: 0),
            SetlistItem(id: 'i1', songId: 'a', orderIndex: 1),
          ],
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
      await pumpPage(tester);
      // One section that fits on screen: the end is already in view.
      expect(state().atEnd, isTrue);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('perf_next')),
          matching: find.text('Next'),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget(find.byKey(const ValueKey('perf_next'))),
        isA<FilledButton>(),
      );
    });
  });

  testWidgets('auto-scroll stops by itself at the end of the chart', (
    tester,
  ) async {
    await pumpPage(tester, songId: 'b');
    await tester.tap(find.byKey(const ValueKey('perf_play')));
    await tester.pump();
    await play(tester, 60);

    expect(state().isScrolling, isFalse);
    final position = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('performance_chart_scroll')),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    expect(position.pixels, position.maxScrollExtent);
    expect(find.text('Play'), findsOneWidget);
  });

  group('end of the set', () {
    testWidgets('shows Set complete with Restart and Close', (tester) async {
      await pumpPage(tester, songId: 'b');
      await tester.tap(find.byKey(const ValueKey('perf_next')));
      await tester.pumpAndSettle();

      expect(find.text('Set complete'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('perf_restart')));
      await tester.pumpAndSettle();
      expect(find.text('Set complete'), findsNothing);
      expect(find.text('Song 1 of 1 · Amazing Grace · G'), findsOneWidget);
    });

    testWidgets('Finish is the label on the last section', (tester) async {
      await pumpPage(tester, songId: 'b');
      expect(find.text('Finish'), findsOneWidget);
    });

    testWidgets('closing asks first, and Cancel stays', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const LivePerformancePage(setlistId: 'set'),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(LivePerformancePage), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('perf_close')));
      await tester.pumpAndSettle();
      expect(find.text('End this live session?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('perf_end_cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(LivePerformancePage), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('perf_close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('perf_end_confirm')));
      await tester.pumpAndSettle();
      expect(find.byType(LivePerformancePage), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });

  group('layout', () {
    for (final size in [
      const Size(320, 640),
      const Size(1024, 768),
      const Size(1180, 820),
    ]) {
      testWidgets('no overflow at ${size.width.toInt()} pt', (tester) async {
        await pumpPage(tester, size: size);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const ValueKey('perf_next')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('perf_speed_up')));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('no transport label is cut short in Spanish at 320 pt', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            // Tests draw text in the Ahem font, whose glyphs are about twice
            // as wide as a real UI font: scale it down to real widths.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(0.55)),
              child: child!,
            ),
            home: const LivePerformancePage(setlistId: 'set'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (var round = 0; round < 2; round++) {
        for (final key in ['perf_play', 'perf_next']) {
          for (final text in tester.widgetList<Text>(
            find.descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(Text),
            ),
          )) {
            final paragraph = tester.renderObject<RenderParagraph>(
              find.byWidget(text),
            );
            expect(paragraph.didExceedMaxLines, isFalse, reason: text.data);
            expect(
              paragraph.size.width,
              greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(1000) - 0.5),
              reason: text.data,
            );
          }
        }
        // Second pass: playing (Pausar) and on the last cue (Terminar).
        await tester.tap(find.byKey(const ValueKey('perf_play')));
        await tester.pump();
        container
            .read(performanceControllerProvider.notifier)
            .jumpToCue(0, songIndex: 2);
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('perf_play')));
      await tester.pump();
    });

    testWidgets('keeps the current section after a rotation', (tester) async {
      await pumpPage(tester, size: const Size(400, 800));
      await tester.ensureVisible(find.byKey(const ValueKey('perf_chip_3')));
      await tester.tap(find.byKey(const ValueKey('perf_chip_3')));
      await tester.pumpAndSettle();
      expect(state().cueIndex, 3);

      tester.view.physicalSize = const Size(800, 400);
      await tester.pumpAndSettle();

      expect(state().cueIndex, 3);
      expect(offset(tester), greaterThan(300));
      expect(tester.takeException(), isNull);
    });
  });
}
