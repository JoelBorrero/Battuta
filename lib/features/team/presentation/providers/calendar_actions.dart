/// Battuta — Calendar writes.
///
/// Every write goes through the `ScheduleRepository`; nothing is applied
/// optimistically, and each method returns the first failure.
library;

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/organizations/domain/repositories/schedule_repository.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide Band;

/// The fields of a service the event dialog edits.
class EventDraft {
  const EventDraft({
    required this.title,
    required this.dateTime,
    required this.type,
    this.location,
    this.notes,
    this.setlistId,
  });

  final String title;

  /// Local date and time.
  final DateTime dateTime;
  final ServiceType type;
  final String? location;
  final String? notes;
  final String? setlistId;
}

/// The fields of a recurring schedule the schedule dialog edits.
class ScheduleDraft {
  const ScheduleDraft({
    required this.title,
    required this.recurrence,
    required this.minuteOfDay,
    required this.type,
    required this.lookaheadCount,
    this.location,
  });

  final String title;
  final EventRecurrence recurrence;
  final int minuteOfDay;
  final ServiceType type;
  final int lookaheadCount;
  final String? location;
}

String? _blankToNull(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}

/// 1 = Monday ... 7 = Sunday, the weekday of the schedule's cadence.
int _dayOfWeekOf(EventRecurrence recurrence) =>
    recurrence == EventRecurrence.weeklyThursday
    ? DateTime.thursday
    : DateTime.sunday;

class CalendarActions {
  const CalendarActions(this._ref);

  final Ref _ref;

  String? get _organizationId => _ref.read(activeOrganizationIdProvider);
  ScheduleRepository get _repository => _ref.read(scheduleRepositoryProvider);

  Either<Failure, T> _noOrganization<T>() =>
      left(const ValidationFailure(message: 'No active organization.'));

  Either<Failure, T> _missing<T>() =>
      left(const ValidationFailure(message: 'The service no longer exists.'));

  // ---- Events --------------------------------------------------------------

  /// Creates a one-off service in the active band (or for all bands).
  Future<Either<Failure, Unit>> createEvent(EventDraft draft) async {
    final organizationId = _organizationId;
    if (organizationId == null) return _noOrganization();
    final result = await _repository.saveEvent(
      CalendarEvent(
        id: newEntityId(),
        organizationId: organizationId,
        title: draft.title.trim(),
        dateTime: draft.dateTime.toUtc(),
        bandId: _ref.read(activeBandIdProvider),
        location: _blankToNull(draft.location),
        notes: _blankToNull(draft.notes),
        eventType: draft.type.name,
        setlistId: draft.setlistId,
      ),
    );
    return result.map((_) => unit);
  }

  CalendarEvent Function(CalendarEvent) _apply(EventDraft draft) =>
      (base) => base.copyWith(
        title: draft.title.trim(),
        dateTime: draft.dateTime.toUtc(),
        eventType: draft.type.name,
        location: _blankToNull(draft.location),
        clearLocation: _blankToNull(draft.location) == null,
        notes: _blankToNull(draft.notes),
        clearNotes: _blankToNull(draft.notes) == null,
        setlistId: draft.setlistId,
        clearSetlist: draft.setlistId == null,
      );

  /// Saves [draft] over [target]. A projected occurrence becomes a real
  /// event first (once, even if another admin got there first).
  Future<Either<Failure, Unit>> updateEvent(
    ServiceEvent target,
    EventDraft draft,
  ) async {
    final apply = _apply(draft);
    if (target.isProjected) {
      return (await _materialize(target, edit: apply)).map((_) => unit);
    }
    final current = _eventById(target.id);
    if (current == null) return _missing();
    return (await _repository.saveEvent(apply(current))).map((_) => unit);
  }

  Future<Either<Failure, Unit>> deleteEvent(ServiceEvent target) async {
    final organizationId = _organizationId;
    if (organizationId == null) return _noOrganization();
    if (target.isProjected) return _missing();
    return _repository.deleteEvent(organizationId, target.id);
  }

