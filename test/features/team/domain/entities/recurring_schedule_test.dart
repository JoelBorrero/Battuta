import 'package:battuta/features/team/domain/entities/recurring_schedule.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecurringSchedule Entity', () {
    test('constructs with defaults and required fields', () {
      const schedule = RecurringSchedule(
        id: 'series-1',
        title: 'Sunday Morning Worship',
        time: TimeOfDay(hour: 9, minute: 0),
      );

      expect(schedule.id, equals('series-1'));
      expect(schedule.title, equals('Sunday Morning Worship'));
      expect(schedule.type, equals(ServiceType.sundayService));
      expect(schedule.recurrence, equals(EventRecurrence.weekly));
      expect(schedule.time, equals(const TimeOfDay(hour: 9, minute: 0)));
      expect(schedule.isActive, isTrue);
      expect(schedule.disabledAfter, isNull);
      expect(schedule.lookaheadCount, equals(4));
    });

    test('generates exact X number of events ahead when active and no cutoff', () {
      final baseDate = DateTime(2026, 11, 8, 9, 0); // Sunday
      const schedule = RecurringSchedule(
        id: 'series-1',
        title: 'Sunday Morning Worship',
        time: TimeOfDay(hour: 9, minute: 0),
        lookaheadCount: 4,
      );

      final dates = schedule.generateOccurrences(fromDateTime: baseDate);

      expect(dates.length, equals(4));
      expect(dates[0], equals(DateTime(2026, 11, 8, 9, 0)));
      expect(dates[1], equals(DateTime(2026, 11, 15, 9, 0)));
      expect(dates[2], equals(DateTime(2026, 11, 22, 9, 0)));
      expect(dates[3], equals(DateTime(2026, 11, 29, 9, 0)));
    });

    test('generates zero occurrences when schedule is paused/inactive', () {
      final baseDate = DateTime(2026, 11, 8, 9, 0);
      const schedule = RecurringSchedule(
        id: 'series-1',
        title: 'Sunday Morning Worship',
        time: TimeOfDay(hour: 9, minute: 0),
        isActive: false,
        lookaheadCount: 4,
      );

      final dates = schedule.generateOccurrences(fromDateTime: baseDate);

      expect(dates, isEmpty);
    });

    test('stops generating occurrences on or after disabledAfter cutoff date', () {
      final baseDate = DateTime(2026, 11, 8, 9, 0);
      // Cutoff date is Nov 20, 2026 -> only Nov 8 and Nov 15 should be generated
      final schedule = RecurringSchedule(
        id: 'series-1',
        title: 'Sunday Morning Worship',
        time: const TimeOfDay(hour: 9, minute: 0),
        disabledAfter: DateTime(2026, 11, 20),
        lookaheadCount: 6,
      );

      final dates = schedule.generateOccurrences(fromDateTime: baseDate);

      expect(dates.length, equals(2));
      expect(dates[0], equals(DateTime(2026, 11, 8, 9, 0)));
      expect(dates[1], equals(DateTime(2026, 11, 15, 9, 0)));
    });

    test('supports copyWith and clearDisabledAfter', () {
      final schedule = RecurringSchedule(
        id: 'series-1',
        title: 'Sunday Worship',
        time: const TimeOfDay(hour: 9, minute: 0),
        disabledAfter: DateTime(2026, 12, 1),
      );

      final cleared = schedule.copyWith(clearDisabledAfter: true);
      expect(cleared.disabledAfter, isNull);

      final updatedCount = schedule.copyWith(lookaheadCount: 8);
      expect(updatedCount.lookaheadCount, equals(8));
      expect(updatedCount.disabledAfter, equals(DateTime(2026, 12, 1)));
    });
  });
}
