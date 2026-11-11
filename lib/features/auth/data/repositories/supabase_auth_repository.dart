/// Battuta — Supabase Authentication Repository Implementation.
///
/// Implements [AuthRepository] using the Supabase GoTrue Auth client.
library;

import 'dart:async';

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/services/supabase_client_manager.dart';
import 'package:battuta/features/auth/data/active_account_guard.dart';
import 'package:battuta/features/auth/data/profile_remote_data_source.dart';
import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required this.clientManager,
    this.clientProvider,
    ProfileRemoteDataSource? profileSource,
  }) {
    _profiles =
        profileSource ?? SupabaseProfileRemoteDataSource(() => _client);
    _activeGuard = ActiveAccountGuard(
      fetchProfile: _profiles.fetchMyProfile,
      signOut: signOut,
    );
  }

  /// Matches the `profiles_username_format` constraint.
  static final RegExp usernamePattern = RegExp(r'^[a-z0-9_.]{3,30}$');

  /// The custom URI scheme callback recognized by Android, iOS, and Supabase.
  static const String authRedirectUrl = 'battuta://login-callback';

  final SupabaseClientManager clientManager;

  /// Overrides how the client is obtained (integration tests).
  final supa.SupabaseClient? Function()? clientProvider;
  late final ProfileRemoteDataSource _profiles;
  late final ActiveAccountGuard _activeGuard;

  supa.SupabaseClient? get _client =>
      clientProvider != null ? clientProvider!() : clientManager.client;

  @override
  AuthUser? get currentUser {
    final client = _client;
    if (client == null) return null;
    final user = client.auth.currentUser;
    return user != null ? _mapUser(user) : null;
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    final client = _client;
    if (client == null) {
      return Stream.value(null);
    }
    return client.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;
      if (user == null) return null;
      // A restored or new session of a deactivated account is ended at once.
      final checkProfile =
          data.event == supa.AuthChangeEvent.initialSession ||
          data.event == supa.AuthChangeEvent.signedIn;
      if (checkProfile && !await _activeGuard.enforce()) return null;
      return _mapUser(user);
    });
  }

  @override
  Future<AuthUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const ServerFailure(message: 'Sign in succeeded but returned no user profile.');
      }
      if (!await _activeGuard.enforce()) {
        throw BackendErrorCode.accountDeactivated.failure(
          message: 'This account has been deactivated.',
        );
      }
      return _mapUser(user);
    } on supa.AuthException catch (e, st) {
      throw ServerFailure(message: e.message, statusCode: int.tryParse(e.statusCode ?? ''), stackTrace: st);
    } catch (e, st) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: 'Sign in failed: $e', stackTrace: st);
    }
  }

  @override
  Future<AuthUser> signUpWithEmailPassword({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (!usernamePattern.hasMatch(normalized)) {
      throw BackendErrorCode.invalidUsername.failure(
        message: 'Username must be 3-30 characters: letters, numbers, _ or .',
      );
    }
    final client = _requireClient();
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: authRedirectUrl,
        data: {
          'username': normalized,
          if (displayName != null && displayName.trim().isNotEmpty)
            'display_name': displayName.trim(),
        },
      );
      final user = response.user;
      if (user == null) {
        throw const ServerFailure(message: 'Registration succeeded but user profile is pending verification.');
      }
      return _mapUser(user);
    } on supa.AuthException catch (e, st) {
      final code = BackendErrorCode.fromMessage(e.message);
      if (code != BackendErrorCode.unknown) {
        throw code.failure(message: e.message, stackTrace: st);
      }
      // GoTrue hides the trigger's message behind "Database error saving new
      // user"; a taken username is the only expected cause after validation.
      if (await _usernameIsTaken(normalized)) {
        throw BackendErrorCode.usernameTaken.failure(
          message: 'That username is already taken.',
          stackTrace: st,
        );
      }
      throw ServerFailure(message: e.message, statusCode: int.tryParse(e.statusCode ?? ''), stackTrace: st);
    } catch (e, st) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: 'Registration failed: $e', stackTrace: st);
    }
  }

  @override
  Future<void> sendMagicLink({required String email}) async {
    final client = _requireClient();
    try {
      await client.auth.signInWithOtp(
        email: email.trim(),
        emailRedirectTo: authRedirectUrl,
      );
    } on supa.AuthException catch (e, st) {
      throw ServerFailure(message: e.message, statusCode: int.tryParse(e.statusCode ?? ''), stackTrace: st);
    } catch (e, st) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: 'Magic link failed: $e', stackTrace: st);
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    final client = _requireClient();
    try {
      await client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: authRedirectUrl,
      );
    } on supa.AuthException catch (e, st) {
      throw ServerFailure(message: e.message, statusCode: int.tryParse(e.statusCode ?? ''), stackTrace: st);
    } catch (e, st) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: 'Password reset request failed: $e', stackTrace: st);
    }
  }

  @override
  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.auth.signOut();
    } catch (e, st) {
      throw ServerFailure(message: 'Sign out failed: $e', stackTrace: st);
    }
  }

  Future<bool> _usernameIsTaken(String normalized) async {
    try {
      return !await _profiles.isUsernameAvailable(normalized);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final normalized = username.trim().toLowerCase();
    if (!usernamePattern.hasMatch(normalized)) return false;
    return _profiles.isUsernameAvailable(normalized);
  }

  @override
  Future<UserProfile?> fetchMyProfile() async {
    if (_client?.auth.currentUser == null) return null;
    return _profiles.fetchMyProfile();
  }

  @override
  Future<void> deactivateAccount() async {
    await _profiles.deactivateAccount();
    await signOut();
  }

  /// Signs the account out when its profile is deactivated. Returns `false`
  /// in that case. For app start-up; sign-in and the auth state stream
  /// already apply it.
  Future<bool> enforceActiveAccount() => _activeGuard.enforce();

  supa.SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw const ValidationFailure(
        message: 'Supabase is not configured or initialized. Please configure credentials in Settings.',
      );
    }
    return client;
  }

  static AuthUser _mapUser(supa.User user) {
    final meta = user.userMetadata ?? {};
    final displayName = (meta['display_name'] as String?) ??
        (meta['name'] as String?) ??
        (meta['full_name'] as String?);

    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      displayName: displayName,
      createdAt: DateTime.tryParse(user.createdAt),
      metadata: meta,
    );
  }
}
