import 'package:battuta/app/routes/app_router.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/organizations/domain/entities/invites.dart';
import 'package:battuta/features/organizations/domain/entities/notification.dart';
import 'package:battuta/features/organizations/presentation/pages/inbox_page.dart';
import 'package:battuta/features/organizations/presentation/pages/organization_settings_page.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/sharing/presentation/pages/merge_request_page.dart';
import 'package:battuta/features/sharing/presentation/pages/song_work_page.dart';
import 'package:battuta/features/team/presentation/pages/team_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_auth_repository.dart';
import '../../../support/fake_organization_repository.dart';
import '../../../support/team_fixtures.dart';

AppNotification note(
  String id,
  NotificationType type, {
  Map<String, dynamic> payload = const {},
  String? orgId = 'org-1',
  bool read = false,
  DateTime? at,
}) => AppNotification(
  id: id,
  recipientId: 'u-me',
  type: type,
  organizationId: orgId,
  payload: payload,
  createdAt: at ?? DateTime.now().subtract(const Duration(minutes: 5)),
  readAt: read ? DateTime.now() : null,
);

const _invitation = Invitation(
  id: 'inv-1',
  organizationId: 'org-9',
  invitedUserId: 'u-me',
  organizationName: 'Youth Band',
);

void main() {
  FakeOrganizationRepository repo() => FakeOrganizationRepository(
    organizations: [org('org-1', 'Grace'), org('org-2', 'Youth')],
    members: [member('m1', 'u-me', 'Me', orgId: 'org-1')],
  );

  AppHarness harness(FakeOrganizationRepository r) => AppHarness(
    auth: FakeAuthRepository(
      user: const AuthUser(id: 'u-me', email: 'me@example.com'),
    ),
    organizations: r,
  );

  Future<void> pumpApp(WidgetTester tester, AppHarness h, {double width = 1024}) async {
    tester.view.physicalSize = Size(width, 2048);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();
  }

  Future<void> openInbox(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('inbox_btn')));
    await tester.pumpAndSettle();
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  String location(WidgetTester tester) => container(tester)
      .read(appRouterProvider)
      .routeInformationProvider
      .value
      .uri
      .toString();

  testWidgets('the bell shows the unread count on every tab', (tester) async {
    final r = repo()
      ..setNotifications([
        note('n1', NotificationType.eventAssigned),
        note('n2', NotificationType.roleChanged),
        note('n3', NotificationType.removed, read: true),
      ]);
    final h = harness(r);
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    expect(find.byKey(const ValueKey('inbox_btn')), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    for (final path in ['/team', '/live', '/settings']) {
      container(tester).read(appRouterProvider).go(path);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('inbox_btn')), findsOneWidget, reason: path);
      expect(find.text('2'), findsOneWidget, reason: path);
    }
  });

  testWidgets('the bell is hidden in local mode', (tester) async {
    final h = AppHarness(); // not signed in
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    container(tester); // first launch shows the welcome page
    expect(find.byKey(const ValueKey('inbox_btn')), findsNothing);
  });

  testWidgets('a pending invitation without a notification still counts', (
    tester,
  ) async {
    final r = repo()..setMyInvitations([_invitation]);
    final h = harness(r);
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('lists notifications newest first with sentences and times', (
    tester,
  ) async {
    final now = DateTime.now();
    final r = repo()
      ..setNotifications([
        note(
          'old',
          NotificationType.removed,
          payload: {'organization_name': 'Choir'},
          at: now.subtract(const Duration(days: 2)),
        ),
        note(
          'new',
          NotificationType.eventAssigned,
          payload: {'event_title': 'Sunday service'},
          at: now.subtract(const Duration(minutes: 3)),
        ),
      ]);
    final h = harness(r);
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await openInbox(tester);

    expect(find.text('You were assigned to Sunday service'), findsOneWidget);
    expect(find.text('You were removed from Choir'), findsOneWidget);
    expect(find.text('3 min ago'), findsOneWidget);
    expect(find.text('2 d ago'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('notification_new'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('notification_old'))).dy),
    );
    expect(find.byKey(const ValueKey('notification_unread_new')), findsOneWidget);
  });

  testWidgets('every notification type renders in the inbox', (tester) async {
    final r = repo()
      ..setNotifications([
        for (final type in NotificationType.values)
          note('n-${type.name}', type),
      ]);
    final h = harness(r);
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await openInbox(tester);

    final list = find.byKey(const ValueKey('inbox_list'));
    for (final type in NotificationType.values) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('notification_n-${type.name}')),
        200,
        scrollable: find.descendant(of: list, matching: find.byType(Scrollable)),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('mark all as read clears the unread state and the badge', (
    tester,
  ) async {
    final r = repo()
      ..setNotifications([
        note('n1', NotificationType.eventAssigned),
        note('n2', NotificationType.roleChanged),
      ]);
    final h = harness(r);
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await openInbox(tester);

    await tester.tap(find.byKey(const ValueKey('inbox_mark_all_read_btn')));
    await tester.pumpAndSettle();

    expect(r.calls, contains('markNotificationsRead:all'));
    expect(find.byKey(const ValueKey('inbox_mark_all_read_btn')), findsNothing);
    expect(find.byKey(const ValueKey('notification_unread_n1')), findsNothing);
  });

  group('tapping a notification', () {
    Future<AppHarness> open(
      WidgetTester tester,
      AppNotification n, {
      FakeOrganizationRepository? repository,
    }) async {
      final r = (repository ?? repo())..setNotifications([n]);
      final h = harness(r);
      addTearDown(h.dispose);
      await pumpApp(tester, h);
      await openInbox(tester);
      await tester.tap(find.byKey(ValueKey('notification_${n.id}')));
      await tester.pumpAndSettle();
      return h;
    }

    testWidgets('marks it read and opens the Roster of its organization', (
      tester,
    ) async {
      final h = await open(
        tester,
        note('n1', NotificationType.roleChanged, orgId: 'org-2'),
      );
      expect(h.organizations.calls, contains('markNotificationsRead:n1'));
      expect(find.byType(TeamPage), findsOneWidget);
      expect(container(tester).read(activeOrganizationIdProvider), 'org-2');
      expect(find.textContaining('Team Roster'), findsOneWidget);
    });

    testWidgets('assignment notifications open the Calendar tab', (
      tester,
    ) async {
      await open(tester, note('n1', NotificationType.eventAssigned));
      expect(find.byType(TeamPage), findsOneWidget);
      final segmented = tester.widget<SegmentedButton<int>>(
        find.byType(SegmentedButton<int>),
      );
      expect(segmented.selected, {1});
    });

    testWidgets('archive notifications open the organization settings', (
      tester,
    ) async {
      await open(
        tester,
        note('n1', NotificationType.archiveRequested, orgId: 'org-2'),
      );
      expect(find.byType(OrganizationSettingsPage), findsOneWidget);
      expect(
        container(tester)
            .read(appRouterProvider)
            .routerDelegate
            .currentConfiguration
            .last
            .matchedLocation,
        '/organizations/org-2/settings',
      );
      expect(container(tester).read(activeOrganizationIdProvider), 'org-2');
    });

    testWidgets('a fork opens the song', (tester) async {
      await open(
        tester,
        note(
          'n1',
          NotificationType.songVersionForked,
          orgId: null,
          payload: {'version_id': 'ver-7'},
        ),
      );
      expect(location(tester), '/repertoire/ver-7');
    });

    String pushedLocation(WidgetTester tester) => container(tester)
        .read(appRouterProvider)
        .routerDelegate
        .currentConfiguration
        .last
        .matchedLocation;

    testWidgets('a copy of my version opens its song', (tester) async {
      await open(
        tester,
        note(
          'n1',
          NotificationType.songVersionForked,
          orgId: null,
          payload: {'version_id': 'ver-7', 'song_id': 'work-3'},
        ),
      );
      expect(find.byType(SongWorkPage), findsOneWidget);
      expect(pushedLocation(tester), '/songs/work-3');
    });

    testWidgets('a merge request opens the request to answer', (tester) async {
      await open(
        tester,
        note(
          'n1',
          NotificationType.songMergeRequested,
          orgId: null,
          payload: {'request_id': 'req-1'},
        ),
      );
      expect(find.byType(MergeRequestPage), findsOneWidget);
      expect(pushedLocation(tester), '/merge-requests/req-1');
    });

    testWidgets('an accepted merge opens the surviving song', (tester) async {
      await open(
        tester,
        note(
          'n1',
          NotificationType.songMergeAccepted,
          orgId: null,
          payload: {'source_song_id': 'song-a', 'target_song_id': 'song-b'},
        ),
      );
      expect(find.byType(SongWorkPage), findsOneWidget);
      expect(pushedLocation(tester), '/songs/song-b');
    });

    testWidgets('a merge request without its id opens the repertoire', (
      tester,
    ) async {
      await open(
        tester,
        note('n1', NotificationType.songMergeRequested, orgId: null),
      );
      expect(location(tester), '/repertoire');
    });

    testWidgets('a declined merge opens the repertoire', (tester) async {
      await open(
        tester,
        note('n1', NotificationType.songMergeDeclined, orgId: null),
      );
      expect(location(tester), '/repertoire');
    });

    testWidgets('an organization I left only says so', (tester) async {
      await open(
        tester,
        note('n1', NotificationType.roleChanged, orgId: 'org-gone'),
      );
      expect(find.text('You are no longer in that organization.'), findsOneWidget);
      expect(find.byType(InboxPage), findsOneWidget);
    });

    testWidgets('an unknown type is only marked as read', (tester) async {
      final h = await open(
        tester,
        note('n1', NotificationType.unknown, orgId: null),
      );
      expect(h.organizations.calls, contains('markNotificationsRead:n1'));
      expect(find.byType(InboxPage), findsOneWidget);
    });
  });

  testWidgets('offline: the inbox opens from the cache and read marks fail softly', (
    tester,
  ) async {
    final r = repo()
      ..offline = true
      ..setNotifications([note('n1', NotificationType.unknown, orgId: null)]);
    final h = harness(r);
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await openInbox(tester);

    expect(find.text('You have a new notification'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('inbox_mark_all_read_btn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification_unread_n1')), findsOneWidget);
    expect(find.text('You have a new notification'), findsOneWidget);
    expect(
      r.calls.where((c) => c.startsWith('markNotificationsRead')),
      isNotEmpty,
    );
    expect(backendFailure(BackendErrorCode.offline).message, 'offline');
  });

  testWidgets('shows the empty state', (tester) async {
    final h = harness(repo());
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await openInbox(tester);
    expect(find.byKey(const ValueKey('inbox_empty')), findsOneWidget);
  });

  group('invitations for me', () {
    testWidgets('the Team page banner accepts and switches organization', (
      tester,
    ) async {
      final r = repo()..setMyInvitations([_invitation]);
      final h = harness(r);
      addTearDown(h.dispose);
      await pumpApp(tester, h);
      container(tester).read(appRouterProvider).go('/team');
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('invitations_banner')), findsOneWidget);
      expect(find.text('Youth Band invited you to join.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('invitation_accept_inv-1')));
      await tester.pumpAndSettle();

      expect(r.calls, contains('respondToInvitation:inv-1:true'));
      expect(find.byKey(const ValueKey('invitations_banner')), findsNothing);
      expect(container(tester).read(activeOrganizationIdProvider), 'org-9');
    });

    testWidgets('the banner declines without switching', (tester) async {
      final r = repo()..setMyInvitations([_invitation]);
      final h = harness(r);
      addTearDown(h.dispose);
      await pumpApp(tester, h);
      container(tester).read(appRouterProvider).go('/team');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('invitation_decline_inv-1')));
      await tester.pumpAndSettle();

      expect(r.calls, contains('respondToInvitation:inv-1:false'));
      expect(find.byKey(const ValueKey('invitations_banner')), findsNothing);
      expect(container(tester).read(activeOrganizationIdProvider), 'org-1');
    });

    testWidgets('the inbox shows the cards on top and accepts', (tester) async {
      final r = repo()
        ..setMyInvitations([_invitation])
        ..setNotifications([
          note(
            'n1',
            NotificationType.invitation,
            orgId: 'org-9',
            payload: {'invitation_id': 'inv-1', 'organization_name': 'Youth Band'},
          ),
        ]);
      final h = harness(r);
      addTearDown(h.dispose);
      await pumpApp(tester, h);
      await openInbox(tester);

      expect(
        tester.getTopLeft(find.byKey(const ValueKey('invitation_card_inv-1'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const ValueKey('notification_n1'))).dy),
      );
      await tester.tap(find.byKey(const ValueKey('invitation_accept_inv-1')));
      await tester.pumpAndSettle();
      expect(r.calls, contains('respondToInvitation:inv-1:true'));
      expect(container(tester).read(activeOrganizationIdProvider), 'org-9');
      expect(find.byKey(const ValueKey('invitation_card_inv-1')), findsNothing);
    });

    testWidgets('answering marks its notification read and clears the badge', (
      tester,
    ) async {
      final r = repo()
        ..setMyInvitations([_invitation])
        ..setNotifications([
          note(
            'n1',
            NotificationType.invitation,
            orgId: 'org-9',
            payload: {'invitation_id': 'inv-1'},
          ),
        ]);
      final badge = find.byWidgetPredicate(
        (w) => w is Badge && w.isLabelVisible,
      );
      final h = harness(r);
      addTearDown(h.dispose);
      await pumpApp(tester, h);
      container(tester).read(appRouterProvider).go('/team');
      await tester.pumpAndSettle();
      expect(badge, findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('invitation_decline_inv-1')));
      await tester.pumpAndSettle();

      expect(r.calls, contains('markNotificationsRead:n1'));
      expect(badge, findsNothing);
    });

    testWidgets('an unread notification of an answered invitation is not counted', (
      tester,
    ) async {
      final r = repo()
        ..setMyInvitations([
          const Invitation(
            id: 'inv-1',
            organizationId: 'org-9',
            invitedUserId: 'u-me',
            status: InvitationStatus.declined,
            organizationName: 'Youth Band',
          ),
        ])
        ..setNotifications([
          note(
            'n1',
            NotificationType.invitation,
            orgId: 'org-9',
            payload: {'invitation_id': 'inv-1'},
          ),
        ]);
      final h = harness(r);
      addTearDown(h.dispose);
      await pumpApp(tester, h);

      expect(find.byKey(const ValueKey('inbox_btn')), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('an accept error is shown', (tester) async {
      final r = repo()..setMyInvitations([_invitation]);
      final h = harness(r);
      addTearDown(h.dispose);
      await pumpApp(tester, h);
      await openInbox(tester);
      r.nextFailure = backendFailure(BackendErrorCode.organizationArchived);

      await tester.tap(find.byKey(const ValueKey('invitation_accept_inv-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('invitation_card_inv-1')), findsOneWidget);
      expect(container(tester).read(activeOrganizationIdProvider), 'org-1');
    });
  });

  group('layout', () {
    for (final width in [320.0, 375.0, 768.0, 1024.0, 1440.0]) {
      testWidgets('inbox at ${width.toInt()} px', (tester) async {
        final r = repo()
          ..setMyInvitations([
            const Invitation(
              id: 'inv-1',
              organizationId: 'org-9',
              invitedUserId: 'u-me',
              organizationName:
                  'An extremely long organization name that keeps going and going',
            ),
          ])
          ..setNotifications([
            for (final type in NotificationType.values)
              note(
                'n-${type.name}',
                type,
                payload: {
                  'organization_name':
                      'An extremely long organization name that keeps going',
                  'event_title': 'A very long service title that must wrap',
                },
              ),
          ]);
        final h = harness(r);
        addTearDown(h.dispose);
        await pumpApp(tester, h, width: width);
        await openInbox(tester);
        expect(tester.takeException(), isNull);
        // The Live page body already overflows below 768 px (not from the
        // inbox button), so it is only checked on wide windows.
        for (final path in [
          '/team',
          '/repertoire',
          if (width >= 768) '/live',
          '/settings',
        ]) {
          container(tester).read(appRouterProvider).go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: path);
        }
      });
    }
  });
}
