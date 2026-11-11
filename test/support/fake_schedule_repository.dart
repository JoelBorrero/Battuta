import 'dart:async';

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repository.dart';
import 'package:battuta/features/organizations/domain/repositories/schedule_repository.dart';
import 'package:flutter_test/flutter_test.dart' show Fake;
import 'package:fpdart/fpdart.dart' hide Band;

/// In-memory [ScheduleRepository] for widget and provider tests. Behaves like
/// the server for the rules the calendar relies on: an occurrence
/// (`series_id` + `occurrence_date`) can exist once (`conflict`), and
/// `membersAvailableOn` leaves out members who are away that day.
class FakeScheduleRepository extends Fake implements ScheduleRepository {
  FakeScheduleRepository({
    List<CalendarEvent> events = const [],
    List<RecurringSchedule> schedules = const [],
    List<EventAssignment> assignments = const [],
    List<MemberAbsence> absences = const [],
    this.memberIds = const [],
  }) : _events = [...events],
       _schedules = [...schedules],
       _assignments = [...assignments],
       _absences = [...absences];

  final List<CalendarEvent> _events;
  final List<RecurringSchedule> _schedules;
  final List<EventAssignment> _assignments;
  final List<MemberAbsence> _absences;
  final _changes = StreamController<void>.broadcast(sync: true);

  /// Member ids `membersAvailableOn` chooses from.
  List<String> memberIds;

  /// Names of the writes made, in order.
  final List<String> calls = [];

  /// When set, the next write returns this failure (then it is cleared).
  Failure? nextFailure;

  /// Runs once before the next `saveEvent` (to simulate another admin).
  void Function()? beforeNextSaveEvent;

  List<CalendarEvent> get events => List.unmodifiable(_events);
  List<RecurringSchedule> get schedules => List.unmodifiable(_schedules);
  List<EventAssignment> get assignments => List.unmodifiable(_assignments);
  List<MemberAbsence> get absences => List.unmodifiable(_absences);

  int _ids = 0;

  void _notify() => _changes.add(null);

  /// Replaces the assignments (as a realtime update would).
  void setAssignments(List<EventAssignment> assignments) {
    _assignments
      ..clear()
      ..addAll(assignments);
    _notify();
  }

  void addEvent(CalendarEvent event) {
    _events.add(event);
    _notify();
  }

