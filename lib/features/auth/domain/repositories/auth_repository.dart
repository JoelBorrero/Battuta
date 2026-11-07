/// Battuta — Authentication Repository Contract.
///
/// Abstract repository defining cloud authentication operations for
/// Band Directors and musicians following Clean Architecture.
library;

import 'package:battuta/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  /// The currently authenticated user, or `null` if unauthenticated.
  AuthUser? get currentUser;

  /// Stream emitting changes in authentication state.
  Stream<AuthUser?> get authStateChanges;

  /// Authenticates using email and password.
  Future<AuthUser> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Registers a new account using email and password.
  Future<AuthUser> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sends a passwordless Magic Link (OTP) to the specified email.
  Future<void> sendMagicLink({required String email});

  /// Signs the active user out and clears session tokens.
  Future<void> signOut();
}
