/// Battuta — Authentication State & Providers.
///
/// Exposes Riverpod providers for managing cloud authentication state,
/// session persistence, and login flows.
library;

import 'package:battuta/core/services/supabase_client_manager.dart';
import 'package:battuta/core/services/supabase_config_service.dart';
import 'package:battuta/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseConfigServiceProvider = Provider<SupabaseConfigService>((ref) {
  return SupabaseConfigService();
});

final supabaseClientManagerProvider = Provider<SupabaseClientManager>((ref) {
  final configService = ref.watch(supabaseConfigServiceProvider);
  return SupabaseClientManager(configService: configService);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final clientManager = ref.watch(supabaseClientManagerProvider);
  return SupabaseAuthRepository(clientManager: clientManager);
});

final authStateChangesProvider = StreamProvider<AuthUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

final currentUserProvider = Provider<AuthUser?>((ref) {
  final streamUser = ref.watch(authStateChangesProvider).value;
  if (streamUser != null) return streamUser;
  final repo = ref.watch(authRepositoryProvider);
  return repo.currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

class AuthControllerNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.signInWithEmailPassword(email: email, password: password);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> sendMagicLink({required String email}) async {
    state = const AsyncLoading();
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.sendMagicLink(email: email);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthControllerNotifier, AsyncValue<void>>(
      AuthControllerNotifier.new,
    );
