import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/organizations/presentation/pages/organization_profile_page.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/profile/presentation/providers/photo_providers.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:battuta/features/team/presentation/providers/team_tab_request_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_repository.dart';
import '../../../support/fake_organization_repository.dart';
import '../../../support/fake_profile_image_picker.dart';
import '../../../support/fake_schedule_repository.dart';
import '../../../support/profile_harness.dart';
import '../../../support/team_fixtures.dart';

void main() {
  late FakeAuthRepository auth;

  setUp(() {
    auth = FakeAuthRepository(
      user: const AuthUser(id: 'u-me', email: 'maria@example.com'),
      profile: const UserProfile(
        id: 'u-me',
        username: 'maria_l',
        displayName: 'Maria Lopez',
      ),
    );
  });

  FakeOrganizationRepository repo({
    String? description = 'Sunday services and youth nights.',
    String? logoPath,
  }) => FakeOrganizationRepository(
    organizations: [
      org(
        'org-1',
        'Grace Church',
        description: description,
        logoPath: logoPath,
      ),
      org('org-2', 'Youth Band', role: OrganizationRole.member),
    ],
    members: [
      member(
        'm1',
        'u-me',
        'Maria Lopez',
        role: OrganizationRole.admin,
        instruments: ['keys', 'leadVocal'],
      ),
      member('m2', 'u-2', 'Daniel Ruiz', role: OrganizationRole.admin),
      member('m3', 'u-3', 'Ana Sanchez', instruments: ['bass']),
      member('m4', 'u-4', 'Pablo Garcia', deactivatedAt: DateTime(2026, 1, 1)),
      member('m5', 'u-5', 'Zoe Zimmer'),
      member('m6', 'u-me', 'Maria Lopez', orgId: 'org-2'),
    ],
    bands: const [
      Band(
        id: 'b1',
        organizationId: 'org-1',
        name: 'Main band',
        colorValue: 0xFFE5A93C,
      ),
      Band(
        id: 'b2',
        organizationId: 'org-1',
        name: 'Youth night',
        colorValue: 0xFF42A5F5,
      ),
    ],
  );

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    FakeOrganizationRepository? organizations,
    String orgId = 'org-1',
    List<Override> overrides = const [],
    FakeScheduleRepository? schedules,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      profileApp(
        auth: auth,
        organizations: organizations ?? repo(),
        initialLocation: AppRoutes.organization(orgId),
        schedules: schedules,
        overrides: overrides,
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(OrganizationProfilePage)),
    );
  }

  Finder byKey(String key) => find.byKey(ValueKey(key));

  group('as an admin', () {
    testWidgets('header: name, badge, description and admin controls', (
      tester,
    ) async {
      await pump(tester);

      expect(
        tester.widget<Text>(byKey('org_profile_name')).data,
        'Grace Church',
      );
      expect(find.text('YOU ARE ADMIN'), findsOneWidget);
      expect(find.text('Sunday services and youth nights.'), findsOneWidget);
      expect(byKey('org_profile_logo_btn'), findsOneWidget);
      expect(byKey('org_profile_invite_btn'), findsOneWidget);
      expect(byKey('org_profile_edit_btn'), findsOneWidget);
      expect(byKey('org_profile_manage_bands'), findsOneWidget);
    });

    testWidgets('stat tiles count active members, bands and songs', (
      tester,
    ) async {
      await pump(tester);

      String valueOf(String key) => tester
          .widget<Text>(
            find.descendant(of: byKey(key), matching: find.byType(Text)).first,
          )
          .data!;
      // Four active members (Pablo is deactivated), two bands, no songs.
      expect(valueOf('org_profile_stat_members'), '4');
      expect(valueOf('org_profile_stat_bands'), '2');
      expect(valueOf('org_profile_stat_songs'), '0');
    });

    testWidgets('bands show as chips', (tester) async {
      await pump(tester);

      expect(find.text('Main band'), findsOneWidget);
      expect(find.text('Youth night'), findsOneWidget);
    });

    testWidgets('members preview: 4 rows, admins first, see all N', (
      tester,
    ) async {
      await pump(tester);

      expect(
        find.byKey(const ValueKey('org_profile_member_m1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('org_profile_member_m2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('org_profile_member_m3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('org_profile_member_m5')),
        findsOneWidget,
      );
      // The deactivated member is the fifth by order, so it is cut off.
      expect(find.byKey(const ValueKey('org_profile_member_m4')), findsNothing);
      expect(find.text('Keys / Piano · Lead Vocalist'), findsOneWidget);
      expect(find.text('See all 4'), findsOneWidget);
    });

    testWidgets('a deactivated member is greyed with its own detail', (
      tester,
    ) async {
      final organizations = FakeOrganizationRepository(
        organizations: [org('org-1', 'Grace Church')],
        members: [
          member('m1', 'u-me', 'Maria Lopez', role: OrganizationRole.admin),
          member('m4', 'u-4', 'Pablo Garcia', deactivatedAt: DateTime(2026)),
        ],
      );
      await pump(tester, organizations: organizations);

      expect(find.text('Account deactivated'), findsOneWidget);
      expect(find.text('PG'), findsOneWidget);
    });

    testWidgets('no upcoming service shows the empty state', (tester) async {
      await pump(tester);
      expect(byKey('org_profile_no_upcoming'), findsOneWidget);
      expect(find.text('No upcoming services'), findsOneWidget);
    });

    testWidgets('next up shows the next service of this organization', (
      tester,
    ) async {
      final schedules = FakeScheduleRepository(
        events: [
          CalendarEvent(
            id: 'evt-1',
            organizationId: 'org-1',
            title: 'Sunday service',
            dateTime: DateTime(2026, 11, 15, 10),
            bandId: 'b1',
          ),
          CalendarEvent(
            id: 'evt-0',
            organizationId: 'org-1',
            title: 'Past rehearsal',
            dateTime: DateTime(2026, 11, 1, 10),
          ),
        ],
      );
      await pump(
        tester,
        schedules: schedules,
        overrides: [
          calendarClockProvider.overrideWithValue(() => DateTime(2026, 11, 11)),
        ],
      );

      expect(byKey('org_profile_next_up'), findsOneWidget);
      expect(find.text('Sunday service'), findsOneWidget);
      expect(find.text('10:00 · Main band'), findsOneWidget);
      expect(find.text('SUN'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Past rehearsal'), findsNothing);
    });

    testWidgets('see all opens the team roster on this organization', (
      tester,
    ) async {
      final container = await pump(tester, orgId: 'org-1');
      await container
          .read(activeOrganizationSelectionProvider.notifier)
          .select('org-2');

      await tester.ensureVisible(byKey('org_profile_see_all'));
      await tester.tap(byKey('org_profile_see_all'));
      await tester.pumpAndSettle();

      expect(find.text('team page'), findsOneWidget);
      expect(container.read(activeOrganizationProvider)?.id, 'org-1');
      expect(container.read(teamTabRequestProvider), TeamTab.roster);
    });

    testWidgets('the gear opens the organization settings', (tester) async {
      await pump(tester);

      await tester.tap(byKey('org_profile_settings_btn'));
      await tester.pumpAndSettle();

      expect(find.text('settings of org-1'), findsOneWidget);
    });

    testWidgets('no description: admins get a hint, members nothing', (
      tester,
    ) async {
      await pump(tester, organizations: repo(description: null));
      expect(byKey('org_profile_description_hint'), findsOneWidget);
      expect(find.text('Add a description'), findsOneWidget);
    });
  });

  group('edit organization profile', () {
    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(byKey('org_profile_edit_btn'));
      await tester.pumpAndSettle();
    }

    testWidgets('saves a new name and description', (tester) async {
      final organizations = repo();
      await pump(tester, organizations: organizations);

      await openSheet(tester);
      await tester.enterText(byKey('org_profile_name_field'), 'Grace Valley');
      await tester.enterText(
        byKey('org_profile_description_field'),
        '  Thursdays at 7 pm  ',
      );
      await tester.tap(byKey('org_profile_save_btn'));
      await tester.pumpAndSettle();

      expect(
        organizations.calls,
        contains(
          'updateOrganizationProfile:org-1:Grace Valley:  Thursdays at 7 pm  ',
        ),
      );
      expect(
        tester.widget<Text>(byKey('org_profile_name')).data,
        'Grace Valley',
      );
      expect(find.text('Thursdays at 7 pm'), findsOneWidget);
      expect(find.text('Organization updated'), findsOneWidget);
    });

    testWidgets('a blank name is refused before any call', (tester) async {
      final organizations = repo();
      await pump(tester, organizations: organizations);

      await openSheet(tester);
      await tester.enterText(byKey('org_profile_name_field'), '   ');
      await tester.tap(byKey('org_profile_save_btn'));
      await tester.pumpAndSettle();

      expect(organizations.calls, isEmpty);
      expect(byKey('org_profile_save_btn'), findsOneWidget);
    });

    testWidgets('the description is limited to 280 characters', (tester) async {
      await pump(tester);
      await openSheet(tester);

      await tester.enterText(byKey('org_profile_description_field'), 'x' * 400);
      await tester.pump();

      final field = tester.widget<TextField>(
        byKey('org_profile_description_field'),
      );
      expect(field.controller!.text.length, 280);
      expect(find.text('280/280'), findsOneWidget);
    });

    testWidgets('a failed save keeps the sheet with the message', (
      tester,
    ) async {
      final organizations = repo();
      await pump(tester, organizations: organizations);

      await openSheet(tester);
      organizations.nextFailure = BackendErrorCode.offline.failure();
      await tester.tap(byKey('org_profile_save_btn'));
      await tester.pumpAndSettle();

      expect(byKey('org_profile_error'), findsOneWidget);
      expect(byKey('org_profile_save_btn'), findsOneWidget);
    });
  });

  group('organization logo', () {
    late FakePicker picker;

    setUp(() => picker = FakePicker()..result = pixel);

    List<Override> pickerOverride() => [
      profileImagePickerProvider.overrideWithValue(picker),
    ];

    testWidgets('an admin picks, saves and the page shows the new logo', (
      tester,
    ) async {
      final organizations = repo();
      await pump(
        tester,
        organizations: organizations,
        overrides: pickerOverride(),
      );

      await tester.tap(byKey('org_profile_logo_btn'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('photo_choose_btn'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('photo_save_btn'));
      await tester.pumpAndSettle();

      expect(
        organizations.calls,
        contains('setOrganizationLogo:org-1:${pixel.length}'),
      );
      expect(find.text('Photo updated'), findsOneWidget);
      expect(
        tester.widget<Text>(byKey('org_profile_name')).data,
        'Grace Church',
      );
    });

    testWidgets('remove clears the logo', (tester) async {
      final organizations = repo(logoPath: 'org-1/old.jpg');
      await pump(
        tester,
        organizations: organizations,
        overrides: pickerOverride(),
      );

      await tester.tap(byKey('org_profile_logo_btn'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('photo_remove_btn'));
      await tester.pumpAndSettle();

      expect(organizations.calls, contains('removeOrganizationLogo:org-1'));
      expect(find.text('Photo removed'), findsOneWidget);
    });

    testWidgets('losing admin rights mid-way shows the refusal', (
      tester,
    ) async {
      final organizations = repo();
      await pump(
        tester,
        organizations: organizations,
        overrides: pickerOverride(),
      );

      await tester.tap(byKey('org_profile_logo_btn'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('photo_choose_btn'));
      await tester.pumpAndSettle();
      organizations.nextFailure = BackendErrorCode.notAdmin.failure();
      await tester.tap(byKey('photo_save_btn'));
      await tester.pumpAndSettle();

      expect(byKey('photo_sheet_error'), findsOneWidget);
      expect(find.text('Photo updated'), findsNothing);
    });

    testWidgets('offline upload shows the offline message', (tester) async {
      final organizations = repo()..offline = true;
      await pump(
        tester,
        organizations: organizations,
        overrides: pickerOverride(),
      );

      await tester.tap(byKey('org_profile_logo_btn'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('photo_choose_btn'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('photo_save_btn'));
      await tester.pumpAndSettle();

      expect(byKey('photo_sheet_error'), findsOneWidget);
    });
  });

  group('as a member', () {
    testWidgets('no camera, badge, invite, edit or manage controls', (
      tester,
    ) async {
      await pump(tester, orgId: 'org-2');

      expect(tester.widget<Text>(byKey('org_profile_name')).data, 'Youth Band');
      expect(byKey('org_profile_logo_btn'), findsNothing);
      expect(byKey('org_profile_admin_badge'), findsNothing);
      expect(byKey('org_profile_invite_btn'), findsNothing);
      expect(byKey('org_profile_edit_btn'), findsNothing);
      expect(byKey('org_profile_manage_bands'), findsNothing);
      expect(byKey('org_profile_description_hint'), findsNothing);
      // Still reads fine with no bands, a single member and no events.
      expect(find.text('No bands yet'), findsOneWidget);
      expect(find.text('See all 1'), findsOneWidget);
      expect(find.text('No upcoming services'), findsOneWidget);
    });
  });

  testWidgets('an organization that is not mine says so', (tester) async {
    await pump(tester, orgId: 'org-404');
    expect(byKey('org_profile_not_found'), findsOneWidget);
  });

  testWidgets('an organization that disappears shows the same message', (
    tester,
  ) async {
    final organizations = repo();
    await pump(tester, organizations: organizations, orgId: 'org-2');
    await organizations.leaveOrganization('org-2');
    await tester.pumpAndSettle();
    expect(byKey('org_profile_not_found'), findsOneWidget);
  });

  testWidgets('very long name and description do not overflow at 320 px', (
    tester,
  ) async {
    final organizations = FakeOrganizationRepository(
      organizations: [
        org(
          'org-1',
          'An extraordinarily long organization name ' * 4,
          description: 'A very long description that keeps going. ' * 12,
        ),
      ],
      members: [
        member(
          'm1',
          'u-me',
          'Member With An Extremely Long Display Name Indeed',
          role: OrganizationRole.admin,
          instruments: ['keys', 'leadVocal', 'acousticGuitar', 'drums'],
        ),
      ],
      bands: const [
        Band(
          id: 'b1',
          organizationId: 'org-1',
          name: 'A band with a really long name that must not overflow',
        ),
      ],
    );
    await pump(tester, organizations: organizations, width: 320);
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('camera button is at least 44 px', (tester) async {
    await pump(tester);
    final size = tester.getSize(byKey('org_profile_logo_btn'));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });
}
