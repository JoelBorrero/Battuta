import 'dart:math' as math;

import 'package:battuta/core/database/database_providers.dart';
import 'package:battuta/core/platform/screen_wake_lock.dart';
import 'package:battuta/core/services/device_preferences_storage.dart';
import 'package:battuta/features/live_session/domain/scroll_pace.dart';
import 'package:battuta/features/live_session/presentation/pages/live_performance_page.dart';
import 'package:battuta/features/live_session/presentation/providers/performance_controller.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_setlist_repository.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/data/seed/repertoire_seeder.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/widgets/chord_lyrics_view.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/device_prefs_fakes.dart';
import '../../../../support/memory_storage.dart';

/// The seeded Way Maker (68 BPM, 4/4): Verso 1 has 4 lyric lines, Coro 2 and
/// Puente 3, each with inline chords and a 4-chord progression.
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        songRepositoryProvider.overrideWithValue(
          InMemorySongRepository(
            initialSongs: RepertoireSeeder.getSampleSongs(),
          ),
        ),
        setlistRepositoryProvider.overrideWithValue(
          InMemorySetlistRepository(),
        ),
        screenWakeLockProvider.overrideWithValue(FakeScreenWakeLock()),
        devicePreferencesStorageProvider.overrideWithValue(MemoryStorage()),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(400, 800),
    double textScale = 1.0,
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
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const LivePerformancePage(songId: 'seed-way-maker'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  PerformanceState state() => container.read(performanceControllerProvider);

  Finder scrollFinder() =>
      find.byKey(const ValueKey('performance_chart_scroll'));

  ScrollPosition position(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(of: scrollFinder(), matching: find.byType(Scrollable)),
      )
      .position;

  /// Card tops in scroll coordinates, read at offset 0.
  List<double> tops(WidgetTester tester) {
    final base = tester.getTopLeft(scrollFinder()).dy + position(tester).pixels;
    return [
      for (var i = 0; i < 3; i++)
        tester.getTopLeft(find.byType(ChordSectionCard).at(i)).dy - base,
    ];
  }

  /// The reading line for scroll offset [p], as the chart computes it.
  double lineAt(double p, double viewport) =>
      p + math.min(viewport * 0.3, p + 8);

  Future<void> start(WidgetTester tester) async {
    container.read(performanceControllerProvider.notifier).toggleScroll();
    await tester.pump();
  }

  Future<void> stop(WidgetTester tester) async {
    container.read(performanceControllerProvider.notifier).pause();
    await tester.pump();
  }

  double bar() => ScrollPace.barSeconds(bpm: 68, timeSignature: (4, 4));

  testWidgets('follows the song tempo across Verso, Coro and Puente', (
    tester,
  ) async {
    await pumpPage(tester);
    final t = tops(tester);
    final heightOfPuente = tester
        .getSize(find.byType(ChordSectionCard).at(2))
        .height;
    final viewport = tester.getSize(scrollFinder()).height;
    // Line distance and duration of each section (2 bars per line).
    final spans = [t[1] - t[0], t[2] - t[1], heightOfPuente];
    final durations = [4 * 2 * bar(), 2 * 2 * bar(), 3 * 2 * bar()];
    final total = durations.reduce((a, b) => a + b);

    double expectedLine(double seconds) {
      var line = t[0];
      var left = seconds;
      for (var i = 0; i < 3; i++) {
        final used = math.min(left, durations[i]);
        line += spans[i] * used / durations[i];
        left -= used;
      }
      return line;
    }

    await start(tester);
    var elapsed = 0.0;
    // Checks before, across and after both boundaries, and near the end.
    final checks = [10.0, 24.0, 30.0, 40.0, 46.0, 55.0];
    for (final at in checks) {
      while (elapsed < at) {
        await tester.pump(const Duration(milliseconds: 100));
        elapsed += 0.1;
      }
      final actual = lineAt(position(tester).pixels, viewport);
      final expected = expectedLine(at);
      final covered = expected - t[0];
      expect(
        actual - t[0],
        closeTo(covered, covered * 0.05 + 3),
        reason: 't=$at s (of $total)',
      );
    }
    await stop(tester);
  });

  testWidgets('the last section scrolls for its full duration', (tester) async {
    await pumpPage(tester);
    final t = tops(tester);
    final viewport = tester.getSize(scrollFinder()).height;
    final bars = bar();
    final total = (4 + 2 + 3) * 2 * bars;

    await start(tester);
    var elapsed = 0.0;
    double? enteredLast;
    while (state().isScrolling && elapsed < total + 20) {
      await tester.pump(const Duration(milliseconds: 100));
      elapsed += 0.1;
      if (enteredLast == null &&
          lineAt(position(tester).pixels, viewport) >= t[2]) {
        enteredLast = elapsed;
      }
    }

    expect(state().isScrolling, isFalse);
    expect(state().atEnd, isTrue);
    expect(enteredLast, isNotNull);
    // Puente (3 lines) takes 3 x 2 bars from the moment it is reached.
    expect(
      elapsed - enteredLast!,
      closeTo(3 * 2 * bars, 3 * 2 * bars * 0.05 + 0.3),
    );
    expect(elapsed, closeTo(total, total * 0.05 + 0.5));
    expect(find.text('Finish'), findsOneWidget);
  });

  testWidgets('a chip, Next and Previous keep it playing', (tester) async {
    await pumpPage(tester);
    await start(tester);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(find.byKey(const ValueKey('perf_chip_2')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(state().isScrolling, isTrue);
    expect(state().cueIndex, 2);

    await tester.tap(find.byKey(const ValueKey('perf_prev')));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(state().isScrolling, isTrue);
    expect(state().cueIndex, 1);

    final before = position(tester).pixels;
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(position(tester).pixels, greaterThan(before));
    await stop(tester);
  });

  testWidgets('jumping to the first section lands at offset 0', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('perf_chip_2')));
    await tester.pumpAndSettle();
    expect(position(tester).pixels, greaterThan(100));

    await tester.tap(find.byKey(const ValueKey('perf_chip_0')));
    await tester.pumpAndSettle();
    expect(position(tester).pixels, 0);
  });

  testWidgets('Play keeps its size when it turns into Pause', (tester) async {
    await pumpPage(tester, size: const Size(320, 640));
    final play = tester.getSize(find.byKey(const ValueKey('perf_play')));
    await start(tester);
    final pause = tester.getSize(find.byKey(const ValueKey('perf_play')));
    expect(pause.width, play.width);
    await stop(tester);
  });

  testWidgets('nothing clips at 320 pt with text scale 1.3', (tester) async {
    await pumpPage(tester, size: const Size(320, 640), textScale: 1.3);
    await start(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.byKey(const ValueKey('perf_chip_2')));
    await tester.tap(find.byKey(const ValueKey('perf_chip_2')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await stop(tester);
  });
}
