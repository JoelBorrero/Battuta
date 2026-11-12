/// Supabase calls about the signed-in account's profile.
library;

import 'dart:typed_data';

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/services/photo_storage.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/organizations/data/backend_gateway.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

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

  /// Uploads [jpeg] as my photo, points my profile at it and deletes the
  /// previous object (best effort).
  Future<void> setMyAvatar(Uint8List jpeg);

  /// Clears my photo and deletes its object (best effort).
  Future<void> removeMyAvatar();
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

  /// Points my profile at [path] (`null` clears it) and returns the previous
  /// path. Fails with `permission_denied` when nothing was updated.
  Future<String?> _swapAvatarPath(
    supa.SupabaseClient c,
    String uid,
    String? path,
  ) async {
    final before = await c
        .from('profiles')
        .select('avatar_path')
        .eq('id', uid)
        .maybeSingle();
    final List<dynamic> updated = await c
        .from('profiles')
        .update({'avatar_path': path})
        .eq('id', uid)
        .select('id');
    if (updated.isEmpty) {
      throw BackendErrorCode.permissionDenied.failure(
        message: 'Your profile could not be updated.',
      );
    }
    return before?['avatar_path'] as String?;
  }

  @override
  Future<void> setMyAvatar(Uint8List jpeg) => run((c, uid) async {
    final path = await uploadPhoto(c, PhotoBucket.avatars, uid, jpeg);
    final String? previous;
    try {
      previous = await _swapAvatarPath(c, uid, path);
    } catch (_) {
      await removePhotoQuietly(c, PhotoBucket.avatars, path);
      rethrow;
    }
    await removePhotoQuietly(c, PhotoBucket.avatars, previous);
  });

  @override
  Future<void> removeMyAvatar() => run((c, uid) async {
    final previous = await _swapAvatarPath(c, uid, null);
    await removePhotoQuietly(c, PhotoBucket.avatars, previous);
  });
}
