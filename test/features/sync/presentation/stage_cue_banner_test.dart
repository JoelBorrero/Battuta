import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/features/sync/domain/models/sync_cue_payload.dart';
import 'package:battuta/features/sync/presentation/widgets/stage_cue_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testCue = SyncCuePayload(
    songId: 'song-cuerdas',
    currentSectionId: 'verso-2',
    nextSectionLabel: 'NEXT: CORO GLORIOSO',
    triggerMeasureIndex: 16,
    leaderTimestampMs: 1700000000000,
    sequenceNumber: 1,
  );

  Widget buildTestWidget({
    required ThemeMode mode,
    required Widget child,
    Size size = const Size(800, 600),
  }) {
    return MaterialApp(
      themeMode: mode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppTheme.pearlBackground,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.obsidian,
      ),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: Center(
            child: SizedBox(width: size.width, child: child),
          ),
        ),
      ),
    );
  }

  group('StageCueBanner Widget Tests', () {
    testWidgets(
      'renders properly in Dark Mode with high-contrast amber border',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            mode: ThemeMode.dark,
            child: const StageCueBanner(cue: testCue, currentMeasure: 14),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('NEXT: CORO GLORIOSO'), findsOneWidget);
        expect(find.text('in 2 bars (Bar 16)'), findsOneWidget);

        final containerFinder = find.byType(Container).first;
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.color, BattutaBrand.dark.card);
        expect(decoration.border?.top.color, AppTheme.amberAccent);
      },
    );

    testWidgets('renders properly in Light Mode', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          mode: ThemeMode.light,
          child: const StageCueBanner(cue: testCue, currentMeasure: 15),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NEXT: CORO GLORIOSO'), findsOneWidget);
      expect(find.text('in 1 bar (Bar 16)'), findsOneWidget);

      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, BattutaBrand.light.card);
      expect(decoration.border?.top.color, AppTheme.amberAccent);
    });

    testWidgets(
      'prevents RenderFlex overflow on narrow split-screen view (320x600)',
      (tester) async {
        // Set surface size to 320x600
        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildTestWidget(
            mode: ThemeMode.dark,
            size: const Size(320, 600),
            child: StageCueBanner(
              cue: testCue,
              currentMeasure: 14,
              onDismiss: () {},
              onJumpNow: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('NEXT: CORO GLORIOSO'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('stage_cue_jump_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('stage_cue_dismiss_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'interactive touch targets meet >= 44x44 pt minimum requirement',
      (tester) async {
        bool dismissed = false;
        bool jumped = false;

        await tester.pumpWidget(
          buildTestWidget(
            mode: ThemeMode.dark,
            child: StageCueBanner(
              cue: testCue,
              onDismiss: () => dismissed = true,
              onJumpNow: () => jumped = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final dismissFinder = find.byKey(
          const ValueKey('stage_cue_dismiss_button'),
        );
        final jumpFinder = find.byKey(const ValueKey('stage_cue_jump_button'));

        final dismissSize = tester.getSize(dismissFinder);
        final jumpSize = tester.getSize(jumpFinder);

        expect(dismissSize.width, greaterThanOrEqualTo(44.0));
        expect(dismissSize.height, greaterThanOrEqualTo(44.0));
        expect(jumpSize.width, greaterThanOrEqualTo(44.0));
        expect(jumpSize.height, greaterThanOrEqualTo(44.0));

        await tester.tap(jumpFinder);
        expect(jumped, isTrue);

        await tester.tap(dismissFinder);
        expect(dismissed, isTrue);
      },
    );

    testWidgets(
      'DirectorControlBar renders section chips and triggers callbacks',
      (tester) async {
        String? queuedSection;
        String? jumpedSection;

        await tester.pumpWidget(
          buildTestWidget(
            mode: ThemeMode.dark,
            child: DirectorControlBar(
              sections: const ['Intro', 'Verso', 'Coro', 'Puente'],
              activeSectionId: 'Verso',
              onQueueSection: (s) => queuedSection = s,
              onJumpSection: (s) => jumpedSection = s,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('INTRO'), findsOneWidget);
        expect(find.text('VERSO'), findsOneWidget);
        expect(find.text('CORO'), findsOneWidget);

        await tester.tap(find.text('CORO'));
        expect(queuedSection, 'Coro');

        // Tap jump bolt icon
        final bolts = find.byIcon(Icons.bolt);
        expect(bolts, findsNWidgets(4));
        await tester.tap(bolts.at(2));
        expect(jumpedSection, 'Coro');
      },
    );

    testWidgets('queued chip reads "· NEXT" and the active one stays plain', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          mode: ThemeMode.dark,
          child: DirectorControlBar(
            sections: const ['Intro', 'Verso', 'Coro'],
            activeSectionId: 'Verso',
            queuedSectionId: 'coro',
            onQueueSection: (_) {},
            onJumpSection: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CORO · NEXT'), findsOneWidget);
      expect(find.text('VERSO'), findsOneWidget);
      expect(find.text('INTRO'), findsOneWidget);
    });
  });
}
