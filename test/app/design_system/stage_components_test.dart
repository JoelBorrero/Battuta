import 'package:battuta/app/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.dark,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('BattutaBrand status roles', () {
    test('map to the existing stage palette', () {
      const brand = BattutaBrand.dark;
      expect(brand.success, AppTheme.stageGreen);
      expect(brand.warning, AppTheme.stageOrange);
      expect(brand.info, AppTheme.stageBlue);
      expect(brand.danger, AppTheme.stageRed);
      expect(brand.wash(AppTheme.stageGreen).a, lessThan(0.2));
    });
  });

  group('StageCard', () {
    testWidgets('is static without onTap and pressable with it', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const StageCard(child: Text('Static'))));
      expect(find.byType(BattutaPressable), findsNothing);

      var taps = 0;
      await tester.pumpWidget(
        _host(StageCard(onTap: () => taps++, child: const Text('Tap me'))),
      );
      await tester.tap(find.text('Tap me'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('selected card draws an amber border', (tester) async {
      await tester.pumpWidget(
        _host(const StageCard(selected: true, child: Text('Next'))),
      );
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final border = (container.decoration! as BoxDecoration).border! as Border;
      expect(border.top.color, AppTheme.amberAccent);
    });
  });

  group('StageGroup', () {
    testWidgets('renders header, rows with dividers, and footer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const StageGroup(
            title: 'Appearance',
            footer: 'Applies everywhere',
            children: [
              ListTile(title: Text('One')),
              ListTile(title: Text('Two')),
              ListTile(title: Text('Three')),
            ],
          ),
        ),
      );
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('Applies everywhere'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('section header uppercases visually but reads naturally', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const StageSectionHeader(title: 'Configuración de API')),
      );
      expect(find.text('CONFIGURACIÓN DE API'), findsOneWidget);
      expect(find.bySemanticsLabel('Configuración de API'), findsOneWidget);
    });
  });

  group('StageIconTile', () {
    testWidgets('shows a label, or an icon with caption', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StageIconTile(label: 'C#m'),
              StageIconTile(icon: Icons.playlist_play, caption: '7'),
            ],
          ),
        ),
      );
      expect(find.text('C#m'), findsOneWidget);
      expect(find.byIcon(Icons.playlist_play), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('StageSegmentedControl', () {
    testWidgets('moves the thumb and reports the selected value', (
      tester,
    ) async {
      var mode = 'a';
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SizedBox(
                width: 320,
                child: StageSegmentedControl<String>(
                  selected: mode,
                  onChanged: (v) => setState(() => mode = v),
                  segments: const [
                    StageSegment(
                      value: 'a',
                      label: 'Director',
                      icon: Icons.cell_tower,
                    ),
                    StageSegment(
                      value: 'b',
                      label: 'Follower',
                      icon: Icons.group,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final thumb = find.byType(AnimatedPositioned);
      final before = tester.getTopLeft(thumb).dx;

      await tester.tap(find.text('Follower'));
      await tester.pumpAndSettle();

      expect(mode, 'b');
      expect(tester.getTopLeft(thumb).dx, greaterThan(before));
    });

    testWidgets('meets the 44pt touch target', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            child: StageSegmentedControl<int>(
              selected: 0,
              onChanged: (_) {},
              segments: const [
                StageSegment(value: 0, label: 'One'),
                StageSegment(value: 1, label: 'Two'),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(StageSegmentedControl<int>)).height,
        greaterThanOrEqualTo(BattutaSpace.minTouchTarget),
      );
    });
  });

  group('StageSegmentedControl hit area', () {
    testWidgets('every segment is at least 44 pt tall', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            child: StageSegmentedControl<int>(
              selected: 0,
              onChanged: (_) {},
              segments: const [
                StageSegment(value: 0, label: 'One'),
                StageSegment(value: 1, label: 'Two'),
              ],
            ),
          ),
        ),
      );
      final pressables = find.byType(BattutaPressable);
      expect(pressables, findsNWidgets(2));
      for (final element in pressables.evaluate()) {
        final size = (element.renderObject! as RenderBox).size;
        expect(size.height, greaterThanOrEqualTo(BattutaSpace.minTouchTarget));
        expect(size.width, greaterThanOrEqualTo(BattutaSpace.minTouchTarget));
      }
    });
  });

  group('StageFilterPill hit area', () {
    testWidgets('the tap box is at least 44 pt tall, the pill 36 pt', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          StageFilterPill(label: 'Both', selected: false, onTap: () => taps++),
        ),
      );
      final box = tester.getSize(find.byType(BattutaPressable));
      expect(box.height, greaterThanOrEqualTo(BattutaSpace.minTouchTarget));
      expect(tester.getSize(find.byType(AnimatedContainer)).height, 36);
      // A tap just above the visible pill still hits.
      final rect = tester.getRect(find.byType(BattutaPressable));
      await tester.tapAt(Offset(rect.center.dx, rect.top + 2));
      expect(taps, 1);
    });
  });

  group('StageLargeTitle', () {
    Future<double> pumpTitle(
      WidgetTester tester,
      String title,
      double width,
    ) async {
      await tester.pumpWidget(
        _host(SizedBox(width: width, child: StageLargeTitle(title))),
      );
      return tester.widget<Text>(find.text(title)).style!.fontSize!;
    }

    testWidgets('keeps 28 pt when it fits', (tester) async {
      expect(await pumpTitle(tester, 'Repertoire', 300), 28);
    });

    testWidgets('scales down instead of ellipsizing, never below 22', (
      tester,
    ) async {
      final size = await pumpTitle(tester, 'Repertoire', 120);
      expect(size, lessThan(28));
      expect(size, greaterThanOrEqualTo(22));
      expect(tester.takeException(), isNull);
    });

    testWidgets('ellipsizes only below the 22 pt floor', (tester) async {
      final size = await pumpTitle(tester, 'Repertoire', 40);
      expect(size, 22);
      expect(
        tester.widget<Text>(find.text('Repertoire')).overflow,
        TextOverflow.ellipsis,
      );
    });
  });

  group('StageStatusPill', () {
    testWidgets('pings once when active and settles', (tester) async {
      await tester.pumpWidget(_host(const StageStatusPill(label: 'IDLE')));
      expect(find.byKey(const ValueKey('ping')), findsNothing);

      await tester.pumpWidget(
        _host(const StageStatusPill(label: 'SYNCED', active: true)),
      );
      expect(find.byKey(const ValueKey('ping')), findsOneWidget);
      await tester.pumpAndSettle(); // finite: no infinite pulse
      expect(find.text('SYNCED'), findsOneWidget);
    });
  });
}
