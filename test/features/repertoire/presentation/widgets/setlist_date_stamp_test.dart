import 'package:battuta/features/repertoire/presentation/widgets/setlist_date_stamp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SetlistDateStamp.calendarDay', () {
    test('uses the device-local day of a UTC-flagged instant', () {
      // 02:00Z is still the previous evening west of UTC.
      final utc = DateTime.utc(2026, 11, 8, 2);
      final local = utc.toLocal();
      final day = SetlistDateStamp.calendarDay(utc);

      expect(
        (day.year, day.month, day.day),
        (local.year, local.month, local.day),
      );
      expect(day.isUtc, isFalse);
    });

    test('an instant west of UTC keeps its local calendar day', () {
      // The same event: 20:00 local on Nov 7 in UTC-6 is Nov 8 02:00Z. The
      // stamp must show the local day, never the UTC day, when zones differ.
      final instant = DateTime.utc(2026, 11, 8, 2);
      final offset = instant.toLocal().timeZoneOffset;
      final expectedDay = offset.isNegative && offset.inHours <= -3 ? 7 : null;

      final day = SetlistDateStamp.calendarDay(instant);
      if (expectedDay != null) expect(day.day, expectedDay);
      expect(day.day, instant.toLocal().day);
    });
  });

  testWidgets('shows month over day', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SetlistDateStamp(date: DateTime(2026, 12, 25, 9), large: true),
        ),
      ),
    );

    expect(find.text('DEC'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
  });
}
