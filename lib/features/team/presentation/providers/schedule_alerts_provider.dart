/// Battuta — Admin Schedule Alerts Provider.
///
/// Detects attendance gaps, declines, and unavailable musicians across
/// upcoming worship services and notifies the Administrator so they
/// can assign a replacement cover.
library;

import 'package:battuta/features/team/domain/entities/schedule_alert.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/features/team/presentation/providers/service_calendar_provider.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DismissedAlertsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void dismiss(String alertId) {
    state = {...state, alertId};
  }

  void reset() {
    state = {};
  }
}

final dismissedAlertsProvider =
    NotifierProvider<DismissedAlertsNotifier, Set<String>>(
      DismissedAlertsNotifier.new,
    );

/// Reactive list of active scheduling alerts for the Administrator.
final adminScheduleAlertsProvider = Provider<List<ScheduleAlert>>((ref) {
  final events = ref.watch(serviceCalendarProvider);
  final members = ref.watch(teamMembersProvider);
  final dismissed = ref.watch(dismissedAlertsProvider);

  final alerts = <ScheduleAlert>[];

  // Examine upcoming events in chronological order
  final upcomingEvents = events.where((e) => e.isUpcoming).toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  for (final event in upcomingEvents) {
    for (final assignment in event.assignments) {
      final alertId = 'alert_${event.id}_${assignment.memberId}';
      if (dismissed.contains(alertId)) continue;

      final member = members.cast<TeamMember?>().firstWhere(
        (m) => m?.id == assignment.memberId,
        orElse: () => null,
      );
      final memberName = member?.name ?? 'Unknown Musician';

      if (assignment.status == AssignmentStatus.declined) {
        alerts.add(
          ScheduleAlert(
            id: alertId,
            eventId: event.id,
            eventTitle: event.title,
            eventDate: event.dateTime,
            memberId: assignment.memberId,
            memberName: memberName,
            role: assignment.role,
            reason:
                "Can't attend — missing cover for ${assignment.role.shortName}",
            timestamp: event.dateTime,
          ),
        );
      }
    }
  }

  return alerts;
});

/// Count of unresolved scheduling gaps needing the Admin's attention.
final pendingAlertCountProvider = Provider<int>((ref) {
  return ref.watch(adminScheduleAlertsProvider).length;
});
