import 'package:battuta/app/routes/app_router.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/presentation/providers/app_entry_provider.dart';
import 'package:battuta/features/organizations/domain/services/invite_link_parser.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/pending_invite_provider.dart';
import 'package:battuta/features/repertoire/presentation/pages/repertoire_page.dart';
import 'package:battuta/features/team/presentation/pages/team_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_auth_repository.dart';
import '../../../support/fake_organization_repository.dart';
import '../../../support/memory_storage.dart';
import '../../../support/team_fixtures.dart';

const _token =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
final _link = inviteLinkFor(_token);

void main() {
  AppHarness signedIn({FakeOrganizationRepository? repo}) => AppHarness(
    auth: FakeAuthRepository(
      user: const AuthUser(id: 'u-me', email: 'me@example.com'),
    ),
    organizations:
        repo ??
        (FakeOrganizationRepository(
          organizations: [org('org-1', 'Grace'), org('org-2', 'Youth')],
          members: [member('m1', 'u-me', 'Me', orgId: 'org-1')],
        )..joinOrganizationId = 'org-2'),
  );

  Future<void> pumpApp(WidgetTester tester, AppHarness h) async {
    tester.view.physicalSize = const Size(1024, 2048);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  Future<void> openLink(WidgetTester tester, AppHarness h, Uri uri) async {
    h.deepLinks.controller.add(uri);
    await tester.pumpAndSettle();
  }

  testWidgets('a deep link joins and switches to the organization', (
    tester,
  ) async {
    final h = signedIn();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    expect(find.byType(RepertoirePage), findsOneWidget);

    await openLink(tester, h, Uri.parse(_link));

    expect(h.organizations.calls, contains('joinWithInviteLink:$_token'));
    expect(find.byType(TeamPage), findsOneWidget);
    expect(container(tester).read(activeOrganizationIdProvider), 'org-2');
    expect(container(tester).read(pendingInviteTokenProvider), isNull);
  });

  testWidgets('an engine-delivered battuta URL is routed to the join page', (
    tester,
  ) async {
    final h = signedIn();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    container(tester).read(appRouterProvider).go(_link);
    await tester.pumpAndSettle();

    expect(h.organizations.calls, contains('joinWithInviteLink:$_token'));
    expect(find.byType(TeamPage), findsOneWidget);
  });

  testWidgets('a link for an organization I belong to still succeeds', (
    tester,
  ) async {
    final repo = FakeOrganizationRepository(
      organizations: [org('org-1', 'Grace'), org('org-2', 'Youth')],
      members: [member('m1', 'u-me', 'Me', orgId: 'org-1')],
    )..joinOrganizationId = 'org-1';
    final h = signedIn(repo: repo);
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    await openLink(tester, h, Uri.parse(_link));
    expect(find.byType(TeamPage), findsOneWidget);
    expect(container(tester).read(activeOrganizationIdProvider), 'org-1');
  });

  for (final code in [
    BackendErrorCode.inviteExpired,
    BackendErrorCode.inviteRevoked,
    BackendErrorCode.inviteUsedUp,
    BackendErrorCode.organizationArchived,
    BackendErrorCode.inviteNotFound,
    BackendErrorCode.offline,
  ]) {
    testWidgets('${code.code} shows the join result page', (tester) async {
      final h = signedIn();
      addTearDown(h.dispose);
      h.organizations.nextFailure = backendFailure(code);
      await pumpApp(tester, h);

      await openLink(tester, h, Uri.parse(_link));

      expect(find.byKey(const ValueKey('join_error')), findsOneWidget);
      expect(find.text('Could not join'), findsOneWidget);
      expect(find.byType(TeamPage), findsNothing);

      // Retry works once the problem is gone.
      await tester.tap(find.byKey(const ValueKey('join_retry_btn')));
      await tester.pumpAndSettle();
      expect(find.byType(TeamPage), findsOneWidget);
    });
  }

  testWidgets('the join error offers a way back to the app', (tester) async {
    final h = signedIn();
    addTearDown(h.dispose);
    h.organizations.nextFailure = backendFailure(
      BackendErrorCode.inviteExpired,
    );
    await pumpApp(tester, h);
    await openLink(tester, h, Uri.parse(_link));
    expect(find.text('This invite link has expired.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('join_back_btn')));
    await tester.pumpAndSettle();
    expect(find.byType(RepertoirePage), findsOneWidget);
  });

  testWidgets('other links (auth callback, wrong scheme) are ignored', (
    tester,
  ) async {
    final h = signedIn();
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    await openLink(tester, h, Uri.parse('battuta://login-callback#x=1'));
    await openLink(tester, h, Uri.parse('https://example.com/join/$_token'));

    expect(h.organizations.calls, isEmpty);
    expect(find.byType(RepertoirePage), findsOneWidget);
  });

  group('signed out', () {
    testWidgets('keeps the token through sign in, then joins', (tester) async {
      final h = AppHarness(
        organizations: FakeOrganizationRepository(
          organizations: [org('org-2', 'Youth')],
        )..joinOrganizationId = 'org-2',
      );
      addTearDown(h.dispose);
      await pumpApp(tester, h);
      expect(find.text('Welcome to Battuta'), findsOneWidget);

      await openLink(tester, h, Uri.parse(_link));
      expect(find.text('Welcome to Battuta'), findsOneWidget);
      expect(find.byKey(const ValueKey('pending_invite_note')), findsOneWidget);
      expect(h.organizations.calls, isEmpty);

      await tester.tap(find.byKey(const ValueKey('welcome_sign_in_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pending_invite_note')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('auth_email_field')),
        'me@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth_password_field')),
        'secret123',
      );
      await tester.tap(find.byKey(const ValueKey('auth_submit_btn')));
      await tester.pumpAndSettle();

      // After sign in the join asks first, naming the account.
      expect(find.byKey(const ValueKey('join_confirm')), findsOneWidget);
      expect(find.textContaining('me@example.com'), findsOneWidget);
      expect(h.organizations.calls, isEmpty);

      await tester.tap(find.byKey(const ValueKey('join_confirm_btn')));
      await tester.pumpAndSettle();

      expect(h.organizations.calls, contains('joinWithInviteLink:$_token'));
      expect(find.byType(TeamPage), findsOneWidget);
    });

    testWidgets(
      'signing out on the confirmation does not keep the token for the next account',
      (tester) async {
        final h = AppHarness(
          organizations: FakeOrganizationRepository(
            organizations: [org('org-2', 'Youth')],
          )..joinOrganizationId = 'org-2',
        );
        addTearDown(h.dispose);
        await pumpApp(tester, h);
        await openLink(tester, h, Uri.parse(_link));
        await tester.tap(find.byKey(const ValueKey('welcome_sign_in_btn')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('auth_email_field')),
          'me@example.com',
        );
        await tester.enterText(
          find.byKey(const ValueKey('auth_password_field')),
          'secret123',
        );
        await tester.tap(find.byKey(const ValueKey('auth_submit_btn')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('join_confirm')), findsOneWidget);

        // The session ends while the confirmation is open.
        await h.auth.signOut();
        await tester.pumpAndSettle();

        expect(container(tester).read(pendingInviteTokenProvider), isNull);
        expect(find.byKey(const ValueKey('pending_invite_note')), findsNothing);
        expect(h.organizations.calls, isEmpty);
      },
    );

    testWidgets('cancelling the confirmation does not join', (tester) async {
      final h = AppHarness(
        organizations: FakeOrganizationRepository(
          organizations: [org('org-2', 'Youth')],
        )..joinOrganizationId = 'org-2',
      );
      addTearDown(h.dispose);
      await pumpApp(tester, h);
      await openLink(tester, h, Uri.parse(_link));
      await tester.tap(find.byKey(const ValueKey('welcome_sign_in_btn')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('auth_email_field')),
        'me@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth_password_field')),
        'secret123',
      );
      await tester.tap(find.byKey(const ValueKey('auth_submit_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('join_cancel_btn')));
      await tester.pumpAndSettle();

      expect(h.organizations.calls, isEmpty);
      expect(find.byType(RepertoirePage), findsOneWidget);
      expect(container(tester).read(pendingInviteTokenProvider), isNull);
    });

    testWidgets('the note can be dismissed', (tester) async {
      final h = AppHarness();
      addTearDown(h.dispose);
      await pumpApp(tester, h);
      await openLink(tester, h, Uri.parse(_link));
      expect(find.byKey(const ValueKey('pending_invite_note')), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('pending_invite_dismiss_btn')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('pending_invite_note')), findsNothing);
      expect(container(tester).read(pendingInviteTokenProvider), isNull);
    });

    testWidgets('continue offline drops the saved invite', (tester) async {
      final h = AppHarness();
      addTearDown(h.dispose);
      await pumpApp(tester, h);
      await openLink(tester, h, Uri.parse(_link));
      expect(container(tester).read(pendingInviteTokenProvider), _token);

      await tester.tap(
        find.byKey(const ValueKey('welcome_continue_offline_btn')),
      );
      await tester.pumpAndSettle();

      expect(container(tester).read(pendingInviteTokenProvider), isNull);
      expect(find.byType(RepertoirePage), findsOneWidget);
    });

    testWidgets('offline mode sends the link to sign in', (tester) async {
      final h = AppHarness(
        entryStorage: MemoryStorage({
          AppEntryStorageKeys.continueOffline: 'true',
        }),
      );
      addTearDown(h.dispose);
      await pumpApp(tester, h);
      expect(find.byType(RepertoirePage), findsOneWidget);

      await openLink(tester, h, Uri.parse(_link));

      expect(find.byKey(const ValueKey('pending_invite_note')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth_submit_btn')), findsOneWidget);
    });

    testWidgets('the welcome paste field keeps a pasted link', (tester) async {
      final h = AppHarness();
      addTearDown(h.dispose);
      await pumpApp(tester, h);

      await tester.tap(find.byKey(const ValueKey('welcome_paste_invite_btn')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('paste_invite_field')),
        'https://example.com/join/$_token',
      );
      await tester.tap(find.byKey(const ValueKey('paste_invite_submit_btn')));
      await tester.pumpAndSettle();
      expect(
        find.text('That is not a valid invite link or code.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('paste_invite_field')),
        '  $_link  ',
      );
      await tester.tap(find.byKey(const ValueKey('paste_invite_submit_btn')));
      await tester.pumpAndSettle();

      expect(container(tester).read(pendingInviteTokenProvider), _token);
      expect(find.byKey(const ValueKey('pending_invite_note')), findsOneWidget);
    });
  });

  testWidgets('the Team empty state joins with a pasted code', (tester) async {
    final repo = FakeOrganizationRepository()..joinOrganizationId = 'org-9';
    final h = signedIn(repo: repo);
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    container(tester).read(appRouterProvider).go('/team');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('empty_join_org_btn')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('paste_invite_field')),
      _token,
    );
    await tester.tap(find.byKey(const ValueKey('paste_invite_submit_btn')));
    await tester.pumpAndSettle();

    expect(repo.calls, contains('joinWithInviteLink:$_token'));
    expect(find.byType(TeamPage), findsOneWidget);
  });

  group('layout', () {
    for (final width in [320.0, 375.0, 768.0, 1024.0, 1440.0]) {
      testWidgets('join error page at ${width.toInt()} px', (tester) async {
        final h = signedIn();
        addTearDown(h.dispose);
        h.organizations.nextFailure = backendFailure(
          BackendErrorCode.organizationArchived,
        );
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(h.build());
        await tester.pumpAndSettle();
        await openLink(tester, h, Uri.parse(_link));
        expect(find.byKey(const ValueKey('join_error')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
