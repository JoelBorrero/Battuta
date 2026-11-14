import 'dart:async';

import 'package:battuta/app/app.dart';
import 'package:battuta/app/localization/locale_provider.dart';
import 'package:battuta/app/routes/deep_links.dart';
import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/database/database_providers.dart';
import 'package:battuta/core/platform/screen_wake_lock.dart';
import 'package:battuta/features/auth/presentation/providers/app_entry_provider.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/organizations/data/organizations_sync_coordinator.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/settings/presentation/providers/api_key_provider.dart';
import 'package:battuta/features/sync/domain/models/cloud_sync_result.dart';
import 'package:battuta/features/sync/domain/services/cloud_sync_service.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:battuta/features/sync/presentation/providers/live_sync_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' show Fake;

import 'device_prefs_fakes.dart';
import 'fake_auth_repository.dart';
import 'fake_organization_repository.dart';
import 'live_fakes.dart';
import 'memory_storage.dart';

/// Counts how often the data layer is started.
class FakeCoordinator extends Fake implements OrganizationsSyncCoordinator {
  int starts = 0;

  @override
  Future<void> start() async => starts++;

  @override
  Future<void> stop() async {}
}

class FakeCloudSyncService implements CloudSyncService {
  int syncs = 0;

  @override
  bool get isSyncing => false;

  @override
  DateTime? get lastSyncedAt => null;

  @override
  Future<CloudSyncResult> syncAll({String? teamId}) async {
    syncs++;
    return CloudSyncResult.offline(reason: 'test');
  }

  @override
  Future<CloudSyncResult> pushLocalChanges() async => syncAll();

  @override
  Future<CloudSyncResult> pullRemoteChanges({String? teamId}) async =>
      syncAll();
}

class FakeDeepLinkSource implements DeepLinkSource {
  final controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get links => controller.stream;
}

/// The whole app (router, welcome flow, shell) on fakes.
class AppHarness {
  AppHarness({
    FakeAuthRepository? auth,
    MemoryStorage? entryStorage,
    FakeOrganizationRepository? organizations,
  }) : auth = auth ?? FakeAuthRepository(),
       entryStorage = entryStorage ?? MemoryStorage(),
       organizations = organizations ?? FakeOrganizationRepository(),
       db = AppDatabase(NativeDatabase.memory());

  final FakeAuthRepository auth;
  final MemoryStorage entryStorage;
  final FakeOrganizationRepository organizations;
  final AppDatabase db;
  final coordinator = FakeCoordinator();
  final cloudSync = FakeCloudSyncService();
  final deepLinks = FakeDeepLinkSource();
  final liveDiscovery = FakeLiveSessionDiscovery();

  Widget build() => ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      appEntryStorageProvider.overrideWithValue(entryStorage),
      activeOrganizationStorageProvider.overrideWithValue(MemoryStorage()),
      localeStorageProvider.overrideWithValue(MemoryStorage()),
      apiKeyStorageProvider.overrideWithValue(MemoryStorage()),
      appDatabaseProvider.overrideWithValue(db),
      organizationRepositoryProvider.overrideWithValue(organizations),
      organizationsSyncCoordinatorProvider.overrideWithValue(coordinator),
      cloudSyncServiceProvider.overrideWithValue(cloudSync),
      deepLinkSourceProvider.overrideWithValue(deepLinks),
      // The Live tab never reaches mDNS or the real network interfaces.
      liveSessionDiscoveryProvider.overrideWithValue(liveDiscovery),
      lanAddressResolverProvider.overrideWithValue(FakeLanAddressResolver()),
      screenWakeLockProvider.overrideWithValue(FakeScreenWakeLock()),
      liveDeviceNameProvider.overrideWithValue('Test iPad'),
    ],
    child: const BattutaApp(),
  );

  Future<void> dispose() => db.close();
}
