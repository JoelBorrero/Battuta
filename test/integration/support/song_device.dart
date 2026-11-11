/// One installation of the app for the song/setlist sync tests: its own
/// in-memory database, repositories and sync service on top of a signed-in
/// client. A second device of the same user shares the account but not the
/// database.
library;

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/services/supabase_client_manager.dart';
import 'package:battuta/features/organizations/data/supabase_account_session.dart';
import 'package:battuta/features/repertoire/data/repositories/drift_setlist_repository.dart';
import 'package:battuta/features/repertoire/data/repositories/drift_song_repository.dart';
import 'package:battuta/features/score/data/repositories/drift_score_repository.dart';
import 'package:battuta/features/sync/data/supabase_cloud_sync_service.dart';
import 'package:battuta/features/sync/domain/models/cloud_sync_result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'stack.dart';
import 'test_user.dart';

class SongDevice {
  SongDevice(
    this.client, {
    AppDatabase? database,
    bool Function(String organizationId)? canAdminister,
  }) : db = database ?? AppDatabase(NativeDatabase.memory()) {
    SupabaseClient? provider() => client;
    session = SupabaseAccountSession(provider);
    songs = DriftSongRepository(db, session: session);
    setlists = DriftSetlistRepository(
      db,
      session: session,
      canAdministerOrganization: canAdminister,
    );
    scores = DriftScoreRepository(db, session: session);
    sync = SupabaseCloudSyncService(
      db: db,
      clientManager: SupabaseClientManager(),
      clientProvider: provider,
    );
  }

  /// The first device of [user]: a fresh database on the user's own client.
  factory SongDevice.of(
    TestUser user, {
    bool Function(String organizationId)? canAdminister,
  }) => SongDevice(user.client, canAdminister: canAdminister);

  /// Another installation signed in as [user] (own client and database).
  static Future<SongDevice> secondDeviceOf(
    TestUser user,
    StackConfig stack,
  ) async {
    final client = SupabaseClient(
      stack.url,
      stack.anonKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    await client.auth.signInWithPassword(
      email: user.email,
      password: testPassword,
    );
    return SongDevice(client);
  }

  final SupabaseClient client;
  final AppDatabase db;
  late final SupabaseAccountSession session;
  late final DriftSongRepository songs;
  late final DriftSetlistRepository setlists;
  late final DriftScoreRepository scores;
  late final SupabaseCloudSyncService sync;

  String get userId => client.auth.currentUser!.id;

  /// Runs a full sync and fails the test unless it succeeded.
  Future<CloudSyncResult> syncOk() async {
    final result = await sync.syncAll();
    expect(
      result.isSuccess,
      isTrue,
      reason: 'sync failed: ${result.errorMessage}',
    );
    return result;
  }

  Future<void> dispose() async {
    await db.close();
  }
}
