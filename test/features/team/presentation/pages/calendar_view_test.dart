import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/team/presentation/pages/team_page.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_organization_repository.dart';
import '../../../../support/fake_schedule_repository.dart';
import '../../../../support/team_fixtures.dart';

void main() {
  // Wednesday. The next Sundays are Nov 15, 22, 29 and Dec 6.
  final now = DateTime(2026, 11, 11, 10);

  const band1 = Band(id: 'band-1', organizationId: 'org-1', name: 'Ensamble 1');

  FakeOrganizationRepository orgRepo({
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
      member('m-ana', 'u-ana', 'Ana Cruz', instruments: ['acousticGuitar']),
    ],
    bands: [band1],
  );

  RecurringSchedule sunday({int lookahead = 2}) => RecurringSchedule(
    id: 'sched-1',
    organizationId: 'org-1',
    title: 'Sunday Worship',
    lookaheadCount: lookahead,
    minuteOfDay: 10 * 60 + 30,
    location: 'Main hall',
  );

  CalendarEvent rehearsal({String? bandId}) => CalendarEvent(
    id: 'evt-1',
    organizationId: 'org-1',
    title: 'Friday Rehearsal',
    dateTime: DateTime(2026, 11, 13, 19),
    bandId: bandId,
    eventType: 'rehearsal',
  );

  EventAssignment assignment({
    String id = 'as-1',
    String memberId = 'm-raul',
    AssignmentResponse response = AssignmentResponse.pending,
    String? reason,
  }) => EventAssignment(
    id: id,
    organizationId: 'org-1',
    eventId: 'evt-1',
    instrument: 'acousticGuitar',
    memberId: memberId,
    response: response,
    declineReason: reason,
  );

  Future<void> pump(
    WidgetTester tester, {
    FakeOrganizationRepository? repository,
    FakeScheduleRepository? schedules,
    Size size = const Size(1024, 2400),
    String? band,
    DateTime Function()? clock,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides:
            signedInOverrides(
              repository ?? orgRepo(),
              schedules: schedules,
              now: clock == null ? now : null,
            )..addAll([
              if (clock != null) calendarClockProvider.overrideWithValue(clock),
            ]),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TeamPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (band != null) {
      ProviderScope.containerOf(tester.element(find.byType(TeamPage)))
          .read(activeBandIdProvider.notifier)
          .select(band);
    }
    await tester.tap(find.textContaining('Band Calendar'));
    await tester.pumpAndSettle();
  }

  Finder key(String value) => find.byKey(ValueKey(value));

  Future<void> tapKey(WidgetTester tester, String value) async {
    final finder = key(value);
    // The list builds lazily: look down, then up.
    for (final delta in [300.0, -300.0]) {
      if (finder.evaluate().isNotEmpty) break;
      try {
        await tester.scrollUntilVisible(
          finder,
          delta,
          scrollable: find.byType(Scrollable).last,
        );
      } on StateError {
        // Not in this direction.
      }
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('Calendar on real data', () {
    testWidgets('shows real events and projected occurrences in date order', (
      tester,
    ) async {
      await pump(
        tester,
        schedules: FakeScheduleRepository(
          events: [rehearsal()],
          schedules: [sunday()],
        ),
      );

      expect(find.text('Friday Rehearsal'), findsOneWidget);
      expect(find.text('Sunday Worship'), findsNWidgets(2));
      expect(find.textContaining('Band Calendar (3)'), findsOneWidget);
      final rehearsalY = tester.getTopLeft(find.text('Friday Rehearsal')).dy;
      final firstSundayY = tester
          .getTopLeft(find.text('Sunday Worship').first)
          .dy;
      expect(rehearsalY, lessThan(firstSundayY));
    });

    testWidgets('Go live shows only on a service that has a setlist', (
      tester,
    ) async {
      await pump(
        tester,
        schedules: FakeScheduleRepository(
          events: [
            CalendarEvent(
              id: 'evt-with',
              organizationId: 'org-1',
              title: 'With setlist',
              dateTime: DateTime(2026, 11, 13, 19),
              setlistId: 'set-1',
            ),
            rehearsal(),
          ],
        ),
      );

      expect(key('go_live_btn_evt-with'), findsOneWidget);
      expect(key('go_live_btn_evt-1'), findsNothing);
      expect(find.text('Go live'), findsOneWidget);
    });

    testWidgets('the month grid marks days with services and selects days', (
      tester,
    ) async {
      await pump(
        tester,
        schedules: FakeScheduleRepository(
          events: [rehearsal()],
          schedules: [sunday(lookahead: 5)],
        ),
      );

      expect(find.text('November 2026'), findsOneWidget);
      // Fri 13 (rehearsal) and the Sundays 15 and 22 carry a dot.
      for (final day in ['2026-11-13', '2026-11-15', '2026-11-22']) {
        expect(key('month_dot_$day'), findsOneWidget);
      }
      expect(key('month_dot_2026-11-14'), findsNothing);
      // Today has no service: the list says so.
      expect(key('no_services_on_day'), findsOneWidget);

      await tester.tap(key('month_day_2026-11-15'));
      await tester.pumpAndSettle();
      expect(key('no_services_on_day'), findsNothing);
      expect(find.text('SUNDAY, NOVEMBER 15, 2026'), findsOneWidget);

      await tester.tap(key('month_next_btn'));
      await tester.pumpAndSettle();
      expect(find.text('December 2026'), findsOneWidget);
      expect(key('month_dot_2026-12-06'), findsOneWidget);
    });

    testWidgets('tapping a day far down a long list brings it into view', (
      tester,
    ) async {
      // Two services a day from Nov 12 to Nov 30: 38 cards.
      final events = [
        for (var day = 12; day <= 30; day++)
          for (final hour in [10, 18])
            CalendarEvent(
              id: 'evt-$day-$hour',
              organizationId: 'org-1',
              title: 'Service $day/$hour',
              dateTime: DateTime(2026, 11, day, hour),
            ),
      ];
      await pump(
        tester,
        schedules: FakeScheduleRepository(events: events),
        size: const Size(390, 700),
      );

      final grid = key('month_day_2026-11-30');
      await tester.ensureVisible(grid);
      await tester.pumpAndSettle();
      await tester.tap(grid);
      await tester.pumpAndSettle();

      final header = find.text('MONDAY, NOVEMBER 30, 2026');
      expect(header, findsOneWidget);
      final y = tester.getTopLeft(header).dy;
      expect(y, greaterThanOrEqualTo(0));
      expect(y, lessThan(700));

      // A day without services shows the message; the grid is still above.
      await tester.ensureVisible(key('month_day_2026-11-11'));
      await tester.pumpAndSettle();
      await tester.tap(key('month_day_2026-11-11'));
      await tester.pumpAndSettle();
      expect(key('no_services_on_day'), findsOneWidget);
      expect(key('month_day_2026-11-11'), findsOneWidget);
    });

    testWidgets('the selected day follows today until a day is picked', (
      tester,
    ) async {
      var clock = DateTime(2026, 11, 11, 23, 30);
      await pump(
        tester,
        schedules: FakeScheduleRepository(
          events: [rehearsal()],
          schedules: [sunday(lookahead: 5)],
        ),
        clock: () => clock,
      );
      expect(key('no_services_on_day'), findsOneWidget);
      expect(find.text('WEDNESDAY, NOVEMBER 11, 2026'), findsOneWidget);

      // Past midnight: Friday 13 (the rehearsal) becomes today and selected.
      clock = DateTime(2026, 11, 13, 0, 5);
      await tester.tap(key('month_next_btn'));
      await tester.pumpAndSettle();
      await tester.tap(key('month_prev_btn'));
      await tester.pumpAndSettle();
      expect(key('no_services_on_day'), findsNothing);
      expect(find.text('WEDNESDAY, NOVEMBER 11, 2026'), findsNothing);

      // A picked day stays when the clock moves on.
      await tester.tap(key('month_day_2026-11-20'));
      await tester.pumpAndSettle();
      expect(key('no_services_on_day'), findsOneWidget);
      clock = DateTime(2026, 11, 14, 9);
      await tester.tap(key('month_next_btn'));
      await tester.pumpAndSettle();
      await tester.tap(key('month_prev_btn'));
      await tester.pumpAndSettle();
      expect(key('no_services_on_day'), findsOneWidget);
      expect(find.text('FRIDAY, NOVEMBER 20, 2026'), findsOneWidget);
    });

    testWidgets('admin creates a one-off service', (tester) async {
      final schedules = FakeScheduleRepository();
      await pump(tester, schedules: schedules);

      await tapKey(tester, 'new_service_btn');
      await tester.enterText(key('service_title_field'), 'Youth Night');
      await tapKey(tester, 'service_save_btn');

      expect(schedules.calls, ['saveEvent:Youth Night']);
      expect(schedules.events.single.organizationId, 'org-1');
      expect(find.text('Youth Night'), findsOneWidget);
    });

    testWidgets('admin creates a recurring schedule', (tester) async {
      final schedules = FakeScheduleRepository();
      await pump(tester, schedules: schedules);

      await tapKey(tester, 'new_service_btn');
      await tester.enterText(key('service_title_field'), 'Thursday Band');
      await tapKey(tester, 'service_repeat_field');
      await tester.tap(find.text('Every Thursday (Weekly Rehearsal)').last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'service_save_btn');

      final saved = schedules.schedules.single;
      expect(saved.pattern, 'weeklyThursday');
      expect(saved.dayOfWeek, DateTime.thursday);
      expect(saved.lookaheadCount, 4);
      // Four projected Thursdays, none of them a real event yet.
      expect(find.text('Thursday Band'), findsNWidgets(4));
      expect(schedules.events, isEmpty);
    });

    testWidgets('assigning on a projected occurrence materializes it once', (
      tester,
    ) async {
      final schedules = FakeScheduleRepository(
        schedules: [sunday()],
        memberIds: ['m-me', 'm-raul', 'm-ana'],
      );
      await pump(tester, schedules: schedules);

      await tapKey(tester, 'assign_musician_btn_projected_sched-1_2026-11-15');
      await tapKey(tester, 'member_option_m-raul');

      expect(schedules.events, hasLength(1));
      final event = schedules.events.single;
      expect(event.seriesId, 'sched-1');
      expect(event.occurrenceDate, DateTime(2026, 11, 15));
      expect(event.title, 'Sunday Worship');
      expect(schedules.assignments.single.eventId, event.id);
      expect(schedules.assignments.single.memberId, 'm-raul');
      expect(schedules.assignments.single.instrument, 'acousticGuitar');
      // The occurrence is not shown twice.
      expect(find.text('Sunday Worship'), findsNWidgets(2));
      expect(find.text('Raul Diaz (Acoustic)'), findsOneWidget);
    });

    testWidgets('admin unassigns a member', (tester) async {
      final schedules = FakeScheduleRepository(
        events: [rehearsal()],
        assignments: [assignment()],
      );
      await pump(tester, schedules: schedules);

      expect(key('lineup_row_as-1'), findsOneWidget);
      await tapKey(tester, 'unassign_btn_as-1');

      expect(schedules.assignments, isEmpty);
      expect(key('lineup_row_as-1'), findsNothing);
    });

    testWidgets('a declined assignment raises an alert; reassign resolves it', (
      tester,
    ) async {
      final schedules = FakeScheduleRepository(
        events: [rehearsal()],
        assignments: [
          assignment(response: AssignmentResponse.declined, reason: 'Sick'),
        ],
        absences: [
          MemberAbsence(
            id: 'ab-ana',
            organizationId: 'org-1',
            memberId: 'm-ana',
            startsOn: DateTime(2026, 11, 13),
            endsOn: DateTime(2026, 11, 13),
          ),
        ],
        memberIds: ['m-me', 'm-raul', 'm-ana'],
      );
      await pump(tester, schedules: schedules);

      expect(key('schedule_alerts_banner'), findsOneWidget);
      expect(
        find.textContaining('Declined — missing cover for Acoustic'),
        findsOneWidget,
      );
      expect(find.textContaining('Reason: Sick'), findsWidgets);
      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('1')),
        findsOneWidget,
      ); // bell badge

      await tapKey(tester, 'alert_cover_as-1');
      // Available members who play the instrument: Ana is away, Maria plays keys.
      expect(key('member_option_m-ana'), findsNothing);
      expect(key('member_option_m-me'), findsNothing);
      expect(key('member_option_m-raul'), findsOneWidget);
      await tester.tap(key('assign_filter_plays'));
      await tester.pumpAndSettle();
      expect(key('member_option_m-me'), findsOneWidget);
      await tester.tap(key('assign_filter_available'));
      await tester.pumpAndSettle();
      expect(key('member_option_m-ana'), findsOneWidget);
      expect(find.text('Away that day'), findsOneWidget);
      await tester.tap(key('assign_filter_available'));
      await tester.pumpAndSettle();

      await tester.tap(key('member_option_m-me'));
      await tester.pumpAndSettle();

      expect(schedules.calls.last, 'reassign:as-1:m-me');
      expect(key('schedule_alerts_banner'), findsNothing);
    });

    testWidgets('an assigned member who is away raises an alert', (
      tester,
    ) async {
      await pump(
        tester,
        schedules: FakeScheduleRepository(
          events: [rehearsal()],
          assignments: [assignment(memberId: 'm-ana')],
          absences: [
            MemberAbsence(
              id: 'ab-ana',
              organizationId: 'org-1',
              memberId: 'm-ana',
              startsOn: DateTime(2026, 11, 12),
              endsOn: DateTime(2026, 11, 14),
            ),
          ],
        ),
      );

      expect(
        find.textContaining('Away that day — missing cover for Acoustic'),
        findsOneWidget,
      );
      expect(find.text('Ana Cruz (Acoustic)'), findsOneWidget);
    });

    testWidgets('dismissing an alert hides it', (tester) async {
      await pump(
        tester,
        schedules: FakeScheduleRepository(
          events: [rehearsal()],
          assignments: [assignment(response: AssignmentResponse.declined)],
        ),
      );

      await tapKey(tester, 'alert_dismiss_as-1');

      expect(key('schedule_alerts_banner'), findsNothing);
    });

    testWidgets('edits an occurrence: it becomes one event with the change', (
      tester,
    ) async {
      final schedules = FakeScheduleRepository(schedules: [sunday()]);
      await pump(tester, schedules: schedules);

      await tapKey(tester, 'event_menu_projected_sched-1_2026-11-15');
      await tapKey(tester, 'event_edit_projected_sched-1_2026-11-15');
      await tester.enterText(key('service_title_field'), 'Easter Worship');
      await tapKey(tester, 'service_save_btn');

      expect(schedules.events.single.title, 'Easter Worship');
      expect(schedules.events.single.occurrenceDate, DateTime(2026, 11, 15));
      expect(find.text('Easter Worship'), findsOneWidget);
      expect(find.text('Sunday Worship'), findsOneWidget);
    });

    testWidgets('admin deletes an event after confirming', (tester) async {
      final schedules = FakeScheduleRepository(events: [rehearsal()]);
      await pump(tester, schedules: schedules);

      await tapKey(tester, 'event_menu_evt-1');
      await tapKey(tester, 'event_delete_evt-1');
      await tapKey(tester, 'confirm_delete_service_btn');

      expect(schedules.events, isEmpty);
    });

    testWidgets('manages recurring schedules: pause, stop, delete', (
      tester,
    ) async {
      final schedules = FakeScheduleRepository(schedules: [sunday()]);
      await pump(tester, schedules: schedules);

      await tapKey(tester, 'recurring_schedules_btn');
      await tapKey(tester, 'schedule_pause_sched-1');
      expect(schedules.schedules.single.isActive, isFalse);
      expect(find.text('Paused'), findsOneWidget);

      await tapKey(tester, 'schedule_pause_sched-1'); // resume
      expect(schedules.schedules.single.isActive, isTrue);

      await tapKey(tester, 'schedule_delete_sched-1');
      await tapKey(tester, 'confirm_delete_schedule_btn');
      expect(schedules.schedules, isEmpty);
    });

    testWidgets('the band filter keeps its own and band-less services', (
      tester,
    ) async {
      final schedules = FakeScheduleRepository(
        events: [
          rehearsal(bandId: 'band-1'),
          CalendarEvent(
            id: 'evt-2',
            organizationId: 'org-1',
            title: 'Other Band Night',
            dateTime: DateTime(2026, 11, 14, 19),
            bandId: 'band-2',
          ),
          CalendarEvent(
            id: 'evt-3',
            organizationId: 'org-1',
            title: 'Everyone Night',
            dateTime: DateTime(2026, 11, 16, 19),
          ),
        ],
      );
      await pump(tester, schedules: schedules, band: 'band-1');

      expect(find.text('Friday Rehearsal'), findsOneWidget);
      expect(find.text('Everyone Night'), findsOneWidget);
      expect(find.text('Other Band Night'), findsNothing);
    });

    testWidgets(
      'an offline write shows the offline message and applies nothing',
      (tester) async {
        final schedules = FakeScheduleRepository();
        await pump(tester, schedules: schedules);

        schedules.nextFailure = BackendErrorCode.offline.failure();
        await tapKey(tester, 'new_service_btn');
        await tester.enterText(key('service_title_field'), 'Youth Night');
        await tapKey(tester, 'service_save_btn');

        expect(
          find.text('You\'re offline. Connect to the internet and try again.'),
          findsOneWidget,
        );
        expect(schedules.events, isEmpty);
        expect(key('service_save_btn'), findsOneWidget);
      },
    );

    testWidgets('a server refusal on a lineup change shows a message', (
      tester,
    ) async {
      final schedules = FakeScheduleRepository(
        events: [rehearsal()],
        assignments: [assignment()],
      );
      await pump(tester, schedules: schedules);

      schedules.nextFailure = BackendErrorCode.offline.failure();
      await tapKey(tester, 'unassign_btn_as-1');

      expect(find.textContaining('offline'), findsOneWidget);
      expect(key('lineup_row_as-1'), findsOneWidget);
    });
  });

  group('Calendar as a member', () {
    FakeOrganizationRepository memberRepo() =>
        orgRepo(myRole: OrganizationRole.member);

    testWidgets('sees no admin actions', (tester) async {
      await pump(
        tester,
        repository: memberRepo(),
        schedules: FakeScheduleRepository(
          events: [rehearsal()],
          schedules: [sunday()],
          assignments: [assignment(response: AssignmentResponse.declined)],
        ),
      );

      expect(key('new_service_btn'), findsNothing);
      expect(key('recurring_schedules_btn'), findsNothing);
      expect(key('assign_musician_btn_evt-1'), findsNothing);
      expect(key('unassign_btn_as-1'), findsNothing);
      expect(key('cover_btn_as-1'), findsNothing);
      expect(key('event_menu_evt-1'), findsNothing);
      expect(key('schedule_alerts_banner'), findsNothing);
      expect(key('admin_alerts_bell_btn'), findsNothing);
      expect(find.text('Friday Rehearsal'), findsOneWidget);
    });

    testWidgets('accepts and declines an assignment with a reason', (
      tester,
    ) async {
      final schedules = FakeScheduleRepository(
        events: [rehearsal()],
        assignments: [assignment(memberId: 'm-me')],
      );
      await pump(tester, repository: memberRepo(), schedules: schedules);

      expect(key('my_services_section'), findsOneWidget);
      await tapKey(tester, 'accept_btn_as-1');
      expect(schedules.calls.last, 'respond:as-1:accepted:null');
      expect(key('accept_btn_as-1'), findsNothing);

      await tapKey(tester, 'decline_btn_as-1');
      await tester.enterText(key('decline_reason_field'), 'Out of town');
      await tapKey(tester, 'confirm_decline_btn');

      expect(schedules.calls.last, 'respond:as-1:declined:Out of town');
      expect(
        schedules.assignments.single.response,
        AssignmentResponse.declined,
      );
      expect(key('decline_btn_as-1'), findsNothing);
      expect(key('accept_btn_as-1'), findsOneWidget);
    });

    testWidgets('does not list services of other members under My services', (
      tester,
    ) async {
      await pump(
        tester,
        repository: memberRepo(),
        schedules: FakeScheduleRepository(
          events: [rehearsal()],
          assignments: [assignment()],
        ),
      );

      expect(key('my_services_section'), findsNothing);
    });

    testWidgets('adds, edits and deletes an absence', (tester) async {
      final schedules = FakeScheduleRepository();
      await pump(tester, repository: memberRepo(), schedules: schedules);

      expect(
        find.text('No absences. Add the days you cannot play.'),
        findsOneWidget,
      );
      await tapKey(tester, 'add_absence_btn');
      await tester.enterText(key('absence_note_field'), 'Holiday');
      await tapKey(tester, 'absence_save_btn');

      final saved = schedules.absences.single;
      expect(saved.memberId, 'm-me');
      expect(saved.startsOn, DateTime(2026, 11, 11));
      expect(saved.endsOn, DateTime(2026, 11, 11));
      expect(saved.note, 'Holiday');
      expect(find.text('Holiday'), findsOneWidget);

      await tapKey(tester, 'absence_edit_${saved.id}');
      await tester.enterText(key('absence_note_field'), 'Back late');
      await tapKey(tester, 'absence_save_btn');
      expect(schedules.absences.single.id, saved.id);
      expect(schedules.absences.single.note, 'Back late');

      await tapKey(tester, 'absence_delete_${saved.id}');
      expect(schedules.absences, isEmpty);
    });

    testWidgets('being away shows on my own assignment', (tester) async {
      await pump(
        tester,
        repository: memberRepo(),
        schedules: FakeScheduleRepository(
          events: [rehearsal()],
          assignments: [assignment(memberId: 'm-me')],
          absences: [
            MemberAbsence(
              id: 'ab',
              organizationId: 'org-1',
              memberId: 'm-me',
              startsOn: DateTime(2026, 11, 13),
              endsOn: DateTime(2026, 11, 13),
            ),
          ],
        ),
      );

      expect(
        find.descendant(
          of: key('my_service_as-1'),
          matching: find.text('Away'),
        ),
        findsOneWidget,
      );
    });
  });

  group('Calendar without an account', () {
    testWidgets('local mode shows the sign in empty state', (tester) async {
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
      await tester.tap(find.textContaining('Band Calendar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Sign in to plan services with your organization'),
        findsOneWidget,
      );
      expect(key('calendar_sign_in_btn'), findsOneWidget);
      expect(key('new_service_btn'), findsNothing);
    });
  });

  group('Calendar layout', () {
    for (final width in [320.0, 375.0, 768.0, 1024.0, 1180.0, 1440.0]) {
      testWidgets('has no overflow at ${width.toInt()} px (admin)', (
        tester,
      ) async {
        final schedules = FakeScheduleRepository(
          events: [rehearsal()],
          schedules: [sunday()],
          assignments: [
            assignment(response: AssignmentResponse.declined, reason: 'Sick'),
            assignment(id: 'as-2', memberId: 'm-me'),
          ],
          absences: [
            MemberAbsence(
              id: 'ab',
              organizationId: 'org-1',
              memberId: 'm-me',
              startsOn: DateTime(2026, 11, 20),
              endsOn: DateTime(2026, 11, 25),
              note: 'A long note about a long trip abroad with the family',
            ),
          ],
          memberIds: ['m-me', 'm-raul', 'm-ana'],
        );
        await pump(tester, schedules: schedules, size: Size(width, 900));

        expect(tester.takeException(), isNull);
        await tapKey(tester, 'new_service_btn');
        // Unexpected exceptions are reported in full by the framework.
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await tapKey(tester, 'alert_cover_as-1');
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        await tapKey(tester, 'recurring_schedules_btn');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('has no overflow at 320 px (member)', (tester) async {
      await pump(
        tester,
        repository: orgRepo(myRole: OrganizationRole.member),
        schedules: FakeScheduleRepository(
          events: [rehearsal()],
          schedules: [sunday()],
          assignments: [assignment(memberId: 'm-me')],
        ),
        size: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
