import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/team/domain/entities/recurring_schedule.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/features/team/presentation/pages/team_page.dart';
import 'package:battuta/features/team/presentation/providers/recurring_schedules_provider.dart';
import 'package:battuta/features/team/presentation/providers/service_calendar_provider.dart';
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

    testWidgets('has no Add member path; admins see a disabled Invite', (
      tester,
    ) async {
      await pump(tester, repo());

      expect(find.text('Add Member'), findsNothing);
      expect(find.byIcon(Icons.person_add), findsNothing);
      final invite = find.byKey(const ValueKey('invite_coming_soon_btn'));
      expect(invite, findsOneWidget);
      expect(find.text('Invite · Coming soon'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(invite).onPressed, isNull);
    });

    testWidgets('members do not see Invite or Manage bands', (tester) async {
      await pump(tester, repo(myRole: OrganizationRole.member));

      expect(
        find.byKey(const ValueKey('invite_coming_soon_btn')),
        findsNothing,
      );
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

  group('Band Calendar (local, no demo data)', () {
    ServiceEvent event({List<ServiceAssignment> assignments = const []}) =>
        ServiceEvent(
          id: 'event-1',
          title: 'Sunday Morning Worship',
          dateTime: DateTime.now().add(const Duration(days: 2)),
          assignments: assignments,
        );

    Future<void> openCalendar(
      WidgetTester tester,
      FakeOrganizationRepository repository, {
      List<ServiceAssignment>? assignments,
      Size size = const Size(1024, 2048),
    }) async {
      await pump(tester, repository, size: size);
      if (assignments != null) {
        ProviderScope.containerOf(tester.element(find.byType(TeamPage)))
            .read(serviceCalendarProvider.notifier)
            .addEvent(event(assignments: assignments));
      }
      await tester.tap(find.textContaining('Band Calendar'));
      await tester.pumpAndSettle();
    }

    const raulAssigned = [
      ServiceAssignment(memberId: 'm-raul', role: TeamRole.acousticGuitar),
    ];

    testWidgets('starts with no sample events', (tester) async {
      await openCalendar(tester, repo());

      expect(find.text('Sunday Morning Worship'), findsNothing);
      expect(find.text('Midweek Band Rehearsal'), findsNothing);
      expect(find.textContaining('Band Calendar (0)'), findsOneWidget);
    });

    testWidgets('adds a new service event', (tester) async {
      await openCalendar(tester, repo());

      await tester.tap(
        find.widgetWithText(FloatingActionButton, 'New Service'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add Service / Rehearsal'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Sunday Morning Worship'),
        'Youth Worship Night',
      );
      await tester.tap(find.byKey(const ValueKey('add_service_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Youth Worship Night'), findsOneWidget);
    });

    testWidgets('manages a recurring schedule', (tester) async {
      await openCalendar(tester, repo());
      ProviderScope.containerOf(tester.element(find.byType(TeamPage)))
          .read(recurringSchedulesProvider.notifier)
          .addSchedule(
            const RecurringSchedule(
              id: 'series-sunday-morning',
              title: 'Sunday Morning Worship',
              type: ServiceType.sundayService,
              recurrence: EventRecurrence.weekly,
              time: TimeOfDay(hour: 9, minute: 0),
              isActive: true,
              lookaheadCount: 4,
            ),
          );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('recurring_schedules_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Recurring Service Schedules'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('recurring_switch_series-sunday-morning')),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Schedule Paused — no occurrences generated'),
        findsOneWidget,
      );
    });

    testWidgets('opens Assign Musician on a 320px screen without overflow', (
      tester,
    ) async {
      await openCalendar(
        tester,
        repo(),
        assignments: raulAssigned,
        size: const Size(320, 640),
      );

      final assignBtn = find.byKey(
        const ValueKey('assign_musician_btn_event-1'),
      );
      await tester.scrollUntilVisible(
        assignBtn,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(assignBtn);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Assign Musician to'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<TeamMember>), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('a plain member gets the musician view', (tester) async {
      await openCalendar(
        tester,
        repo(myRole: OrganizationRole.member),
        assignments: raulAssigned,
      );

      expect(find.text('Musician View'), findsOneWidget);
      expect(find.text('Recurring Schedules'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('replaces a musician who cannot attend', (tester) async {
      await openCalendar(tester, repo(), assignments: raulAssigned);

      await tester.tap(
        find.byKey(const ValueKey('lineup_chip_event-1_m-raul')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Unavailable / Cannot Attend'));
      await tester.pumpAndSettle();

      // The declined musician raises a coverage alert for the admin.
      expect(
        find.textContaining('Scheduling Attention Needed'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('replace_btn_event-1_m-raul')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Assign Musician Replacement'), findsOneWidget);
      expect(find.textContaining('Cannot Attend: Raul Diaz'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('confirm_replacement_btn')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('lineup_chip_event-1_m-raul')),
        findsNothing,
      );
    });

    testWidgets('assigns a band to the service lineup', (tester) async {
      await openCalendar(tester, repo(), assignments: raulAssigned);

      await tester.tap(find.byKey(const ValueKey('assign_group_btn_event-1')));
      await tester.pumpAndSettle();
      expect(find.text('Assign Group to Service'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('assign_group_item_band-2')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Assigned Ensamble 2'), findsOneWidget);
    });
  });
}
