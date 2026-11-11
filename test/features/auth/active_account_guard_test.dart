import 'package:battuta/features/auth/data/active_account_guard.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UserProfile profile({DateTime? deactivatedAt}) => UserProfile(
    id: 'u1',
    username: 'jane',
    displayName: 'Jane',
    deactivatedAt: deactivatedAt,
  );

  test('a deactivated profile signs the session out immediately', () async {
    var signedOut = 0;
    final guard = ActiveAccountGuard(
      fetchProfile: () async => profile(deactivatedAt: DateTime.utc(2026)),
      signOut: () async => signedOut++,
    );
    expect(await guard.enforce(), isFalse);
    expect(signedOut, 1);
  });

  test('an active profile keeps the session', () async {
    var signedOut = 0;
    final guard = ActiveAccountGuard(
      fetchProfile: () async => profile(),
      signOut: () async => signedOut++,
    );
    expect(await guard.enforce(), isTrue);
    expect(signedOut, 0);
  });

  test('offline or missing profile keeps the session (only a positive answer signs out)', () async {
    var signedOut = 0;
    final failing = ActiveAccountGuard(
      fetchProfile: () async => throw Exception('offline'),
      signOut: () async => signedOut++,
    );
    final missing = ActiveAccountGuard(
      fetchProfile: () async => null,
      signOut: () async => signedOut++,
    );
    expect(await failing.enforce(), isTrue);
    expect(await missing.enforce(), isTrue);
    expect(signedOut, 0);
  });

  test('a failing sign-out still reports the account as deactivated', () async {
    final guard = ActiveAccountGuard(
      fetchProfile: () async => profile(deactivatedAt: DateTime.utc(2026)),
      signOut: () async => throw Exception('network'),
    );
    expect(await guard.enforce(), isFalse);
  });
}
