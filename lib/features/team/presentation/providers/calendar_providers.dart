/// Battuta — Calendar on real data.
///
/// Streams the events, recurring schedules, assignments and absences of the
/// active organization (cache first, see `ScheduleRepository`) and adapts
/// them to the [ServiceEvent] view models of the Calendar tab, filtered by
/// the active band. Admin alerts and the member's own services and absences
/// are derived from the same data.
library;

import 'dart:convert';

import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/team/domain/entities/schedule_alert.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/features/team/domain/services/service_calendar_builder.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time; tests override it.
final calendarClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

StreamProvider<List<T>> _organizationStream<T>(
  Stream<List<T>> Function(Ref ref, String organizationId) watch,
) => StreamProvider<List<T>>((ref) {
  final id = ref.watch(activeOrganizationIdProvider);
  if (id == null) return Stream.value(const []);
  return watch(ref, id);
});

final activeEventsProvider = _organizationStream<CalendarEvent>(
  (ref, id) => ref.watch(scheduleRepositoryProvider).watchEvents(id),
);

final activeSchedulesProvider = _organizationStream<RecurringSchedule>(
  (ref, id) => ref.watch(scheduleRepositoryProvider).watchSchedules(id),
);

final activeAssignmentsProvider = _organizationStream<EventAssignment>(
  (ref, id) => ref.watch(scheduleRepositoryProvider).watchAssignments(id),
);

final activeAbsencesProvider = _organizationStream<MemberAbsence>(
  (ref, id) => ref.watch(scheduleRepositoryProvider).watchAbsences(id),
);

/// Today's and later services of the active organization (all bands).
final allServiceEventsProvider = Provider<List<ServiceEvent>>((ref) {
  if (ref.watch(activeOrganizationIdProvider) == null) return const [];
  return buildServiceEvents(
    now: ref.watch(calendarClockProvider)(),
    events: ref.watch(activeEventsProvider).value ?? const [],
    schedules: ref.watch(activeSchedulesProvider).value ?? const [],
    assignments: ref.watch(activeAssignmentsProvider).value ?? const [],
    absences: ref.watch(activeAbsencesProvider).value ?? const [],
  );
});

/// The services shown by the Calendar tab: those of the active band plus the
/// ones without a band (everyone's), or all of them with no band selected.
final serviceCalendarProvider = Provider<List<ServiceEvent>>((ref) {
  final events = ref.watch(allServiceEventsProvider);
  final bandId = ref.watch(activeBandIdProvider);
  if (bandId == null) return events;
  return [
    for (final event in events)
      if (event.bandId == null || event.bandId == bandId) event,
  ];
});

/// An upcoming service where I am on the lineup.
typedef MyService = ({ServiceEvent event, ServiceAssignment assignment});

/// My assignments on upcoming services, in date order (all bands).
final myServicesProvider = Provider<List<MyService>>((ref) {
  final me = ref.watch(currentMemberProvider);
  if (me == null) return const [];
  return [
    for (final event in ref.watch(allServiceEventsProvider))
      for (final assignment in event.assignments)
        if (assignment.memberId == me.id)
          (event: event, assignment: assignment),
  ];
});

/// My own absences, soonest first.
final myAbsencesProvider = Provider<List<MemberAbsence>>((ref) {
  final me = ref.watch(currentMemberProvider);
  if (me == null) return const [];
  return [
    for (final absence in ref.watch(activeAbsencesProvider).value ?? const [])
      if (absence.memberId == me.id) absence,
  ];
});

String dismissedAlertsStorageKey(String accountId) =>
    'battuta_dismissed_alerts_$accountId';

