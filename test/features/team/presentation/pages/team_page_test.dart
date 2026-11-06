import 'package:battuta/features/team/domain/entities/team_member.dart';
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
    testWidgets('renders team roster, statistics, and filter chips',
        (tester) async {
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

      // Tap Sarah Jenkins (member-1) status badge to cycle Confirmed -> Unavailable
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

    testWidgets('edits an existing team member through dialog', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Tap Sarah Jenkins card to edit
      await tester.tap(find.text('Sarah Jenkins'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Team Member'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Sarah Jenkins'), findsOneWidget);

      // Edit name
      await tester.enterText(
        find.widgetWithText(TextField, 'Sarah Jenkins'),
        'Sarah Jenkins-Smith',
      );

      // Add Keys / Piano role (so she sings and plays piano)
      await tester.tap(find.byKey(ValueKey('role_chip_${TeamRole.keys.name}')));
      await tester.pumpAndSettle();

      // Tap Save Changes
      await tester.tap(find.byKey(const ValueKey('save_member_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Sarah Jenkins-Smith'), findsOneWidget);
      expect(find.text('Lead Vocalist'), findsWidgets);
      expect(find.text('Keys / Piano'), findsWidgets);
    });

    testWidgets(
        'automatically discards vocal tessitura when only instrument roles are selected',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Open Add dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // By default Keys (an instrument) is selected -> vocal range is discarded
      expect(find.byKey(const ValueKey('vocal_range_discarded_info')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('vocal_tessitura_dropdown')), findsNothing);

      // Select Lead Vocalist -> vocal tessitura becomes available
      await tester
          .tap(find.byKey(ValueKey('role_chip_${TeamRole.leadVocal.name}')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vocal_tessitura_dropdown')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('vocal_range_discarded_info')),
          findsNothing);

      // Deselect Lead Vocalist -> vocal tessitura is automatically discarded again
      await tester
          .tap(find.byKey(ValueKey('role_chip_${TeamRole.leadVocal.name}')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vocal_range_discarded_info')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('vocal_tessitura_dropdown')), findsNothing);
    });

    testWidgets(
        'supports adding multiple roles (pianist who is also a singer and guitarist)',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Open Add dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Full Name *'),
        'Jordan Blake',
      );

      // Keys is already selected, let's also select Lead Vocalist and Acoustic Guitar
      await tester
          .tap(find.byKey(ValueKey('role_chip_${TeamRole.leadVocal.name}')));
      await tester.pumpAndSettle();

      await tester.tap(
          find.byKey(ValueKey('role_chip_${TeamRole.acousticGuitar.name}')));
      await tester.pumpAndSettle();

      // Save new member
      await tester.tap(find.byKey(const ValueKey('add_member_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Jordan Blake'), findsOneWidget);
      // All three roles are displayed as badges for Jordan Blake
      expect(find.text('Keys / Piano'), findsWidgets);
      expect(find.text('Lead Vocalist'), findsWidgets);
      expect(find.text('Acoustic Guitar'), findsWidgets);
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

    testWidgets('switches to Band Calendar tab and renders periodic services',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Switch to Band Calendar tab
      await tester.tap(find.textContaining('Band Calendar'));
      await tester.pumpAndSettle();

      // Verify calendar sections and periodic events
      expect(find.textContaining('Periodic & Upcoming Services'), findsOneWidget);
      expect(find.text('Sunday Morning Worship'), findsWidgets);
      expect(find.text('Midweek Band Rehearsal'), findsOneWidget);
      expect(find.text('NEXT SERVICE'), findsOneWidget);
      expect(find.textContaining('Sarah Jenkins'), findsWidgets);
      expect(find.text('Auto-Sundays'), findsOneWidget);
    });

    testWidgets('adds a new service event in Band Calendar', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Switch to Band Calendar tab
      await tester.tap(find.textContaining('Band Calendar'));
      await tester.pumpAndSettle();

      // Tap New Service FAB
      await tester.tap(find.widgetWithText(FloatingActionButton, 'New Service'));
      await tester.pumpAndSettle();

      expect(find.text('Add Service / Rehearsal'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Sunday Morning Worship'),
        'Youth Worship Night',
      );

      await tester.tap(find.byKey(const ValueKey('add_service_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Youth Worship Night'), findsOneWidget);
    });

    testWidgets('auto-generates periodic upcoming Sundays', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Switch to Band Calendar tab
      await tester.tap(find.textContaining('Band Calendar'));
      await tester.pumpAndSettle();

      // Tap Auto-Sundays button
      await tester.tap(find.text('Auto-Sundays'));
      await tester.pumpAndSettle();

      expect(find.text('Auto-generated next 4 Sunday services!'), findsOneWidget);
    });
  });
}
