import 'dart:io';

import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/live_session/presentation/pages/live_session_page.dart';
import 'package:battuta/features/sync/data/lan_websocket_sync_service.dart';
import 'package:battuta/features/sync/presentation/providers/live_sync_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_auth_repository.dart';
import '../../../support/fake_organization_repository.dart';
import '../../../support/team_fixtures.dart';

void main() {
  testWidgets('a battuta-live link opens Live and joins that session', (
    tester,
  ) async {
    final h = AppHarness(
      auth: FakeAuthRepository(
        user: const AuthUser(id: 'u-me', email: 'me@example.com'),
      ),
      organizations: FakeOrganizationRepository(
        organizations: [org('org-1', 'Grace')],
        members: [member('m1', 'u-me', 'Me', orgId: 'org-1')],
      ),
    );
    addTearDown(h.dispose);
    final director = LanWebSocketSyncService();
    addTearDown(director.dispose);
    late int port;
    await tester.runAsync(() async {
      port = await director.startDirectorServer(
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
    });

    tester.view.physicalSize = const Size(1024, 2048);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();
    expect(find.byType(LiveSessionPage), findsNothing);

    h.deepLinks.controller.add(Uri.parse('battuta-live://127.0.0.1:$port'));
    await tester.pumpAndSettle();
    // The handshake finishes on the real event loop; the fake clock needs a
    // pump between each wait to run what that completed.
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    expect(find.byType(LiveSessionPage), findsOneWidget);
    expect(find.text('SYNCED'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    expect(container.read(liveSyncControllerProvider).isConnected, isTrue);
    expect(director.connectedFollowersCount, 1);

    // Leave, then let the socket close handshake finish.
    final leaving = container
        .read(liveSyncControllerProvider.notifier)
        .disconnect();
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump(const Duration(seconds: 6));
    await leaving;
    await tester.pumpAndSettle();
  });

  group('a link while a session is running', () {
    Future<
      ({
        AppHarness h,
        ProviderContainer container,
        LanWebSocketSyncService other,
        int otherPort,
      })
    >
    hostAndSetUp(WidgetTester tester) async {
      final h = AppHarness(
        auth: FakeAuthRepository(
          user: const AuthUser(id: 'u-me', email: 'me@example.com'),
        ),
        organizations: FakeOrganizationRepository(
          organizations: [org('org-1', 'Grace')],
          members: [member('m1', 'u-me', 'Me', orgId: 'org-1')],
        ),
      );
      addTearDown(h.dispose);
      final other = LanWebSocketSyncService();
      addTearDown(other.dispose);
      late int otherPort;
      await tester.runAsync(() async {
        otherPort = await other.startDirectorServer(
          address: InternetAddress.loopbackIPv4,
          port: 0,
        );
      });
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(h.build());
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      await tester.runAsync(() async {
        await container
            .read(liveSyncControllerProvider.notifier)
            .startHosting(sessionName: 'Sunday');
      });
      await tester.pumpAndSettle();
      expect(container.read(liveSyncControllerProvider).isDirector, isTrue);
      expect(h.liveDiscovery.advertised, isNotNull);
      return (h: h, container: container, other: other, otherPort: otherPort);
    }

    Future<void> settleReal(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
      }
    }

    Future<void> end(WidgetTester tester, ProviderContainer container) async {
      final leaving = container
          .read(liveSyncControllerProvider.notifier)
          .disconnect();
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(seconds: 6));
      await leaving;
      await tester.pumpAndSettle();
    }

    testWidgets('asks first; Cancel keeps hosting, Join switches', (
      tester,
    ) async {
      final t = await hostAndSetUp(tester);
      final hostedPort = t.container
          .read(liveSyncControllerProvider)
          .serverPort;

      t.h.deepLinks.controller.add(
        Uri.parse('battuta-live://127.0.0.1:${t.otherPort}'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LiveSessionPage), findsOneWidget);
      expect(find.text('Leave the current session?'), findsOneWidget);
      expect(find.textContaining('127.0.0.1:${t.otherPort}'), findsOneWidget);
      // Nothing happened yet.
      var s = t.container.read(liveSyncControllerProvider);
      expect(s.isDirector, isTrue);
      expect(t.h.liveDiscovery.advertised, isNotNull);

      await tester.tap(find.byKey(const ValueKey('live_switch_cancel')));
      await tester.pumpAndSettle();
      s = t.container.read(liveSyncControllerProvider);
      expect(s.isDirector, isTrue);
      expect(s.isConnected, isTrue);
      expect(s.serverPort, hostedPort);
      expect(s.pendingJoin, isNull);
      expect(t.h.liveDiscovery.advertised, isNotNull);

      t.h.deepLinks.controller.add(
        Uri.parse('battuta-live://127.0.0.1:${t.otherPort}'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('live_switch_join')));
      await tester.pumpAndSettle();
      await settleReal(tester);

      s = t.container.read(liveSyncControllerProvider);
      expect(s.isDirector, isFalse);
      expect(s.isConnected, isTrue);
      expect(s.serverPort, isNull);
      expect(s.joinAddress, isNull);
      expect(s.followers, isEmpty);
      expect(t.h.liveDiscovery.advertised, isNull);
      expect(t.other.connectedFollowersCount, 1);

      await end(tester, t.container);
    });

    testWidgets('the address already in use is a no-op', (tester) async {
      final t = await hostAndSetUp(tester);
      final own = t.container.read(liveSyncControllerProvider).joinAddress!;

      t.h.deepLinks.controller.add(Uri.parse(own.link));
      await tester.pumpAndSettle();

      expect(find.text('Leave the current session?'), findsNothing);
      expect(t.container.read(liveSyncControllerProvider).isDirector, isTrue);
      await end(tester, t.container);
    });

    testWidgets('a malformed link is ignored', (tester) async {
      final t = await hostAndSetUp(tester);

      for (final bad in ['battuta-live://', 'battuta-live://x:99999']) {
        t.h.deepLinks.controller.add(Uri.parse(bad));
        await tester.pumpAndSettle();
      }

      expect(find.text('Leave the current session?'), findsNothing);
      final s = t.container.read(liveSyncControllerProvider);
      expect(s.isDirector, isTrue);
      expect(s.pendingJoin, isNull);
      await end(tester, t.container);
    });
  });
}
