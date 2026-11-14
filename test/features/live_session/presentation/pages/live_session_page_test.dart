import 'dart:io';

import 'package:battuta/core/platform/screen_wake_lock.dart';
import 'package:battuta/features/live_session/presentation/pages/live_session_page.dart';
import 'package:battuta/features/sync/data/lan_websocket_sync_service.dart';
import 'package:battuta/features/sync/domain/models/live_session.dart';
import 'package:battuta/features/sync/presentation/providers/live_sync_provider.dart';
import 'package:battuta/features/sync/presentation/widgets/stage_cue_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/device_prefs_fakes.dart';
import '../../../../support/live_fakes.dart';

void main() {
  late FakeLiveSessionDiscovery discovery;
  late FakeLanAddressResolver resolver;

  setUp(() {
    discovery = FakeLiveSessionDiscovery();
    resolver = FakeLanAddressResolver();
  });

  Widget buildSubject() {
    // Never reach the wake lock plugin, mDNS or the real network interfaces
    // from a widget test.
    return ProviderScope(
      overrides: [
        screenWakeLockProvider.overrideWithValue(FakeScreenWakeLock()),
        liveSessionDiscoveryProvider.overrideWithValue(discovery),
        lanAddressResolverProvider.overrideWithValue(resolver),
        liveDeviceNameProvider.overrideWithValue('Test iPad'),
      ],
      child: const MaterialApp(home: LiveSessionPage()),
    );
  }

  Future<void> hostSession(WidgetTester tester) async {
    await tester.tap(find.text('Director (Host)'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('live_host_toggle')));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
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
        // Defaults to Follower mode: browsing for sessions, no typed IP.
        expect(discovery.browsing, isTrue);
        expect(find.text('Looking for sessions…'), findsOneWidget);
        expect(find.text('Join by address'), findsOneWidget);
        expect(find.text('Director Host IP'), findsNothing);
        expect(find.text('ON STAGE NOW'), findsOneWidget);
      },
    );

    testWidgets('toggles between Follower and Director modes', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Initially in Follower mode
      expect(find.text('Join by address'), findsOneWidget);
      expect(discovery.browsing, isTrue);

      // Tap Director mode
      await tester.tap(find.text('Director (Host)'));
      await tester.pumpAndSettle();

      // Director view is displayed; browsing stops
      expect(find.text('HOST A SESSION'), findsOneWidget);
      expect(find.text('Host session'), findsOneWidget);
      expect(find.text('Trigger Test Cue'), findsOneWidget);
      expect(find.byType(DirectorControlBar), findsOneWidget);
      expect(discovery.browsing, isFalse);

      // Tap back to Follower mode
      await tester.tap(find.text('Musician (Follower)'));
      await tester.pumpAndSettle();

      expect(find.text('Join by address'), findsOneWidget);
      expect(discovery.browsing, isTrue);
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

      await hostSession(tester);

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
      expect(discovery.advertised, isNull);
    });

    testWidgets('lists sessions found nearby, live', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      discovery.emit(const [
        LiveSession(
          id: 'a',
          name: 'Sunday service',
          directorName: "Joel's iPad",
          host: '192.168.1.20',
          port: 47320,
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('NEARBY SESSIONS'), findsOneWidget);
      expect(find.text('Sunday service'), findsOneWidget);
      expect(find.text("Joel's iPad"), findsOneWidget);
      expect(find.text('Looking for sessions…'), findsNothing);

      discovery.emit(const []);
      await tester.pumpAndSettle();
      expect(find.text('Sunday service'), findsNothing);
    });

    testWidgets('shows "No sessions found nearby" after 5 seconds', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('No sessions found nearby'), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('No sessions found nearby'), findsOneWidget);
      expect(find.text('Join by address'), findsOneWidget);
    });

    testWidgets('tapping a nearby session joins it', (tester) async {
      final director = LanWebSocketSyncService();
      addTearDown(director.dispose);
      late int port;
      await tester.runAsync(() async {
        port = await director.startDirectorServer(
          address: InternetAddress.loopbackIPv4,
          port: 0,
        );
      });

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      discovery.emit([
        LiveSession(
          id: 'a',
          name: 'Sunday service',
          directorName: "Joel's iPad",
          host: '127.0.0.1',
          port: port,
        ),
      ]);
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('live_session_a')));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();

      expect(find.text('SYNCED'), findsOneWidget);
      expect(find.byKey(const ValueKey('live_end_button')), findsOneWidget);
      expect(director.followerNames, ['Test iPad']);
      expect(discovery.browsing, isFalse);

      // Leave.
      await tester.tap(find.byKey(const ValueKey('live_end_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('live_end_confirm')));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      // The socket close handshake leaves a 5 s timer on the fake clock.
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.text('STANDALONE'), findsOneWidget);
    });

    testWidgets('join by address rejects garbage with a message', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('live_join_by_address')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('live_address_field')),
        'banana',
      );
      await tester.tap(find.byKey(const ValueKey('live_address_join')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'That address is not valid. Use something like 192.168.1.20.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('join by address with an unreachable host explains why', (
      tester,
    ) async {
      final closed = await tester.runAsync(() async {
        final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final port = s.port;
        await s.close();
        return port;
      });
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('live_join_by_address')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('live_address_field')),
        '127.0.0.1:$closed',
      );
      await tester.tap(find.byKey(const ValueKey('live_address_join')));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('live_issue')), findsOneWidget);
      expect(find.textContaining('Could not reach the host'), findsOneWidget);
      expect(find.text('STANDALONE'), findsOneWidget);
    });

    testWidgets('hosting shows the address, a QR and who is connected', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      await hostSession(tester);

      expect(find.text('HOSTING'), findsOneWidget);
      expect(find.text('Live session · Test iPad'), findsOneWidget);
      expect(find.text('0 devices connected'), findsOneWidget);
      expect(find.text('CAN’T SEE IT? JOIN BY ADDRESS'), findsOneWidget);
      expect(find.byKey(const ValueKey('live_join_qr')), findsOneWidget);
      final shown = tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('live_join_address')),
          )
          .data!;
      expect(shown, startsWith('192.168.1.20:'));
      expect(discovery.advertised?.sessionName, 'Live session');
      expect(discovery.advertised?.directorName, 'Test iPad');
      expect(shown, endsWith(':${discovery.advertised?.port}'));

      // A follower joins and says hello.
      final follower = LanWebSocketSyncService(deviceName: 'Ana Galaxy');
      addTearDown(follower.dispose);
      await tester.runAsync(() async {
        await follower.connect('127.0.0.1', discovery.advertised!.port);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();

      expect(find.text('1 device connected'), findsOneWidget);
      expect(find.text('Ana Galaxy'), findsOneWidget);

      // The follower leaves; the host stops.
      await tester.runAsync(follower.disconnect);
      await tester.tap(find.byKey(const ValueKey('live_host_toggle')));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pumpAndSettle();
      // Drains the bounded close timeout of any socket still closing.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('hosting without Wi-Fi explains what to do', (tester) async {
      resolver.address = null;
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      await hostSession(tester);

      expect(
        find.text('Connect to Wi-Fi or turn on your hotspot to host'),
        findsOneWidget,
      );
      expect(find.text('HOSTING'), findsNothing);
      expect(discovery.advertised, isNull);
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
        expect(tester.takeException(), isNull);

        await hostSession(tester);
        await tester.tap(find.text('Trigger Test Cue'));
        await tester.pumpAndSettle();

        expect(find.byType(StageCueBanner), findsOneWidget);
        expect(find.byKey(const ValueKey('live_join_qr')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
