import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/auth/presentation/providers/account_notice_provider.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_repository.dart';
import '../../../support/fake_organization_repository.dart';
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

  FakeOrganizationRepository repo() => FakeOrganizationRepository(
    organizations: [
      org('org-1', 'Grace Church'),
      org('org-2', 'Youth Band', role: OrganizationRole.member),
    ],
    members: [
      member(
        'm1',
        'u-me',
        'Maria Lopez',
        instruments: ['keys', 'leadVocal', 'theremin'],
      ),
      member(
        'm2',
        'u-me',
        'Maria Lopez',
        orgId: 'org-2',
        role: OrganizationRole.member,
      ),
      member('m3', 'u-other', 'Other Person'),
    ],
  );

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    FakeOrganizationRepository? organizations,
    double width = 800,
  }) async {
    tester.view.physicalSize = Size(width, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      profileApp(auth: auth, organizations: organizations ?? repo()),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(ProfilePage)));
  }

  Finder byKey(String key) => find.byKey(ValueKey(key));

  Future<void> openMenu(WidgetTester tester, String orgId) async {
    await tester.ensureVisible(byKey('profile_org_menu_$orgId'));
    await tester.tap(byKey('profile_org_menu_$orgId'));
    await tester.pumpAndSettle();
  }

  group('header', () {
    testWidgets('shows initials, name, username and email', (tester) async {
      await pump(tester);

      expect(find.text('ML'), findsOneWidget);
      expect(find.text('Maria Lopez'), findsOneWidget);
      expect(find.text('@maria_l'), findsOneWidget);
      expect(find.text('maria@example.com'), findsOneWidget);
    });

    testWidgets('without a loaded profile: falls back to the email, no edit', (
      tester,
    ) async {
      auth.profile = null;
      await pump(tester);

      expect(byKey('profile_name'), findsOneWidget);
      expect(
        tester.widget<Text>(byKey('profile_name')).data,
        'maria@example.com',
      );
      expect(byKey('profile_username'), findsNothing);
      expect(
        tester.widget<OutlinedButton>(byKey('profile_edit_btn')).onPressed,
        isNull,
      );
      expect(byKey('profile_edit_hint'), findsOneWidget);
    });
  });

  group('edit profile', () {
    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(byKey('profile_edit_btn'));
      await tester.pumpAndSettle();
    }

    testWidgets('saves the name and a free username, and the page updates', (
      tester,
    ) async {
      await pump(tester);
      await openSheet(tester);

      await tester.enterText(byKey('profile_name_field'), 'Maria L. Perez');
      await tester.enterText(byKey('profile_username_field'), 'Maria_P');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Username is available'), findsOneWidget);

      await tester.tap(byKey('profile_save_btn'));
      await tester.pumpAndSettle();

      expect(auth.calls, contains('updateProfile:Maria L. Perez:maria_p'));
      expect(byKey('profile_save_btn'), findsNothing);
      expect(find.text('Profile updated'), findsOneWidget);
      expect(find.text('Maria L. Perez'), findsOneWidget);
      expect(find.text('@maria_p'), findsOneWidget);
    });

    testWidgets('my current username counts as available (no lookup)', (
      tester,
    ) async {
      await pump(tester);
      await openSheet(tester);

      await tester.enterText(byKey('profile_username_field'), 'MARIA_L');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Username is available'), findsOneWidget);
      expect(auth.calls.where((c) => c.startsWith('available')), isEmpty);
    });

    testWidgets('a taken username is flagged live and cannot be saved', (
      tester,
    ) async {
      auth.takenUsernames = {'raul'};
      await pump(tester);
      await openSheet(tester);

      await tester.enterText(byKey('profile_username_field'), 'raul');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('That username is already taken.'), findsOneWidget);

      await tester.tap(byKey('profile_save_btn'));
      await tester.pumpAndSettle();
      expect(auth.calls.where((c) => c.startsWith('updateProfile')), isEmpty);
      expect(byKey('profile_save_btn'), findsOneWidget);
    });

    testWidgets('a unique violation on save shows on the field', (
      tester,
    ) async {
      auth.updateProfileError = BackendErrorCode.usernameTaken.failure();
      await pump(tester);
      await openSheet(tester);

      await tester.enterText(byKey('profile_username_field'), 'raul');
      await tester.tap(byKey('profile_save_btn'));
      await tester.pumpAndSettle();

      expect(find.text('That username is already taken.'), findsOneWidget);
      expect(byKey('profile_save_btn'), findsOneWidget);
    });

    testWidgets('offline keeps the form open with the offline message', (
      tester,
    ) async {
      auth.updateProfileError = BackendErrorCode.offline.failure();
      await pump(tester);
      await openSheet(tester);

      await tester.enterText(byKey('profile_name_field'), 'Maria Perez');
      await tester.tap(byKey('profile_save_btn'));
      await tester.pumpAndSettle();

      expect(byKey('profile_edit_error'), findsOneWidget);
      expect(find.textContaining('offline'), findsOneWidget);
      expect(byKey('profile_save_btn'), findsOneWidget);
      expect(find.text('Maria Lopez'), findsOneWidget);
    });

    testWidgets('rejects an empty name and a malformed username', (
      tester,
    ) async {
      await pump(tester);
      await openSheet(tester);

      await tester.enterText(byKey('profile_name_field'), '   ');
      await tester.tap(byKey('profile_save_btn'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a name of up to 80 characters.'), findsOneWidget);

      await tester.enterText(byKey('profile_name_field'), 'Maria');
      await tester.enterText(byKey('profile_username_field'), 'no');
      await tester.tap(byKey('profile_save_btn'));
      await tester.pumpAndSettle();
      expect(byKey('profile_edit_error'), findsOneWidget);
      expect(auth.calls.where((c) => c.startsWith('updateProfile')), isEmpty);
    });
  });

  group('my organizations', () {
    testWidgets('lists every organization with role and my instruments', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Grace Church'), findsOneWidget);
      expect(find.text('Youth Band'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Member'), findsOneWidget);
      // Known roles by short name, unknown instruments as stored.
      expect(find.text('Keys'), findsOneWidget);
      expect(find.text('Lead Vocals'), findsOneWidget);
      expect(find.text('theremin'), findsOneWidget);
      expect(find.text('No instruments yet'), findsOneWidget);
    });

    testWidgets('tapping a row makes it the active organization', (
      tester,
    ) async {
      await pump(tester);
      expect(byKey('profile_org_active_org-1'), findsOneWidget);

      await tester.tap(byKey('profile_org_org-2'));
      await tester.pumpAndSettle();

      expect(byKey('profile_org_active_org-2'), findsOneWidget);
      expect(byKey('profile_org_active_org-1'), findsNothing);
    });

    testWidgets('edit my instruments saves the chips and keeps unknown ones', (
      tester,
    ) async {
      final organizations = repo();
      await pump(tester, organizations: organizations);

      await openMenu(tester, 'org-1');
      await tester.tap(find.text('Edit my instruments'));
      await tester.pumpAndSettle();
      expect(find.text('My instruments in Grace Church'), findsOneWidget);

      await tester.tap(byKey('instrument_chip_keys'));
      await tester.tap(byKey('instrument_chip_drums'));
      await tester.tap(byKey('instruments_save_btn'));
      await tester.pumpAndSettle();

      expect(
        organizations.calls,
        contains(
          'updateMusicianProfile:m1:leadVocal,drums,theremin:null:null:null',
        ),
      );
      expect(find.text('Instruments updated'), findsOneWidget);
      expect(find.text('Drums'), findsOneWidget);
      expect(find.text('Keys'), findsNothing);
    });

    testWidgets('a failed instruments save keeps the sheet open', (
      tester,
    ) async {
      final organizations = repo();
      await pump(tester, organizations: organizations);

      await openMenu(tester, 'org-1');
      await tester.tap(find.text('Edit my instruments'));
      await tester.pumpAndSettle();
      organizations.nextFailure = BackendErrorCode.offline.failure();
      await tester.tap(byKey('instruments_save_btn'));
      await tester.pumpAndSettle();

      expect(byKey('instruments_error'), findsOneWidget);
      expect(byKey('instruments_save_btn'), findsOneWidget);
    });

    testWidgets('admins open the organization settings and cannot leave', (
      tester,
    ) async {
      await pump(tester);

      await openMenu(tester, 'org-1');
      expect(byKey('profile_leave_hint_org-1'), findsOneWidget);
      await tester.tap(find.text('Leave organization'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(byKey('confirm_leave_org_btn'), findsNothing);

      await tester.tap(find.text('Organization settings'));
      await tester.pumpAndSettle();
      expect(find.text('settings of org-1'), findsOneWidget);
    });

    testWidgets('members have no organization settings item', (tester) async {
      await pump(tester);

      await openMenu(tester, 'org-2');
      expect(find.text('Organization settings'), findsNothing);
      expect(byKey('profile_leave_hint_org-2'), findsNothing);
    });

    testWidgets('a member leaves after confirming', (tester) async {
      final organizations = repo();
      await pump(tester, organizations: organizations);

      await openMenu(tester, 'org-2');
      await tester.tap(find.text('Leave organization'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('confirm_leave_org_btn'));
      await tester.pumpAndSettle();

      expect(organizations.calls, contains('leaveOrganization:org-2'));
      expect(find.text('Youth Band'), findsNothing);
      expect(find.text('Grace Church'), findsOneWidget);
    });

    testWidgets('cancelling the leave changes nothing', (tester) async {
      final organizations = repo();
      await pump(tester, organizations: organizations);

      await openMenu(tester, 'org-2');
      await tester.tap(find.text('Leave organization'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(organizations.calls, isEmpty);
      expect(find.text('Youth Band'), findsOneWidget);
    });

    testWidgets('a failed leave (offline) is reported', (tester) async {
      final organizations = repo();
      await pump(tester, organizations: organizations);

      await openMenu(tester, 'org-2');
      await tester.tap(find.text('Leave organization'));
      await tester.pumpAndSettle();
      organizations.nextFailure = BackendErrorCode.offline.failure();
      await tester.tap(byKey('confirm_leave_org_btn'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Youth Band'), findsOneWidget);
    });

    testWidgets('an organization that disappears leaves the list', (
      tester,
    ) async {
      final organizations = repo();
      await pump(tester, organizations: organizations);

      await organizations.leaveOrganization('org-2');
      await tester.pumpAndSettle();

      expect(find.text('Youth Band'), findsNothing);
    });

    testWidgets('no organizations: empty state with the join action', (
      tester,
    ) async {
      await pump(tester, organizations: FakeOrganizationRepository());

      expect(byKey('profile_no_organizations'), findsOneWidget);
      expect(find.text('No organization yet'), findsOneWidget);
      expect(byKey('profile_join_org_btn'), findsOneWidget);
    });
  });

  group('account actions', () {
    testWidgets('sign out ends the session and returns to the app', (
      tester,
    ) async {
      await pump(tester);

      await tester.ensureVisible(byKey('profile_sign_out_btn'));
      await tester.tap(byKey('profile_sign_out_btn'));
      await tester.pumpAndSettle();

      expect(auth.calls, contains('signOut'));
      expect(find.text('tab page'), findsOneWidget);
      expect(byKey('profile_sign_out_btn'), findsNothing);
    });

    Future<void> startDeactivation(WidgetTester tester) async {
      await tester.tap(byKey('profile_menu_btn'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('profile_deactivate_item'));
      await tester.pumpAndSettle();
    }

    testWidgets('deactivating needs the typed username', (tester) async {
      final container = await pump(tester);

      await startDeactivation(tester);
      expect(find.text('Deactivate account?'), findsOneWidget);
      expect(find.textContaining('Type maria_l to confirm'), findsOneWidget);

      FilledButton confirm() =>
          tester.widget<FilledButton>(byKey('deactivate_confirm_btn'));
      expect(confirm().onPressed, isNull);

      await tester.enterText(byKey('deactivate_confirm_field'), 'wrong');
      await tester.pump();
      expect(confirm().onPressed, isNull);

      await tester.enterText(byKey('deactivate_confirm_field'), 'maria_l');
      await tester.pump();
      expect(confirm().onPressed, isNotNull);

      await tester.tap(byKey('deactivate_confirm_btn'));
      await tester.pumpAndSettle();

      expect(auth.deactivated, isTrue);
      expect(container.read(accountNoticeProvider), AccountNotice.deactivated);
    });

    testWidgets('cancelling the deactivation changes nothing', (tester) async {
      await pump(tester);

      await startDeactivation(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(auth.deactivated, isFalse);
      expect(auth.user, isNotNull);
    });

    testWidgets('a failed deactivation (offline) is reported', (tester) async {
      auth = _FailingDeactivation(auth.user, auth.profile);
      await pump(tester);

      await startDeactivation(tester);
      await tester.enterText(byKey('deactivate_confirm_field'), 'maria_l');
      await tester.pump();
      await tester.tap(byKey('deactivate_confirm_btn'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(auth.user, isNotNull);
    });

    testWidgets('does not crash when the user disappears', (tester) async {
      await pump(tester);

      auth.emit(null);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

class _FailingDeactivation extends FakeAuthRepository {
  _FailingDeactivation(AuthUser? user, UserProfile? profile)
    : super(user: user, profile: profile);

  @override
  Future<void> deactivateAccount() async => throw StateError('offline');
}