  CalendarEvent? _eventById(String id) {
    for (final event in _ref.read(activeEventsProvider).value ?? const []) {
      if (event.id == id) return event;
    }
    return null;
  }

  RecurringSchedule? _scheduleById(String? id) {
    for (final schedule
        in _ref.read(activeSchedulesProvider).value ??
            const <RecurringSchedule>[]) {
      if (schedule.id == id) return schedule;
    }
    return null;
  }

  /// Makes the occurrence a real event, applying [edit] to it. Another admin
  /// may have materialized it meanwhile (`conflict`): reload, then apply the
  /// edit to theirs, once.
  Future<Either<Failure, CalendarEvent>> _materialize(
    ServiceEvent occurrence, {
    CalendarEvent Function(CalendarEvent)? edit,
  }) async {
    final organizationId = _organizationId;
    if (organizationId == null) return _noOrganization();
    final schedule = _scheduleById(occurrence.seriesId);
    final day = occurrence.occurrenceDate;
    if (schedule == null || day == null) return _missing();

    final base = CalendarEvent(
      id: newEntityId(),
      organizationId: organizationId,
      title: schedule.title,
      dateTime: occurrence.dateTime.toUtc(),
      bandId: schedule.bandId,
      location: schedule.location,
      eventType: schedule.eventType,
      seriesId: schedule.id,
      occurrenceDate: day,
    );
    final first = await _repository.saveEvent(edit?.call(base) ?? base);
    final failure = first.fold((f) => f, (_) => null);
    if (failure?.errorCode != BackendErrorCode.conflict) return first;

    final refreshed = await _repository.refreshOrganization(organizationId);
    if (refreshed case Left(value: final f)) return left(f);
    final events = await _repository.watchEvents(organizationId).first;
    for (final event in events) {
      if (event.seriesId == schedule.id && event.occurrenceDate == day) {
        return edit == null ? right(event) : _repository.saveEvent(edit(event));
      }
    }
    return first;
  }

  // ---- Recurring schedules -------------------------------------------------

  Future<Either<Failure, Unit>> createSchedule(ScheduleDraft draft) async {
    final organizationId = _organizationId;
    if (organizationId == null) return _noOrganization();
    final result = await _repository.saveSchedule(
      RecurringSchedule(
        id: newEntityId(),
        organizationId: organizationId,
        title: draft.title.trim(),
        bandId: _ref.read(activeBandIdProvider),
        dayOfWeek: _dayOfWeekOf(draft.recurrence),
        pattern: draft.recurrence.name,
        lookaheadCount: draft.lookaheadCount,
        minuteOfDay: draft.minuteOfDay,
        location: _blankToNull(draft.location),
        eventType: draft.type.name,
      ),
    );
    return result.map((_) => unit);
  }

  Future<Either<Failure, Unit>> updateSchedule(
    RecurringSchedule schedule,
    ScheduleDraft draft,
  ) async {
    final result = await _repository.saveSchedule(
      schedule.copyWith(
        title: draft.title.trim(),
        dayOfWeek: _dayOfWeekOf(draft.recurrence),
        pattern: draft.recurrence.name,
        lookaheadCount: draft.lookaheadCount,
        minuteOfDay: draft.minuteOfDay,
        location: _blankToNull(draft.location),
        clearLocation: _blankToNull(draft.location) == null,
        eventType: draft.type.name,
      ),
    );
    return result.map((_) => unit);
  }

  /// Pauses or resumes a schedule (a paused one projects nothing).
  Future<Either<Failure, Unit>> setScheduleActive(
    RecurringSchedule schedule, {
    required bool active,
  }) async =>
      (await _repository.saveSchedule(schedule.copyWith(isActive: active)))
          .map((_) => unit);

