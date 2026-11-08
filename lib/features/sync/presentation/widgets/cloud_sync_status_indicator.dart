/// Battuta — Cloud Sync Status Indicator Widget.
///
/// Stage-ready visual badge displaying connection and sync state with
/// one-tap manual sync invocation.
library;

import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CloudSyncStatusIndicator extends ConsumerWidget {
  const CloudSyncStatusIndicator({super.key, this.compact = true});

  final bool compact;

  static const Color stageAmber = Color(0xFFE5A93C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final syncState = ref.watch(cloudSyncProvider);

    final (icon, color, tooltip) = switch (syncState.status) {
      CloudSyncStatus.syncing => (
        Icons.sync,
        stageAmber,
        l10n?.syncingChangesTooltip ?? 'Syncing changes with Supabase…',
      ),
      CloudSyncStatus.success => (
        Icons.cloud_done_outlined,
        stageAmber,
        syncState.lastSyncedAt != null
            ? (l10n?.cloudSyncedWithTimeTooltip(_formatTime(syncState.lastSyncedAt!)) ??
                'Cloud synced (${_formatTime(syncState.lastSyncedAt!)})')
            : (l10n?.cloudSyncedTooltip ?? 'Cloud synced'),
      ),
      CloudSyncStatus.offline => (
        Icons.cloud_off_outlined,
        Colors.grey,
        l10n?.offlineSQLiteTooltip ?? 'Offline — working with local SQLite database',
      ),
      CloudSyncStatus.error => (
        Icons.cloud_sync_outlined,
        Colors.redAccent,
        syncState.errorMessage ?? (l10n?.syncErrorTooltip ?? 'Sync error'),
      ),
      CloudSyncStatus.idle => (
        Icons.cloud_queue_outlined,
        Colors.grey.shade400,
        l10n?.cloudReadyTooltip ?? 'Cloud ready (tap to sync)',
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
                  ? (l10n?.syncingStatus ?? 'Syncing…')
                  : syncState.status == CloudSyncStatus.success
                      ? (l10n?.syncedStatusLabel ?? 'Synced')
                      : syncState.isOffline
                          ? (l10n?.offlineStatusLabel ?? 'Offline')
                          : (l10n?.syncNow ?? 'Sync Now'),
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
