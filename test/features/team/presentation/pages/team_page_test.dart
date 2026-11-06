import 'package:battuta/features/team/presentation/pages/team_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject() {
    return const ProviderScope(
      child: MaterialApp(
        home: TeamPage(),
      ),
    );
  }

  group('TeamPage', () {
    testWidgets('renders team roster, statistics, and filter chips', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Worship Team & Band'), findsOneWidget);
      expect(find.text('Total Roster'), findsOneWidget);
      expect(find.text('Scheduled'), findsWidgets);
      expect(find.text('Available'), findsWidgets);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('David Chen'), findsOneWidget);
      expect(find.text('Marcus Miller'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('filters team members by category chips', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Tap Vocals filter
      await tester.tap(find.widgetWithText(FilterChip, 'Vocals'));
      await tester.pumpAndSettle();

      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('David Chen'), findsOneWidget); // tenor vocal
    });

    testWidgets('cycles availability status on tap', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Tap Sarah Jenkins (member-1) status badge to cycle Scheduled -> Unavailable
      await tester.tap(find.byKey(const ValueKey('member_status_member-1')));
      await tester.pumpAndSettle();

      expect(find.text('Unavailable'), findsWidgets);
    });

    testWidgets('adds new team member through dialog', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Team Member'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Full Name *'),
        'Grace Hopper',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Add Member'));
      await tester.pumpAndSettle();

      expect(find.text('Grace Hopper'), findsOneWidget);
    });

    testWidgets('renders team cards without overflow on narrow width screens',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
    });
  });
}
