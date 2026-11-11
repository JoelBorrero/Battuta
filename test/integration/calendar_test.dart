/// The Calendar on real data: an admin schedules a recurring service,
/// assigns a member to an occurrence, the member declines, the admin sees the
/// alert and reassigns to a member who is available.
///
/// Written against the 006 migration; not run when Docker is down:
///
///   supabase db reset
///   flutter test --tags supabase --run-skipped test/integration
@Tags(['supabase'])
library;

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/services/service_calendar_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/stack.dart';
import 'support/test_user.dart';

void main() {
  StackConfig? stack;
  late TestUser admin;
  late TestUser first;
  late TestUser second;
  final created = <TestUser>[];

  setUpAll(() async {
    stack = await resolveStack();
    if (stack == null) return;
    admin = await TestUser.signUp(stack!, 'caladmin');
    first = await TestUser.signUp(stack!, 'calfirst');
    second = await TestUser.signUp(stack!, 'calsecond');
    created.addAll([admin, first, second]);
  });

  tearDownAll(() async {
    for (final user in created) {
      await user.dispose();
    }
  });

  test(
    'schedule, assign, decline, alert, reassign to an available member',
    () async {
      if (stack == null) {
        markTestSkipped(
          'Supabase stack not available: set SUPABASE_TEST_URL / '
          'SUPABASE_TEST_ANON_KEY or run `supabase start`.',
        );
        return;
      }

      final org = ok(await admin.orgs.createOrganization('Calendar Org'));
      final link = ok(await admin.orgs.createInviteLink(org.id));
      ok(await first.orgs.joinWithInviteLink(link.token));
      ok(await second.orgs.joinWithInviteLink(link.token));
      ok(await admin.orgs.refreshMembers(org.id));
      final members = await admin.orgs.watchMembers(org.id).first;
      OrganizationMember rowOf(TestUser user) =>
          members.firstWhere((m) => m.userId == user.id);

      // The admin schedules a weekly Sunday service.
      final schedule = ok(
        await admin.schedules.saveSchedule(
          RecurringSchedule(
            id: newEntityId(),
            organizationId: org.id,
            title: 'Sunday worship',
            lookaheadCount: 3,
            minuteOfDay: 10 * 60 + 30,
            location: 'Main hall',
            eventType: 'sundayService',
          ),
        ),
      );
      expect(schedule.minuteOfDay, 10 * 60 + 30);
      expect(schedule.location, 'Main hall');

      // The first projected occurrence becomes a real event when assigned.
      final now = DateTime.now();
      final projected = buildServiceEvents(
        now: now,
        events: const [],
        schedules: [schedule],
        assignments: const [],
        absences: const [],
      ).first;
      expect(projected.isProjected, isTrue);
      final materialized = ok(
        await admin.schedules.saveEvent(
          CalendarEvent(
            id: newEntityId(),
            organizationId: org.id,
            title: schedule.title,
            dateTime: projected.dateTime.toUtc(),
            location: schedule.location,
            eventType: schedule.eventType,
            seriesId: schedule.id,
            occurrenceDate: projected.occurrenceDate,
          ),
        ),
      );
      expect(materialized.seriesId, schedule.id);
      expect(materialized.occurrenceDate, projected.occurrenceDate);

      // A second materialization of the same occurrence is a conflict.
      final duplicate = await admin.schedules.saveEvent(
        CalendarEvent(
          id: newEntityId(),
          organizationId: org.id,
          title: schedule.title,
          dateTime: projected.dateTime.toUtc(),
          seriesId: schedule.id,
          occurrenceDate: projected.occurrenceDate,
        ),
      );
      expect(
        duplicate.fold((f) => f.errorCode, (_) => null),
        BackendErrorCode.conflict,
      );

      // Members cannot create events or link a setlist.
      final memberWrite = await first.schedules.saveEvent(
        CalendarEvent(
          id: newEntityId(),
          organizationId: org.id,
          title: 'Nope',
          dateTime: DateTime.now().toUtc().add(const Duration(days: 1)),
        ),
      );
      expect(memberWrite.isLeft(), isTrue);

      // The admin assigns the first member; they decline.
      final assignment = ok(
        await admin.schedules.assign(
          organizationId: org.id,
          eventId: materialized.id,
          memberId: rowOf(first).id,
          instrument: 'bass',
        ),
      );
      ok(
        await first.schedules.respond(
          org.id,
          assignment.id,
          AssignmentResponse.declined,
          declineReason: 'Out of town',
        ),
      );

      // The admin's calendar shows the declined slot (the alert source).
      ok(await admin.schedules.refreshOrganization(org.id));
      Future<List<ServiceEvent>> calendar() async => buildServiceEvents(
        now: now,
        events: await admin.schedules.watchEvents(org.id).first,
        schedules: await admin.schedules.watchSchedules(org.id).first,
        assignments: await admin.schedules.watchAssignments(org.id).first,
        absences: await admin.schedules.watchAbsences(org.id).first,
      );
      var event = (await calendar()).firstWhere((e) => e.id == materialized.id);
      expect(event.assignments.single.status, AssignmentStatus.declined);
      expect(event.assignments.single.declineReason, 'Out of town');

      // The second member is away that day: not available. The admin finds
      // cover among the available members instead.
      final day = DateTime(
        materialized.dateTime.toLocal().year,
        materialized.dateTime.toLocal().month,
        materialized.dateTime.toLocal().day,
      );
      ok(
        await second.schedules.saveAbsence(
          MemberAbsence(
            id: newEntityId(),
            organizationId: org.id,
            memberId: rowOf(second).id,
            startsOn: day,
            endsOn: day,
            note: 'Trip',
          ),
        ),
      );
      final available = ok(
        await admin.schedules.membersAvailableOn(org.id, day),
      );
      final availableIds = available.map((m) => m.memberId).toSet();
      expect(availableIds, contains(rowOf(first).id));
      expect(availableIds, isNot(contains(rowOf(second).id)));

      // Reassign to the (available) admin.
      final adminRow = rowOf(admin);
      expect(availableIds, contains(adminRow.id));
      ok(
        await admin.schedules.reassign(
          org.id,
          assignment.id,
          memberId: adminRow.id,
        ),
      );
      ok(await admin.schedules.refreshOrganization(org.id));
      event = (await calendar()).firstWhere((e) => e.id == materialized.id);
      expect(event.assignments.single.memberId, adminRow.id);
      expect(event.assignments.single.status, AssignmentStatus.scheduled);

      // Assigning the absent member shows them as away.
      ok(
        await admin.schedules.assign(
          organizationId: org.id,
          eventId: materialized.id,
          memberId: rowOf(second).id,
          instrument: 'keys',
        ),
      );
      ok(await admin.schedules.refreshOrganization(org.id));
      event = (await calendar()).firstWhere((e) => e.id == materialized.id);
      expect(
        event.assignments
            .firstWhere((a) => a.memberId == rowOf(second).id)
            .status,
        AssignmentStatus.away,
      );

      // Deleting the schedule keeps the materialized event, unlinked.
      ok(await admin.schedules.deleteSchedule(org.id, schedule.id));
      ok(await admin.schedules.refreshOrganization(org.id));
      final kept = (await admin.schedules.watchEvents(org.id).first).firstWhere(
        (e) => e.id == materialized.id,
      );
      expect(kept.seriesId, isNull);
      expect(kept.occurrenceDate, projected.occurrenceDate);
    },
  );
}
