/// Battuta — Settings page.
///
/// Provides app-level configuration options including theme selection,
/// API key management (placeholder), version display, and about info.
library;

import 'package:battuta/app/localization/locale_provider.dart';
import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/app/theme/theme_provider.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/scanner/presentation/widgets/omr_log_viewer_modal.dart';
import 'package:battuta/features/settings/presentation/providers/api_key_provider.dart';
import 'package:battuta/features/settings/presentation/widgets/api_key_dialog.dart';
import 'package:battuta/features/settings/presentation/widgets/supabase_auth_dialog.dart';
import 'package:battuta/features/settings/presentation/widgets/supabase_config_dialog.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:battuta/features/workspace/presentation/providers/workspace_usage_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
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
    final languageOption = ref.watch(appLanguageOptionProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.settingsTitle ?? 'Settings')),
      body: ListView(
        children: [
          // ── Appearance ──
          _SectionHeader(title: l10n?.appearanceSection ?? 'Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(l10n?.themeLabel ?? 'Theme'),
            subtitle: Text(l10n?.themeSubtitle ?? 'Choose light, dark, or system mode'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode),
                    label: Text(l10n?.themeLight ?? 'Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode),
                    label: Text(l10n?.themeDark ?? 'Dark'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.settings_suggest),
                    label: Text(l10n?.themeSystem ?? 'System'),
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

          // ── Language / Idioma ──
          _SectionHeader(title: l10n?.languageSection ?? 'Language / Idioma'),
          ListTile(
            key: const ValueKey('language_tile'),
            leading: const Icon(Icons.language),
            title: Text(l10n?.languageLabel ?? 'Language'),
            subtitle: Text(
              l10n?.languageSubtitle ?? 'Choose English, Spanish, or System Default',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<AppLanguageOption>(
                key: const ValueKey('language_segmented_btn'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: AppLanguageOption.system,
                    icon: const Icon(Icons.settings_suggest),
                    label: Text(l10n?.languageAuto ?? 'Auto'),
                  ),
                  ButtonSegment(
                    value: AppLanguageOption.english,
                    icon: const Icon(Icons.language),
                    label: Text(l10n?.languageEnglish ?? 'English'),
                  ),
                  ButtonSegment(
                    value: AppLanguageOption.spanish,
                    icon: const Icon(Icons.translate),
                    label: Text(l10n?.languageSpanish ?? 'Español'),
                  ),
                ],
                selected: {languageOption},
                onSelectionChanged: (options) {
                  ref
                      .read(appLanguageOptionProvider.notifier)
                      .setLanguage(options.first);
                },
              ),
            ),
          ),

          const Divider(),

          // ── Cloud Synchronization (Supabase) ──
          _SectionHeader(
            title: l10n?.cloudSyncSection ?? 'Cloud Synchronization (Supabase)',
          ),
          ListTile(
            key: const ValueKey('supabase_account_tile'),
            leading: const Icon(Icons.cloud_sync_outlined),
            title: Text(l10n?.cloudAccountLabel ?? 'Cloud Account'),
            subtitle: Text(
              currentUser != null
                  ? '${currentUser.email}${currentUser.displayName != null ? ' (${currentUser.displayName})' : ''}'
                  : 'Not signed in — Offline SQLite active',
            ),
            trailing: currentUser != null
                ? TextButton(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                    child: Text(l10n?.signOut ?? 'Sign Out'),
                  )
                : const Icon(Icons.chevron_right),
            onTap: currentUser == null
                ? () => SupabaseAuthDialog.show(context)
                : null,
          ),
          ListTile(
            key: const ValueKey('supabase_config_tile'),
            leading: const Icon(Icons.settings_ethernet),
            title: Text(l10n?.supabaseConnectionLabel ?? 'Supabase Connection'),
            subtitle: const Text('Configure Project URL & Anon Key'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => SupabaseConfigDialog.show(context),
          ),
          ListTile(
            key: const ValueKey('supabase_sync_status_tile'),
            leading: const Icon(Icons.sync),
            title: Text(l10n?.syncStatusLabel ?? 'Sync Status'),
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
                    child: Text(l10n?.syncNow ?? 'Sync Now'),
                  ),
          ),

          const Divider(),

          // ── Workspace Resources & Quota ──
          _SectionHeader(
            title: l10n?.workspaceResourcesSection ?? 'Workspace Resources & Quota',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Card(
              key: const ValueKey('workspace_usage_card'),
              elevation: 0,
              color: const Color(0xFF1E2024),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF2E323B)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ref.watch(workspaceUsageProvider).when(
                  data: (usage) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              l10n?.activeWorkspacePool ?? 'ACTIVE WORKSPACE POOL',
                              style: const TextStyle(
                                color: Color(0xFF8A8F98),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.stageAmber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${usage.workspaceName} • ${usage.tier}',
                                style: const TextStyle(
                                  color: AppTheme.stageAmber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Gemini AI Credits
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome, size: 16, color: AppTheme.stageAmber),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    l10n?.geminiAiCredits ?? 'Gemini AI Credits',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            usage.formattedCredits,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: usage.creditsRatio,
                          backgroundColor: const Color(0xFF2E323B),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.stageAmber),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${usage.geminiScansCount} full lead-sheet scans this billing period',
                        style: const TextStyle(color: Color(0xFF8A8F98), fontSize: 11),
                      ),

                      const SizedBox(height: 16),

                      // Cloud Storage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.cloud_outlined, size: 16, color: Colors.blueAccent),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    l10n?.cloudStorage ?? 'Cloud Storage',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            usage.formattedStorage,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: usage.storageRatio,
                          backgroundColor: const Color(0xFF2E323B),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${usage.filesUploadedCount} scores and audio tracks stored',
                        style: const TextStyle(color: Color(0xFF8A8F98), fontSize: 11),
                      ),
                    ],
                  ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (error, stack) => const Text('Workspace metrics unavailable'),
                ),
              ),
            ),
          ),

          const Divider(),

          // ── API Configuration ──
          const _SectionHeader(
            title: 'API Configuration',
          ),
          ListTile(
            key: const ValueKey('gemini_api_key_tile'),
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
          ListTile(
            key: const ValueKey('omr_debug_logs_tile'),
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('OMR Diagnostic Logs'),
            subtitle: const Text('Inspect Gemini requests, latencies & responses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => OmrLogViewerModal.show(context),
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
