import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/settings/presentation/widgets/account_section.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/fake_auth_repository.dart';

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

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Scaffold(body: AccountSection()),
              ),
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, _) => const Text('profile page'),
              ),
              GoRoute(
                path: AppRoutes.signIn,
                builder: (_, _) => const Text('sign in page'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the avatar, name and username', (tester) async {
    await pump(tester);

    expect(find.text('Maria Lopez'), findsOneWidget);
    expect(find.text('@maria_l'), findsOneWidget);
    expect(find.text('ML'), findsOneWidget);
  });

  testWidgets('the signed-in row opens the profile', (tester) async {
    await pump(tester);

    expect(find.byKey(const ValueKey('account_sign_out_btn')), findsNothing);
    expect(find.byKey(const ValueKey('account_deactivate_btn')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('supabase_account_tile')));
    await tester.pumpAndSettle();
    expect(find.text('profile page'), findsOneWidget);
  });

  testWidgets('signed out: offers sign in and create account', (tester) async {
    auth.user = null;
    await pump(tester);

    expect(find.byKey(const ValueKey('supabase_account_tile')), findsOneWidget);
    expect(find.byKey(const ValueKey('account_create_tile')), findsOneWidget);
    expect(find.byKey(const ValueKey('account_sign_out_btn')), findsNothing);
  });
}
