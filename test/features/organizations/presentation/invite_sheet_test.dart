import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/organizations/domain/entities/invites.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/invite_actions_providers.dart';
import 'package:battuta/features/team/presentation/pages/team_page.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../support/fake_organization_repository.dart';
import '../../../support/team_fixtures.dart';

const _ana = UserProfile(
  id: 'u-ana',
  username: 'ana_g',
  displayName: 'Ana Gómez',
);
const _bob = UserProfile(id: 'u-bob', username: 'bobby', displayName: 'Bob');

FakeOrganizationRepository adminRepo({bool member = false}) =>
    FakeOrganizationRepository(
      organizations: [
        org(
          'org-1',
          'Grace Church',
          role: member ? OrganizationRole.member : OrganizationRole.admin,
        ),
      ],
      members: [member_('m1', member)],
      bands: const [Band(id: 'b1', organizationId: 'org-1', name: 'Alpha')],
    )..directory = const [_ana, _bob];

OrganizationMember member_(String id, bool asMember) => member(
  id,
  'u-me',
  'Me',
  role: asMember ? OrganizationRole.member : OrganizationRole.admin,
);

void main() {
  late List<String> shared;

  Future<void> pump(
    WidgetTester tester,
    FakeOrganizationRepository repository, {
    Size size = const Size(1024, 2048),
  }) async {
    shared = [];
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...signedInOverrides(repository),
          inviteSharerProvider.overrideWithValue(
            (text, {origin}) async => shared.add(text),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TeamPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('invite_btn')));
    await tester.pumpAndSettle();
  }

  testWidgets('a member never sees the invite button', (tester) async {
    await pump(tester, adminRepo(member: true));
    expect(find.byKey(const ValueKey('invite_btn')), findsNothing);
  });

  testWidgets('admin creates a link with expiry, max uses and band', (
    tester,
  ) async {
    final repo = adminRepo();
    await pump(tester, repo);
    await openSheet(tester);

    await tester.tap(find.byKey(const ValueKey('invite_expiry_30')));
    await tester.enterText(
      find.byKey(const ValueKey('invite_max_uses_field')),
      '5',
    );
    await tester.tap(find.byKey(const ValueKey('invite_band_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alpha').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('invite_create_link_btn')));
    await tester.pumpAndSettle();

    expect(repo.calls, contains('createInviteLink:org-1:b1:30:5'));
    expect(find.byKey(const ValueKey('invite_link_card')), findsOneWidget);
    final linkText = tester.widget<SelectableText>(
      find.byKey(const ValueKey('invite_link_text')),
    );
    expect(linkText.data, startsWith('battuta://join/a1b2c3d4'));
    final qr = tester.widget<QrImageView>(
      find.byKey(const ValueKey('invite_qr')),
    );
    expect(qr.semanticsLabel, 'QR code of the invite link');
    expect(find.text('5 uses', skipOffstage: false), findsNothing);
    expect(find.text('0 of 5 uses', skipOffstage: false), findsOneWidget);
  });

  testWidgets('copy puts the link on the clipboard, share opens the sheet', (
    tester,
  ) async {
    final repo = adminRepo();
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pump(tester, repo);
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('invite_create_link_btn')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('invite_copy_btn')));
    await tester.pumpAndSettle();
    expect(clipboard, startsWith('battuta://join/'));
    expect(find.text('Link copied'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('invite_share_btn')));
    await tester.pumpAndSettle();
    expect(shared, hasLength(1));
    expect(shared.single, contains('Grace Church'));
    expect(shared.single, contains('battuta://join/'));
  });

  testWidgets('revoke removes the link from the active list', (tester) async {
    final repo = adminRepo();
    await pump(tester, repo);
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('invite_create_link_btn')));
    await tester.pumpAndSettle();
    expect(find.text('No active links yet.'), findsNothing);

    await tester.tap(find.textContaining('Revoke'));
    await tester.pumpAndSettle();
    // Asks first; cancelling keeps the link.
    expect(find.byKey(const ValueKey('invite_revoke_confirm')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('invite_revoke_cancel_btn')));
    await tester.pumpAndSettle();
    expect(repo.calls.any((c) => c.startsWith('revokeInviteLink')), isFalse);
    expect(find.byKey(const ValueKey('invite_link_card')), findsOneWidget);

    await tester.tap(find.textContaining('Revoke'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('invite_revoke_confirm_btn')));
    await tester.pumpAndSettle();

    expect(repo.calls.any((c) => c.startsWith('revokeInviteLink')), isTrue);
    expect(find.text('No active links yet.'), findsOneWidget);
    expect(find.byKey(const ValueKey('invite_link_card')), findsNothing);
  });

  testWidgets('offline link creation shows the offline message', (
    tester,
  ) async {
    final repo = adminRepo()..offline = true;
    await pump(tester, repo);
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('invite_create_link_btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('invite_error')), findsOneWidget);
    expect(find.byKey(const ValueKey('invite_link_card')), findsNothing);
  });

  testWidgets('an invalid max uses is refused before calling the server', (
    tester,
  ) async {
    final repo = adminRepo();
    await pump(tester, repo);
    await openSheet(tester);
    await tester.enterText(
      find.byKey(const ValueKey('invite_max_uses_field')),
      '0',
    );
    await tester.tap(find.byKey(const ValueKey('invite_create_link_btn')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a whole number of 1 or more'), findsOneWidget);
    expect(repo.calls.where((c) => c.startsWith('createInviteLink')), isEmpty);
  });

  group('username tab', () {
    Future<void> search(WidgetTester tester, String text) async {
      await tester.tap(find.byKey(const ValueKey('invite_tab_username')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('invite_search_field')),
        text,
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    }

    testWidgets('results show username and display name, never email', (
      tester,
    ) async {
      await pump(tester, adminRepo());
      await openSheet(tester);
      await search(tester, 'ana');

      expect(find.text('Ana Gómez'), findsOneWidget);
      expect(find.text('@ana_g'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
      expect(find.textContaining('@example'), findsNothing);
    });

    testWidgets('short queries do not search', (tester) async {
      final repo = adminRepo();
      await pump(tester, repo);
      await openSheet(tester);
      await search(tester, 'an');
      expect(repo.searches, isEmpty);
    });

    testWidgets('invites, lists the pending invitation and cancels it', (
      tester,
    ) async {
      final repo = adminRepo();
      await pump(tester, repo);
      await openSheet(tester);
      await search(tester, 'ana');

      await tester.tap(find.byKey(const ValueKey('invite_send_u-ana')));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('inviteUserByUsername:ana_g:-'));
      expect(find.byKey(const ValueKey('invite_state_u-ana')), findsOneWidget);
      expect(find.textContaining('Ana Gómez (@ana_g)'), findsOneWidget);

      await tester.tap(find.textContaining('Cancel invitation'));
      await tester.pumpAndSettle();
      expect(repo.calls.any((c) => c.startsWith('cancelInvitation')), isTrue);
      expect(find.text('No pending invitations.'), findsOneWidget);
    });

    testWidgets('marks a previously declined person', (tester) async {
      final repo = adminRepo()
        ..setInvitations(const [
          Invitation(
            id: 'inv-old',
            organizationId: 'org-1',
            invitedUserId: 'u-ana',
            status: InvitationStatus.declined,
          ),
        ]);
      await pump(tester, repo);
      await openSheet(tester);
      await search(tester, 'ana');
      expect(
        find.byKey(const ValueKey('invite_declined_u-ana')),
        findsOneWidget,
      );
      expect(find.text('Previously declined'), findsOneWidget);
    });

    for (final (code, message) in [
      (BackendErrorCode.alreadyMember, 'That person is already a member.'),
      (
        BackendErrorCode.userNotFound,
        'No active user found with that username.',
      ),
      (
        BackendErrorCode.alreadyInvited,
        'That person already has a pending invitation.',
      ),
      (BackendErrorCode.cannotInviteSelf, 'You cannot invite yourself.'),
      (
        BackendErrorCode.memberDeactivated,
        'You are not a member of this organization.',
      ),
      (BackendErrorCode.offline, null),
    ]) {
      testWidgets('shows the ${code.code} error', (tester) async {
        final repo = adminRepo();
        await pump(tester, repo);
        await openSheet(tester);
        await search(tester, 'ana');
        repo.nextFailure = backendFailure(code);
        await tester.tap(find.byKey(const ValueKey('invite_send_u-ana')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('invite_error')), findsOneWidget);
        if (message != null) {
          expect(find.text(message), findsOneWidget);
        }
        // The person can be invited again.
        expect(find.byKey(const ValueKey('invite_send_u-ana')), findsOneWidget);
      });
    }
  });

  group('layout', () {
    for (final width in [320.0, 375.0, 768.0, 1024.0, 1440.0]) {
      testWidgets('invite sheet has no overflow at ${width.toInt()} px', (
        tester,
      ) async {
        final repo = adminRepo()
          ..setInvitations(const [
            Invitation(
              id: 'inv-1',
              organizationId: 'org-1',
              invitedUserId: 'u-ana',
              inviteeUsername: 'a_very_long_username_for_layout_checks',
              inviteeDisplayName:
                  'A very long display name that must wrap and not overflow',
            ),
          ]);
        await pump(tester, repo, size: Size(width, 800));
        await openSheet(tester);
        await tester.tap(find.byKey(const ValueKey('invite_create_link_btn')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const ValueKey('invite_tab_username')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('invite_search_field')),
          'ana',
        );
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