  Stream<List<T>> _watch<T>(List<T> Function() read) {
    late StreamController<List<T>> controller;
    StreamSubscription<void>? sub;
    controller = StreamController<List<T>>(
      onListen: () {
        controller.add(read());
        sub = _changes.stream.listen((_) => controller.add(read()));
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  Either<Failure, T>? _failed<T>() {
    final failure = nextFailure;
    if (failure == null) return null;
    nextFailure = null;
    return left(failure);
  }

  @override
  Stream<List<CalendarEvent>> watchEvents(String organizationId) => _watch(
    () => [
      for (final e in _events)
        if (e.organizationId == organizationId) e,
    ],
  );

  @override
  Stream<List<RecurringSchedule>> watchSchedules(String organizationId) =>
      _watch(
        () => [
          for (final s in _schedules)
            if (s.organizationId == organizationId) s,
        ],
      );

  @override
  Stream<List<EventAssignment>> watchAssignments(String organizationId) =>
      _watch(
        () => [
          for (final a in _assignments)
            if (a.organizationId == organizationId) a,
        ],
      );

  @override
  Stream<List<MemberAbsence>> watchAbsences(String organizationId) => _watch(
    () => [
      for (final a in _absences)
        if (a.organizationId == organizationId) a,
    ],
  );

  @override
  Future<Result<Unit>> refreshOrganization(String organizationId) async {
    calls.add('refresh');
    return right(unit);
  }

  @override
  Future<Result<CalendarEvent>> saveEvent(CalendarEvent event) async {
    calls.add('saveEvent:${event.title}');
    final hook = beforeNextSaveEvent;
    beforeNextSaveEvent = null;
    hook?.call();
    if (_failed<CalendarEvent>() case final f?) return f;
    final clash = _events.any(
      (e) =>
          e.id != event.id &&
          event.seriesId != null &&
          e.seriesId == event.seriesId &&
          e.occurrenceDate == event.occurrenceDate,
    );
    if (clash) {
      return left(
        BackendErrorCode.conflict.failure(message: 'duplicate key value'),
      );
    }
    _events
      ..removeWhere((e) => e.id == event.id)
      ..add(event);
    _notify();
    return right(event);
  }

  @override
  Future<Result<Unit>> deleteEvent(String organizationId, String eventId) async {
    calls.add('deleteEvent:$eventId');
    if (_failed<Unit>() case final f?) return f;
    _events.removeWhere((e) => e.id == eventId);
    _assignments.removeWhere((a) => a.eventId == eventId);
    _notify();
    return right(unit);
  }

  @override
  Future<Result<RecurringSchedule>> saveSchedule(
    RecurringSchedule schedule,
  ) async {
    calls.add('saveSchedule:${schedule.title}');
    if (_failed<RecurringSchedule>() case final f?) return f;
    _schedules
      ..removeWhere((s) => s.id == schedule.id)
      ..add(schedule);
    _notify();
    return right(schedule);
  }

  @override
  Future<Result<Unit>> deleteSchedule(
    String organizationId,
    String scheduleId,
  ) async {
    calls.add('deleteSchedule:$scheduleId');
    if (_failed<Unit>() case final f?) return f;
    _schedules.removeWhere((s) => s.id == scheduleId);
    _notify();
    return right(unit);
  }

  @override
  Future<Result<EventAssignment>> assign({
    required String organizationId,
    required String eventId,
    required String memberId,
    required String instrument,
  }) async {
    calls.add('assign:$eventId:$memberId:$instrument');
    if (_failed<EventAssignment>() case final f?) return f;
    final created = EventAssignment(
      id: 'a-new-${_ids++}',
      organizationId: organizationId,
      eventId: eventId,
      instrument: instrument,
      memberId: memberId,
    );
    _assignments.add(created);
    _notify();
    return right(created);
  }

  @override
  Future<Result<EventAssignment>> reassign(
    String organizationId,
    String assignmentId, {
    String? memberId,
    String? instrument,
  }) async {
    calls.add('reassign:$assignmentId:$memberId');
    if (_failed<EventAssignment>() case final f?) return f;
    final index = _assignments.indexWhere((a) => a.id == assignmentId);
    final old = _assignments[index];
    // The server resets the answer when the slot changes hands.
    final updated = EventAssignment(
      id: old.id,
      organizationId: old.organizationId,
      eventId: old.eventId,
      instrument: instrument ?? old.instrument,
      memberId: memberId ?? old.memberId,
    );
    _assignments[index] = updated;
    _notify();
    return right(updated);
  }

  @override
  Future<Result<Unit>> unassign(
    String organizationId,
    String assignmentId,
  ) async {
    calls.add('unassign:$assignmentId');
    if (_failed<Unit>() case final f?) return f;
    _assignments.removeWhere((a) => a.id == assignmentId);
    _notify();
    return right(unit);
  }

  @override
  Future<Result<EventAssignment>> respond(
    String organizationId,
    String assignmentId,
    AssignmentResponse response, {
    String? declineReason,
  }) async {
    calls.add('respond:$assignmentId:${response.name}:$declineReason');
    if (_failed<EventAssignment>() case final f?) return f;
    final index = _assignments.indexWhere((a) => a.id == assignmentId);
    final old = _assignments[index];
    final updated = EventAssignment(
      id: old.id,
      organizationId: old.organizationId,
      eventId: old.eventId,
      instrument: old.instrument,
      memberId: old.memberId,
      response: response,
      declineReason: declineReason,
    );
    _assignments[index] = updated;
    _notify();
    return right(updated);
  }

  @override
  Future<Result<MemberAbsence>> saveAbsence(MemberAbsence absence) async {
    calls.add('saveAbsence:${absence.id}');
    if (_failed<MemberAbsence>() case final f?) return f;
    _absences
      ..removeWhere((a) => a.id == absence.id)
      ..add(absence);
    _notify();
    return right(absence);
  }

  @override
  Future<Result<Unit>> deleteAbsence(
    String organizationId,
    String absenceId,
  ) async {
    calls.add('deleteAbsence:$absenceId');
    if (_failed<Unit>() case final f?) return f;
    _absences.removeWhere((a) => a.id == absenceId);
    _notify();
    return right(unit);
  }

  @override
  Future<Result<List<AvailableMember>>> membersAvailableOn(
    String organizationId,
    DateTime day,
  ) async {
    calls.add('availableOn');
    if (_failed<List<AvailableMember>>() case final f?) return f;
    return right([
      for (final id in memberIds)
        if (!_absences.any((a) => a.memberId == id && a.covers(day)))
          AvailableMember(
            memberId: id,
            userId: 'u-$id',
            username: id,
            displayName: id,
          ),
    ]);
  }
}
