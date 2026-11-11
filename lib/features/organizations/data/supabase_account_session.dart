/// [AccountSession] backed by the Supabase auth client.
library;

import 'dart:async';

import 'package:battuta/features/organizations/data/backend_gateway.dart';
import 'package:battuta/features/organizations/domain/repositories/account_session.dart';

class SupabaseAccountSession implements AccountSession {
  SupabaseAccountSession(this._clientProvider);

  final SupabaseClientProvider _clientProvider;

  @override
  String? get userId => _clientProvider()?.auth.currentUser?.id;

  @override
  Stream<String?> get userIdChanges {
    final client = _clientProvider();
    if (client == null) return const Stream.empty();
    return client.auth.onAuthStateChange
        .map((data) => data.session?.user.id)
        .distinct();
  }

  @override
  Future<void> signOut() async => _clientProvider()?.auth.signOut();
}
