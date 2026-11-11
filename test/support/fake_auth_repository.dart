import 'dart:async';

import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/auth/domain/repositories/auth_repository.dart';

/// In-memory [AuthRepository]. Sign-in / sign-up succeed unless [signInError]
/// / [signUpError] is set; [takenUsernames] drives the availability check.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user, this.profile});

  AuthUser? user;
  UserProfile? profile;
  Object? signInError;
  Object? signUpError;
  Set<String> takenUsernames = {};
  bool? availabilityOverride;
  bool deactivated = false;
  final _controller = StreamController<AuthUser?>.broadcast();

  final List<String> calls = [];

  void emit(AuthUser? user) {
    this.user = user;
    _controller.add(user);
  }

  @override
  AuthUser? get currentUser => user;

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  Future<AuthUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    calls.add('signIn:$email');
    if (signInError case final error?) throw error;
    final user = AuthUser(id: 'user-1', email: email);
    emit(user);
    return user;
  }

  @override
  Future<AuthUser> signUpWithEmailPassword({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    calls.add('signUp:$email:$username:$displayName');
    if (signUpError case final error?) throw error;
    final user = AuthUser(id: 'user-1', email: email, displayName: displayName);
    emit(user);
    return user;
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    calls.add('available:$username');
    return availabilityOverride ?? !takenUsernames.contains(username);
  }

  @override
  Future<UserProfile?> fetchMyProfile() async => user == null ? null : profile;

  @override
  Future<void> deactivateAccount() async {
    calls.add('deactivate');
    deactivated = true;
    emit(null);
  }

  @override
  Future<void> sendMagicLink({required String email}) async {
    calls.add('magic:$email');
  }

  @override
  Future<void> resetPassword({required String email}) async {
    calls.add('reset:$email');
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    emit(null);
  }
}
