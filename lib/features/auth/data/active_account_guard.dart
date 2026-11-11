/// Signs a deactivated account out as soon as it is detected.
///
/// GoTrue still hands a session to a deactivated account (RLS blocks all of
/// its data), so the app must end that session itself.
library;

import 'package:battuta/features/auth/domain/entities/user_profile.dart';

class ActiveAccountGuard {
  ActiveAccountGuard({required this.fetchProfile, required this.signOut});

  final Future<UserProfile?> Function() fetchProfile;
  final Future<void> Function() signOut;

  /// Returns `false` (after signing out) when the profile is deactivated.
  ///
  /// When the profile cannot be read (offline, error) the session is kept:
  /// the guard only acts on a positive "deactivated" answer.
  Future<bool> enforce() async {
    final UserProfile? profile;
    try {
      profile = await fetchProfile();
    } catch (_) {
      return true;
    }
    if (profile == null || !profile.isDeactivated) return true;
    try {
      await signOut();
    } catch (_) {
      // The caller still treats the account as signed out.
    }
    return false;
  }
}
