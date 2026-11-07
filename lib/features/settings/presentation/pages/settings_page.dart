/// Battuta — Settings page.
///
/// Provides app-level configuration options including theme selection,
/// API key management (placeholder), version display, and about info.
library;

import 'package:battuta/app/theme/theme_provider.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/settings/presentation/providers/api_key_provider.dart';
import 'package:battuta/features/settings/presentation/widgets/api_key_dialog.dart';
import 'package:battuta/features/settings/presentation/widgets/supabase_auth_dialog.dart';
import 'package:battuta/features/settings/presentation/widgets/supabase_config_dialog.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The settings page for the Battuta application.
///
/// Currently offers:
/// - **Theme** toggle between light and dark mode
/// - **API Key Configuration** (placeholder for future Gemini integration)
/// - **About** section with version and attribution
class SettingsPage extends ConsumerWidget {
  /// Creates a [SettingsPage].
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final apiKeyState = ref.watch(apiKeyNotifierProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currentUser = ref.watch(currentUserProvider);
    final syncState = ref.watch(cloudSyncProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Appearance ──
          const _SectionHeader(title: 'Appearance'),
          const ListTile(
            leading: Icon(Icons.brightness_6),
            title: Text('Theme'),
            subtitle: Text('Choose light, dark, or system mode'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.settings_suggest),
                    label: Text('System'),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (modes) {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(modes.first);
                },
              ),
            ),
          ),

          const Divider(),

          // ── Cloud Synchronization (Supabase) ──
          const _SectionHeader(title: 'Cloud Synchronization (Supabase)'),
          ListTile(
            key: const ValueKey('supabase_account_tile'),
            leading: const Icon(Icons.cloud_sync_outlined),
            title: const Text('Cloud Account'),
            subtitle: Text(
              currentUser != null
                  ? '${currentUser.email}${currentUser.displayName != null ? ' (${currentUser.displayName})' : ''}'
                  : 'Not signed in — Offline SQLite active',
            ),
            trailing: currentUser != null
                ? TextButton(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                    child: const Text('Sign Out'),
                  )
                : const Icon(Icons.chevron_right),
            onTap: currentUser == null
                ? () => SupabaseAuthDialog.show(context)
                : null,
          ),
          ListTile(
            key: const ValueKey('supabase_config_tile'),
            leading: const Icon(Icons.settings_ethernet),
            title: const Text('Supabase Connection'),
            subtitle: const Text('Configure Project URL & Anon Key'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => SupabaseConfigDialog.show(context),
          ),
          ListTile(
            key: const ValueKey('supabase_sync_status_tile'),
            leading: const Icon(Icons.sync),
            title: const Text('Sync Status'),
            subtitle: Text(
              syncState.isSyncing
                  ? 'Synchronizing local Drift database with cloud…'
                  : syncState.status == CloudSyncStatus.success &&
                          syncState.lastSyncedAt != null
                      ? 'Last synced: ${syncState.lastSyncedAt!.toLocal().hour.toString().padLeft(2, '0')}:${syncState.lastSyncedAt!.toLocal().minute.toString().padLeft(2, '0')}'
                      : syncState.isOffline
                          ? 'Offline: Local changes safely cached'
                          : syncState.errorMessage ?? 'Ready to sync',
            ),
            trailing: syncState.isSyncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : FilledButton.tonal(
                    key: const ValueKey('sync_now_btn'),
                    onPressed: () =>
                        ref.read(cloudSyncProvider.notifier).triggerSync(),
                    child: const Text('Sync Now'),
                  ),
          ),

          const Divider(),

          // ── API Configuration ──
          const _SectionHeader(title: 'API Configuration'),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('Gemini API Key'),
            subtitle: Text(
              apiKeyState.when(
                data: (s) => s.isConfigured
                    ? '${s.maskedKey} (${s.isUserCustom ? 'Custom' : 'Dev .env'})'
                    : 'Not configured — tap to enter key',
                loading: () => 'Loading status...',
                error: (_, _) => 'Error loading key',
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ApiKeyDialog.show(context),
          ),

          const Divider(),

          // ── About ──
          const _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Battuta'),
            subtitle: Text(
              'A music rehearsal & lead-sheet companion\n'
              'for worship teams and bands.',
            ),
            isThreeLine: true,
          ),
          const ListTile(
            leading: Icon(Icons.verified),
            title: Text('Version'),
            subtitle: Text('0.1.0+1'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Battuta',
              applicationVersion: '0.1.0+1',
              applicationIcon: Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(
                  Icons.music_note,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Footer ──
          Center(
            child: Text(
              'Made with ♪ for worship teams',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

/// A simple section header used to group settings.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
