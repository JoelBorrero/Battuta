import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/services/service_calendar_builder.dart';
import 'package:flutter_test/flutter_test.dart';

RecurringSchedule schedule({
  String id = 's1',
  String pattern = 'weekly',
  int lookahead = 4,
  bool active = true,
  DateTime? disabledAfter,
  int minuteOfDay = 9 * 60,
}) => RecurringSchedule(
  id: id,
  organizationId: 'o1',
  title: 'Worship',
  pattern: pattern,
  lookaheadCount: lookahead,
  isActive: active,
  disabledAfter: disabledAfter,
  minuteOfDay: minuteOfDay,
);

String ymd(DateTime d) => '${d.year}-${d.month}-${d.day}';

void main() {
  group('occurrenceDays', () {
    test('weekly Sundays start on the next Sunday and count lookahead', () {
      final days = schedule().occurrenceDays(DateTime(2026, 11, 11));
      expect(days, [
        DateTime(2026, 11, 15),
        DateTime(2026, 11, 22),
        DateTime(2026, 11, 29),
        DateTime(2026, 12, 6),
      ]);
    });

    test('today counts when it is the day', () {
      final days = schedule(lookahead: 2).occurrenceDays(DateTime(2026, 11, 15, 23));
      expect(days.first, DateTime(2026, 11, 15));
    });

    test('rolls over months and years', () {
      final days = schedule(lookahead: 4).occurrenceDays(DateTime(2026, 12, 20));
      expect(days, [
        DateTime(2026, 12, 20),
        DateTime(2026, 12, 27),
        DateTime(2027, 1, 3),
        DateTime(2027, 1, 10),
      ]);
    });

    test('first Sunday of the month crosses the year', () {
      final days = schedule(pattern: 'firstSundayOfMonth', lookahead: 3)
          .occurrenceDays(DateTime(2026, 11, 11));
      expect(days, [
        DateTime(2026, 12, 6),
        DateTime(2027, 1, 3),
        DateTime(2027, 2, 7),
      ]);
    });

    test('last Sunday of the month', () {
      final days = schedule(pattern: 'lastSundayOfMonth', lookahead: 3)
          .occurrenceDays(DateTime(2026, 12, 1));
      expect(days, [
        DateTime(2026, 12, 27),
        DateTime(2027, 1, 31),
        DateTime(2027, 2, 28),
      ]);
    });

    test('third Sunday is right around the daylight saving changes', () {
      // Nov 2026 (US/EU clocks change in Oct/Nov), Mar 2027 and Oct 2027.
      for (final month in [
        [2026, 10, 1],
        [2026, 11, 1],
        [2027, 3, 1],
        [2027, 10, 1],
      ]) {
        final days = schedule(pattern: 'thirdSundayOfMonth', lookahead: 1)
            .occurrenceDays(DateTime(month[0], month[1], month[2]));
        final day = days.single;
        expect(day.weekday, DateTime.sunday, reason: '$day');
        expect(day.day, inInclusiveRange(15, 21), reason: '$day');
        expect(day.hour, 0);
      }
    });

    test('weekly dates stay on Sundays across a whole year of clock changes', () {
      final days = schedule(lookahead: 60).occurrenceDays(DateTime(2026, 1, 1));
      expect(days, hasLength(60));
      for (var i = 0; i < days.length; i++) {
        expect(days[i].weekday, DateTime.sunday, reason: '${days[i]}');
        expect(days[i].hour, 0);
        if (i > 0) {
          expect(
            DateTime(days[i].year, days[i].month, days[i].day - 7),
            days[i - 1],
          );
        }
      }
    });

    test('a paused schedule projects nothing', () {
      expect(schedule(active: false).occurrenceDays(DateTime(2026, 11, 11)), isEmpty);
    });

    test('zero lookahead projects nothing', () {
      expect(schedule(lookahead: 0).occurrenceDays(DateTime(2026, 11, 11)), isEmpty);
    });

    test('stops on the local day of disabledAfter', () {
      final days = schedule(
        lookahead: 6,
        disabledAfter: DateTime(2026, 11, 22, 12).toUtc(),
      ).occurrenceDays(DateTime(2026, 11, 11));
      expect(days, [DateTime(2026, 11, 15)]);
    });

    test('startOn applies the time of day', () {
      final start = schedule(minuteOfDay: 10 * 60 + 30).startOn(DateTime(2026, 11, 15));
      expect(start, DateTime(2026, 11, 15, 10, 30));
    });
  });

  group('buildServiceEvents', () {
    final now = DateTime(2026, 11, 11, 10);

    CalendarEvent event({
      String id = 'e1',
      DateTime? at,
      String? seriesId,
      DateTime? occurrence,
    }) => CalendarEvent(
      id: id,
      organizationId: 'o1',
      title: 'Event $id',
      dateTime: (at ?? DateTime(2026, 11, 13, 19)).toUtc(),
      seriesId: seriesId,
      occurrenceDate: occurrence,
    );

    test('merges real events and projections in date order', () {
      final result = buildServiceEvents(
        now: now,
        events: [event()],
        schedules: [schedule(lookahead: 2)],
        assignments: const [],
        absences: const [],
      );
      expect(result.map((e) => e.isProjected), [false, true, true]);
      expect(result.map((e) => ymd(e.dateTime)), ['2026-11-13', '2026-11-15', '2026-11-22']);
      expect(result[1].id, 'projected_s1_2026-11-15');
      expect(result[1].seriesId, 's1');
    });

    test('leaves out past events but keeps today', () {
      final result = buildServiceEvents(
        now: now,
        events: [
          event(id: 'old', at: DateTime(2026, 11, 10, 19)),
          event(id: 'today', at: DateTime(2026, 11, 11, 7)),
        ],
        schedules: const [],
        assignments: const [],
        absences: const [],
      );
      expect(result.map((e) => e.id), ['today']);
    });

    test('a materialized occurrence replaces its projection, once', () {
      final result = buildServiceEvents(
        now: now,
        events: [
          event(
            id: 'real',
            at: DateTime(2026, 11, 15, 9),
            seriesId: 's1',
            occurrence: DateTime(2026, 11, 15),
          ),
        ],
        schedules: [schedule(lookahead: 2)],
        assignments: const [],
        absences: const [],
      );
      expect(result.map((e) => e.id), ['real', 'projected_s1_2026-11-22']);
    });

    test('an occurrence moved to another day is still not projected again', () {
      final result = buildServiceEvents(
        now: now,
        events: [
          event(
            id: 'moved',
            at: DateTime(2026, 11, 16, 20),
            seriesId: 's1',
            occurrence: DateTime(2026, 11, 15),
          ),
        ],
        schedules: [schedule(lookahead: 1)],
        assignments: const [],
        absences: const [],
      );
      expect(result.map((e) => e.id), ['moved']);
    });

    test('a stopped or paused schedule keeps its materialized events', () {
      final materialized = event(
        id: 'real',
        at: DateTime(2026, 11, 22, 9),
        seriesId: 's1',
        occurrence: DateTime(2026, 11, 22),
      );
      for (final s in [
        schedule(active: false),
        schedule(disabledAfter: DateTime(2026, 11, 12)),
      ]) {
        final result = buildServiceEvents(
          now: now,
          events: [materialized],
          schedules: [s],
          assignments: const [],
          absences: const [],
        );
        expect(result.map((e) => e.id), ['real']);
      }
    });

    test('a deleted schedule keeps its events as one-offs', () {
      final result = buildServiceEvents(
        now: now,
        events: [event(id: 'real', at: DateTime(2026, 11, 22, 9), occurrence: DateTime(2026, 11, 22))],
        schedules: const [],
        assignments: const [],
        absences: const [],
      );
      expect(result.single.recurrence, EventRecurrence.none);
    });

    test('maps assignment answers and away days', () {
      EventAssignment a(String id, String member, AssignmentResponse r) =>
          EventAssignment(
            id: id,
            organizationId: 'o1',
            eventId: 'e1',
            instrument: 'bass',
            memberId: member,
            response: r,
          );
      final result = buildServiceEvents(
        now: now,
        events: [event()],
        schedules: const [],
        assignments: [
          a('pending', 'm1', AssignmentResponse.pending),
          a('accepted', 'm2', AssignmentResponse.accepted),
          a('declined', 'm3', AssignmentResponse.declined),
          a('away', 'm4', AssignmentResponse.accepted),
          a('declined-away', 'm5', AssignmentResponse.declined),
          const EventAssignment(
            id: 'left',
            organizationId: 'o1',
            eventId: 'e1',
            instrument: 'bass',
          ),
        ],
        absences: [
          for (final m in ['m4', 'm5'])
            MemberAbsence(
              id: 'ab-$m',
              organizationId: 'o1',
              memberId: m,
              startsOn: DateTime(2026, 11, 12),
              endsOn: DateTime(2026, 11, 13),
            ),
        ],
      );
      final byId = {for (final a in result.single.assignments) a.id: a.status};
      expect(byId, {
        'pending': AssignmentStatus.scheduled,
        'accepted': AssignmentStatus.confirmed,
        'declined': AssignmentStatus.declined,
        'away': AssignmentStatus.away,
        'declined-away': AssignmentStatus.declined,
      });
    });

    test('an absence ending the day before does not cover the event', () {
      final result = buildServiceEvents(
        now: now,
        events: [event()],
        schedules: const [],
        assignments: [
          const EventAssignment(
            id: 'a',
            organizationId: 'o1',
            eventId: 'e1',
            instrument: 'bass',
            memberId: 'm1',
          ),
        ],
        absences: [
          MemberAbsence(
            id: 'ab',
            organizationId: 'o1',
            memberId: 'm1',
            startsOn: DateTime(2026, 12, 30),
            endsOn: DateTime(2027, 1, 12),
          ),
        ],
      );
      expect(result.single.assignments.single.status, AssignmentStatus.scheduled);
    });
  });
}
