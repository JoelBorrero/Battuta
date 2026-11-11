import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/routes/app_router.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/presentation/pages/create_account_page.dart';
import 'package:battuta/features/auth/presentation/pages/sign_in_page.dart';
import 'package:battuta/features/auth/presentation/providers/account_notice_provider.dart';
import 'package:battuta/features/auth/presentation/providers/app_entry_provider.dart';
import 'package:battuta/features/repertoire/presentation/pages/repertoire_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_auth_repository.dart';
import '../../../support/memory_storage.dart';

void main() {
  late AppHarness harness;

  setUp(() => harness = AppHarness());
  tearDown(() => harness.dispose());

  Future<void> pumpApp(WidgetTester tester, [AppHarness? h]) async {
    tester.view.physicalSize = const Size(1024, 2048);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget((h ?? harness).build());
    await tester.pumpAndSettle();
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  testWidgets('first launch shows the welcome screen, not the app', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Welcome to Battuta'), findsOneWidget);
    expect(find.byKey(const ValueKey('welcome_sign_in_btn')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('welcome_create_account_btn')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('welcome_continue_offline_btn')),
      findsOneWidget,
    );
    expect(find.byType(RepertoirePage), findsNothing);
  });

  testWidgets('sign in with email and password lands in the app', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('welcome_sign_in_btn')));
    await tester.pumpAndSettle();
    expect(find.byType(BattutaWordmark), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('auth_email_field')),
      'me@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth_password_field')),
      'secret123',
    );
    await tester.tap(find.byKey(const ValueKey('auth_submit_btn')));
    await tester.pumpAndSettle();

    expect(harness.auth.calls, contains('signIn:me@example.com'));
    expect(find.byType(RepertoirePage), findsOneWidget);
    expect(find.text('Welcome to Battuta'), findsNothing);
  });

  testWidgets('signing in starts the data layer and the song sync', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('welcome_sign_in_btn')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('auth_email_field')),
      'me@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth_password_field')),
      'secret123',
    );
    await tester.tap(find.byKey(const ValueKey('auth_submit_btn')));
    await tester.pumpAndSettle();

    expect(harness.coordinator.starts, 1);
    expect(harness.cloudSync.syncs, 1);
  });

  testWidgets('an unexpected sign-in error shows a generic message and stays', (
    tester,
  ) async {
    harness.auth.signInError = Exception('x');
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('welcome_sign_in_btn')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('auth_email_field')),
      'me@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth_password_field')),
      'secret123',
    );
    await tester.tap(find.byKey(const ValueKey('auth_submit_btn')));
    await tester.pumpAndSettle();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(RepertoirePage), findsNothing);
  });

  testWidgets('sign in validates the email and password locally', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('welcome_sign_in_btn')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('auth_submit_btn')));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a valid email address.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('auth_email_field')),
      'me@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('auth_submit_btn')));
    await tester.pumpAndSettle();
    expect(
      find.text('Password must be at least 6 characters.'),
      findsOneWidget,
    );
    expect(harness.auth.calls, isEmpty);
  });

  testWidgets('a deactivated account cannot sign in and is told why', (
    tester,
  ) async {
    harness.auth.signInError = BackendErrorCode.accountDeactivated.failure();
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('welcome_sign_in_btn')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('auth_email_field')),
      'me@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth_password_field')),
      'secret123',
    );
    await tester.tap(find.byKey(const ValueKey('auth_submit_btn')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This account was deactivated and signed out. Its history is kept.',
      ),
      findsOneWidget,
    );
    expect(find.byType(RepertoirePage), findsNothing);
  });

  group('create account', () {
    Future<void> openCreate(WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(
        find.byKey(const ValueKey('welcome_create_account_btn')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BattutaWordmark), findsOneWidget);
    }

    Future<void> typeUsername(WidgetTester tester, String value) async {
      await tester.enterText(
        find.byKey(const ValueKey('auth_username_field')),
        value,
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }

    testWidgets('an invalid username is flagged without a request', (
      tester,
    ) async {
      await openCreate(tester);
      await typeUsername(tester, 'a b');

      expect(
        find.text('Use 3-30 characters: letters, numbers, _ or .'),
        findsOneWidget,
      );
      expect(
        harness.auth.calls.where((c) => c.startsWith('available')),
        isEmpty,
      );
    });

    testWidgets('a taken username says so while typing', (tester) async {
      harness.auth.takenUsernames = {'maria'};
      await openCreate(tester);
      await typeUsername(tester, 'Maria');

      expect(find.text('Username is already taken'), findsOneWidget);
      expect(harness.auth.calls, contains('available:maria'));
    });

    testWidgets('an available username is confirmed', (tester) async {
      await openCreate(tester);
      await typeUsername(tester, 'maria_l');

      expect(find.text('Username is available'), findsOneWidget);
    });

    testWidgets('creating the account signs in and enters the app', (
      tester,
    ) async {
      await openCreate(tester);
      await tester.enterText(
        find.byKey(const ValueKey('auth_name_field')),
        'Maria Lopez',
      );
      await typeUsername(tester, 'maria_l');
      await tester.enterText(
        find.byKey(const ValueKey('auth_email_field')),
        'maria@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth_password_field')),
        'secret123',
      );
      await tester.tap(find.byKey(const ValueKey('auth_submit_btn')));
      await tester.pumpAndSettle();

      expect(
        harness.auth.calls,
        contains('signUp:maria@example.com:maria_l:Maria Lopez'),
      );
      expect(find.byType(RepertoirePage), findsOneWidget);
    });

    testWidgets('a username taken between check and submit shows the error', (
      tester,
    ) async {
      // The pre-checks say "available"; the server then refuses.
      harness.auth.signUpError = BackendErrorCode.usernameTaken.failure();
      await openCreate(tester);
      await typeUsername(tester, 'maria_l');
      await tester.enterText(
        find.byKey(const ValueKey('auth_email_field')),
        'maria@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth_password_field')),
        'secret123',
      );
      await tester.tap(find.byKey(const ValueKey('auth_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.text('That username is already taken.'), findsOneWidget);
      expect(find.text('Username is already taken'), findsOneWidget);
      expect(find.byType(RepertoirePage), findsNothing);
    });

    testWidgets('sign up that needs email confirmation returns to sign in', (
      tester,
    ) async {
      final auth = _PendingConfirmationAuth();
      final h = AppHarness(auth: auth);
      addTearDown(h.dispose);
      await pumpApp(tester, h);
      await tester.tap(
        find.byKey(const ValueKey('welcome_create_account_btn')),
      );
      await tester.pumpAndSettle();
      await typeUsername(tester, 'maria_l');
      await tester.enterText(
        find.byKey(const ValueKey('auth_email_field')),
        'maria@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth_password_field')),
        'secret123',
      );
      await tester.tap(find.byKey(const ValueKey('auth_submit_btn')));
      await tester.pumpAndSettle();

      // Back on the sign-in page, email filled in, with the next step.
      expect(find.byType(SignInPage), findsOneWidget);
      expect(find.byType(CreateAccountPage), findsNothing);
      expect(
        find.text(
          'Account created! Confirm it from the email we sent you, then '
          'sign in here.',
        ),
        findsOneWidget,
      );
      final email = tester.widget<TextField>(
        find.byKey(const ValueKey('auth_email_field')),
      );
      expect(email.controller!.text, 'maria@example.com');
      expect(find.byType(BattutaWordmark), findsOneWidget);
    });
  });

  testWidgets(
    'signing in from Settings while offline enters the app without a back arrow',
    (tester) async {
      final h = AppHarness(
        entryStorage: MemoryStorage({
          AppEntryStorageKeys.continueOffline: 'true',
        }),
      );
      addTearDown(h.dispose);
      await pumpApp(tester, h);
      container(tester).read(appRouterProvider).go(AppRoutes.settings);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInPage), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('auth_email_field')),
        'me@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth_password_field')),
        'secret123',
      );
      await tester.tap(find.byKey(const ValueKey('auth_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsNothing);
      expect(find.byType(RepertoirePage), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    },
  );

  testWidgets(
    'sign up enters the app even before the auth stream reports the session',
    (tester) async {
      final auth = _LaggingStreamAuth();
      final h = AppHarness(auth: auth);
      addTearDown(h.dispose);
      await pumpApp(tester, h);
      await tester.tap(
        find.byKey(const ValueKey('welcome_create_account_btn')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('auth_username_field')),
        'maria_l',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(
        find.byKey(const ValueKey('auth_email_field')),
        'maria@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth_password_field')),
        'secret123',
      );
      await tester.tap(find.byKey(const ValueKey('auth_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(RepertoirePage), findsOneWidget);
      expect(find.byType(SignInPage), findsNothing);
      expect(find.byType(CreateAccountPage), findsNothing);
    },
  );

  testWidgets('continue offline enters the app and is remembered', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(
      find.byKey(const ValueKey('welcome_continue_offline_btn')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RepertoirePage), findsOneWidget);
    expect(
      harness.entryStorage.values[AppEntryStorageKeys.continueOffline],
      'true',
    );

    // A new run with the same storage skips the welcome screen.
    final restarted = AppHarness(entryStorage: harness.entryStorage);
    addTearDown(restarted.dispose);
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, restarted);
    expect(find.text('Welcome to Battuta'), findsNothing);
    expect(find.byType(RepertoirePage), findsOneWidget);
  });

  testWidgets('a restored session goes straight to the app', (tester) async {
    final h = AppHarness(
      auth: FakeAuthRepository(
        user: const AuthUser(id: 'u-me', email: 'me@example.com'),
      ),
    );
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    expect(find.text('Welcome to Battuta'), findsNothing);
    expect(find.byType(RepertoirePage), findsOneWidget);
    expect(h.coordinator.starts, 1);
    expect(h.cloudSync.syncs, 1);
  });

  testWidgets(
    'a deactivated account lands on the welcome screen with a message',
    (tester) async {
      final h = AppHarness(
        auth: FakeAuthRepository(
          user: const AuthUser(id: 'u-me', email: 'me@example.com'),
        ),
        // The user had also chosen to continue offline before.
        entryStorage: MemoryStorage({
          AppEntryStorageKeys.continueOffline: 'true',
        }),
      );
      addTearDown(h.dispose);
      await pumpApp(tester, h);
      expect(find.byType(RepertoirePage), findsOneWidget);

      // The guard signs the account out and tells why.
      container(tester)
          .read(accountNoticeProvider.notifier)
          .show(AccountNotice.deactivated);
      h.auth.emit(null);
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Battuta'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('welcome_deactivated_message')),
        findsOneWidget,
      );
      expect(find.byType(RepertoirePage), findsNothing);

      // Continuing offline clears the message and opens the app.
      await tester.tap(
        find.byKey(const ValueKey('welcome_continue_offline_btn')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RepertoirePage), findsOneWidget);
      expect(container(tester).read(accountNoticeProvider), isNull);
    },
  );

  testWidgets('a stale deactivation notice is cleared when a user signs in', (
    tester,
  ) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    container(tester)
        .read(accountNoticeProvider.notifier)
        .show(AccountNotice.deactivated);
    expect(container(tester).read(accountNoticeProvider), isNotNull);

    h.auth.emit(const AuthUser(id: 'u-me', email: 'me@example.com'));
    await tester.pumpAndSettle();

    expect(container(tester).read(accountNoticeProvider), isNull);
  });

  testWidgets('signing out returns a first-launch user to the welcome screen', (
    tester,
  ) async {
    final h = AppHarness(
      auth: FakeAuthRepository(
        user: const AuthUser(id: 'u-me', email: 'me@example.com'),
      ),
    );
    addTearDown(h.dispose);
    await pumpApp(tester, h);

    h.auth.emit(null);
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Battuta'), findsOneWidget);
  });
}

/// Sign-up succeeds but no session starts (email confirmation required).
class _PendingConfirmationAuth extends FakeAuthRepository {
  @override
  Future<AuthUser> signUpWithEmailPassword({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async => AuthUser(id: 'pending', email: email);
}

/// Signs up with a session, but the auth stream never reports it (as when
/// the stream emits after the form reads the user).
class _LaggingStreamAuth extends FakeAuthRepository {
  @override
  Future<AuthUser> signUpWithEmailPassword({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    final created = AuthUser(id: 'user-1', email: email);
    user = created;
    return created;
  }
}
