import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/features/team/presentation/providers/schedule_alerts_provider.dart';
import 'package:battuta/features/team/presentation/providers/service_calendar_provider.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockTeamMembersNotifier extends TeamMembersNotifier {
  MockTeamMembersNotifier(this._initial);
  final List<TeamMember> _initial;
  @override
  List<TeamMember> build() => _initial;
}

class MockServiceCalendarNotifier extends ServiceCalendarNotifier {
  MockServiceCalendarNotifier(this._initial);
  final List<ServiceEvent> _initial;
  @override
  List<ServiceEvent> build() => _initial;
}

void main() {
  group('ScheduleAlertsProvider', () {
    test('empty alerts when all upcoming assignments are confirmed and available', () {
      final container = ProviderContainer(
        overrides: [
          teamMembersProvider.overrideWith(
            () => MockTeamMembersNotifier([
              const TeamMember(
                id: 'member-1',
                name: 'Sarah',
                roles: [TeamRole.leadVocal],
                availability: AvailabilityStatus.available,
              ),
            ]),
          ),
          serviceCalendarProvider.overrideWith(
            () => MockServiceCalendarNotifier([
              ServiceEvent(
                id: 'event-1',
                title: 'Sunday Worship',
                dateTime: DateTime.now().add(const Duration(days: 2)),
                assignments: const [
                  ServiceAssignment(
                    memberId: 'member-1',
                    role: TeamRole.leadVocal,
                    status: AssignmentStatus.confirmed,
                  ),
                ],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final alerts = container.read(adminScheduleAlertsProvider);
      final count = container.read(pendingAlertCountProvider);

      expect(alerts, isEmpty);
      expect(count, equals(0));
    });

    test('generates alert when assigned musician declines attendance', () {
      final upcomingDate = DateTime.now().add(const Duration(days: 3));
      final container = ProviderContainer(
        overrides: [
          teamMembersProvider.overrideWith(
            () => MockTeamMembersNotifier([
              const TeamMember(
                id: 'member-1',
                name: 'David Chen',
                roles: [TeamRole.keys],
                availability: AvailabilityStatus.available,
              ),
            ]),
          ),
          serviceCalendarProvider.overrideWith(
            () => MockServiceCalendarNotifier([
              ServiceEvent(
                id: 'event-1',
                title: 'Sunday Morning Worship',
                dateTime: upcomingDate,
                assignments: const [
                  ServiceAssignment(
                    memberId: 'member-1',
                    role: TeamRole.keys,
                    status: AssignmentStatus.declined,
                  ),
                ],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final alerts = container.read(adminScheduleAlertsProvider);
      final count = container.read(pendingAlertCountProvider);

      expect(alerts.length, equals(1));
      expect(count, equals(1));

      final alert = alerts.first;
      expect(alert.id, equals('alert_event-1_member-1'));
      expect(alert.eventId, equals('event-1'));
      expect(alert.memberName, equals('David Chen'));
      expect(alert.role, equals(TeamRole.keys));
      expect(alert.reason, contains("Can't attend — missing cover for Keys"));
    });

    test('generates alert when member general availability is unavailable', () {
      final upcomingDate = DateTime.now().add(const Duration(days: 1));
      final container = ProviderContainer(
        overrides: [
          teamMembersProvider.overrideWith(
            () => MockTeamMembersNotifier([
              const TeamMember(
                id: 'member-2',
                name: 'Marcus Miller',
                roles: [TeamRole.bass],
                availability: AvailabilityStatus.unavailable,
              ),
            ]),
          ),
          serviceCalendarProvider.overrideWith(
            () => MockServiceCalendarNotifier([
              ServiceEvent(
                id: 'event-2',
                title: 'Midweek Rehearsal',
                dateTime: upcomingDate,
                assignments: const [
                  ServiceAssignment(
                    memberId: 'member-2',
                    role: TeamRole.bass,
                    status: AssignmentStatus.confirmed,
                  ),
                ],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final alerts = container.read(adminScheduleAlertsProvider);
      expect(alerts.length, equals(1));
      expect(alerts.first.memberName, equals('Marcus Miller'));
      expect(alerts.first.reason, contains('Unavailable — may need substitute'));
    });

    test('dismissing an alert excludes it from the reactive alerts provider', () {
      final upcomingDate = DateTime.now().add(const Duration(days: 2));
      final container = ProviderContainer(
        overrides: [
          teamMembersProvider.overrideWith(
            () => MockTeamMembersNotifier([
              const TeamMember(
                id: 'member-1',
                name: 'Sarah',
                roles: [TeamRole.leadVocal],
              ),
            ]),
          ),
          serviceCalendarProvider.overrideWith(
            () => MockServiceCalendarNotifier([
              ServiceEvent(
                id: 'event-1',
                title: 'Sunday Worship',
                dateTime: upcomingDate,
                assignments: const [
                  ServiceAssignment(
                    memberId: 'member-1',
                    role: TeamRole.leadVocal,
                    status: AssignmentStatus.declined,
                  ),
                ],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(pendingAlertCountProvider), equals(1));

      // Dismiss the alert
      container
          .read(dismissedAlertsProvider.notifier)
          .dismiss('alert_event-1_member-1');

      expect(container.read(adminScheduleAlertsProvider), isEmpty);
      expect(container.read(pendingAlertCountProvider), equals(0));
    });
  });
}
