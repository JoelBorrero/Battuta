import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/database/database_providers.dart';
import 'package:battuta/core/services/supabase_client_manager.dart';
import 'package:battuta/features/sync/data/supabase_cloud_sync_service.dart';
import 'package:battuta/features/sync/domain/models/cloud_sync_result.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CloudSyncResult Model Tests', () {
    test('success factory creates valid object', () {
      final now = DateTime(2026, 3, 15, 10, 0);
      final result = CloudSyncResult.success(
        pushedCount: 5,
        pulledCount: 3,
        timestamp: now,
      );

      expect(result.isSuccess, isTrue);
      expect(result.isOffline, isFalse);
      expect(result.pushedCount, equals(5));
      expect(result.pulledCount, equals(3));
      expect(result.totalAffected, equals(8));
      expect(result.errorMessage, isNull);
      expect(result.timestamp, equals(now));
    });

    test('offline factory creates valid offline object', () {
      final result = CloudSyncResult.offline(reason: 'Airplane mode');

      expect(result.isSuccess, isFalse);
      expect(result.isOffline, isTrue);
      expect(result.pushedCount, equals(0));
      expect(result.pulledCount, equals(0));
      expect(result.errorMessage, equals('Airplane mode'));
    });

    test('failure factory creates valid failure object', () {
      final result = CloudSyncResult.failure(error: 'Database timeout');

      expect(result.isSuccess, isFalse);
      expect(result.isOffline, isFalse);
      expect(result.errorMessage, equals('Database timeout'));
    });
  });

  group('SupabaseCloudSyncService Offline Resilience Tests', () {
    late AppDatabase db;
    late SupabaseClientManager clientManager;
    late SupabaseCloudSyncService service;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      clientManager = SupabaseClientManager();
      service = SupabaseCloudSyncService(db: db, clientManager: clientManager);
    });

    tearDown(() async {
      await db.close();
    });

    test('syncAll returns offline result when client is not configured', () async {
      final result = await service.syncAll();

      expect(result.isSuccess, isFalse);
      expect(result.isOffline, isTrue);
      expect(service.isSyncing, isFalse);
    });

    test('pushLocalChanges returns offline result when unconfigured', () async {
      final result = await service.pushLocalChanges();

      expect(result.isSuccess, isFalse);
      expect(result.isOffline, isTrue);
    });

    test('pullRemoteChanges returns offline result when unconfigured', () async {
      final result = await service.pullRemoteChanges();

      expect(result.isSuccess, isFalse);
      expect(result.isOffline, isTrue);
    });
  });

  group('CloudSyncNotifier Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('triggerSync transitions through syncing to offline state gracefully', () async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(cloudSyncProvider.notifier);
      final result = await notifier.triggerSync();

      expect(result.isOffline, isTrue);
      final finalState = container.read(cloudSyncProvider);
      expect(finalState.status, equals(CloudSyncStatus.offline));
      expect(finalState.isOffline, isTrue);
      expect(finalState.isSyncing, isFalse);
    });

    test('clearError resets offline/error status to idle', () async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(cloudSyncProvider.notifier);
      await notifier.triggerSync();

      expect(container.read(cloudSyncProvider).status, equals(CloudSyncStatus.offline));

      notifier.clearError();
      expect(container.read(cloudSyncProvider).status, equals(CloudSyncStatus.idle));
    });
  });
}
