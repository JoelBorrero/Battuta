import 'package:battuta/features/team/presentation/widgets/month_grid.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('monthCells', () {
    test('a month starting on Sunday has no leading blanks (Sunday first)', () {
      // November 2026 starts on a Sunday and has 30 days.
      final cells = monthCells(DateTime(2026, 11), 0);

      expect(cells.length, 35);
      expect(cells.first, DateTime(2026, 11));
      expect(cells[29], DateTime(2026, 11, 30));
      expect(cells.skip(30), everyElement(isNull));
    });

    test('a month starting on Sunday has six blanks when Monday is first', () {
      final cells = monthCells(DateTime(2026, 11), 1);

      expect(cells.take(6), everyElement(isNull));
      expect(cells[6], DateTime(2026, 11));
      expect(cells.length, 42);
    });

    test('a month can span six weeks', () {
      // May 2026 starts on a Friday and has 31 days: 5 + 31 = 36 cells.
      final cells = monthCells(DateTime(2026, 5), 0);

      expect(cells.length, 42);
      expect(cells[5], DateTime(2026, 5));
      expect(cells[35], DateTime(2026, 5, 31));
      expect(cells.skip(36), everyElement(isNull));
    });

    test('February of a common year starting on the first day is 4 weeks', () {
      // February 2027 starts on a Monday.
      final cells = monthCells(DateTime(2027, 2), 1);

      expect(cells.length, 28);
      expect(cells.every((c) => c != null), isTrue);
    });
  });

  group('MonthGrid', () {
    Future<void> pumpGrid(
      WidgetTester tester, {
      required Size size,
      Locale locale = const Locale('en'),
      DateTime? month,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      var shown = month ?? DateTime(2026, 12);
      var selected = DateTime(2026, 12, 31);
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Padding(
                padding: const EdgeInsets.all(16),
                child: MonthGrid(
                  month: shown,
                  today: DateTime(2026, 12, 20),
                  selected: selected,
                  markedDays: {DateTime(2026, 12, 25), DateTime(2027, 1, 3)},
                  onSelect: (d) => setState(() => selected = d),
                  onPreviousMonth: () => setState(
                    () => shown = DateTime(shown.year, shown.month - 1),
                  ),
                  onNextMonth: () => setState(
                    () => shown = DateTime(shown.year, shown.month + 1),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final width in [320.0, 1180.0]) {
      testWidgets('fits ${width.toInt()} pt with 44 pt tall day cells', (
        tester,
      ) async {
        await pumpGrid(tester, size: Size(width, 800));

        expect(tester.takeException(), isNull);
        final cell = find.byKey(const ValueKey('month_day_2026-12-25'));
        expect(tester.getSize(cell).height, 44);
        expect(tester.getSize(cell).width, greaterThanOrEqualTo(38));
      });
    }

    testWidgets('moves from December to January across the year', (
      tester,
    ) async {
      await pumpGrid(tester, size: const Size(390, 800));

      expect(find.text('December 2026'), findsOneWidget);
      expect(find.byKey(const ValueKey('month_dot_2026-12-25')), findsOne);
      expect(find.byKey(const ValueKey('month_dot_2027-01-03')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('month_next_btn')));
      await tester.pumpAndSettle();

      expect(find.text('January 2027'), findsOneWidget);
      expect(find.byKey(const ValueKey('month_dot_2027-01-03')), findsOne);
      expect(find.byKey(const ValueKey('month_day_2026-12-31')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('month_prev_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('month_prev_btn')));
      await tester.pumpAndSettle();

      expect(find.text('November 2026'), findsOneWidget);
    });

    testWidgets('a selected day in another month marks nothing here', (
      tester,
    ) async {
      await pumpGrid(tester, size: const Size(390, 800));
      await tester.tap(find.byKey(const ValueKey('month_next_btn')));
      await tester.pumpAndSettle();

      // 31 Dec is selected but January shows no such cell, and no crash.
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('month_day_2027-01-03')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the week starts on the locale first day', (tester) async {
      await pumpGrid(tester, size: const Size(390, 800));
      final en = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(MonthGrid),
          matching: find.byType(Text),
        ),
      );
      expect(en.map((t) => t.data).whereType<String>().toList().sublist(1, 3), [
        'S',
        'M',
      ]);

      await pumpGrid(
        tester,
        size: const Size(390, 800),
        locale: const Locale('es'),
      );
      // Spanish weeks start on Monday: L M X J V S D.
      final es = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(MonthGrid),
          matching: find.byType(Text),
        ),
      );
      expect(es.map((t) => t.data).whereType<String>().toList().sublist(1, 3), [
        'L',
        'M',
      ]);
    });
  });
}
