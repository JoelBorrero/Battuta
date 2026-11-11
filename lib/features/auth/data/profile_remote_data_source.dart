/// Supabase calls about the signed-in account's profile.
library;

import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/organizations/data/backend_gateway.dart';

abstract interface class ProfileRemoteDataSource {
  /// The signed-in user's profile, or `null` when there is none.
  Future<UserProfile?> fetchMyProfile();

  /// Sign-up pre-check; the unique index stays the real guard.
  Future<bool> isUsernameAvailable(String username);

  Future<void> deactivateAccount();
}

class SupabaseProfileRemoteDataSource extends SupabaseGateway
    implements ProfileRemoteDataSource {
  SupabaseProfileRemoteDataSource(super.clientProvider);

  @override
  Future<UserProfile?> fetchMyProfile() => run((c, uid) async {
    final data = await c
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
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
}
