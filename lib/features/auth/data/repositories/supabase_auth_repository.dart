/// Battuta — Supabase Authentication Repository Implementation.
///
/// Implements [AuthRepository] using the Supabase GoTrue Auth client.
library;

import 'dart:async';

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/services/supabase_client_manager.dart';
import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required this.clientManager,
  });

  final SupabaseClientManager clientManager;

  supa.SupabaseClient? get _client => clientManager.client;

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
    return client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      return user != null ? _mapUser(user) : null;
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
    String? displayName,
  }) async {
    final client = _requireClient();
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: displayName != null ? {'display_name': displayName.trim()} : null,
      );
      final user = response.user;
      if (user == null) {
        throw const ServerFailure(message: 'Registration succeeded but user profile is pending verification.');
      }
      return _mapUser(user);
    } on supa.AuthException catch (e, st) {
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
        emailRedirectTo: 'org.battuta.battuta://login-callback',
      );
    } on supa.AuthException catch (e, st) {
      throw ServerFailure(message: e.message, statusCode: int.tryParse(e.statusCode ?? ''), stackTrace: st);
    } catch (e, st) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: 'Magic link failed: $e', stackTrace: st);
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
