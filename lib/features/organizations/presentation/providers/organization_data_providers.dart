/// Riverpod wiring of the organization data layer (no UI yet).
library;

import 'package:battuta/core/database/database_providers.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/organizations/data/organization_repository_impl.dart';
import 'package:battuta/features/organizations/data/organizations_local_cache.dart';
import 'package:battuta/features/organizations/data/organizations_remote_data_source.dart';
import 'package:battuta/features/organizations/data/organizations_sync_coordinator.dart';
import 'package:battuta/features/organizations/data/schedule_repository_impl.dart';
import 'package:battuta/features/organizations/data/schedules_remote_data_source.dart';
import 'package:battuta/features/organizations/data/supabase_account_session.dart';
import 'package:battuta/features/organizations/domain/repositories/account_session.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repository.dart';
import 'package:battuta/features/organizations/domain/repositories/schedule_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountSessionProvider = Provider<AccountSession>((ref) {
  final manager = ref.watch(supabaseClientManagerProvider);
  return SupabaseAccountSession(() => manager.client);
});

final organizationsLocalCacheProvider = Provider<OrganizationsLocalCache>((
  ref,
) {
  final session = ref.watch(accountSessionProvider);
  return OrganizationsLocalCache(
    ref.watch(appDatabaseProvider),
    currentAccount: () => session.userId,
  );
});

final organizationsRemoteDataSourceProvider =
    Provider<OrganizationsRemoteDataSource>((ref) {
      final manager = ref.watch(supabaseClientManagerProvider);
      return SupabaseOrganizationsRemoteDataSource(() => manager.client);
    });

final schedulesRemoteDataSourceProvider = Provider<SchedulesRemoteDataSource>((
  ref,
) {
  final manager = ref.watch(supabaseClientManagerProvider);
  return SupabaseSchedulesRemoteDataSource(() => manager.client);
});

final organizationRepositoryProvider = Provider<OrganizationRepository>(
  (ref) => OrganizationRepositoryImpl(
    remote: ref.watch(organizationsRemoteDataSourceProvider),
    cache: ref.watch(organizationsLocalCacheProvider),
    session: ref.watch(accountSessionProvider),
  ),
);

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepositoryImpl(
    remote: ref.watch(schedulesRemoteDataSourceProvider),
    cache: ref.watch(organizationsLocalCacheProvider),
    session: ref.watch(accountSessionProvider),
  ),
);

/// Follows the session: clears the previous account's cache, refreshes and
/// applies realtime changes. Nothing starts it yet; the app shell does in 005.
final organizationsSyncCoordinatorProvider =
    Provider<OrganizationsSyncCoordinator>((ref) {
      final coordinator = OrganizationsSyncCoordinator(
        session: ref.watch(accountSessionProvider),
        cache: ref.watch(organizationsLocalCacheProvider),
        remote: ref.watch(organizationsRemoteDataSourceProvider),
        organizations: ref.watch(organizationRepositoryProvider),
        schedules: ref.watch(scheduleRepositoryProvider),
      );
      ref.onDispose(coordinator.stop);
      return coordinator;
    });
