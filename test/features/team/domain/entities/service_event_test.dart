import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventRecurrenceCalculator', () {
    test('weekly generates occurrences spaced by 7 days on Sundays', () {
      final base = DateTime(2026, 11, 8, 9, 0); // Sunday Nov 8, 2026
      final dates = EventRecurrence.weekly.generateOccurrences(
        fromDateTime: base,
        count: 4,
      );

      expect(dates.length, equals(4));
      expect(dates[0], equals(DateTime(2026, 11, 8, 9, 0)));
      expect(dates[1], equals(DateTime(2026, 11, 15, 9, 0)));
      expect(dates[2], equals(DateTime(2026, 11, 22, 9, 0)));
      expect(dates[3], equals(DateTime(2026, 11, 29, 9, 0)));
      for (final d in dates) {
        expect(d.weekday, equals(DateTime.sunday));
      }
    });

    test('weeklyThursday generates occurrences on Thursdays', () {
      final base = DateTime(2026, 11, 12, 19, 0); // Thursday Nov 12, 2026
      final dates = EventRecurrence.weeklyThursday.generateOccurrences(
        fromDateTime: base,
        count: 3,
      );

      expect(dates.length, equals(3));
      for (final d in dates) {
        expect(d.weekday, equals(DateTime.thursday));
        expect(d.hour, equals(19));
      }
    });

    test(
      'firstSundayOfMonth computes exact 1st Sunday of consecutive months',
      () {
        // Starting in Nov 2026
        final base = DateTime(2026, 11, 2, 9, 0);
        final dates = EventRecurrence.firstSundayOfMonth.generateOccurrences(
          fromDateTime: base,
          count: 4,
        );

        expect(dates.length, equals(4));
        // In Dec 2026, 1st Sunday is Dec 6
        expect(dates[0], equals(DateTime(2026, 12, 6, 9, 0)));
        // In Jan 2027, 1st Sunday is Jan 3
        expect(dates[1], equals(DateTime(2027, 1, 3, 9, 0)));
        // In Feb 2027, 1st Sunday is Feb 7
        expect(dates[2], equals(DateTime(2027, 2, 7, 9, 0)));
        // In Mar 2027, 1st Sunday is Mar 7
        expect(dates[3], equals(DateTime(2027, 3, 7, 9, 0)));

        for (final d in dates) {
          expect(d.weekday, equals(DateTime.sunday));
          expect(
            d.day,
            inInclusiveRange(1, 7),
          ); // 1st weekday is always between day 1 and 7
        }
      },
    );

    test(
      'secondSundayOfMonth computes exact 2nd Sunday of consecutive months',
      () {
        final base = DateTime(2026, 11, 9, 10, 0);
        final dates = EventRecurrence.secondSundayOfMonth.generateOccurrences(
          fromDateTime: base,
          count: 3,
        );

        expect(dates.length, equals(3));
        for (final d in dates) {
          expect(d.weekday, equals(DateTime.sunday));
          expect(
            d.day,
            inInclusiveRange(8, 14),
          ); // 2nd weekday is between 8 and 14
        }
      },
    );

    test(
      'lastSundayOfMonth computes exact last Sunday of consecutive months',
      () {
        final base = DateTime(2026, 11, 1, 18, 0);
        final dates = EventRecurrence.lastSundayOfMonth.generateOccurrences(
          fromDateTime: base,
          count: 3,
        );

        expect(dates.length, equals(3));
        // Nov 2026 has 30 days -> last Sunday is Nov 29
        expect(dates[0], equals(DateTime(2026, 11, 29, 18, 0)));
        // Dec 2026 has 31 days -> last Sunday is Dec 27
        expect(dates[1], equals(DateTime(2026, 12, 27, 18, 0)));
        // Jan 2027 has 31 days -> last Sunday is Jan 31
        expect(dates[2], equals(DateTime(2027, 1, 31, 18, 0)));

        for (final d in dates) {
          expect(d.weekday, equals(DateTime.sunday));
        }
      },
    );

    test('biweekly generates occurrences spaced by 14 days', () {
      final base = DateTime(2026, 11, 8, 9, 0);
      final dates = EventRecurrence.biweekly.generateOccurrences(
        fromDateTime: base,
        count: 3,
      );

      expect(dates.length, equals(3));
      expect(dates[0], equals(DateTime(2026, 11, 8, 9, 0)));
      expect(dates[1], equals(DateTime(2026, 11, 22, 9, 0)));
      expect(dates[2], equals(DateTime(2026, 12, 6, 9, 0)));
    });
  });
}
