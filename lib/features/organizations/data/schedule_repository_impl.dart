/// Cache-first implementation of [ScheduleRepository].
library;

import 'dart:async';

import 'package:battuta/features/organizations/data/cached_repository_support.dart';
import 'package:battuta/features/organizations/data/organizations_local_cache.dart';
import 'package:battuta/features/organizations/data/schedules_remote_data_source.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/organizations/domain/repositories/account_session.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repository.dart';
import 'package:battuta/features/organizations/domain/repositories/schedule_repository.dart';
import 'package:fpdart/fpdart.dart' hide Band;

class ScheduleRepositoryImpl
    with CachedRepositorySupport
    implements ScheduleRepository {
  ScheduleRepositoryImpl({
    required this.remote,
    required this.cache,
    required this.session,
  });

  final SchedulesRemoteDataSource remote;
  @override
  final OrganizationsLocalCache cache;
  @override
  final AccountSession session;

  Future<void> _put(
    String accountId,
    String kind,
    String id,
    Map<String, dynamic> json,
    String organizationId,
  ) => cache.upsert(accountId, kind, id, json, scopeId: organizationId);

  Future<void> _refreshQuietly(String organizationId) async {
    await refreshOrganization(organizationId);
  }

  @override
  Stream<List<CalendarEvent>> watchEvents(String organizationId) =>
      watchCached<CalendarEvent>(
        CacheKind.event,
        CalendarEvent.fromJson,
        scopeId: organizationId,
        refresh: () => _refreshQuietly(organizationId),
        sort: (a, b) => a.dateTime.compareTo(b.dateTime),
      );

  @override
  Stream<List<RecurringSchedule>> watchSchedules(String organizationId) =>
      watchCached<RecurringSchedule>(
        CacheKind.schedule,
        RecurringSchedule.fromJson,
        scopeId: organizationId,
        sort: (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );

  @override
  Stream<List<EventAssignment>> watchAssignments(String organizationId) =>
      watchCached<EventAssignment>(
        CacheKind.assignment,
        EventAssignment.fromJson,
        scopeId: organizationId,
      );

  @override
  Stream<List<MemberAbsence>> watchAbsences(String organizationId) =>
      watchCached<MemberAbsence>(
        CacheKind.absence,
        MemberAbsence.fromJson,
        scopeId: organizationId,
        sort: (a, b) => a.startsOn.compareTo(b.startsOn),
      );

  @override
  Future<Result<Unit>> refreshOrganization(String organizationId) =>
      guard((accountId) async {
        final events = await remote.fetchEvents(organizationId);
        final schedules = await remote.fetchSchedules(organizationId);
        final assignments = await remote.fetchAssignments(organizationId);
        final absences = await remote.fetchAbsences(organizationId);
        Future<void> replace(String kind, Iterable<CacheRow> rows) =>
            cache.replaceAll(accountId, kind, rows, scopeId: organizationId);
        await replace(
          CacheKind.event,
          events.map((e) => (id: e.id, json: e.toJson())),
        );
        await replace(
          CacheKind.schedule,
          schedules.map((e) => (id: e.id, json: e.toJson())),
        );
        await replace(
          CacheKind.assignment,
          assignments.map((e) => (id: e.id, json: e.toJson())),
        );
        await replace(
          CacheKind.absence,
          absences.map((e) => (id: e.id, json: e.toJson())),
        );
        return unit;
      });

  // ---- Events --------------------------------------------------------------

  @override
  Future<Result<CalendarEvent>> saveEvent(CalendarEvent event) =>
      guardWrite(event.organizationId, (accountId) async {
        final saved = await remote.upsertEvent(event);
        await _put(
          accountId,
          CacheKind.event,
          saved.id,
          saved.toJson(),
          saved.organizationId,
        );
        return saved;
      });

  @override
  Future<Result<Unit>> deleteEvent(String organizationId, String eventId) =>
      guardWrite(organizationId, (accountId) async {
        await remote.deleteEvent(eventId);
        await cache.remove(accountId, CacheKind.event, eventId);
        // Assignments are deleted with their event.
        final assignments = await cache.read(
          accountId,
          CacheKind.assignment,
          EventAssignment.fromJson,
          scopeId: organizationId,
        );
        for (final a in assignments.where((a) => a.eventId == eventId)) {
          await cache.remove(accountId, CacheKind.assignment, a.id);
        }
        return unit;
      });

  // ---- Recurring schedules -------------------------------------------------

  @override
  Future<Result<RecurringSchedule>> saveSchedule(RecurringSchedule schedule) =>
      guardWrite(schedule.organizationId, (accountId) async {
        final saved = await remote.upsertSchedule(schedule);
        await _put(
          accountId,
          CacheKind.schedule,
          saved.id,
          saved.toJson(),
          saved.organizationId,
        );
        return saved;
      });

  @override
  Future<Result<Unit>> deleteSchedule(
    String organizationId,
    String scheduleId,
  ) => guardWrite(organizationId, (accountId) async {
    await remote.deleteSchedule(scheduleId);
    await cache.remove(accountId, CacheKind.schedule, scheduleId);
    return unit;
  });

  // ---- Assignments ---------------------------------------------------------

  @override
  Future<Result<EventAssignment>> assign({
    required String organizationId,
    required String eventId,
    required String memberId,
    required String instrument,
  }) => guardWrite(organizationId, (accountId) async {
    final saved = await remote.assign(
      organizationId: organizationId,
      eventId: eventId,
      memberId: memberId,
      instrument: instrument,
    );
    await _put(
      accountId,
      CacheKind.assignment,
      saved.id,
      saved.toJson(),
      organizationId,
    );
    return saved;
  });

  @override
  Future<Result<EventAssignment>> reassign(
    String organizationId,
    String assignmentId, {
    String? memberId,
    String? instrument,
  }) => guardWrite(organizationId, (accountId) async {
    final saved = await remote.reassign(
      assignmentId,
      memberId: memberId,
      instrument: instrument,
    );
    await _put(
      accountId,
      CacheKind.assignment,
      saved.id,
      saved.toJson(),
      organizationId,
    );
    return saved;
  });

  @override
  Future<Result<Unit>> unassign(String organizationId, String assignmentId) =>
      guardWrite(organizationId, (accountId) async {
        await remote.unassign(assignmentId);
        await cache.remove(accountId, CacheKind.assignment, assignmentId);
        return unit;
      });

  @override
  Future<Result<EventAssignment>> respond(
    String organizationId,
    String assignmentId,
    AssignmentResponse response, {
    String? declineReason,
  }) => guardWrite(organizationId, (accountId) async {
    final saved = await remote.respond(
      assignmentId,
      response,
      declineReason: declineReason,
    );
    await _put(
      accountId,
      CacheKind.assignment,
      saved.id,
      saved.toJson(),
      organizationId,
    );
    return saved;
  });

  // ---- Absences ------------------------------------------------------------

  @override
  Future<Result<MemberAbsence>> saveAbsence(MemberAbsence absence) =>
      guardWrite(absence.organizationId, (accountId) async {
        final saved = await remote.upsertAbsence(absence);
        await _put(
          accountId,
          CacheKind.absence,
          saved.id,
          saved.toJson(),
          saved.organizationId,
        );
        return saved;
      });

  @override
  Future<Result<Unit>> deleteAbsence(String organizationId, String absenceId) =>
      guardWrite(organizationId, (accountId) async {
        await remote.deleteAbsence(absenceId);
        await cache.remove(accountId, CacheKind.absence, absenceId);
        return unit;
      });

  @override
  Future<Result<List<AvailableMember>>> membersAvailableOn(
    String organizationId,
    DateTime day,
  ) => guard((_) => remote.membersAvailableOn(organizationId, day));
}
