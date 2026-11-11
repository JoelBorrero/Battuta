/// Thin Supabase calls for events, recurring schedules, assignments and
/// absences. Columns follow `supabase/README.md`.
library;

import 'package:battuta/features/organizations/data/backend_gateway.dart';
import 'package:battuta/features/organizations/domain/entities/json_helpers.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';

abstract interface class SchedulesRemoteDataSource {
  Future<List<CalendarEvent>> fetchEvents(String organizationId);
  Future<CalendarEvent> upsertEvent(CalendarEvent event);
  Future<void> deleteEvent(String eventId);

  Future<List<RecurringSchedule>> fetchSchedules(String organizationId);
  Future<RecurringSchedule> upsertSchedule(RecurringSchedule schedule);
  Future<void> deleteSchedule(String scheduleId);

  Future<List<EventAssignment>> fetchAssignments(String organizationId);
  Future<EventAssignment> assign({
    required String organizationId,
    required String eventId,
    required String memberId,
    required String instrument,
  });
  Future<EventAssignment> reassign(
    String assignmentId, {
    String? memberId,
    String? instrument,
  });
  Future<void> unassign(String assignmentId);
  Future<EventAssignment> respond(
    String assignmentId,
    AssignmentResponse response, {
    String? declineReason,
  });

  Future<List<MemberAbsence>> fetchAbsences(String organizationId);
  Future<MemberAbsence> upsertAbsence(MemberAbsence absence);
  Future<void> deleteAbsence(String absenceId);
  Future<List<AvailableMember>> membersAvailableOn(
    String organizationId,
    DateTime day,
  );
}

class SupabaseSchedulesRemoteDataSource extends SupabaseGateway
    implements SchedulesRemoteDataSource {
  SupabaseSchedulesRemoteDataSource(super.clientProvider);

  static List<Map<String, dynamic>> _rows(Object? data) =>
      (data as List).cast<Map<String, dynamic>>();

  @override
  Future<List<CalendarEvent>> fetchEvents(String organizationId) =>
      run((c, _) async {
        final data = await c
            .from('calendar_events')
            .select()
            .eq('organization_id', organizationId)
            .order('date_time');
        return _rows(data).map(CalendarEvent.fromJson).toList();
      });

  @override
  Future<CalendarEvent> upsertEvent(CalendarEvent event) => run((c, uid) async {
    final data = await c
        .from('calendar_events')
        .upsert({...event.toWriteJson(), 'created_by': event.createdBy ?? uid})
        .select()
        .single();
    return CalendarEvent.fromJson(data);
  });

  @override
  Future<void> deleteEvent(String eventId) => run((c, _) async {
    await c.from('calendar_events').delete().eq('id', eventId);
  });

  @override
  Future<List<RecurringSchedule>> fetchSchedules(String organizationId) =>
      run((c, _) async {
        final data = await c
            .from('recurring_schedules')
            .select()
            .eq('organization_id', organizationId);
        return _rows(data).map(RecurringSchedule.fromJson).toList();
      });

  @override
  Future<RecurringSchedule> upsertSchedule(RecurringSchedule schedule) =>
      run((c, uid) async {
        final data = await c
            .from('recurring_schedules')
            .upsert({
              ...schedule.toWriteJson(),
              'created_by': schedule.createdBy ?? uid,
            })
            .select()
            .single();
        return RecurringSchedule.fromJson(data);
      });

  @override
  Future<void> deleteSchedule(String scheduleId) => run((c, _) async {
    await c.from('recurring_schedules').delete().eq('id', scheduleId);
  });

  @override
  Future<List<EventAssignment>> fetchAssignments(String organizationId) =>
      run((c, _) async {
        final data = await c
            .from('event_assignments')
            .select()
            .eq('organization_id', organizationId);
        return _rows(data).map(EventAssignment.fromJson).toList();
      });

  @override
  Future<EventAssignment> assign({
    required String organizationId,
    required String eventId,
    required String memberId,
    required String instrument,
  }) => run((c, _) async {
    final data = await c
        .from('event_assignments')
        .insert({
          'id': newEntityId(),
          'organization_id': organizationId,
          'event_id': eventId,
          'member_id': memberId,
          'instrument': instrument,
        })
        .select()
        .single();
    return EventAssignment.fromJson(data);
  });

  @override
  Future<EventAssignment> reassign(
    String assignmentId, {
    String? memberId,
    String? instrument,
  }) => run((c, _) async {
    final data = await c
        .from('event_assignments')
        .update({'member_id': ?memberId, 'instrument': ?instrument})
        .eq('id', assignmentId)
        .select()
        .single();
    return EventAssignment.fromJson(data);
  });

  @override
  Future<void> unassign(String assignmentId) => run((c, _) async {
    await c.from('event_assignments').delete().eq('id', assignmentId);
  });

  @override
  Future<EventAssignment> respond(
    String assignmentId,
    AssignmentResponse response, {
    String? declineReason,
  }) => run((c, _) async {
    final data = await c
        .from('event_assignments')
        .update({
          'response': response.name,
          'decline_reason': response == AssignmentResponse.declined
              ? declineReason
              : null,
        })
        .eq('id', assignmentId)
        .select()
        .single();
    return EventAssignment.fromJson(data);
  });

  @override
  Future<List<MemberAbsence>> fetchAbsences(String organizationId) =>
      run((c, _) async {
        final data = await c
            .from('member_absences')
            .select()
            .eq('organization_id', organizationId)
            .order('starts_on');
        return _rows(data).map(MemberAbsence.fromJson).toList();
      });

  @override
  Future<MemberAbsence> upsertAbsence(MemberAbsence absence) =>
      run((c, _) async {
        final data = await c
            .from('member_absences')
            .upsert(absence.toWriteJson())
            .select()
            .single();
        return MemberAbsence.fromJson(data);
      });

  @override
  Future<void> deleteAbsence(String absenceId) => run((c, _) async {
    await c.from('member_absences').delete().eq('id', absenceId);
  });

  @override
  Future<List<AvailableMember>> membersAvailableOn(
    String organizationId,
    DateTime day,
  ) => run((c, _) async {
    final data = await c.rpc(
      'members_available_on',
      params: {'p_org': organizationId, 'p_date': formatDateOnly(day)},
    );
    return _rows(data).map(AvailableMember.fromJson).toList();
  });
}
