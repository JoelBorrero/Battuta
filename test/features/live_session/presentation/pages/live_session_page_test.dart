import 'package:battuta/core/platform/screen_wake_lock.dart';
import 'package:battuta/features/live_session/presentation/pages/live_session_page.dart';
import 'package:battuta/features/sync/presentation/widgets/stage_cue_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/device_prefs_fakes.dart';

void main() {
  Widget buildSubject() {
    // Never reach the real wake lock plugin from a widget test.
    return ProviderScope(
      overrides: [
        screenWakeLockProvider.overrideWithValue(FakeScreenWakeLock()),
      ],
      child: const MaterialApp(home: LiveSessionPage()),
    );
  }

  group('LiveSessionPage', () {
    testWidgets(
      'renders stage session header and director/follower toggle (defaults to follower)',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.text('Live Stage Sync'), findsOneWidget);
        expect(find.text('Director (Host)'), findsOneWidget);
        expect(find.text('Musician (Follower)'), findsOneWidget);
        // Defaults to Follower mode
        expect(find.text('CONNECT TO DIRECTOR DEVICE'), findsOneWidget);
        expect(find.text('Director Host IP'), findsOneWidget);
        expect(find.text('Connect as Follower'), findsOneWidget);
        expect(find.text('ON STAGE NOW'), findsOneWidget);
      },
    );

    testWidgets('toggles between Follower and Director modes', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Initially in Follower mode
      expect(find.text('CONNECT TO DIRECTOR DEVICE'), findsOneWidget);

      // Tap Director mode
      await tester.tap(find.text('Director (Host)'));
      await tester.pumpAndSettle();

      // Director view is displayed
      expect(find.text('LOCAL LAN DIRECTOR SERVER'), findsOneWidget);
      expect(find.text('Start LAN Host'), findsOneWidget);
      expect(find.text('Trigger Test Cue'), findsOneWidget);
      expect(find.byType(DirectorControlBar), findsOneWidget);

      // Tap back to Follower mode
      await tester.tap(find.text('Musician (Follower)'));
      await tester.pumpAndSettle();

      expect(find.text('CONNECT TO DIRECTOR DEVICE'), findsOneWidget);
    });

    testWidgets(
      'switches to Director mode and triggers test cue to display StageCueBanner',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Switch to Director mode
        await tester.tap(find.text('Director (Host)'));
        await tester.pumpAndSettle();

        // Verify sections in DirectorControlBar
        expect(find.text('INTRO'), findsOneWidget);
        expect(find.text('VERSO 1'), findsOneWidget);
        expect(find.text('CORO'), findsOneWidget);
        expect(find.text('PUENTE'), findsOneWidget);
        expect(find.text('FINAL'), findsOneWidget);

        // Tap Trigger Test Cue
        await tester.tap(find.text('Trigger Test Cue'));
        await tester.pumpAndSettle();

        // StageCueBanner should appear
        expect(find.byType(StageCueBanner), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(StageCueBanner),
            matching: find.text('NEXT: CORO GLORIOSO'),
          ),
          findsOneWidget,
        );
        expect(find.text('JUMP'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('stage_cue_dismiss_button')),
          findsOneWidget,
        );
      },
    );
    testWidgets(
      'shows the muted LIVE badge and no End action when standalone',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.text('LIVE'), findsOneWidget);
        expect(find.text('STANDALONE'), findsOneWidget);
        expect(find.byKey(const ValueKey('live_end_button')), findsNothing);
      },
    );

    testWidgets('End stops the hosted session', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Director (Host)'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Start LAN Host'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.text('HOSTING'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);

      // Cancelling keeps the session running.
      await tester.tap(find.byKey(const ValueKey('live_end_button')));
      await tester.pumpAndSettle();
      expect(find.text('End the live session?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('live_end_cancel')));
      await tester.pumpAndSettle();
      expect(find.text('HOSTING'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('live_end_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('live_end_confirm')));
      // The dialog closes first; then the real socket shuts down.
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();

      expect(find.text('STANDALONE'), findsOneWidget);
      expect(find.byKey(const ValueKey('live_end_button')), findsNothing);
    });

    testWidgets('queueing a section marks its chip as NEXT', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('CORO'));
      await tester.pumpAndSettle();

      expect(find.text('CORO · NEXT'), findsOneWidget);
    });

    for (final width in [320.0, 1180.0]) {
      testWidgets('lays out without overflow at ${width.toInt()} pt', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        await tester.tap(find.text('Director (Host)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Trigger Test Cue'));
        await tester.pumpAndSettle();

        expect(find.byType(StageCueBanner), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
