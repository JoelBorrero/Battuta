/// Pure logic of the Calendar tab: projects the occurrences of recurring
/// schedules and merges them with the real events, assignments and absences
/// of an organization into the [ServiceEvent] view models.
library;

import 'package:battuta/features/organizations/domain/entities/json_helpers.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';

DateTime _dayOf(DateTime value) => DateTime(value.year, value.month, value.day);

/// How a recurring schedule is shown.
extension RecurringScheduleProjection on RecurringSchedule {
  EventRecurrence get recurrence => EventRecurrence.parse(pattern);
  ServiceType get serviceType => ServiceType.parse(eventType);

  /// The local dates (date-only) the schedule produces from [from] on:
  /// `lookaheadCount` of them, none when paused, and none on or after the
  /// local day of [disabledAfter].
  List<DateTime> occurrenceDays(DateTime from) {
    if (!isActive || lookaheadCount <= 0) return const [];
    final anchor = DateTime(
      from.year,
      from.month,
      from.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    final cutoff = disabledAfter == null
        ? null
        : _dayOf(disabledAfter!.toLocal());
    return [
      for (final date in recurrence.generateOccurrences(
        fromDateTime: anchor,
        count: lookaheadCount,
      ))
        if (cutoff == null || _dayOf(date).isBefore(cutoff)) _dayOf(date),
    ];
  }

  /// The local start of the occurrence on [day].
  DateTime startOn(DateTime day) => DateTime(
    day.year,
    day.month,
    day.day,
    minuteOfDay ~/ 60,
    minuteOfDay % 60,
  );
}

/// The synthetic id of the occurrence of [seriesId] on [day].
String projectedEventId(String seriesId, DateTime day) =>
    'projected_${seriesId}_${formatDateOnly(day)}';

/// The status the calendar shows for [assignment] on [day]: what the member
/// answered, or away when they have an absence that day (a decline stays).
AssignmentStatus assignmentStatus(
  EventAssignment assignment,
  DateTime day,
  Iterable<MemberAbsence> absences,
) {
  if (assignment.response == AssignmentResponse.declined) {
    return AssignmentStatus.declined;
  }
  final memberId = assignment.memberId;
  if (memberId != null &&
      absences.any((a) => a.memberId == memberId && a.covers(day))) {
    return AssignmentStatus.away;
  }
  return switch (assignment.response) {
    AssignmentResponse.accepted => AssignmentStatus.confirmed,
    _ => AssignmentStatus.scheduled,
  };
}

/// Today's and later services of an organization, sorted by date.
///
/// * Every real event of today or later is listed (also the occurrences of
///   stopped or paused schedules that were already materialized).
/// * Each active schedule adds its projected occurrences that are not a real
///   event yet (matched by schedule and occurrence day).
/// * Assignments of members who left (no member id) are left out.
List<ServiceEvent> buildServiceEvents({
  required DateTime now,
  required List<CalendarEvent> events,
  required List<RecurringSchedule> schedules,
  required List<EventAssignment> assignments,
  required List<MemberAbsence> absences,
}) {
  final today = _dayOf(now);
  final schedulesById = {for (final s in schedules) s.id: s};
  final assignmentsByEvent = <String, List<EventAssignment>>{};
  for (final assignment in assignments) {
    assignmentsByEvent
        .putIfAbsent(assignment.eventId, () => [])
        .add(assignment);
  }

  final result = <ServiceEvent>[];
  final materialized = <String>{};
  for (final event in events) {
    final seriesId = event.seriesId;
    final occurrence = event.occurrenceDate;
    if (seriesId != null && occurrence != null) {
      materialized.add('$seriesId|${formatDateOnly(occurrence)}');
    }
    final local = event.dateTime.toLocal();
    if (_dayOf(local).isBefore(today)) continue;
    final schedule = seriesId == null ? null : schedulesById[seriesId];
    result.add(
      ServiceEvent(
        id: event.id,
        title: event.title,
        dateTime: local,
        type: ServiceType.parse(event.eventType),
        recurrence: schedule?.recurrence ?? EventRecurrence.none,
        location: event.location,
        notes: event.notes,
        setlistId: event.setlistId,
        seriesId: seriesId,
        occurrenceDate: occurrence,
        bandId: event.bandId,
        assignments: [
          for (final a in assignmentsByEvent[event.id] ?? const [])
            if (a.memberId != null)
              ServiceAssignment(
                id: a.id,
                memberId: a.memberId!,
                instrument: a.instrument,
                status: assignmentStatus(a, _dayOf(local), absences),
                declineReason: a.declineReason,
              ),
        ],
      ),
    );
  }

  for (final schedule in schedules) {
    for (final day in schedule.occurrenceDays(today)) {
      if (materialized.contains('${schedule.id}|${formatDateOnly(day)}')) {
        continue;
      }
      result.add(
        ServiceEvent(
          id: projectedEventId(schedule.id, day),
          title: schedule.title,
          dateTime: schedule.startOn(day),
          type: schedule.serviceType,
          recurrence: schedule.recurrence,
          location: schedule.location,
          seriesId: schedule.id,
          occurrenceDate: day,
          bandId: schedule.bandId,
          isProjected: true,
        ),
      );
    }
  }

  result.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  return result;
}
