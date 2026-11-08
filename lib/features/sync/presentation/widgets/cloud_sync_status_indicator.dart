/// Battuta — Cloud Sync Status Indicator Widget.
///
/// Stage-ready visual badge displaying connection and sync state with
/// one-tap manual sync invocation, clear visual feedback, and an
/// interactive bottom sheet for status review and configuration.
library;

import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/settings/presentation/widgets/supabase_auth_dialog.dart';
import 'package:battuta/features/settings/presentation/widgets/supabase_config_dialog.dart';
import 'package:battuta/features/sync/domain/models/cloud_sync_result.dart';
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
            : () => _handleSyncTap(context, ref),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: syncState.isSyncing
          ? null
          : () => _handleSyncTap(context, ref),
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

  Future<void> _handleSyncTap(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(stageAmber),
              ),
            ),
            const SizedBox(width: 12),
            Text(l10n?.syncingChangesTooltip ?? 'Syncing changes with Supabase…'),
          ],
        ),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final result = await ref.read(cloudSyncProvider.notifier).triggerSync();

    if (!context.mounted) return;

    if (result.isSuccess) {
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_done_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n?.cloudSyncSuccess(result.pushedCount, result.pulledCount) ??
                      'Cloud synced successfully (${result.pushedCount} pushed, ${result.pulledCount} pulled)',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E3A24),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      messenger?.hideCurrentSnackBar();
      _showCloudSyncStatusSheet(context, ref, result);
    }
  }

  void _showCloudSyncStatusSheet(
    BuildContext context,
    WidgetRef ref,
    CloudSyncResult result,
  ) {
    final l10n = AppLocalizations.of(context);
    final isAuthenticated = ref.read(isAuthenticatedProvider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1C20) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2F36) : const Color(0xFFE1E4E8),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      result.isOffline
                          ? Icons.cloud_off_outlined
                          : Icons.cloud_sync_outlined,
                      color: result.isOffline ? Colors.orange : AppTheme.stageRed,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n?.cloudSyncStatusTitle ?? 'Cloud Synchronization',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (result.isOffline ? Colors.orange : AppTheme.stageRed)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (result.isOffline ? Colors.orange : AppTheme.stageRed)
                          .withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    () {
                      final err = result.errorMessage;
                      if (err != null) {
                        if (err.contains('not configured')) {
                          return l10n?.supabaseNotConfigured ??
                              'Supabase client is not configured. Local changes cached.';
                        }
                        if (err.toLowerCase().contains('sign in')) {
                          return l10n?.cloudSignInRequired ??
                              'Please sign in to Supabase to enable cloud sync.';
                        }
                        return err;
                      }
                      return result.isOffline
                          ? (l10n?.cloudOfflineMode ??
                              'Offline mode active. All changes are saved safely to local SQLite.')
                          : (l10n?.cloudSignInRequired ??
                              'Please sign in to Supabase to enable cloud sync.');
                    }(),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    if (!isAuthenticated)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.login, size: 16),
                        label: Text(l10n?.signInAction ?? 'Sign In'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: stageAmber,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          SupabaseAuthDialog.show(context);
                        },
                      ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.settings_outlined, size: 16),
                      label: Text(l10n?.configureAction ?? 'Configure'),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        SupabaseConfigDialog.show(context);
                      },
                    ),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(l10n?.retryAction ?? 'Retry'),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _handleSyncTap(context, ref);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
