/// Battuta — Service Calendar & Band Schedule Provider.
///
/// Manages upcoming services, band rehearsals, periodic weekly events,
/// and musician lineup assignments.
library;

import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final serviceCalendarProvider =
    NotifierProvider<ServiceCalendarNotifier, List<ServiceEvent>>(
  ServiceCalendarNotifier.new,
);

class ServiceCalendarNotifier extends Notifier<List<ServiceEvent>> {
  @override
  List<ServiceEvent> build() {
    return _initialSampleEvents();
  }

  /// Adds a new calendar service or rehearsal event.
  void addEvent(ServiceEvent event) {
    state = [...state, event]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Updates an existing service event.
  void updateEvent(ServiceEvent updated) {
    state = [
      for (final e in state)
        if (e.id == updated.id) updated else e,
    ]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Deletes a service event by id.
  void deleteEvent(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  /// Assigns or updates a team member's role and status for a service.
  void assignMember({
    required String eventId,
    required String memberId,
    required TeamRole role,
    AssignmentStatus status = AssignmentStatus.confirmed,
  }) {
    state = [
      for (final event in state)
        if (event.id == eventId)
          event.copyWith(
            assignments: [
              ...event.assignments.where((a) => a.memberId != memberId),
              ServiceAssignment(
                memberId: memberId,
                role: role,
                status: status,
              ),
            ],
          )
        else
          event,
    ];
  }

  /// Removes a team member assignment from a service.
  void removeMemberAssignment({
    required String eventId,
    required String memberId,
  }) {
    state = [
      for (final event in state)
        if (event.id == eventId)
          event.copyWith(
            assignments:
                event.assignments.where((a) => a.memberId != memberId).toList(),
          )
        else
          event,
    ];
  }

  /// Cycles a member's attendance/availability status for the next upcoming service.
  void cycleMemberStatusForNextService(String memberId, TeamRole defaultRole) {
    final upcoming = state.where((e) => e.isUpcoming).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (upcoming.isEmpty) return;

    final nextEvent = upcoming.first;
    final existingIndex =
        nextEvent.assignments.indexWhere((a) => a.memberId == memberId);

    if (existingIndex < 0) {
      // Member not currently scheduled for next event -> schedule them!
      assignMember(
        eventId: nextEvent.id,
        memberId: memberId,
        role: defaultRole,
        status: AssignmentStatus.confirmed,
      );
    } else {
      final currentStatus = nextEvent.assignments[existingIndex].status;
      final nextStatus = switch (currentStatus) {
        AssignmentStatus.confirmed => AssignmentStatus.declined,
        AssignmentStatus.declined => AssignmentStatus.scheduled,
        AssignmentStatus.scheduled => AssignmentStatus.confirmed,
      };

      state = [
        for (final event in state)
          if (event.id == nextEvent.id)
            event.copyWith(
              assignments: [
                for (final a in event.assignments)
                  if (a.memberId == memberId)
                    a.copyWith(status: nextStatus)
                  else
                    a,
              ],
            )
          else
            event,
      ];
    }
  }

  /// Schedules a series of repetitive recurring events (e.g. Every Sunday, 1st Sunday of the Month).
  List<ServiceEvent> scheduleRecurringSeries({
    required String title,
    required ServiceType type,
    required EventRecurrence recurrence,
    required DateTime startDateTime,
    required String location,
    String? notes,
    int count = 6,
    List<ServiceAssignment> defaultAssignments = const [],
  }) {
    final occurrences = recurrence.generateOccurrences(
      fromDateTime: startDateTime,
      count: count,
    );

    final newEvents = <ServiceEvent>[];
    for (final dt in occurrences) {
      newEvents.add(
        ServiceEvent(
          id: 'event_${dt.millisecondsSinceEpoch}_${newEvents.length}',
          title: title,
          dateTime: dt,
          type: type,
          recurrence: recurrence,
          location: location,
          notes: notes,
          assignments: defaultAssignments,
        ),
      );
    }

    state = [...state, ...newEvents]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return newEvents;
  }

  /// Generates the next [count] periodic Sunday morning services automatically.
  void generatePeriodicSundays({int count = 4}) {
    final now = DateTime.now();
    DateTime lastSunday = now;

    // Find the latest Sunday in existing events
    for (final event in state) {
      if (event.type == ServiceType.sundayService &&
          event.dateTime.isAfter(lastSunday)) {
        lastSunday = event.dateTime;
      }
    }

    // If no Sunday in future, calculate upcoming Sunday
    if (lastSunday == now) {
      final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
      final nextSunday = now.add(
        Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday),
      );
      lastSunday = DateTime(
        nextSunday.year,
        nextSunday.month,
        nextSunday.day,
        9,
        0,
      );
    }

    final newEvents = <ServiceEvent>[];
    for (var i = 1; i <= count; i++) {
      final sundayDate = lastSunday.add(Duration(days: 7 * i));
      newEvents.add(
        ServiceEvent(
          id: 'sunday_${sundayDate.millisecondsSinceEpoch}',
          title: 'Sunday Worship Service',
          dateTime: DateTime(
            sundayDate.year,
            sundayDate.month,
            sundayDate.day,
            9,
            0,
          ),
          type: ServiceType.sundayService,
          recurrence: EventRecurrence.weekly,
          location: 'Main Sanctuary',
          notes: '9:00 AM & 11:15 AM Services • Call time: 7:45 AM',
        ),
      );
    }

    state = [...state, ...newEvents]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  static List<ServiceEvent> _initialSampleEvents() {
    final now = DateTime.now();

    // Upcoming Sunday (9:00 AM)
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    final nextSundayDate = now.add(
      Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday),
    );
    final nextSunday = DateTime(
      nextSundayDate.year,
      nextSundayDate.month,
      nextSundayDate.day,
      9,
      0,
    );

    // Upcoming Thursday rehearsal (7:00 PM)
    final daysUntilThursday = (DateTime.thursday - now.weekday) % 7;
    final nextThursdayDate = now.add(
      Duration(
        days: daysUntilThursday <= 0
            ? daysUntilThursday + 7
            : daysUntilThursday,
      ),
    );
    final nextThursday = DateTime(
      nextThursdayDate.year,
      nextThursdayDate.month,
      nextThursdayDate.day,
      19,
      0,
    );

    // Following Sunday (Sunday + 7 days)
    final followingSunday = nextSunday.add(const Duration(days: 7));

    // Third Sunday (Sunday + 14 days)
    final thirdSunday = nextSunday.add(const Duration(days: 14));

    return [
      ServiceEvent(
        id: 'event-next-sunday',
        title: 'Sunday Morning Worship',
        dateTime: nextSunday,
        type: ServiceType.sundayService,
        recurrence: EventRecurrence.weekly,
        location: 'Main Sanctuary',
        notes: 'Soundcheck at 7:45 AM. Lead sheet package in Battuta.',
        assignments: const [
          ServiceAssignment(
            memberId: 'member-1', // Sarah Jenkins
            role: TeamRole.leadVocal,
            status: AssignmentStatus.confirmed,
          ),
          ServiceAssignment(
            memberId: 'member-2', // David Chen
            role: TeamRole.acousticGuitar,
            status: AssignmentStatus.confirmed,
          ),
          ServiceAssignment(
            memberId: 'member-3', // Marcus Miller
            role: TeamRole.bass,
            status: AssignmentStatus.confirmed,
          ),
          ServiceAssignment(
            memberId: 'member-4', // Elena Rostova
            role: TeamRole.keys,
            status: AssignmentStatus.confirmed,
          ),
          ServiceAssignment(
            memberId: 'member-5', // James Wilson
            role: TeamRole.drums,
            status: AssignmentStatus.confirmed,
          ),
        ],
      ),
      ServiceEvent(
        id: 'event-next-rehearsal',
        title: 'Midweek Band Rehearsal',
        dateTime: nextThursday,
        type: ServiceType.rehearsal,
        recurrence: EventRecurrence.weekly,
        location: 'Rehearsal Hall B',
        notes: 'Working through new arrangement and vocal harmonies.',
        assignments: const [
          ServiceAssignment(
            memberId: 'member-1',
            role: TeamRole.leadVocal,
            status: AssignmentStatus.confirmed,
          ),
          ServiceAssignment(
            memberId: 'member-2',
            role: TeamRole.acousticGuitar,
            status: AssignmentStatus.confirmed,
          ),
          ServiceAssignment(
            memberId: 'member-4',
            role: TeamRole.keys,
            status: AssignmentStatus.confirmed,
          ),
        ],
      ),
      ServiceEvent(
        id: 'event-following-sunday',
        title: 'Sunday Morning Worship',
        dateTime: followingSunday,
        type: ServiceType.sundayService,
        recurrence: EventRecurrence.weekly,
        location: 'Main Sanctuary',
        notes: 'Communion Sunday. Call time 8:00 AM.',
        assignments: const [
          ServiceAssignment(
            memberId: 'member-1',
            role: TeamRole.leadVocal,
            status: AssignmentStatus.confirmed,
          ),
          ServiceAssignment(
            memberId: 'member-2',
            role: TeamRole.backingVocal,
            status: AssignmentStatus.confirmed,
          ),
          ServiceAssignment(
            memberId: 'member-4',
            role: TeamRole.keys,
            status: AssignmentStatus.confirmed,
          ),
          ServiceAssignment(
            memberId: 'member-6', // Mateo Rodriguez
            role: TeamRole.electricGuitar,
            status: AssignmentStatus.scheduled,
          ),
        ],
      ),
      ServiceEvent(
        id: 'event-third-sunday',
        title: 'Sunday Morning Worship',
        dateTime: thirdSunday,
        type: ServiceType.sundayService,
        recurrence: EventRecurrence.weekly,
        location: 'Main Sanctuary',
        notes: 'Regular 2-service schedule (9:00 AM & 11:15 AM).',
        assignments: const [
          ServiceAssignment(
            memberId: 'member-2',
            role: TeamRole.acousticGuitar,
            status: AssignmentStatus.scheduled,
          ),
          ServiceAssignment(
            memberId: 'member-3',
            role: TeamRole.bass,
            status: AssignmentStatus.scheduled,
          ),
          ServiceAssignment(
            memberId: 'member-5',
            role: TeamRole.drums,
            status: AssignmentStatus.scheduled,
          ),
        ],
      ),
    ];
  }
}

