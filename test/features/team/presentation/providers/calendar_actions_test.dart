import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/team/domain/entities/schedule_alert.dart';
import 'package:battuta/features/team/presentation/providers/calendar_actions.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_organization_repository.dart';
import '../../../../support/fake_schedule_repository.dart';
import '../../../../support/memory_storage.dart';
import '../../../../support/team_fixtures.dart';

void main() {
  final now = DateTime(2026, 11, 11, 10);
  const sunday = RecurringSchedule(
    id: 'sched-1',
    organizationId: 'org-1',
    title: 'Sunday Worship',
    lookaheadCount: 2,
  );

  FakeOrganizationRepository orgRepo({
    OrganizationRole role = OrganizationRole.admin,
  }) => FakeOrganizationRepository(
    organizations: [org('org-1', 'Grace Church', role: role)],
    members: [
      member('m-me', 'u-me', 'Maria Lopez', role: role),
      member('m-raul', 'u-raul', 'Raul Diaz'),
    ],
  );

  /// A container with the data providers kept alive and loaded.
  Future<ProviderContainer> container(
    FakeScheduleRepository schedules, {
    OrganizationRole role = OrganizationRole.admin,
    MemoryStorage? storage,
  }) async {
    final c = ProviderContainer(
      overrides: signedInOverrides(
        orgRepo(role: role),
        schedules: schedules,
        storage: storage,
        now: now,
      ),
    );
    addTearDown(c.dispose);
    c
      ..listen(activeOrganizationProvider, (_, _) {})
      ..listen(activeMembersProvider, (_, _) {})
      ..listen(activeEventsProvider, (_, _) {})
      ..listen(activeSchedulesProvider, (_, _) {})
      ..listen(activeAssignmentsProvider, (_, _) {})
      ..listen(activeAbsencesProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return c;
  }

  group('materializing an occurrence', () {
    test('assigning twice on the same occurrence creates one event', () async {
      final schedules = FakeScheduleRepository(schedules: [sunday]);
      final c = await container(schedules);
      final actions = c.read(calendarActionsProvider);

      final occurrence = c
          .read(allServiceEventsProvider)
          .firstWhere((e) => e.isProjected);
      await actions.assign(occurrence, 'm-raul', 'bass');
      await Future<void>.delayed(Duration.zero);
      final real = c
          .read(allServiceEventsProvider)
          .firstWhere((e) => e.occurrenceDate == occurrence.occurrenceDate);
      expect(real.isProjected, isFalse);
      await actions.assign(real, 'm-me', 'keys');

      expect(schedules.events, hasLength(1));
      expect(schedules.assignments, hasLength(2));
      expect(schedules.assignments.map((a) => a.eventId).toSet(), {
        schedules.events.single.id,
      });
    });

    test('a concurrent materialization is reloaded and reused', () async {
      final schedules = FakeScheduleRepository(schedules: [sunday]);
      final c = await container(schedules);
      final occurrence = c
          .read(allServiceEventsProvider)
          .firstWhere((e) => e.isProjected);

      // Another admin materializes the same occurrence first.
      schedules.beforeNextSaveEvent = () => schedules.addEvent(
        CalendarEvent(
          id: 'theirs',
          organizationId: 'org-1',
          title: 'Sunday Worship',
          dateTime: occurrence.dateTime.toUtc(),
          seriesId: 'sched-1',
          occurrenceDate: occurrence.occurrenceDate,
        ),
      );
      final result = await c
          .read(calendarActionsProvider)
          .assign(occurrence, 'm-raul', 'bass');

      expect(result.isRight(), isTrue);
      expect(schedules.events, hasLength(1));
      expect(schedules.events.single.id, 'theirs');
      expect(schedules.assignments.single.eventId, 'theirs');
      expect(schedules.calls.where((c) => c == 'refresh'), hasLength(1));
      expect(schedules.calls.where((c) => c.startsWith('saveEvent')), hasLength(1));
    });

    test('an edit made during the conflict is applied to the other admin\'s event', () async {
      final schedules = FakeScheduleRepository(schedules: [sunday]);
      final c = await container(schedules);
      final occurrence = c
          .read(allServiceEventsProvider)
          .firstWhere((e) => e.isProjected);
      schedules.beforeNextSaveEvent = () => schedules.addEvent(
        CalendarEvent(
          id: 'theirs',
          organizationId: 'org-1',
          title: 'Sunday Worship',
          dateTime: occurrence.dateTime.toUtc(),
          seriesId: 'sched-1',
          occurrenceDate: occurrence.occurrenceDate,
        ),
      );

      final result = await c.read(calendarActionsProvider).updateEvent(
        occurrence,
        EventDraft(
          title: 'Easter Worship',
          dateTime: occurrence.dateTime,
          type: occurrence.type,
        ),
      );

      expect(result.isRight(), isTrue);
      expect(schedules.events.single.id, 'theirs');
      expect(schedules.events.single.title, 'Easter Worship');
    });

    test('a failure other than a conflict is returned untouched', () async {
      final schedules = FakeScheduleRepository(schedules: [sunday]);
      final c = await container(schedules);
      final occurrence = c
          .read(allServiceEventsProvider)
          .firstWhere((e) => e.isProjected);
      schedules.nextFailure = BackendErrorCode.offline.failure();

      final result = await c
          .read(calendarActionsProvider)
          .assign(occurrence, 'm-raul', 'bass');

      expect(
        result.fold((f) => f.errorCode, (_) => null),
        BackendErrorCode.offline,
      );
      expect(schedules.events, isEmpty);
      expect(schedules.assignments, isEmpty);
    });
  });

  group('schedule alerts', () {
    CalendarEvent event() => CalendarEvent(
      id: 'e1',
      organizationId: 'org-1',
      title: 'Rehearsal',
      dateTime: DateTime(2026, 11, 13, 19).toUtc(),
    );

    EventAssignment assignment(
      AssignmentResponse response, {
      String memberId = 'm-raul',
    }) => EventAssignment(
      id: 'as-1',
      organizationId: 'org-1',
      eventId: 'e1',
      instrument: 'bass',
      memberId: memberId,
      response: response,
    );

    test('declined and absent assignments alert admins only', () async {
      final schedules = FakeScheduleRepository(
        events: [event()],
        assignments: [assignment(AssignmentResponse.declined)],
      );
      final admin = await container(schedules);
      expect(admin.read(adminScheduleAlertsProvider).single.kind, ScheduleAlertKind.declined);
      expect(admin.read(pendingAlertCountProvider), 1);

      final member = await container(
        FakeScheduleRepository(
          events: [event()],
          assignments: [assignment(AssignmentResponse.declined)],
        ),
        role: OrganizationRole.member,
      );
      expect(member.read(adminScheduleAlertsProvider), isEmpty);
    });

    test('an absence on the event day raises an absent alert', () async {
      final schedules = FakeScheduleRepository(
        events: [event()],
        assignments: [assignment(AssignmentResponse.accepted)],
        absences: [
          MemberAbsence(
            id: 'ab',
            organizationId: 'org-1',
            memberId: 'm-raul',
            startsOn: DateTime(2026, 11, 13),
            endsOn: DateTime(2026, 11, 14),
          ),
        ],
      );
      final c = await container(schedules);

      final alert = c.read(adminScheduleAlertsProvider).single;
      expect(alert.kind, ScheduleAlertKind.absent);
      expect(alert.memberName, 'Raul Diaz');
      expect(alert.instrument, 'bass');
    });

    test('alerts go away when resolved', () async {
      final schedules = FakeScheduleRepository(
        events: [event()],
        assignments: [assignment(AssignmentResponse.declined)],
      );
      final c = await container(schedules);
      expect(c.read(adminScheduleAlertsProvider), hasLength(1));

      await c.read(calendarActionsProvider).reassign('as-1', 'm-me');
      await Future<void>.delayed(Duration.zero);

      expect(c.read(adminScheduleAlertsProvider), isEmpty);
    });

    test('dismissals are kept for the account', () async {
      final storage = MemoryStorage();
      final schedules = FakeScheduleRepository(
        events: [event()],
        assignments: [assignment(AssignmentResponse.declined)],
      );
      final first = await container(schedules, storage: storage);
      final alert = first.read(adminScheduleAlertsProvider).single;
      await first.read(dismissedAlertsProvider.notifier).dismiss(alert.id);
      expect(first.read(adminScheduleAlertsProvider), isEmpty);

      final second = await container(schedules, storage: storage);
      second.listen(dismissedAlertsProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(second.read(adminScheduleAlertsProvider), isEmpty);
    });

    test('a different member declining the same slot is a new alert', () async {
      final schedules = FakeScheduleRepository(
        events: [event()],
        assignments: [assignment(AssignmentResponse.declined)],
      );
      final c = await container(schedules);
      await c
          .read(dismissedAlertsProvider.notifier)
          .dismiss(c.read(adminScheduleAlertsProvider).single.id);
      schedules.setAssignments([
        assignment(AssignmentResponse.declined, memberId: 'm-me'),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(c.read(adminScheduleAlertsProvider), hasLength(1));
    });
  });
}
