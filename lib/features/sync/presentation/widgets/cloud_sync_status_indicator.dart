/// Battuta — Cloud Sync Status Indicator Widget.
///
/// Stage-ready visual badge displaying connection and sync state with
/// one-tap manual sync invocation.
library;

import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CloudSyncStatusIndicator extends ConsumerWidget {
  const CloudSyncStatusIndicator({super.key, this.compact = true});

  final bool compact;

  static const Color stageAmber = Color(0xFFE5A93C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(cloudSyncProvider);

    final (icon, color, tooltip) = switch (syncState.status) {
      CloudSyncStatus.syncing => (
        Icons.sync,
        stageAmber,
        'Syncing changes with Supabase…',
      ),
      CloudSyncStatus.success => (
        Icons.cloud_done_outlined,
        stageAmber,
        syncState.lastSyncedAt != null
            ? 'Cloud synced (${_formatTime(syncState.lastSyncedAt!)})'
            : 'Cloud synced',
      ),
      CloudSyncStatus.offline => (
        Icons.cloud_off_outlined,
        Colors.grey,
        'Offline — working with local SQLite database',
      ),
      CloudSyncStatus.error => (
        Icons.cloud_sync_outlined,
        Colors.redAccent,
        syncState.errorMessage ?? 'Sync error',
      ),
      CloudSyncStatus.idle => (
        Icons.cloud_queue_outlined,
        Colors.grey.shade400,
        'Cloud ready (tap to sync)',
      ),
    };

    if (compact) {
      return IconButton(
        icon: syncState.isSyncing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(stageAmber),
                ),
              )
            : Icon(icon, color: color, size: 22),
        tooltip: tooltip,
        onPressed: syncState.isSyncing
            ? null
            : () => ref.read(cloudSyncProvider.notifier).triggerSync(),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: syncState.isSyncing
          ? null
          : () => ref.read(cloudSyncProvider.notifier).triggerSync(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (syncState.isSyncing)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(stageAmber),
                ),
              )
            else
              Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              syncState.isSyncing
                  ? 'Syncing…'
                  : syncState.status == CloudSyncStatus.success
                      ? 'Synced'
                      : syncState.isOffline
                          ? 'Offline'
                          : 'Sync Now',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
