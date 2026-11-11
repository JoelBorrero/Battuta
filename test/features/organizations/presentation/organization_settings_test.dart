import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/pages/organization_settings_page.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/fake_organization_repository.dart';
import '../../../support/team_fixtures.dart';

void main() {
  late FakeOrganizationRepository repo;

  FakeOrganizationRepository twoAdmins() => FakeOrganizationRepository(
    organizations: [
      org('org-1', 'Grace Church'),
      org('org-2', 'Youth Band', role: OrganizationRole.member),
    ],
    members: [
      member('m1', 'u-me', 'Me', orgId: 'org-1', role: OrganizationRole.admin),
      member('m2', 'u-b', 'Beatriz', orgId: 'org-1', role: OrganizationRole.admin),
      member('m3', 'u-c', 'Carlos', orgId: 'org-1'),
      member('m4', 'u-me', 'Me', orgId: 'org-2'),
    ],
  );

  setUp(() => repo = twoAdmins());

  Future<void> pump(
    WidgetTester tester,
    String organizationId, {
    double width = 1024,
    double height = 2400,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      ProviderScope(
        overrides: signedInOverrides(repo),
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            initialLocation: '/org',
            routes: [
              GoRoute(
                path: '/org',
                builder: (_, _) =>
                    OrganizationSettingsPage(organizationId: organizationId),
              ),
              GoRoute(
                path: '/repertoire',
                builder: (_, _) => const Scaffold(body: Text('REPERTOIRE')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder byKey(String key) => find.byKey(ValueKey(key));

  group('a member', () {
    testWidgets('sees the name and role and can leave, nothing else', (
      tester,
    ) async {
      await pump(tester, 'org-2');

      expect(find.text('Youth Band'), findsOneWidget);
      expect(
        tester.widget<Text>(byKey('org_settings_role')).data,
        'Member',
      );
      expect(byKey('org_leave_btn'), findsOneWidget);
      expect(byKey('org_rename_btn'), findsNothing);
      expect(byKey('org_quota'), findsNothing);
      expect(byKey('org_archive_warning'), findsNothing);
      expect(repo.calls.where((c) => c.startsWith('getQuota')), isEmpty);
    });

    testWidgets('leaves after confirming and goes back to the app', (
      tester,
    ) async {
      await pump(tester, 'org-2');

      await tester.tap(byKey('org_leave_btn'));
      await tester.pumpAndSettle();
      expect(find.text('Leave organization'), findsWidgets);
      await tester.tap(byKey('org_leave_confirm'));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('leaveOrganization:org-2'));
      expect(find.text('REPERTOIRE'), findsOneWidget);
    });
  });

  group('an admin', () {
    testWidgets('sees rename, quota and the archive warning', (tester) async {
      await pump(tester, 'org-1');

      expect(
        tester.widget<Text>(byKey('org_settings_role')).data,
        'Admin',
      );
      expect(byKey('org_rename_btn'), findsOneWidget);
      expect(find.text('Plan: free'), findsOneWidget);
      expect(find.text('100 AI credits per month'), findsOneWidget);
      expect(find.text('Storage: 50 MB'), findsOneWidget);
      expect(
        tester.widget<Text>(byKey('org_archive_warning')).data,
        contains('cannot be undone from the app'),
      );
    });

    testWidgets('quota says so when offline', (tester) async {
      repo.offline = true;
      await pump(tester, 'org-1');

      expect(byKey('org_quota_unavailable'), findsOneWidget);
      expect(find.text('Quota is not available offline.'), findsOneWidget);
      expect(byKey('org_quota'), findsNothing);
    });

    testWidgets('renames the organization', (tester) async {
      await pump(tester, 'org-1');

      await tester.tap(byKey('org_rename_btn'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('org_rename_field'), 'Grace Chapel');
      await tester.tap(byKey('org_rename_confirm'));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('renameOrganization:org-1:Grace Chapel'));
      expect(find.text('Grace Chapel'), findsOneWidget);
      expect(find.text('Organization renamed'), findsOneWidget);
    });

    testWidgets('a rename refusal stays in the dialog', (tester) async {
      await pump(tester, 'org-1');
      repo.nextFailure = BackendErrorCode.invalidName.failure();

      await tester.tap(byKey('org_rename_btn'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('org_rename_field'), 'x');
      await tester.tap(byKey('org_rename_confirm'));
      await tester.pumpAndSettle();

      expect(byKey('org_rename_field'), findsOneWidget);
      expect(find.text('Grace Church'), findsOneWidget);
    });

    testWidgets('leaving as the last admin explains why it fails', (
      tester,
    ) async {
      await pump(tester, 'org-1');
      repo.nextFailure = BackendErrorCode.lastAdmin.failure();

      await tester.tap(byKey('org_leave_btn'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('org_leave_confirm'));
      await tester.pumpAndSettle();

      expect(find.textContaining('at least one admin'), findsOneWidget);
      expect(find.text('REPERTOIRE'), findsNothing);
      expect(
        find.text(
          'If you are the only admin, make another member an admin first.',
        ),
        findsOneWidget,
      );
    });
  });

  group('archiving', () {
    testWidgets('needs the organization name typed and warns it is final', (
      tester,
    ) async {
      await pump(tester, 'org-1');

      await tester.tap(byKey('org_archive_request_btn'));
      await tester.pumpAndSettle();

      expect(find.text('Archive Grace Church?'), findsOneWidget);
      expect(
        find.textContaining('cannot be undone from the app'),
        findsWidgets,
      );
      FilledButton confirm() =>
          tester.widget<FilledButton>(byKey('archive_confirm_btn'));
      expect(confirm().onPressed, isNull);

      await tester.enterText(byKey('archive_confirm_field'), 'Grace');
      await tester.pump();
      expect(confirm().onPressed, isNull);

      await tester.enterText(byKey('archive_confirm_field'), 'grace church');
      await tester.pump();
      expect(confirm().onPressed, isNotNull);

      await tester.tap(byKey('archive_confirm_btn'));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('requestArchive:org-1'));
      // Beatriz still has to approve.
      expect(byKey('archive_approval_u-b'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Requested by Me'), findsOneWidget);
      expect(byKey('org_archive_approve_btn'), findsNothing);
    });

    testWidgets('cancelling the typed confirmation requests nothing', (
      tester,
    ) async {
      await pump(tester, 'org-1');

      await tester.tap(byKey('org_archive_request_btn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repo.calls.where((c) => c.startsWith('requestArchive')), isEmpty);
      expect(byKey('org_archive_request_btn'), findsOneWidget);
    });

    testWidgets('offline, the request says so', (tester) async {
      await pump(tester, 'org-1');
      repo.offline = true;

      await tester.tap(byKey('org_archive_request_btn'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('archive_confirm_field'), 'Grace Church');
      await tester.pump();
      await tester.tap(byKey('archive_confirm_btn'));
      await tester.pumpAndSettle();

      expect(find.textContaining('offline'), findsOneWidget);
      expect(byKey('org_archive_request_btn'), findsOneWidget);
    });

    testWidgets('the other admin approves, which archives the organization', (
      tester,
    ) async {
      repo.setArchiveRequest(
        'org-1',
        const ArchiveRequest(
          organizationId: 'org-1',
          requestedBy: 'u-b',
          approvals: [ArchiveApproval(userId: 'u-b')],
        ),
      );
      await pump(tester, 'org-1');
      expect(find.text('Requested by Beatriz'), findsOneWidget);

      await tester.tap(byKey('org_archive_approve_btn'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('archive_confirm_field'), 'Grace Church');
      await tester.pump();
      await tester.tap(byKey('archive_confirm_btn'));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('approveArchive:org-1'));
      expect(byKey('org_archived_notice'), findsOneWidget);
      expect(byKey('org_archive_request_btn'), findsNothing);
      expect(byKey('org_leave_btn'), findsNothing);
      // The organization left the switcher.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(OrganizationSettingsPage)),
      );
      container.listen(myOrganizationsProvider, (_, _) {});
      await tester.pump();
      expect(
        container.read(myOrganizationsProvider).value!.map((o) => o.id),
        ['org-2'],
      );
    });

    testWidgets('an admin who already approved cannot approve twice', (
      tester,
    ) async {
      repo.setArchiveRequest(
        'org-1',
        const ArchiveRequest(
          organizationId: 'org-1',
          requestedBy: 'u-me',
          approvals: [ArchiveApproval(userId: 'u-me')],
        ),
      );
      await pump(tester, 'org-1');

      expect(byKey('org_archive_approve_btn'), findsNothing);
      expect(byKey('org_archive_cancel_btn'), findsOneWidget);
    });

    testWidgets('an admin cancels the request', (tester) async {
      repo.setArchiveRequest(
        'org-1',
        const ArchiveRequest(
          organizationId: 'org-1',
          requestedBy: 'u-b',
          approvals: [ArchiveApproval(userId: 'u-b')],
        ),
      );
      await pump(tester, 'org-1');

      await tester.tap(byKey('org_archive_cancel_btn'));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('cancelArchive:org-1'));
      expect(byKey('org_archive_request_btn'), findsOneWidget);
      expect(find.text('Archive request cancelled'), findsOneWidget);
    });

    testWidgets('members never see the archive section', (tester) async {
      repo.setArchiveRequest(
        'org-2',
        const ArchiveRequest(organizationId: 'org-2', requestedBy: 'u-x'),
      );
      await pump(tester, 'org-2');

      expect(byKey('org_archive_warning'), findsNothing);
      expect(byKey('org_archive_approve_btn'), findsNothing);
    });
  });

  testWidgets('an organization that is not mine says so', (tester) async {
    await pump(tester, 'org-gone');
    expect(find.text('This organization is not available.'), findsOneWidget);
  });

  group('layout', () {
    for (final width in [320.0, 375.0, 768.0, 1024.0, 1440.0]) {
      testWidgets('has no overflow at ${width.toInt()} px', (tester) async {
        repo = FakeOrganizationRepository(
          organizations: [
            org(
              'org-1',
              'An organization with a really very long name that must wrap '
                  'without overflowing anything on a phone',
            ),
          ],
          members: [
            for (var i = 0; i < 4; i++)
              member(
                'm$i',
                i == 0 ? 'u-me' : 'u$i',
                'Administrator With A Very Long Display Name Number $i',
                orgId: 'org-1',
                role: OrganizationRole.admin,
              ),
          ],
        )..setArchiveRequest(
            'org-1',
            const ArchiveRequest(
              organizationId: 'org-1',
              requestedBy: 'u1',
              approvals: [ArchiveApproval(userId: 'u1')],
            ),
          );
        await pump(tester, 'org-1', width: width, height: 900);
        expect(tester.takeException(), isNull);

        await tester.scrollUntilVisible(
          byKey('org_archive_approve_btn'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(byKey('org_archive_approve_btn'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('org_archive_approve_btn'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(byKey('archive_confirm_field'), findsOneWidget);
      });
    }
  });
}
