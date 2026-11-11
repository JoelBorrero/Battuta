import 'dart:async';

import 'package:battuta/features/organizations/domain/repositories/account_session.dart';

/// An [AccountSession] the test can switch between accounts.
class FakeAccountSession implements AccountSession {
  FakeAccountSession([this._userId]);

  String? _userId;
  final _changes = StreamController<String?>.broadcast();

  @override
  String? get userId => _userId;

  @override
  Stream<String?> get userIdChanges => _changes.stream;

  void signInAs(String? id) {
    _userId = id;
    _changes.add(id);
  }

  @override
  Future<void> signOut() async => signInAs(null);
}
