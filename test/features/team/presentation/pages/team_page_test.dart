import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/team/presentation/pages/team_page.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_organization_repository.dart';
import '../../../../support/team_fixtures.dart';

void main() {
  const band1 = Band(id: 'band-1', organizationId: 'org-1', name: 'Ensamble 1');
  const band2 = Band(
    id: 'band-2',
    organizationId: 'org-1',
    name: 'Ensamble 2',
    colorValue: 0xFF4A90E2,
  );

  FakeOrganizationRepository repo({
    OrganizationRole myRole = OrganizationRole.admin,
  }) => FakeOrganizationRepository(
    organizations: [org('org-1', 'Grace Church', role: myRole)],
    members: [
      member(
        'm-me',
        'u-me',
        'Maria Lopez',
        role: myRole,
        instruments: ['keys'],
      ),
      member('m-raul', 'u-raul', 'Raul Diaz', instruments: ['acousticGuitar']),
      member(
        'm-ana',
        'u-ana',
        'Ana Cruz',
        instruments: ['leadVocal'],
        minPitch: 'C4',
        maxPitch: 'A5',
      ),
      member('m-gone', 'u-gone', 'Gone Person', deactivatedAt: DateTime(2026)),
    ],
    bands: [band1, band2],
    bandMembers: const [
      BandMember(
        id: 'bm-1',
        organizationId: 'org-1',
        bandId: 'band-1',
        memberId: 'm-raul',
      ),
      BandMember(
        id: 'bm-2',
        organizationId: 'org-1',
        bandId: 'band-2',
        memberId: 'm-ana',
      ),
    ],
  );

  Widget subject(FakeOrganizationRepository repository) => ProviderScope(
    overrides: signedInOverrides(repository),
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TeamPage(),
    ),
  );

  Future<void> pump(
    WidgetTester tester,
    FakeOrganizationRepository repository, {
    Size size = const Size(1024, 2048),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(subject(repository));
    await tester.pumpAndSettle();
  }

  group('Roster on real data', () {
    testWidgets('lists active members of the active organization', (
      tester,
    ) async {
      await pump(tester, repo());

      expect(find.text('Grace Church'), findsOneWidget);
      expect(find.text('Maria Lopez'), findsOneWidget);
      expect(find.text('Raul Diaz'), findsOneWidget);
      expect(find.text('Ana Cruz'), findsOneWidget);
      expect(find.text('Gone Person'), findsNothing);
      expect(find.text('Total Roster'), findsOneWidget);
      expect(find.textContaining('Team Roster (3)'), findsOneWidget);
    });

    testWidgets('marks my own card with a You badge and admins with a shield', (
      tester,
    ) async {
      await pump(tester, repo());

      expect(find.byKey(const ValueKey('you_badge_m-me')), findsOneWidget);
      expect(find.byKey(const ValueKey('you_badge_m-raul')), findsNothing);
      expect(find.byKey(const ValueKey('admin_badge_m-me')), findsOneWidget);
      expect(find.byKey(const ValueKey('admin_badge_m-raul')), findsNothing);
    });

    testWidgets('has no Add member path; admins see an enabled Invite', (
      tester,
    ) async {
      await pump(tester, repo());

      expect(find.text('Add Member'), findsNothing);
      expect(find.byIcon(Icons.person_add), findsNothing);
      final invite = find.byKey(const ValueKey('invite_btn'));
      expect(invite, findsOneWidget);
      expect(find.text('Invite'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(invite).onPressed, isNotNull);
    });

    testWidgets('members do not see Invite or Manage bands', (tester) async {
      await pump(tester, repo(myRole: OrganizationRole.member));

      expect(find.byKey(const ValueKey('invite_btn')), findsNothing);
      expect(find.byKey(const ValueKey('manage_bands_btn')), findsNothing);
      expect(find.byKey(const ValueKey('leave_org_btn')), findsOneWidget);
    });

    testWidgets('filters by category chips', (tester) async {
      await pump(tester, repo());

      await tester.tap(find.byKey(const ValueKey('filter_chip_vocals')));
      await tester.pumpAndSettle();
      expect(find.text('Ana Cruz'), findsOneWidget);
      expect(find.text('Raul Diaz'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('filter_chip_band')));
      await tester.pumpAndSettle();
      expect(find.text('Raul Diaz'), findsOneWidget);
      expect(find.text('Ana Cruz'), findsNothing);
    });

    testWidgets('filters by band and shows band badges', (tester) async {
      await pump(tester, repo());

      expect(
        find.byKey(const ValueKey('member_group_badge_m-raul_band-1')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('filter_chip_group_band-2')));
      await tester.pumpAndSettle();
      expect(find.text('Ana Cruz'), findsOneWidget);
      expect(find.text('Raul Diaz'), findsNothing);
      expect(find.text('Maria Lopez'), findsNothing);

      // Tapping the selected band again returns to all bands.
      await tester.tap(find.byKey(const ValueKey('filter_chip_group_band-2')));
      await tester.pumpAndSettle();
      expect(find.text('Raul Diaz'), findsOneWidget);
    });

    testWidgets('admin edits instruments, pitch range and notes of a member', (
      tester,
    ) async {
      final repository = repo();
      await pump(tester, repository);

      await tester.tap(find.byKey(const ValueKey('member_card_m-raul')));
      await tester.pumpAndSettle();
      expect(find.text('Edit Team Member'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('vocal_range_discarded_info')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('role_chip_leadVocal')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('vocal_tessitura_dropdown')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('member_notes_field')),
        'Plays fingerstyle',
      );
      await tester.tap(find.byKey(const ValueKey('save_member_btn')));
      await tester.pumpAndSettle();

      expect(
        repository.calls,
        contains(
          'updateMusicianProfile:m-raul:leadVocal,acousticGuitar:C4:A5:'
          'Plays fingerstyle',
        ),
      );
      expect(find.text('Edit Team Member'), findsNothing);
      expect(find.text('Lead Vocalist'), findsWidgets);
      expect(find.text('Plays fingerstyle'), findsOneWidget);
    });

    testWidgets('admin promotes a member and assigns bands', (tester) async {
      final repository = repo();
      await pump(tester, repository);

      await tester.tap(find.byKey(const ValueKey('member_card_m-raul')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('member_admin_switch')));
      await tester.tap(
        find.byKey(const ValueKey('member_dialog_group_chip_band-2')),
      );
      await tester.tap(
        find.byKey(const ValueKey('member_dialog_group_chip_band-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save_member_btn')));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('setMemberRole:m-raul:admin'));
      expect(repository.calls, contains('addBandMember:band-2:m-raul'));
      expect(repository.calls, contains('removeBandMember:bm-1'));
      expect(find.byKey(const ValueKey('admin_badge_m-raul')), findsOneWidget);
    });

    testWidgets('demoting the last admin shows the localized error', (
      tester,
    ) async {
      final repository = repo();
      await pump(tester, repository);

      await tester.tap(find.byKey(const ValueKey('member_card_m-me')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('member_admin_switch')));
      await tester.pumpAndSettle();
      // The profile write succeeds, then the role change is refused.
      repository.failWhen = (call) => call.startsWith('setMemberRole')
          ? backendFailure(BackendErrorCode.lastAdmin)
          : null;
      await tester.tap(find.byKey(const ValueKey('save_member_btn')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Some changes were saved, but the role could not be changed. '
          'An organization needs at least one admin. Make someone else an admin first.',
        ),
        findsOneWidget,
      );
      expect(find.text('Edit Team Member'), findsOneWidget);
      expect(find.byKey(const ValueKey('admin_badge_m-me')), findsOneWidget);
    });

    testWidgets(
      'a failure after earlier writes says changes were saved partly',
      (tester) async {
        final repository = repo();
        await pump(tester, repository);

        await tester.tap(find.byKey(const ValueKey('member_card_m-raul')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('role_chip_drums')));
        await tester.tap(find.byKey(const ValueKey('member_admin_switch')));
        await tester.tap(
          find.byKey(const ValueKey('member_dialog_group_chip_band-2')),
        );
        await tester.pumpAndSettle();
        repository.failWhen = (call) => call.startsWith('addBandMember')
            ? backendFailure(BackendErrorCode.offline)
            : null;
        await tester.tap(find.byKey(const ValueKey('save_member_btn')));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Some changes were saved, but the bands could not be updated. '
            "You're offline. Connect to the internet and try again.",
          ),
          findsOneWidget,
        );
        // The retry only sends what is still missing.
        repository
          ..failWhen = null
          ..calls.clear();
        await tester.tap(find.byKey(const ValueKey('save_member_btn')));
        await tester.pumpAndSettle();
        expect(
          repository.calls.where((c) => c.startsWith('setMemberRole')),
          isEmpty,
        );
        expect(repository.calls, contains('addBandMember:band-2:m-raul'));
      },
    );

    testWidgets('offline writes show the offline message and apply nothing', (
      tester,
    ) async {
      final repository = repo();
      await pump(tester, repository);

      await tester.tap(find.byKey(const ValueKey('member_card_m-raul')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('role_chip_drums')));
      repository.nextFailure = backendFailure(BackendErrorCode.offline);
      await tester.tap(find.byKey(const ValueKey('save_member_btn')));
      await tester.pumpAndSettle();

      expect(
        find.text("You're offline. Connect to the internet and try again."),
        findsOneWidget,
      );
      expect(find.text('Edit Team Member'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Drums / Percussion'), findsNothing);
    });

    testWidgets('a member edits only their own card', (tester) async {
      final repository = repo(myRole: OrganizationRole.member);
      await pump(tester, repository);

      // Someone else's card does nothing.
      await tester.tap(find.byKey(const ValueKey('member_card_m-raul')));
      await tester.pumpAndSettle();
      expect(find.text('Edit Team Member'), findsNothing);
      expect(find.byKey(const ValueKey('member_menu_m-raul')), findsNothing);

      // Their own card opens a dialog without role or band controls.
      await tester.tap(find.byKey(const ValueKey('member_card_m-me')));
      await tester.pumpAndSettle();
      expect(find.text('Edit Team Member'), findsOneWidget);
      expect(find.byKey(const ValueKey('member_admin_switch')), findsNothing);
      expect(
        find.byKey(const ValueKey('member_dialog_group_chip_band-1')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('role_chip_bass')));
      await tester.tap(find.byKey(const ValueKey('save_member_btn')));
      await tester.pumpAndSettle();
      expect(
        repository.calls.single,
        startsWith('updateMusicianProfile:m-me:'),
      );
      expect(repository.calls.single, contains('bass'));
      expect(
        repository.calls.any((c) => c.startsWith('setMemberRole')),
        isFalse,
      );
    });

    testWidgets('admin removes a member after confirming', (tester) async {
      final repository = repo();
      await pump(tester, repository);

      await tester.tap(find.byKey(const ValueKey('member_menu_m-raul')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove Member').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm_remove_member_btn')));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('removeMember:m-raul'));
      expect(find.text('Raul Diaz'), findsNothing);
    });

    testWidgets('a member leaves the organization', (tester) async {
      final repository = repo(myRole: OrganizationRole.member);
      await pump(tester, repository);

      await tester.tap(find.byKey(const ValueKey('leave_org_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm_leave_org_btn')));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('leaveOrganization:org-1'));
      expect(find.text('No organization yet'), findsOneWidget);
    });

    testWidgets('only admins manage bands: create, rename, delete', (
      tester,
    ) async {
      final repository = repo();
      await pump(tester, repository);

      await tester.tap(find.byKey(const ValueKey('manage_bands_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add_band_btn')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('band_name_field')),
        'Youth',
      );
      await tester.tap(find.byKey(const ValueKey('band_save_btn')));
      await tester.pumpAndSettle();
      expect(repository.calls, contains('createBand:Youth'));
      expect(find.text('Youth'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('band_edit_band-1')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('band_name_field')),
        'Morning',
      );
      await tester.tap(find.byKey(const ValueKey('band_save_btn')));
      await tester.pumpAndSettle();
      expect(repository.calls, contains('updateBand:band-1:Morning'));

      await tester.tap(find.byKey(const ValueKey('band_delete_band-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm_delete_band_btn')));
      await tester.pumpAndSettle();
      expect(repository.calls, contains('deleteBand:band-2'));
    });

    testWidgets('a band error from the server is shown in the dialog', (
      tester,
    ) async {
      final repository = repo();
      await pump(tester, repository);

      await tester.tap(find.byKey(const ValueKey('manage_bands_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add_band_btn')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('band_name_field')),
        'Youth',
      );
      repository.nextFailure = backendFailure(BackendErrorCode.notAdmin);
      await tester.tap(find.byKey(const ValueKey('band_save_btn')));
      await tester.pumpAndSettle();

      expect(
        find.text('Only organization admins can do this.'),
        findsOneWidget,
      );
    });

    testWidgets('renders cards without overflow on a narrow screen', (
      tester,
    ) async {
      await pump(tester, repo(), size: const Size(320, 640));

      expect(tester.takeException(), isNull);
      expect(find.text('Maria Lopez'), findsOneWidget);
    });

    testWidgets('shows a sign in prompt in local mode', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TeamPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign in to see your team'), findsOneWidget);
      expect(find.byKey(const ValueKey('roster_sign_in_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('org_switcher_btn')), findsNothing);
    });
  });
}
