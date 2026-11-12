/// Battuta — Authentication Repository Contract.
///
/// Abstract repository defining cloud authentication operations for
/// Band Directors and musicians following Clean Architecture.
library;

import 'dart:typed_data';

import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';

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
  ///
  /// [username] (3-30 characters of `a-z0-9_.`, case-insensitive) is
  /// required; a malformed one fails with `invalid_username`.
  Future<AuthUser> signUpWithEmailPassword({
    required String email,
    required String password,
    required String username,
    String? displayName,
  });

  /// Whether [username] is free (sign-up pre-check).
  Future<bool> isUsernameAvailable(String username);

  /// The profile of the signed-in account, or `null` when signed out.
  Future<UserProfile?> fetchMyProfile();

  /// Updates my display name (1-80 characters) and username (3-30 characters
  /// of `a-z0-9_.`, case-insensitive; stored lower case). Fails with
  /// `invalid_username`, `invalid_name`, `username_taken` or `offline`.
  Future<void> updateMyProfile({
    required String displayName,
    required String username,
  });

  /// Sets my profile photo to the cropped JPEG [jpeg] (at most 2 MB). The old
  /// photo is deleted afterwards. Fails with `offline`, `image_too_large` or
  /// `permission_denied`; the old photo stays in that case.
  Future<void> setMyAvatar(Uint8List jpeg);

  /// Removes my profile photo.
  Future<void> removeMyAvatar();

  /// Deactivates the account (kept as history) and signs out.
  Future<void> deactivateAccount();

  /// Sends a passwordless Magic Link (OTP) to the specified email.
  Future<void> sendMagicLink({required String email});

  /// Sends a password reset email to the specified address.
  Future<void> resetPassword({required String email});

  /// Signs the active user out and clears session tokens.
  Future<void> signOut();
}
