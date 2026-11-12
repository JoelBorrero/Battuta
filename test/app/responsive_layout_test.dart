import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/auth/presentation/pages/create_account_page.dart';
import 'package:battuta/features/auth/presentation/pages/sign_in_page.dart';
import 'package:battuta/features/auth/presentation/pages/welcome_page.dart';
import 'package:battuta/features/auth/presentation/providers/app_entry_provider.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/settings/presentation/pages/settings_page.dart';
import 'package:battuta/features/team/presentation/pages/team_page.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/app_harness.dart';
import '../support/fake_auth_repository.dart';
import '../support/fake_organization_repository.dart';
import '../support/memory_storage.dart';
import '../support/profile_harness.dart';
import '../support/team_fixtures.dart';

/// No RenderFlex overflow from iPhone width to a desktop window.
void main() {
  const widths = [320.0, 375.0, 768.0, 1024.0, 1440.0];

  FakeOrganizationRepository richRepo() => FakeOrganizationRepository(
    organizations: [
      for (var i = 0; i < 8; i++)
        org(
          'org-$i',
          'A rather long organization name for the switcher, number $i',
          role: i.isEven ? OrganizationRole.admin : OrganizationRole.member,
        ),
    ],
    members: [
      for (var i = 0; i < 6; i++)
        member(
          'm$i',
          i == 0 ? 'u-me' : 'u$i',
          'Member With A Very Long Display Name Number $i',
          orgId: 'org-0',
          role: i == 0 ? OrganizationRole.admin : OrganizationRole.member,
          instruments: ['keys', 'leadVocal', 'acousticGuitar', 'drums'],
          minPitch: 'C4',
          maxPitch: 'A5',
          notes: 'Some long notes about the player ' * 4,
        ),
    ],
    bands: [
      for (var i = 0; i < 5; i++)
        Band(
          id: 'b$i',
          organizationId: 'org-0',
          name: 'Band number $i with a long name',
        ),
    ],
    bandMembers: const [
      BandMember(
        id: 'bm',
        organizationId: 'org-0',
        bandId: 'b0',
        memberId: 'm1',
      ),
    ],
  );

  Widget localized(Widget home, {List<Override> overrides = const []}) =>
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  Widget routed(Widget home, {List<Override> overrides = const []}) =>
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => home),
              GoRoute(
                path: AppRoutes.signIn,
                builder: (_, _) => const SignInPage(),
              ),
            ],
          ),
        ),
      );

  Future<void> at(
    WidgetTester tester,
    double width,
    Widget widget, {
    double height = 900,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    // A fresh provider scope for every screen.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  for (final width in widths) {
    group('at ${width.toInt()} px', () {
      testWidgets('welcome, sign in and create account', (tester) async {
        for (final page in const [
          WelcomePage(),
          SignInPage(),
          CreateAccountPage(),
        ]) {
          await at(tester, width, routed(page));
          expect(tester.takeException(), isNull, reason: '$page');
        }
      });

      testWidgets('create account with keyboard-sized viewport', (
        tester,
      ) async {
        await at(tester, width, routed(const CreateAccountPage()), height: 420);
        expect(tester.takeException(), isNull);
      });

      testWidgets('roster, switcher and member dialog', (tester) async {
        await at(
          tester,
          width,
          localized(const TeamPage(), overrides: signedInOverrides(richRepo())),
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const ValueKey('org_switcher_btn')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('member_card_m1')),
          200,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('member_card_m1')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('member_card_m1')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('manage_bands_btn')),
          -200,
        );
        await tester.tap(find.byKey(const ValueKey('manage_bands_btn')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('roster empty states', (tester) async {
        await at(tester, width, localized(const TeamPage()));
        expect(tester.takeException(), isNull);
        await at(
          tester,
          width,
          localized(
            const TeamPage(),
            overrides: signedInOverrides(FakeOrganizationRepository()),
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('profile page with many long organizations', (tester) async {
        final repository = richRepo();
        await at(
          tester,
          width,
          profileApp(
            auth: FakeAuthRepository(
              user: const AuthUser(
                id: 'u-me',
                email: 'a.very.long.email.address.for.layout@example.com',
              ),
              profile: const UserProfile(
                id: 'u-me',
                username: 'a_very_long_username_for_layout',
                displayName: 'A Very Long Display Name For The Layout Test',
              ),
            ),
            organizations: repository,
          ),
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const ValueKey('profile_edit_btn')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const ValueKey('profile_org_menu_org-0')),
        );
        await tester.tap(find.byKey(const ValueKey('profile_org_menu_org-0')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Organization settings'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('tab app bars with the avatar, signed in and local', (
        tester,
      ) async {
        final signedIn = AppHarness(
          auth: FakeAuthRepository(
            user: const AuthUser(id: 'u-me', email: 'me@example.com'),
            profile: const UserProfile(
              id: 'u-me',
              username: 'a_very_long_username_for_layout',
              displayName: 'A Very Long Display Name For The Layout Test',
            ),
          ),
          organizations: richRepo(),
        );
        addTearDown(signedIn.dispose);
        await at(tester, width, signedIn.build(), height: 900);
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('profile_avatar_btn')),
          findsOneWidget,
        );

        final local = AppHarness(
          entryStorage: MemoryStorage({
            AppEntryStorageKeys.continueOffline: 'true',
          }),
        );
        addTearDown(local.dispose);
        await at(tester, width, local.build(), height: 900);
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('profile_avatar_btn')),
          findsOneWidget,
        );
      });

      testWidgets('settings signed out and signed in', (tester) async {
        await at(tester, width, routed(const SettingsPage()));
        expect(tester.takeException(), isNull);

        await at(
          tester,
          width,
          routed(
            const SettingsPage(),
            overrides: [
              authRepositoryProvider.overrideWithValue(
                FakeAuthRepository(
                  user: const AuthUser(
                    id: 'u-me',
                    email: 'a.very.long.email.address.for.layout@example.com',
                    displayName: 'A Very Long Display Name For The Layout Test',
                  ),
                ),
              ),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('the whole app at the narrowest split view', (tester) async {
    final harness = AppHarness();
    addTearDown(harness.dispose);
    await at(tester, 320, harness.build(), height: 640);
    expect(tester.takeException(), isNull);
  });
}
