import 'package:battuta/features/live_session/presentation/pages/live_session_page.dart';
import 'package:battuta/features/sync/presentation/widgets/stage_cue_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject() {
    return const ProviderScope(child: MaterialApp(home: LiveSessionPage()));
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
        expect(find.text('Intro'), findsOneWidget);
        expect(find.text('Verso 1'), findsOneWidget);
        expect(find.text('Coro'), findsOneWidget);
        expect(find.text('Puente'), findsOneWidget);
        expect(find.text('Final'), findsOneWidget);

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
  });
}
