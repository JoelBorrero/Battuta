/// A signed-up user with its own client, cache and repositories.
library;

import 'dart:math';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/services/supabase_client_manager.dart';
import 'package:battuta/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:battuta/features/organizations/data/organization_repository_impl.dart';
import 'package:battuta/features/organizations/data/organizations_local_cache.dart';
import 'package:battuta/features/organizations/data/organizations_remote_data_source.dart';
import 'package:battuta/features/organizations/data/organizations_sync_coordinator.dart';
import 'package:battuta/features/organizations/data/schedule_repository_impl.dart';
import 'package:battuta/features/organizations/data/schedules_remote_data_source.dart';
import 'package:battuta/features/organizations/data/supabase_account_session.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Band;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'stack.dart';

const testPassword = 'battuta-test-pw-123';

String randomUsername(String label) {
  final suffix = Random.secure().nextInt(1 << 32).toRadixString(36);
  return 'it_${label}_$suffix'.toLowerCase();
}

class TestUser {
  TestUser._(this.stack, this.username, this.email, this.displayName);

  final StackConfig stack;
  final String username;
  final String email;
  final String displayName;

  late SupabaseClient client;
  late SupabaseAuthRepository auth;
  late OrganizationsRemoteDataSource orgRemote;
  late SchedulesRemoteDataSource scheduleRemote;
  late AppDatabase db;
  late OrganizationsLocalCache cache;
  late SupabaseAccountSession session;
  late OrganizationRepositoryImpl orgs;
  late ScheduleRepositoryImpl schedules;
  late OrganizationsSyncCoordinator coordinator;

  String get id => client.auth.currentUser!.id;

  /// Registers a new account through the app's own [SupabaseAuthRepository].
  static Future<TestUser> signUp(
    StackConfig stack,
    String label, {
    String? username,
  }) async {
    username ??= randomUsername(label);
    final user = TestUser._(
      stack,
      username,
      '${randomUsername(label)}@example.test',
      'Test ${label[0].toUpperCase()}${label.substring(1)}',
    );
    user._wire();
    await user.auth.signUpWithEmailPassword(
      email: user.email,
      password: testPassword,
      username: username,
      displayName: user.displayName,
    );
    return user;
  }

  void _wire() {
    // Every user owns an independent in-memory database.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    client = SupabaseClient(
      stack.url,
      stack.anonKey,
      // The PKCE flow needs persistent storage; tests keep sessions in memory.
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    SupabaseClient? provider() => client;
    auth = SupabaseAuthRepository(
      clientManager: SupabaseClientManager(),
      clientProvider: provider,
    );
    orgRemote = SupabaseOrganizationsRemoteDataSource(provider);
    scheduleRemote = SupabaseSchedulesRemoteDataSource(provider);
    db = AppDatabase(NativeDatabase.memory());
    session = SupabaseAccountSession(provider);
    cache = OrganizationsLocalCache(db, currentAccount: () => session.userId);
    orgs = OrganizationRepositoryImpl(
      remote: orgRemote,
      cache: cache,
      session: session,
    );
    schedules = ScheduleRepositoryImpl(
      remote: scheduleRemote,
      cache: cache,
      session: session,
    );
    coordinator = OrganizationsSyncCoordinator(
      session: session,
      cache: cache,
      remote: orgRemote,
      organizations: orgs,
      schedules: schedules,
    );
  }

  Future<void> signIn() async {
    await auth.signInWithEmailPassword(email: email, password: testPassword);
  }

  Future<void> dispose() async {
    await coordinator.stop();
    await db.close();
    await client.dispose();
  }
}

/// Unwraps a repository result, failing the test with the failure message.
T ok<T>(Either<Failure, T> result) => result.fold(
  (f) => fail('Expected success but got ${f.errorCode ?? f.runtimeType}: ${f.message}'),
  (v) => v,
);

/// The error code of a failed result (fails the test when it succeeded).
BackendErrorCode? failed<T>(Either<Failure, T> result) => result.fold(
  (f) => f.errorCode,
  (v) => fail('Expected a failure but got $v'),
);

/// Polls [check] until it is true or [timeout] passes.
Future<void> eventually(
  Future<bool> Function() check, {
  Duration timeout = const Duration(seconds: 15),
  String reason = 'condition',
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (await check()) return;
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
  fail('Timed out waiting for $reason');
}
