/// Starts the data layer when an account signs in (or its session is
/// restored): the organizations coordinator (cache refresh + realtime) and
/// the song sync. Sign-out needs no call here: the coordinator follows the
/// session itself, stopping realtime and clearing the account's cache.
library;

import 'package:battuta/features/auth/presentation/providers/account_notice_provider.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountLifecycleProvider = Provider<void>((ref) {
  String? startedFor;

  void onUser(String? accountId) {
    if (accountId == null) {
      startedFor = null;
      return;
    }
    // A signed-in user (any sign-in method) makes a stale notice obsolete.
    // Deferred: providers cannot be modified while they are building.
    Future(() => ref.read(accountNoticeProvider.notifier).clear());
    if (accountId == startedFor) return;
    startedFor = accountId;
    Future<void>(() async {
      try {
        await ref.read(organizationsSyncCoordinatorProvider).start();
      } catch (_) {
        // Offline-first: the cache keeps working.
      }
      try {
        await ref.read(cloudSyncProvider.notifier).triggerSync();
      } catch (_) {
        // The result is reported through the sync state.
      }
    });
  }

  ref.listen(
    currentUserProvider.select((user) => user?.id),
    (_, next) => onUser(next),
    fireImmediately: true,
  );
});
