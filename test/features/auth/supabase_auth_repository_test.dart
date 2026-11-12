import 'dart:typed_data';

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/services/supabase_client_manager.dart';
import 'package:battuta/features/auth/data/profile_remote_data_source.dart';
import 'package:battuta/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingProfiles implements ProfileRemoteDataSource {
  final List<String> updates = [];

  @override
  Future<UserProfile?> fetchMyProfile() async => null;

  @override
  Future<bool> isUsernameAvailable(String username) async => true;

  @override
  Future<void> deactivateAccount() async {}

  @override
  Future<void> updateMyProfile({
    required String displayName,
    required String username,
  }) async => updates.add('$displayName:$username');

  @override
  Future<void> setMyAvatar(Uint8List jpeg) async {}

  @override
  Future<void> removeMyAvatar() async {}
}

void main() {
  group('AuthUser Entity Tests', () {
    test('instantiates and supports equality and copyWith', () {
      final user1 = AuthUser(
        id: 'usr-1',
        email: 'director@battuta.app',
        displayName: 'Director Sarah',
        createdAt: DateTime(2026, 1, 1),
      );

      final user2 = AuthUser(
        id: 'usr-1',
        email: 'director@battuta.app',
        displayName: 'Director Sarah',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(user1, equals(user2));

      final updated = user1.copyWith(displayName: 'Sarah Jenkins');
      expect(updated.displayName, equals('Sarah Jenkins'));
      expect(updated.id, equals('usr-1'));
    });
  });

  group('SupabaseAuthRepository Tests', () {
    test('returns null when client is not initialized', () {
      final manager = SupabaseClientManager();
      final repo = SupabaseAuthRepository(clientManager: manager);

      expect(repo.currentUser, isNull);
    });

    test('throws ValidationFailure when attempting sign in without configured client', () async {
      final manager = SupabaseClientManager();
      final repo = SupabaseAuthRepository(clientManager: manager);

      expect(
        () => repo.signInWithEmailPassword(
          email: 'test@battuta.app',
          password: 'password123',
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('throws ValidationFailure when attempting signUp without configured client', () async {
      final manager = SupabaseClientManager();
      final repo = SupabaseAuthRepository(clientManager: manager);

      expect(
        () => repo.signUpWithEmailPassword(
          email: 'test@battuta.app',
          password: 'password123',
          username: 'jane_doe',
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test(
      'rejects a malformed username with invalid_username before any request',
      () async {
        final repo = SupabaseAuthRepository(
          clientManager: SupabaseClientManager(),
        );
        for (final bad in [
          '',
          'ab',
          'has space',
          'UPPER!',
          'x' * 31,
          'ñandú',
        ]) {
          await expectLater(
            repo.signUpWithEmailPassword(
              email: 'test@battuta.app',
              password: 'password123',
              username: bad,
            ),
            throwsA(
              isA<ValidationFailure>().having(
                (f) => f.errorCode,
                'errorCode',
                BackendErrorCode.invalidUsername,
              ),
            ),
            reason: bad,
          );
        }
      },
    );

    test('username availability is false for malformed names and fails offline for valid ones', () async {
      final repo = SupabaseAuthRepository(
        clientManager: SupabaseClientManager(),
      );
      expect(await repo.isUsernameAvailable('no'), isFalse);
      await expectLater(
        repo.isUsernameAvailable('jane_doe'),
        throwsA(
          isA<Failure>().having(
            (f) => f.errorCode,
            'errorCode',
            BackendErrorCode.offline,
          ),
        ),
      );
    });

    test(
      'updateMyProfile validates, trims and lower-cases before the request',
      () async {
        final profiles = _RecordingProfiles();
        final repo = SupabaseAuthRepository(
          clientManager: SupabaseClientManager(),
          profileSource: profiles,
        );

        await repo.updateMyProfile(
          displayName: '  Maria L  ',
          username: ' Maria_L ',
        );
        expect(profiles.updates, ['Maria L:maria_l']);

        Matcher code(BackendErrorCode expected) => throwsA(
          isA<Failure>().having((f) => f.errorCode, 'errorCode', expected),
        );
        await expectLater(
          repo.updateMyProfile(displayName: '   ', username: 'maria_l'),
          code(BackendErrorCode.invalidName),
        );
        await expectLater(
          repo.updateMyProfile(displayName: 'x' * 81, username: 'maria_l'),
          code(BackendErrorCode.invalidName),
        );
        await expectLater(
          repo.updateMyProfile(displayName: 'Maria', username: 'no'),
          code(BackendErrorCode.invalidUsername),
        );
        expect(profiles.updates, hasLength(1));
      },
    );

    test('fetchMyProfile is null when signed out', () async {
      final repo = SupabaseAuthRepository(
        clientManager: SupabaseClientManager(),
      );
      expect(await repo.fetchMyProfile(), isNull);
    });

    test('throws ValidationFailure when attempting sendMagicLink without configured client', () async {
      final manager = SupabaseClientManager();
      final repo = SupabaseAuthRepository(clientManager: manager);

      expect(
        () => repo.sendMagicLink(email: 'test@battuta.app'),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('throws ValidationFailure when attempting resetPassword without configured client', () async {
      final manager = SupabaseClientManager();
      final repo = SupabaseAuthRepository(clientManager: manager);

      expect(
        () => repo.resetPassword(email: 'test@battuta.app'),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test(
      'defines correct auth redirect URL scheme for mobile deep linking',
      () {
        expect(
          SupabaseAuthRepository.authRedirectUrl,
          equals('battuta://login-callback'),
        );
      },
    );
  });

  group('AuthControllerNotifier Provider Tests', () {
    test('initial state is AsyncData(null)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(authControllerProvider);
      expect(state, equals(const AsyncData<void>(null)));
    });

    test('fails gracefully when client is unconfigured', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final success = await container
          .read(authControllerProvider.notifier)
          .signInWithEmailPassword(
            email: 'admin@battuta.app',
            password: 'password123',
          );

      expect(success, isFalse);
      expect(container.read(authControllerProvider), isA<AsyncError>());
    });

    test('sendPasswordReset fails gracefully when unconfigured', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final success = await container
          .read(authControllerProvider.notifier)
          .sendPasswordReset(email: 'admin@battuta.app');

      expect(success, isFalse);
      expect(container.read(authControllerProvider), isA<AsyncError>());
    });
  });
}
