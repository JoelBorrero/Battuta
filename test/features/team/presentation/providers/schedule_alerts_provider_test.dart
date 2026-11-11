import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/features/team/presentation/providers/schedule_alerts_provider.dart';
import 'package:battuta/features/team/presentation/providers/service_calendar_provider.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockServiceCalendarNotifier extends ServiceCalendarNotifier {
  MockServiceCalendarNotifier(this._initial);
  final List<ServiceEvent> _initial;
  @override
  List<ServiceEvent> build() => _initial;
}

void main() {
  group('ScheduleAlertsProvider', () {
    test('empty alerts when all upcoming assignments are confirmed', () {
      final container = ProviderContainer(
        overrides: [
          teamMembersProvider.overrideWithValue([
            const TeamMember(
              id: 'member-1',
              name: 'Sarah',
              instruments: ['leadVocal'],
            ),
          ]),
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
          teamMembersProvider.overrideWithValue([
            const TeamMember(
              id: 'member-1',
              name: 'David Chen',
              instruments: ['keys'],
            ),
          ]),
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

    test(
      'dismissing an alert excludes it from the reactive alerts provider',
      () {
        final upcomingDate = DateTime.now().add(const Duration(days: 2));
        final container = ProviderContainer(
          overrides: [
            teamMembersProvider.overrideWithValue([
              const TeamMember(
                id: 'member-1',
                name: 'Sarah',
                instruments: ['leadVocal'],
              ),
            ]),
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
      },
    );
  });
}