/// Alerts an administrator dismissed; kept on this device per account.
class DismissedAlertsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final accountId = ref.watch(currentAccountIdProvider);
    if (accountId == null) return {};
    _load(accountId);
    return {};
  }

  Future<void> _load(String accountId) async {
    try {
      final raw = await ref
          .read(activeOrganizationStorageProvider)
          .read(dismissedAlertsStorageKey(accountId));
      if (raw == null || ref.read(currentAccountIdProvider) != accountId) {
        return;
      }
      final saved = (jsonDecode(raw) as List).cast<String>();
      state = {...state, ...saved};
    } catch (_) {
      // Nothing dismissed.
    }
  }

  Future<void> dismiss(String alertId) async {
    state = {...state, alertId};
    final accountId = ref.read(currentAccountIdProvider);
    if (accountId == null) return;
    try {
      await ref
          .read(activeOrganizationStorageProvider)
          .write(
            dismissedAlertsStorageKey(accountId),
            jsonEncode(state.toList()),
          );
    } catch (_) {
      // Kept in memory for this run.
    }
  }
}

final dismissedAlertsProvider =
    NotifierProvider<DismissedAlertsNotifier, Set<String>>(
      DismissedAlertsNotifier.new,
    );

/// Lineup gaps of upcoming services (declined, or the member is away),
/// for administrators only. Resolved or dismissed ones are gone.
final adminScheduleAlertsProvider = Provider<List<ScheduleAlert>>((ref) {
  if (ref.watch(currentAccountIdProvider) == null) return const [];
  if (ref.watch(activeOrganizationProvider)?.isAdmin != true) return const [];
  final dismissed = ref.watch(dismissedAlertsProvider);
  final names = ref.watch(memberNamesProvider);

  final alerts = <ScheduleAlert>[];
  for (final event in ref.watch(allServiceEventsProvider)) {
    for (final assignment in event.assignments) {
      final kind = switch (assignment.status) {
        AssignmentStatus.declined => ScheduleAlertKind.declined,
        AssignmentStatus.away => ScheduleAlertKind.absent,
        _ => null,
      };
      if (kind == null) continue;
      final alert = ScheduleAlert(
        kind: kind,
        eventId: event.id,
        eventTitle: event.title,
        eventDate: event.dateTime,
        assignmentId: assignment.id,
        memberId: assignment.memberId,
        memberName: names[assignment.memberId] ?? '',
        instrument: assignment.instrument,
        reason: assignment.declineReason,
      );
      if (!dismissed.contains(alert.id)) alerts.add(alert);
    }
  }
  return alerts;
});

/// Count of unresolved lineup gaps.
final pendingAlertCountProvider = Provider<int>(
  (ref) => ref.watch(adminScheduleAlertsProvider).length,
);

/// Active members of the organization an administrator can put on a service:
/// the active band's members first (when a band is selected), then by name.
final assignableMembersProvider = Provider<List<TeamMember>>((ref) {
  final members = ref.watch(activeMembersProvider).value ?? const [];
  final links = ref.watch(activeBandMembersProvider).value ?? const [];
  final bandId = ref.watch(activeBandIdProvider);
  final me = ref.watch(currentAccountIdProvider);
  final bandsOf = <String, List<String>>{};
  for (final link in links) {
    bandsOf.putIfAbsent(link.memberId, () => []).add(link.bandId);
  }
  final result = [
    for (final member in members)
      if (member.isActive)
        toTeamMember(
          member,
          currentAccountId: me,
          bandIds: bandsOf[member.id] ?? const [],
        ),
  ];
  int rank(TeamMember m) =>
      bandId != null && m.groupIds.contains(bandId) ? 0 : 1;
  result.sort((a, b) {
    final byBand = rank(a).compareTo(rank(b));
    return byBand != 0
        ? byBand
        : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return result;
});

/// Display names of every member of the organization by member id (also
/// those who are deactivated, so past lineups still read well).
final memberNamesProvider = Provider<Map<String, String>>((ref) {
  return {
    for (final member in ref.watch(activeMembersProvider).value ?? const [])
      member.id: toTeamMember(member, currentAccountId: null).name,
  };
});