  /// Resumes a paused or stopped schedule.
  Future<Either<Failure, Unit>> resumeSchedule(
    RecurringSchedule schedule,
  ) async => (await _repository.saveSchedule(
    schedule.copyWith(isActive: true, clearDisabledAfter: true),
  )).map((_) => unit);

  /// Stops projecting on or after [after] (or resumes with `null`). Events
  /// that were already materialized stay.
  Future<Either<Failure, Unit>> setScheduleEnd(
    RecurringSchedule schedule,
    DateTime? after,
  ) async => (await _repository.saveSchedule(
    schedule.copyWith(
      disabledAfter: after?.toUtc(),
      clearDisabledAfter: after == null,
    ),
  )).map((_) => unit);

  Future<Either<Failure, Unit>> deleteSchedule(RecurringSchedule schedule) =>
      _repository.deleteSchedule(schedule.organizationId, schedule.id);

  // ---- Assignments ---------------------------------------------------------

  /// Puts [memberId] on [event] as [instrument]. A projected occurrence
  /// becomes a real event first.
  Future<Either<Failure, Unit>> assign(
    ServiceEvent event,
    String memberId,
    String instrument,
  ) async {
    final organizationId = _organizationId;
    if (organizationId == null) return _noOrganization();
    var eventId = event.id;
    if (event.isProjected) {
      final materialized = await _materialize(event);
      switch (materialized) {
        case Left(value: final failure):
          return left(failure);
        case Right(value: final created):
          eventId = created.id;
      }
    }
    final result = await _repository.assign(
      organizationId: organizationId,
      eventId: eventId,
      memberId: memberId,
      instrument: instrument,
    );
    return result.map((_) => unit);
  }

  Future<Either<Failure, Unit>> unassign(String assignmentId) async {
    final organizationId = _organizationId;
    if (organizationId == null) return _noOrganization();
    return _repository.unassign(organizationId, assignmentId);
  }

  /// Hands an assignment to another member.
  Future<Either<Failure, Unit>> reassign(
    String assignmentId,
    String memberId,
  ) async {
    final organizationId = _organizationId;
    if (organizationId == null) return _noOrganization();
    final result = await _repository.reassign(
      organizationId,
      assignmentId,
      memberId: memberId,
    );
    return result.map((_) => unit);
  }

  /// Members without an absence on [day].
  Future<Either<Failure, List<AvailableMember>>> availableOn(
    DateTime day,
  ) async {
    final organizationId = _organizationId;
    if (organizationId == null) return _noOrganization();
    return _repository.membersAvailableOn(organizationId, day);
  }

  // ---- Member actions ------------------------------------------------------

  Future<Either<Failure, Unit>> respond(
    String assignmentId,
    AssignmentResponse response, {
    String? declineReason,
  }) async {
    final organizationId = _organizationId;
    if (organizationId == null) return _noOrganization();
    final result = await _repository.respond(
      organizationId,
      assignmentId,
      response,
      declineReason: _blankToNull(declineReason),
    );
    return result.map((_) => unit);
  }

  /// Adds (`existing == null`) or edits one of my absences.
  Future<Either<Failure, Unit>> saveAbsence({
    MemberAbsence? existing,
    required DateTime startsOn,
    required DateTime endsOn,
    String? note,
  }) async {
    final organizationId = _organizationId;
    final me = _ref.read(currentMemberProvider);
    if (organizationId == null || me == null) return _noOrganization();
    final result = await _repository.saveAbsence(
      MemberAbsence(
        id: existing?.id ?? newEntityId(),
        organizationId: organizationId,
        memberId: me.id,
        startsOn: startsOn,
        endsOn: endsOn,
        note: _blankToNull(note),
      ),
    );
    return result.map((_) => unit);
  }

  Future<Either<Failure, Unit>> deleteAbsence(MemberAbsence absence) =>
      _repository.deleteAbsence(absence.organizationId, absence.id);
}

final calendarActionsProvider = Provider<CalendarActions>(CalendarActions.new);
