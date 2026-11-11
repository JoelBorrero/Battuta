/// Battuta — Service Calendar & Band Schedule Provider.
///
/// Manages upcoming services, band rehearsals, periodic weekly events,
/// and musician lineup assignments. Integrates single recurring schedule rules
/// to dynamically project an X-count rolling window of upcoming events while
/// respecting cutoff dates when recurring generation is disabled.
library;

import 'package:battuta/features/team/domain/entities/recurring_schedule.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/features/team/presentation/providers/recurring_schedules_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final serviceCalendarProvider =
    NotifierProvider<ServiceCalendarNotifier, List<ServiceEvent>>(
      ServiceCalendarNotifier.new,
    );

class ServiceCalendarNotifier extends Notifier<List<ServiceEvent>> {
  final List<ServiceEvent> _userEvents = [];

  @override
  List<ServiceEvent> build() {
    final schedules = ref.watch(recurringSchedulesProvider);
    return _computeProjectedEvents(_userEvents, schedules);
  }

  void _syncState() {
    final schedules = ref.read(recurringSchedulesProvider);
    state = _computeProjectedEvents(_userEvents, schedules);
  }

  /// Adds a new calendar service or rehearsal event.
  void addEvent(ServiceEvent event) {
    _userEvents.add(event);
    _syncState();
  }

