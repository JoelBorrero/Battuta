/// Events, recurring schedules, assignments and absences of an organization.
///
/// Same contract as `OrganizationRepository`: cache-first reads, writes need
/// a connection (`BackendErrorCode.offline` otherwise), archived organizations
/// are read-only (`BackendErrorCode.organizationArchived`).
library;

import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repository.dart';
import 'package:fpdart/fpdart.dart' hide Band;

abstract interface class ScheduleRepository {
  Stream<List<CalendarEvent>> watchEvents(String organizationId);
  Stream<List<RecurringSchedule>> watchSchedules(String organizationId);
  Stream<List<EventAssignment>> watchAssignments(String organizationId);
  Stream<List<MemberAbsence>> watchAbsences(String organizationId);

  /// Refreshes events, schedules, assignments and absences.
  Future<Result<Unit>> refreshOrganization(String organizationId);

  Future<Result<CalendarEvent>> saveEvent(CalendarEvent event);
  Future<Result<Unit>> deleteEvent(String organizationId, String eventId);

  Future<Result<RecurringSchedule>> saveSchedule(RecurringSchedule schedule);
  Future<Result<Unit>> deleteSchedule(String organizationId, String scheduleId);

  Future<Result<EventAssignment>> assign({
    required String organizationId,
    required String eventId,
    required String memberId,
    required String instrument,
  });
  Future<Result<EventAssignment>> reassign(
    String organizationId,
    String assignmentId, {
    String? memberId,
    String? instrument,
  });
  Future<Result<Unit>> unassign(String organizationId, String assignmentId);

  /// Answers an assignment as the assigned member.
  Future<Result<EventAssignment>> respond(
    String organizationId,
    String assignmentId,
    AssignmentResponse response, {
    String? declineReason,
  });

  Future<Result<MemberAbsence>> saveAbsence(MemberAbsence absence);
  Future<Result<Unit>> deleteAbsence(String organizationId, String absenceId);
  Future<Result<List<AvailableMember>>> membersAvailableOn(
    String organizationId,
    DateTime day,
  );
}
