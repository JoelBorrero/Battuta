/// Supabase calls about the signed-in account's profile.
library;

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/organizations/data/backend_gateway.dart';

abstract interface class ProfileRemoteDataSource {
  /// The signed-in user's profile, or `null` when there is none.
  Future<UserProfile?> fetchMyProfile();

  /// Sign-up pre-check; the unique index stays the real guard.
  Future<bool> isUsernameAvailable(String username);

  Future<void> deactivateAccount();

  /// Updates my own display name and username (already validated and
  /// normalised). A username in use fails with `username_taken`.
  Future<void> updateMyProfile({
    required String displayName,
    required String username,
  });
}

class SupabaseProfileRemoteDataSource extends SupabaseGateway
    implements ProfileRemoteDataSource {
  SupabaseProfileRemoteDataSource(super.clientProvider);

  @override
  Future<UserProfile?> fetchMyProfile() => run((c, uid) async {
    final data = await c.from('profiles').select().eq('id', uid).maybeSingle();
    return data == null ? null : UserProfile.fromJson(data);
  });

  @override
  Future<bool> isUsernameAvailable(String username) => runPublic((c) async {
    final data = await c.rpc(
      'is_username_available',
      params: {'p_username': username.trim()},
    );
    return data as bool;
  });

  @override
  Future<void> deactivateAccount() => run((c, _) async {
    await c.rpc('deactivate_account');
  });

  @override
  Future<void> updateMyProfile({
    required String displayName,
    required String username,
  }) => run((c, uid) async {
    final List<dynamic> updated;
    try {
      updated = await c
          .from('profiles')
          .update({'display_name': displayName, 'username': username})
          .eq('id', uid)
          .select('id');
    } catch (e, st) {
      final failure = mapBackendError(e, st);
      // The unique index on lower(username) raises a bare 23505.
      if (failure.errorCode == BackendErrorCode.conflict) {
        throw BackendErrorCode.usernameTaken.failure(
          message: 'That username is already taken.',
          stackTrace: st,
        );
      }
      throw failure;
    }
    // RLS (e.g. a deactivated account) or a missing profile updates nothing
    // without an error: report it instead of pretending it saved.
    if (updated.isEmpty) {
      throw BackendErrorCode.permissionDenied.failure(
        message: 'Your profile could not be updated.',
      );
    }
  });
}