  /// Updates an existing service event.
  void updateEvent(ServiceEvent updated) {
    final idx = _userEvents.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _userEvents[idx] = updated;
    }
    _syncState();
  }

  /// Deletes a service event by id.
  void deleteEvent(String id) {
    _userEvents.removeWhere((e) => e.id == id);
    _syncState();
  }

  /// Ensures an event exists in `_userEvents` before mutating its assignments.
  void _materializeEventIfNeeded(String eventId) {
    final exists = _userEvents.any((e) => e.id == eventId);
    if (!exists) {
      final projected = state.where((e) => e.id == eventId).firstOrNull;
      if (projected != null) {
        _userEvents.add(projected);
      }
    }
  }

  void _updateUserEvent(
    String eventId,
    ServiceEvent Function(ServiceEvent) updater,
  ) {
    _materializeEventIfNeeded(eventId);
    final idx = _userEvents.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      _userEvents[idx] = updater(_userEvents[idx]);
    }
    _syncState();
  }

  /// Assigns or updates a team member's role and status for a service.
  void assignMember({
    required String eventId,
    required String memberId,
    required TeamRole role,
    AssignmentStatus status = AssignmentStatus.confirmed,
  }) {
    _updateUserEvent(
      eventId,
      (event) => event.copyWith(
        assignments: <ServiceAssignment>[
          ...event.assignments.where((a) => a.memberId != memberId),
          ServiceAssignment(memberId: memberId, role: role, status: status),
        ],
      ),
    );
  }

  /// Removes a team member assignment from a service.
  void removeMemberAssignment({
    required String eventId,
    required String memberId,
  }) {
    _updateUserEvent(
      eventId,
      (event) => event.copyWith(
        assignments: event.assignments
            .where((a) => a.memberId != memberId)
            .toList(),
      ),
    );
  }

  /// Replaces an existing musician assignment with a substitute team member.
  void replaceMember({
    required String eventId,
    required String oldMemberId,
    required String newMemberId,
    TeamRole? role,
    AssignmentStatus status = AssignmentStatus.confirmed,
  }) {
    _updateUserEvent(
      eventId,
      (event) => event.copyWith(
        assignments: <ServiceAssignment>[
          ...event.assignments.where(
            (a) => a.memberId != oldMemberId && a.memberId != newMemberId,
          ),
          ServiceAssignment(
            memberId: newMemberId,
            role:
                role ??
                event.assignments
                    .firstWhere(
                      (a) => a.memberId == oldMemberId,
                      orElse: () => const ServiceAssignment(
                        memberId: '',
                        role: TeamRole.keys,
                      ),
                    )
                    .role,
            status: status,
          ),
        ],
      ),
    );
  }

  /// Assigns all members of a group to a service event.
  void assignGroup({
    required String eventId,
    required List<TeamMember> groupMembers,
  }) {
    _updateUserEvent(
      eventId,
      (event) => event.copyWith(
        assignments: <ServiceAssignment>[
          ...event.assignments,
          for (final member in groupMembers)
            if (!event.assignments.any((a) => a.memberId == member.id))
              ServiceAssignment(
                memberId: member.id,
                role: member.role,
                status: AssignmentStatus.confirmed,
              ),
        ],
      ),
    );
  }

  /// Cycles a member's attendance/availability status for the next upcoming service.
  void cycleMemberStatusForNextService(String memberId, TeamRole defaultRole) {
    final upcoming = state.where((e) => e.isUpcoming).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (upcoming.isEmpty) return;

    final targetEvent = upcoming.firstWhere(
      (e) => e.assignments.any((a) => a.memberId == memberId),
      orElse: () => upcoming.first,
    );

    final existingIndex = targetEvent.assignments.indexWhere(
      (a) => a.memberId == memberId,
    );

    if (existingIndex < 0) {
      assignMember(
        eventId: targetEvent.id,
        memberId: memberId,
        role: defaultRole,
        status: AssignmentStatus.confirmed,
      );
    } else {
      final currentStatus = targetEvent.assignments[existingIndex].status;
      final nextStatus = switch (currentStatus) {
        AssignmentStatus.confirmed => AssignmentStatus.declined,
        AssignmentStatus.declined => AssignmentStatus.scheduled,
        AssignmentStatus.scheduled => AssignmentStatus.confirmed,
      };

      _updateUserEvent(
        targetEvent.id,
        (event) => event.copyWith(
          assignments: <ServiceAssignment>[
            for (final a in event.assignments)
              if (a.memberId == memberId) a.copyWith(status: nextStatus) else a,
          ],
        ),
      );
    }
  }

  /// Computes the combined calendar events by applying active recurring schedule rules,
  /// rolling lookaheads (X events ahead), and cutoff dates where recurring generation is disabled.
  static List<ServiceEvent> _computeProjectedEvents(
    List<ServiceEvent> customEvents,
    List<RecurringSchedule> schedules,
  ) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final scheduleMap = {for (final s in schedules) s.id: s};

    final result = <ServiceEvent>[];

    // 1. Filter customized events by active schedule rules & disabled cutoff dates:
    for (final event in customEvents) {
      if (event.seriesId != null) {
        final schedule = scheduleMap[event.seriesId];
        if (schedule != null) {
          if (!schedule.isActive) continue;
          if (schedule.disabledAfter != null) {
            final cutoff = DateTime(
              schedule.disabledAfter!.year,
              schedule.disabledAfter!.month,
              schedule.disabledAfter!.day,
            );
            final eventDay = DateTime(
              event.dateTime.year,
              event.dateTime.month,
              event.dateTime.day,
            );
            if (!eventDay.isBefore(cutoff)) {
              continue; // Exclude event because series generation is disabled from this date
            }
          }
        }
      }
      result.add(event);
    }

    // 2. Project upcoming events for each active schedule up to lookaheadCount (X events ahead):
    for (final schedule in schedules) {
      if (!schedule.isActive || schedule.lookaheadCount <= 0) continue;

      final projectedDates = schedule.generateOccurrences(
        fromDateTime: todayStart,
      );

      final existingForSeries = result.where((e) {
        final isUpcoming =
            e.dateTime.isAfter(todayStart) ||
            (e.dateTime.year == todayStart.year &&
                e.dateTime.month == todayStart.month &&
                e.dateTime.day == todayStart.day);
        return isUpcoming &&
            (e.seriesId == schedule.id || e.title == schedule.title);
      }).toList();

      for (final dt in projectedDates) {
        if (existingForSeries.length >= schedule.lookaheadCount) break;

        final alreadyCovered = result.any((e) {
          final isSameDay =
              e.dateTime.year == dt.year &&
              e.dateTime.month == dt.month &&
              e.dateTime.day == dt.day;
          return isSameDay &&
              (e.seriesId == schedule.id || e.title == schedule.title);
        });

        if (!alreadyCovered) {
          final newEvent = ServiceEvent(
            id: 'projected_${schedule.id}_${dt.year}_${dt.month}_${dt.day}',
            title: schedule.title,
            dateTime: dt,
            type: schedule.type,
            recurrence: schedule.recurrence,
            location: schedule.location,
            notes: schedule.notes,
            seriesId: schedule.id,
            assignments: schedule.defaultAssignments,
          );
          result.add(newEvent);
          existingForSeries.add(newEvent);
        }
      }

      // Enforce lookaheadCount: if upcoming events for this series exceed X, trim the furthest dates
      final upcomingSeriesEvents = result.where((e) {
        final isUpcoming =
            e.dateTime.isAfter(todayStart) ||
            (e.dateTime.year == todayStart.year &&
                e.dateTime.month == todayStart.month &&
                e.dateTime.day == todayStart.day);
        return isUpcoming &&
            (e.seriesId == schedule.id || e.title == schedule.title);
      }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      if (upcomingSeriesEvents.length > schedule.lookaheadCount) {
        final toRemove = upcomingSeriesEvents.sublist(schedule.lookaheadCount);
        final removeIds = toRemove.map((e) => e.id).toSet();
        result.removeWhere((e) => removeIds.contains(e.id));
      }
    }

    result.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return result;
  }
}
