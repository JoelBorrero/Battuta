import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/features/team/presentation/pages/team_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject() {
    return const ProviderScope(child: MaterialApp(home: TeamPage()));
  }

  group('TeamPage', () {
    testWidgets('renders team roster, statistics, and filter chips', (
      tester,
    ) async {
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
        expect(
          find.byKey(const ValueKey('vocal_range_discarded_info')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('vocal_tessitura_dropdown')),
          findsNothing,
        );

        // Select Lead Vocalist -> vocal tessitura becomes available
        await tester.tap(
          find.byKey(ValueKey('role_chip_${TeamRole.leadVocal.name}')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('vocal_tessitura_dropdown')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('vocal_range_discarded_info')),
          findsNothing,
        );

        // Deselect Lead Vocalist -> vocal tessitura is automatically discarded again
        await tester.tap(
          find.byKey(ValueKey('role_chip_${TeamRole.leadVocal.name}')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('vocal_range_discarded_info')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('vocal_tessitura_dropdown')),
          findsNothing,
        );
      },
    );

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
        await tester.tap(
          find.byKey(ValueKey('role_chip_${TeamRole.leadVocal.name}')),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(ValueKey('role_chip_${TeamRole.acousticGuitar.name}')),
        );
        await tester.pumpAndSettle();

        // Save new member
        await tester.tap(find.byKey(const ValueKey('add_member_btn')));
        await tester.pumpAndSettle();

        expect(find.text('Jordan Blake'), findsOneWidget);
        // All three roles are displayed as badges for Jordan Blake
        expect(find.text('Keys / Piano'), findsWidgets);
        expect(find.text('Lead Vocalist'), findsWidgets);
        expect(find.text('Acoustic Guitar'), findsWidgets);
      },
    );

    testWidgets('renders team cards without overflow on narrow width screens', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
    });

    testWidgets('switches to Band Calendar tab and renders periodic services', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Switch to Band Calendar tab
      await tester.tap(find.textContaining('Band Calendar'));
      await tester.pumpAndSettle();

      // Verify calendar sections and periodic events
      expect(
        find.textContaining('Periodic & Upcoming Services'),
        findsOneWidget,
      );
      expect(find.text('Sunday Morning Worship'), findsWidgets);
      expect(find.text('Midweek Band Rehearsal'), findsWidgets);
      expect(find.text('NEXT SERVICE'), findsOneWidget);
      expect(find.textContaining('Sarah Jenkins'), findsWidgets);
      expect(find.text('Recurring Schedules'), findsOneWidget);
      expect(find.text('Auto-Sundays'), findsNothing);
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
      await tester.tap(
        find.widgetWithText(FloatingActionButton, 'New Service'),
      );
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

    testWidgets('manages single recurring instance: toggles active and changes lookahead count', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Switch to Band Calendar tab
      await tester.tap(find.textContaining('Band Calendar'));
      await tester.pumpAndSettle();

      // Tap Recurring Schedules button
      await tester.tap(find.byKey(const ValueKey('recurring_schedules_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Recurring Service Schedules'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('recurring_card_series-sunday-morning')),
        findsOneWidget,
      );

      // Toggle Sunday Morning Worship to Paused
      await tester.tap(
        find.byKey(const ValueKey('recurring_switch_series-sunday-morning')),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Schedule Paused — no occurrences generated'),
        findsOneWidget,
      );
    });

    testWidgets(
      'configures single recurring instance with cutoff date and lookahead',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 2048);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Switch to Band Calendar tab
        await tester.tap(find.textContaining('Band Calendar'));
        await tester.pumpAndSettle();

        // Tap Recurring Schedules button
        await tester.tap(find.byKey(const ValueKey('recurring_schedules_btn')));
        await tester.pumpAndSettle();

        expect(find.text('Recurring Service Schedules'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('lookahead_dropdown_series-sunday-morning')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('set_cutoff_btn_series-sunday-morning')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'schedules recurring series from Add Service dialog with occurrence selector',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 2048);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Switch to Band Calendar tab
        await tester.tap(find.textContaining('Band Calendar'));
        await tester.pumpAndSettle();

        // Tap New Service FAB
        await tester.tap(
          find.widgetWithText(FloatingActionButton, 'New Service'),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Sunday Morning Worship'),
          'First Sunday Prayer & Praise',
        );

        // Recurrence is already 'Every Sunday (Weekly)' by default -> series count dropdown should be visible
        expect(
          find.byKey(const ValueKey('series_count_dropdown')),
          findsOneWidget,
        );
        expect(find.text('Create Service'), findsOneWidget);

        // Select 6 occurrences
        await tester.tap(find.byKey(const ValueKey('series_count_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('6 occurrences (~1.5 months)').last);
        await tester.pumpAndSettle();

        expect(find.text('Create Series (6)'), findsOneWidget);

        // Tap Create Series
        await tester.tap(find.text('Create Series (6)'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'Configured recurring schedule for First Sunday Prayer & Praise (showing next 6 events)!',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'opens Assign Musician dialog on narrow 320px screen without RenderFlex overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Switch to Band Calendar tab
        await tester.tap(find.textContaining('Band Calendar'));
        await tester.pumpAndSettle();

        // Find the "Assign Musician" button and scroll to it
        final assignBtn = find.byKey(
          const ValueKey('assign_musician_btn_event-next-sunday'),
        );
        await tester.scrollUntilVisible(
          assignBtn,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(assignBtn);
        await tester.pumpAndSettle();

        // Verify the dialog is visible and zero layout exceptions occurred
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Assign Musician to'), findsOneWidget);
        expect(
          find.byType(DropdownButtonFormField<TeamMember>),
          findsOneWidget,
        );
        expect(find.byType(DropdownButtonFormField<TeamRole>), findsOneWidget);
        expect(
          find.byType(DropdownButtonFormField<AssignmentStatus>),
          findsOneWidget,
        );

        // Tap cancel to close dialog cleanly
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'shows admin badge on Sarah Jenkins and allows adding an Admin member',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 2048);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Admin badge should be visible for Sarah Jenkins (member-1)
        expect(
          find.byKey(const ValueKey('admin_badge_member-1')),
          findsOneWidget,
        );

        // Open Add Member dialog
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('member_admin_switch')),
          findsOneWidget,
        );

        // Fill form and toggle admin switch on
        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name *'),
          'Pastor Michael',
        );
        await tester.tap(find.byKey(const ValueKey('member_admin_switch')));
        await tester.pumpAndSettle();

        // Tap Add Member
        await tester.tap(find.widgetWithText(FilledButton, 'Add Member'));
        await tester.pumpAndSettle();

        expect(find.text('Pastor Michael'), findsOneWidget);
      },
    );

    testWidgets(
      'switches active user profile to non-admin and enforces musician view restrictions',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 2048);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Active profile button should be visible in AppBar
        expect(
          find.byKey(const ValueKey('active_user_switcher_btn')),
          findsOneWidget,
        );

        // Tap to open profile switcher modal
        await tester.tap(find.byKey(const ValueKey('active_user_switcher_btn')));
        await tester.pumpAndSettle();

        expect(find.text('Select Active User Profile'), findsOneWidget);

        // Switch to David Chen (member-2, non-admin)
        await tester.tap(find.byKey(const ValueKey('switch_user_member-2')));
        await tester.pumpAndSettle();

        // Non-admin mode: FloatingActionButton should be gone
        expect(find.byType(FloatingActionButton), findsNothing);

        // Switch to Band Calendar tab
        await tester.tap(find.textContaining('Band Calendar'));
        await tester.pumpAndSettle();

        // In non-admin mode: "Musician View" badge is shown, and "Auto-Sundays" / "Recurring Schedules" are not shown
        expect(find.text('Musician View'), findsOneWidget);
        expect(find.text('Auto-Sundays'), findsNothing);
        expect(find.text('Recurring Schedules'), findsNothing);
        expect(find.text('Assign Musician'), findsNothing);
      },
    );

    testWidgets(
      'replaces a musician who cannot attend using the replacement dialog',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 2048);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Switch to Band Calendar tab
        await tester.tap(find.textContaining('Band Calendar'));
        await tester.pumpAndSettle();

        // In the first event, tap David Chen's lineup chip to mark him unavailable
        final davidChip = find.byKey(
          const ValueKey('lineup_chip_event-next-sunday_member-2'),
        );
        expect(davidChip, findsOneWidget);
        await tester.tap(davidChip);
        await tester.pumpAndSettle();

        // Tap "Cannot Attend / Mark Unavailable"
        await tester.tap(find.text('Mark Unavailable / Cannot Attend'));
        await tester.pumpAndSettle();

        // Now the Replace button should appear for David Chen
        final replaceBtn = find.byKey(
          const ValueKey('replace_btn_event-next-sunday_member-2'),
        );
        expect(replaceBtn, findsOneWidget);

        // Tap Replace
        await tester.tap(replaceBtn);
        await tester.pumpAndSettle();

        expect(find.text('Assign Musician Replacement'), findsOneWidget);
        expect(find.textContaining('Cannot Attend: David Chen'), findsOneWidget);

        // Confirm replacement
        await tester.tap(find.byKey(const ValueKey('confirm_replacement_btn')));
        await tester.pumpAndSettle();

        // David Chen is replaced in lineup
        expect(
          find.byKey(const ValueKey('lineup_chip_event-next-sunday_member-2')),
          findsNothing,
        );
      },
    );

    testWidgets('filters roster by arrangement group filter chip', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Find group filter chips
      expect(
        find.byKey(const ValueKey('filter_chip_group_group-alpha')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('filter_chip_group_group-beta')),
        findsOneWidget,
      );

      // Scroll Group Beta filter into view and tap it
      final betaChip = find.byKey(const ValueKey('filter_chip_group_group-beta'));
      await tester.ensureVisible(betaChip);
      await tester.pumpAndSettle();
      await tester.tap(betaChip);
      await tester.pumpAndSettle();

      // Sarah Jenkins and Elena Rostova belong to Group Beta
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Elena Rostova'), findsOneWidget);
      // Marcus Miller does not belong to Group Beta
      expect(find.text('Marcus Miller'), findsNothing);
    });

    testWidgets('member belongs to multiple groups and displays badges', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Sarah Jenkins belongs to Group Alpha and Group Beta
      expect(
        find.byKey(const ValueKey('member_group_badge_member-1_group-alpha')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('member_group_badge_member-1_group-beta')),
        findsOneWidget,
      );
    });

    testWidgets('admin view displays alert banner and triggers find cover workflow', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Switch to Band Calendar tab
      await tester.tap(find.textContaining('Band Calendar'));
      await tester.pumpAndSettle();

      // In the first event, mark David Chen unavailable to trigger an alert
      final davidChip = find.byKey(
        const ValueKey('lineup_chip_event-next-sunday_member-2'),
      );
      await tester.tap(davidChip);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark Unavailable / Cannot Attend'));
      await tester.pumpAndSettle();

      // The AdminScheduleAlertsBanner should now be visible
      expect(
        find.textContaining('Scheduling Attention Needed'),
        findsOneWidget,
      );
      expect(find.textContaining("Can't attend — missing cover"), findsOneWidget);

      // Tap "Find Cover" button on the banner
      final findCoverBtn = find.byKey(
        const ValueKey('find_cover_btn_alert_event-next-sunday_member-2'),
      );
      expect(findCoverBtn, findsOneWidget);
      await tester.tap(findCoverBtn);
      await tester.pumpAndSettle();

      // Replacement dialog opens
      expect(find.text('Assign Musician Replacement'), findsOneWidget);
      expect(find.textContaining('Cannot Attend: David Chen'), findsOneWidget);

      // Confirm replacement
      await tester.tap(find.byKey(const ValueKey('confirm_replacement_btn')));
      await tester.pumpAndSettle();

      // David Chen was replaced and alert banner clears
      expect(
        find.byKey(const ValueKey('lineup_chip_event-next-sunday_member-2')),
        findsNothing,
      );
    });

    testWidgets('admin notification bell opens coverage alerts modal', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Switch to Band Calendar tab
      await tester.tap(find.textContaining('Band Calendar'));
      await tester.pumpAndSettle();

      // Mark David Chen as unavailable
      final davidChip = find.byKey(
        const ValueKey('lineup_chip_event-next-sunday_member-2'),
      );
      await tester.tap(davidChip);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Unavailable / Cannot Attend'));
      await tester.pumpAndSettle();

      // Admin notification bell icon should be present
      final bellBtn = find.byKey(const ValueKey('admin_alerts_bell_btn'));
      expect(bellBtn, findsOneWidget);

      // Tap the bell icon to open alerts modal
      await tester.tap(bellBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Coverage Alerts'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('modal_find_cover_btn_alert_event-next-sunday_member-2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('assigns group to upcoming service lineup', (tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Switch to Band Calendar tab
      await tester.tap(find.textContaining('Band Calendar'));
      await tester.pumpAndSettle();

      // Tap Assign Group on the first event
      final assignGroupBtn = find.byKey(
        const ValueKey('assign_group_btn_event-next-sunday'),
      );
      expect(assignGroupBtn, findsOneWidget);
      await tester.tap(assignGroupBtn);
      await tester.pumpAndSettle();

      expect(find.text('Assign Group to Service'), findsOneWidget);
      expect(find.text('Youth Band'), findsOneWidget);

      // Select Youth Band
      await tester.tap(
        find.byKey(const ValueKey('assign_group_item_group-gamma')),
      );
      await tester.pumpAndSettle();

      // Members of Youth Band (David Chen, Elena Rostova, James Wilson) assigned
      expect(find.textContaining('Assigned Youth Band'), findsOneWidget);
    });
  });
}
