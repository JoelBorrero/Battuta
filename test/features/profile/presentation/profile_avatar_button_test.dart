import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/profile/presentation/widgets/profile_avatar_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_repository.dart';
import '../../../support/fake_organization_repository.dart';
import '../../../support/profile_harness.dart';

void main() {
  group('initialsOf', () {
    test('takes the first letters of the first two words', () {
      expect(initialsOf('Maria Lopez'), 'ML');
      expect(initialsOf('maria'), 'M');
      expect(initialsOf('  ana  maria  lopez '), 'AM');
      expect(initialsOf('Álvaro Núñez'), 'ÁN');
      expect(initialsOf('   '), '?');
    });
  });

  Future<void> pump(WidgetTester tester, FakeAuthRepository auth) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      profileApp(
        auth: auth,
        organizations: FakeOrganizationRepository(),
        initialLocation: AppRoutes.initial,
        tab: const ProfileAvatarButton(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signed in: initials, 44 px target, opens the profile', (
    tester,
  ) async {
    await pump(
      tester,
      FakeAuthRepository(
        user: const AuthUser(id: 'u-me', email: 'maria@example.com'),
        profile: const UserProfile(
          id: 'u-me',
          username: 'maria_l',
          displayName: 'Maria Lopez',
        ),
      ),
    );

    expect(find.text('ML'), findsOneWidget);
    final size = tester.getSize(
      find.byKey(const ValueKey('profile_avatar_btn')),
    );
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));

    await tester.tap(find.byKey(const ValueKey('profile_avatar_btn')));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('maria@example.com'), findsOneWidget);
  });

  testWidgets('signed in without a profile: initials of the email', (
    tester,
  ) async {
    await pump(
      tester,
      FakeAuthRepository(
        user: const AuthUser(id: 'u-me', email: 'maria@example.com'),
      ),
    );

    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('signed out: person icon that opens the sign-in page', (
    tester,
  ) async {
    await pump(tester, FakeAuthRepository());

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('profile_avatar_btn')));
    await tester.pumpAndSettle();
    expect(find.text('sign in page'), findsOneWidget);
  });
}
