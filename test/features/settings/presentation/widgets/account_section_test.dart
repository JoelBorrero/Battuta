import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/auth/presentation/providers/account_notice_provider.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/settings/presentation/widgets/account_section.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Future<ProviderContainer> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AccountSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(AccountSection)),
    );
  }

  testWidgets('shows the profile: name, username and email', (tester) async {
    await pump(tester);

    expect(find.text('Maria Lopez'), findsOneWidget);
    expect(find.textContaining('@maria_l'), findsOneWidget);
    expect(find.textContaining('maria@example.com'), findsOneWidget);
  });

  testWidgets('signs out', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('account_sign_out_btn')));
    await tester.pumpAndSettle();

    expect(auth.calls, contains('signOut'));
    expect(find.byKey(const ValueKey('account_sign_out_btn')), findsNothing);
  });

  testWidgets('deactivating needs the typed username', (tester) async {
    final container = await pump(tester);

    await tester.tap(find.byKey(const ValueKey('account_deactivate_btn')));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate account?'), findsOneWidget);
    expect(find.textContaining('Type maria_l to confirm'), findsOneWidget);

    FilledButton confirm() => tester.widget<FilledButton>(
      find.byKey(const ValueKey('deactivate_confirm_btn')),
    );
    expect(confirm().onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('deactivate_confirm_field')),
      'wrong',
    );
    await tester.pump();
    expect(confirm().onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('deactivate_confirm_field')),
      'maria_l',
    );
    await tester.pump();
    expect(confirm().onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('deactivate_confirm_btn')));
    await tester.pumpAndSettle();

    expect(auth.deactivated, isTrue);
    expect(container.read(accountNoticeProvider), AccountNotice.deactivated);
  });

  testWidgets('cancelling the deactivation changes nothing', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('account_deactivate_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(auth.deactivated, isFalse);
    expect(auth.user, isNotNull);
  });

  testWidgets('a failed deactivation (offline) is reported', (tester) async {
    auth = _FailingDeactivation(auth.user, auth.profile);
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('account_deactivate_btn')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('deactivate_confirm_field')),
      'maria_l',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('deactivate_confirm_btn')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(auth.user, isNotNull);
  });

  testWidgets('signed out: offers sign in and create account', (tester) async {
    auth.user = null;
    await pump(tester);

    expect(find.byKey(const ValueKey('supabase_account_tile')), findsOneWidget);
    expect(find.byKey(const ValueKey('account_create_tile')), findsOneWidget);
    expect(find.byKey(const ValueKey('account_sign_out_btn')), findsNothing);
  });
}

class _FailingDeactivation extends FakeAuthRepository {
  _FailingDeactivation(AuthUser? user, UserProfile? profile)
    : super(user: user, profile: profile);

  @override
  Future<void> deactivateAccount() async => throw StateError('offline');
}
