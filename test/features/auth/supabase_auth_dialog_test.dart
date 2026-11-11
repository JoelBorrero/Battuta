import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/auth/domain/repositories/auth_repository.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/settings/presentation/widgets/supabase_auth_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  final taken = <String>{'taken_name'};
  final checked = <String>[];
  String? signedUpWith;

  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(null);

  @override
  Future<bool> isUsernameAvailable(String username) async {
    checked.add(username);
    return !taken.contains(username);
  }

  @override
  Future<AuthUser> signUpWithEmailPassword({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    signedUpWith = username;
    return const AuthUser(id: 'u1', email: 'a@b.c');
  }

  @override
  Future<AuthUser> signInWithEmailPassword({required String email, required String password}) =>
      throw UnimplementedError();
  @override
  Future<void> sendMagicLink({required String email}) => throw UnimplementedError();
  @override
  Future<void> resetPassword({required String email}) => throw UnimplementedError();
  @override
  Future<void> signOut() async {}
  @override
  Future<UserProfile?> fetchMyProfile() async => null;
  @override
  Future<void> deactivateAccount() async {}
}

void main() {
  late _FakeAuthRepository repo;

  Future<void> openDialog(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => SupabaseAuthDialog.show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  setUp(() => repo = _FakeAuthRepository());

  testWidgets('the username field only shows when registering', (tester) async {
    await openDialog(tester);
    const usernameKey = ValueKey('supabase_auth_username_field');
    expect(find.byKey(usernameKey), findsNothing);

    await tester.tap(find.text('New? Register'));
    await tester.pumpAndSettle();
    expect(find.byKey(usernameKey), findsOneWidget);
  });

  testWidgets('checks availability while typing', (tester) async {
    await openDialog(tester);
    await tester.tap(find.text('New? Register'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('supabase_auth_username_field')), 'Taken_Name');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Username is already taken'), findsOneWidget);
    expect(repo.checked, ['taken_name']);

    await tester.enterText(find.byKey(const ValueKey('supabase_auth_username_field')), 'free_name');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Username is available'), findsOneWidget);
  });

  testWidgets('a malformed username blocks the submit', (tester) async {
    await openDialog(tester);
    await tester.tap(find.text('New? Register'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('supabase_auth_username_field')), 'no');
    await tester.enterText(find.byKey(const ValueKey('supabase_auth_email_field')), 'a@b.c');
    await tester.enterText(find.byKey(const ValueKey('supabase_auth_password_field')), 'secret123');
    await tester.tap(find.byKey(const ValueKey('supabase_auth_submit_btn')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Username must be 3-30 characters'), findsOneWidget);
    expect(repo.signedUpWith, isNull);
  });

  testWidgets('a taken username is rejected on submit; a free one registers lowercase', (tester) async {
    await openDialog(tester);
    await tester.tap(find.text('New? Register'));
    await tester.pumpAndSettle();

    final username = find.byKey(const ValueKey('supabase_auth_username_field'));
    await tester.enterText(find.byKey(const ValueKey('supabase_auth_email_field')), 'a@b.c');
    await tester.enterText(find.byKey(const ValueKey('supabase_auth_password_field')), 'secret123');

    await tester.enterText(username, 'taken_name');
    await tester.tap(find.byKey(const ValueKey('supabase_auth_submit_btn')));
    await tester.pumpAndSettle();
    expect(find.text('That username is already taken.'), findsOneWidget);
    expect(repo.signedUpWith, isNull);

    await tester.enterText(username, 'Jane_Doe');
    await tester.tap(find.byKey(const ValueKey('supabase_auth_submit_btn')));
    await tester.pumpAndSettle();
    expect(repo.signedUpWith, 'jane_doe');
  });
}
