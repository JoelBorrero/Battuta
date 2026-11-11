import 'package:battuta/features/team/domain/entities/recurring_schedule.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/presentation/providers/recurring_schedules_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _series = RecurringSchedule(
  id: 'series-sunday-morning',
  title: 'Sunday Morning Worship',
  type: ServiceType.sundayService,
  recurrence: EventRecurrence.weekly,
  time: TimeOfDay(hour: 9, minute: 0),
  isActive: true,
  lookaheadCount: 4,
);

void main() {
  ProviderContainer seeded() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(recurringSchedulesProvider.notifier).addSchedule(_series);
    return container;
  }

  RecurringSchedule current(ProviderContainer c) => c
      .read(recurringSchedulesProvider)
      .firstWhere((s) => s.id == 'series-sunday-morning');

  group('RecurringSchedulesProvider', () {
    test('starts empty: there are no sample schedules', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(recurringSchedulesProvider), isEmpty);
    });

    test('adds a schedule', () {
      final container = seeded();

      expect(container.read(recurringSchedulesProvider), hasLength(1));
    });

    test('toggles active state of a recurring schedule', () {
      final container = seeded();

      expect(current(container).isActive, isTrue);
      container
          .read(recurringSchedulesProvider.notifier)
          .toggleActive('series-sunday-morning');
      expect(current(container).isActive, isFalse);
    });

    test('sets and clears cutoff disabled date', () {
      final container = seeded();
      final cutoff = DateTime(2026, 12, 1);

      container
          .read(recurringSchedulesProvider.notifier)
          .setDisabledDate('series-sunday-morning', cutoff);
      expect(current(container).disabledAfter, equals(cutoff));

      container
          .read(recurringSchedulesProvider.notifier)
          .setDisabledDate('series-sunday-morning', null);
      expect(current(container).disabledAfter, isNull);
    });

    test('updates lookahead count (X number of events ahead)', () {
      final container = seeded();

      container
          .read(recurringSchedulesProvider.notifier)
          .setLookaheadCount('series-sunday-morning', 8);
      expect(current(container).lookaheadCount, equals(8));
    });
  });
}
