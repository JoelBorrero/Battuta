import 'dart:convert';
import 'dart:io';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/services/supabase_client_manager.dart';
import 'package:battuta/features/repertoire/data/repositories/drift_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/sync/data/supabase_cloud_sync_service.dart';
import 'package:battuta/features/sync/data/sync_context.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// An HTTP client for a device in Airplane Mode.
class _NoNetwork extends http.BaseClient {
  int calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls++;
    throw const SocketException('Failed host lookup');
  }
}

String _jwt(String userId) {
  String part(Map<String, Object?> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final exp =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${part({'sub': userId, 'role': 'authenticated', 'exp': exp})}.sig';
}

/// A client with a restored session that cannot reach any server.
Future<SupabaseClient> _signedInOfflineClient(
  String userId,
  _NoNetwork http,
) async {
  final client = SupabaseClient(
    'http://localhost:54321',
    'anon',
    httpClient: http,
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
  final exp =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  await client.auth.recoverSession(
    jsonEncode({
      'access_token': _jwt(userId),
      'token_type': 'bearer',
      'expires_in': 3600,
      'expires_at': exp,
      'refresh_token': 'refresh',
      'user': {
        'id': userId,
        'aud': 'authenticated',
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'created_at': '2026-01-01T00:00:00Z',
      },
    }),
  );
  return client;
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Song song(String id) => Song(
    id: id,
    title: 'Offline $id',
    artist: 'a',
    key: 'C',
    tempo: 100,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test('signed out: offline result, local data and flags untouched', () async {
    final client = SupabaseClient(
      'http://localhost:54321',
      'anon',
      httpClient: _NoNetwork(),
    );
    addTearDown(client.dispose);
    final service = SupabaseCloudSyncService(
      db: db,
      clientManager: SupabaseClientManager(),
      clientProvider: () => client,
    );
    await DriftSongRepository(db).saveSong(song('a'));
    final result = await service.syncAll();
    expect(result.isOffline, isTrue);
    final row = await db.select(db.songs).getSingle();
    // Not even claimed: claiming needs an account.
    expect(row.accountId, isNull);
  });

  test(
    'signed in without a connection: offline, local saves are never blocked',
    () async {
      final net = _NoNetwork();
      final client = await _signedInOfflineClient(
        '11111111-1111-4111-8111-111111111111',
        net,
      );
      addTearDown(client.dispose);
      expect(
        client.auth.currentUser?.id,
        '11111111-1111-4111-8111-111111111111',
      );

      final service = SupabaseCloudSyncService(
        db: db,
        clientManager: SupabaseClientManager(),
        clientProvider: () => client,
      );
      final songs = DriftSongRepository(db);
      await songs.saveSong(song('before'));

      final result = await service.syncAll();
      expect(result.isOffline, isTrue);
      expect(result.isSuccess, isFalse);
      expect(service.isSyncing, isFalse);
      expect(service.lastSyncedAt, isNull);
      expect(net.calls, greaterThan(0));

      // Saving keeps working and everything stays queued for the next sync.
      expect((await songs.saveSong(song('after'))).isRight(), isTrue);
      final rows = await db.select(db.songs).get();
      expect(rows, hasLength(2));
      expect(rows.every((r) => r.remoteUpdatedAt == null), isTrue);
      // The claim is local work and survives the failed run.
      final claimed = rows.firstWhere((r) => r.title == 'Offline before');
      expect(claimed.ownerId, '11111111-1111-4111-8111-111111111111');
      expect(claimed.id, isNot('before')); // legacy id replaced by a UUID

      // A second try after the failure is allowed (the lock was released).
      expect((await service.syncAll()).isOffline, isTrue);
    },
    // postgrest retries every failed read 3 times with real delays
    // (1 s + 2 s + 4 s), and supabase 2.16.5's `from()` ignores
    // `PostgrestClientOptions.retryEnabled`, so two offline syncs take ~14 s.
    // Under load or macOS timer throttling (App Nap) that exceeded the default
    // 30 s. See the backlog item on offline detection speed.
    timeout: const Timeout(Duration(minutes: 3)),
  );

  group('SyncContext', () {
    SyncContext context(String? Function() current) => SyncContext(
      db: db,
      client: SupabaseClient(
        'http://localhost:54321',
        'anon',
        httpClient: _NoNetwork(),
      ),
      accountId: 'u1',
      currentAccount: current,
    );

    test('ensureCurrent stops a run once the account changed', () {
      var account = 'u1';
      final ctx = context(() => account);
      expect(ctx.ensureCurrent, returnsNormally);
      account = 'u2';
      expect(ctx.ensureCurrent, throwsA(isA<StaleAccountException>()));
      account = 'u1';
      expect(ctx.ensureCurrent, returnsNormally);
    });

    test('ensureCurrent also stops after a sign-out', () {
      final ctx = context(() => null);
      expect(ctx.ensureCurrent, throwsA(isA<StaleAccountException>()));
    });

    test(
      'a failing row is recorded and the run goes on; offline aborts',
      () async {
        final ctx = context(() => 'u1');
        await ctx.guardRow(
          'row',
          () async => throw const FormatException('bad'),
        );
        expect(ctx.errors, hasLength(1));
        await expectLater(
          ctx.guardRow('row', () async => throw const SocketException('down')),
          throwsA(
            isA<ServerFailure>().having(
              (f) => f.errorCode,
              'errorCode',
              BackendErrorCode.offline,
            ),
          ),
        );
        await expectLater(
          ctx.guardRow('row', () async => throw const StaleAccountException()),
          throwsA(isA<StaleAccountException>()),
        );
      },
    );
  });

  test('not_owner is a client side code, not a server one', () {
    expect(
      BackendErrorCode.documented,
      isNot(contains(BackendErrorCode.notOwner)),
    );
    expect(
      BackendErrorCode.notOwner.failure().errorCode,
      BackendErrorCode.notOwner,
    );
  });
}
