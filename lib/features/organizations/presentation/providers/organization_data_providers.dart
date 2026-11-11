/// Riverpod wiring of the organization data layer (no UI yet).
library;

import 'package:battuta/core/database/database_providers.dart';
import 'package:battuta/features/auth/presentation/providers/account_notice_provider.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/organizations/data/organization_repertoire_remote_data_source.dart';
import 'package:battuta/features/organizations/data/organization_repertoire_repository_impl.dart';
import 'package:battuta/features/organizations/data/organization_repository_impl.dart';
import 'package:battuta/features/organizations/data/organizations_local_cache.dart';
import 'package:battuta/features/organizations/data/organizations_remote_data_source.dart';
import 'package:battuta/features/organizations/data/organizations_sync_coordinator.dart';
import 'package:battuta/features/organizations/data/schedule_repository_impl.dart';
import 'package:battuta/features/organizations/data/schedules_remote_data_source.dart';
import 'package:battuta/features/organizations/data/supabase_account_session.dart';
import 'package:battuta/features/organizations/domain/repositories/account_session.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repertoire_repository.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repository.dart';
import 'package:battuta/features/organizations/domain/repositories/schedule_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The data layer only ends a session for a deactivated account, so the
/// welcome screen is told why.
class _NoticingAccountSession implements AccountSession {
  _NoticingAccountSession(this._inner, this._onDeactivated);

  final AccountSession _inner;
  final void Function() _onDeactivated;

  @override
  String? get userId => _inner.userId;

  @override
  Stream<String?> get userIdChanges => _inner.userIdChanges;

  @override
  Future<void> signOut() {
    _onDeactivated();
    return _inner.signOut();
  }
}

final accountSessionProvider = Provider<AccountSession>((ref) {
  final manager = ref.watch(supabaseClientManagerProvider);
  return _NoticingAccountSession(
    SupabaseAccountSession(() => manager.client),
    () => ref
        .read(accountNoticeProvider.notifier)
        .show(AccountNotice.deactivated),
  );
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

final organizationRepertoireRemoteDataSourceProvider =
    Provider<OrganizationRepertoireRemoteDataSource>((ref) {
      final manager = ref.watch(supabaseClientManagerProvider);
      return SupabaseOrganizationRepertoireRemoteDataSource(
        () => manager.client,
      );
    });

final organizationRepertoireRepositoryProvider =
    Provider<OrganizationRepertoireRepository>(
      (ref) => OrganizationRepertoireRepositoryImpl(
        remote: ref.watch(organizationRepertoireRemoteDataSourceProvider),
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
/// applies realtime changes. `accountLifecycleProvider` starts it on sign-in.
final organizationsSyncCoordinatorProvider =
    Provider<OrganizationsSyncCoordinator>((ref) {
      final coordinator = OrganizationsSyncCoordinator(
        session: ref.watch(accountSessionProvider),
        cache: ref.watch(organizationsLocalCacheProvider),
        remote: ref.watch(organizationsRemoteDataSourceProvider),
        organizations: ref.watch(organizationRepositoryProvider),
        schedules: ref.watch(scheduleRepositoryProvider),
        repertoire: ref.watch(organizationRepertoireRepositoryProvider),
      );
      ref.onDispose(coordinator.stop);
      return coordinator;
    });
