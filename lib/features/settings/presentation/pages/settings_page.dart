/// Battuta — Settings page.
///
/// App-level configuration in the "Battuta Screens" design: appearance,
/// general, account and sync, workspace quota and about.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/locale_provider.dart';
import 'package:battuta/app/theme/theme_provider.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/widgets/inbox_button.dart';
import 'package:battuta/features/profile/presentation/widgets/profile_avatar_button.dart';
import 'package:battuta/features/scanner/presentation/widgets/omr_log_viewer_modal.dart';
import 'package:battuta/features/settings/presentation/providers/api_key_provider.dart';
import 'package:battuta/features/settings/presentation/widgets/account_section.dart';
import 'package:battuta/features/settings/presentation/widgets/api_key_dialog.dart';
import 'package:battuta/features/settings/presentation/widgets/supabase_config_dialog.dart';
import 'package:battuta/features/settings/presentation/widgets/workspace_usage_group.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _appVersion = '0.1.0+1';

/// The settings page for the Battuta application.
class SettingsPage extends ConsumerWidget {
  /// Creates a [SettingsPage].
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = BattutaBrand.of(context);
    final apiKeyState = ref.watch(apiKeyNotifierProvider);
    final themeMode = ref.watch(themeModeProvider);
    final languageOption = ref.watch(appLanguageOptionProvider);
    final isAdmin = ref.watch(isCurrentUserAdminProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: StageAppBar.large(
        title: l10n?.settingsTitle ?? 'Settings',
        actions: const [InboxButton(), ProfileAvatarButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: BattutaSpace.xl),
        children: [
          // ── Appearance ──
          StageGroup(
            title: l10n?.appearanceSection ?? 'Appearance',
            children: [
              Padding(
                padding: const EdgeInsets.all(BattutaSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n?.themeLabel ?? 'Theme',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: brand.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StageSegmentedControl<ThemeMode>(
                      selected: themeMode,
                      onChanged: (mode) => ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(mode),
                      segments: [
                        StageSegment(
                          value: ThemeMode.dark,
                          label: l10n?.themeStage ?? 'Stage',
                        ),
                        StageSegment(
                          value: ThemeMode.light,
                          label: l10n?.themeRehearsal ?? 'Rehearsal',
                        ),
                        StageSegment(
                          value: ThemeMode.system,
                          label: l10n?.themeSystem ?? 'System',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── General ──
          StageGroup(
            title: l10n?.generalSection ?? 'General',
            children: [
              StageRow(
                key: const ValueKey('language_tile'),
                icon: Icons.language,
                label: l10n?.languageLabel ?? 'Language',
                value: _languageName(languageOption, l10n),
                onTap: () => _showLanguageSheet(context),
              ),
            ],
          ),

          // ── Account and sync ──
          StageSectionHeader(
            title: l10n?.accountSyncSection ?? 'Account and sync',
            padding: const EdgeInsets.fromLTRB(
              BattutaSpace.lg,
              BattutaSpace.xl,
              BattutaSpace.lg,
              BattutaSpace.sm,
            ),
          ),
          const _SyncStatusCard(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BattutaSpace.lg,
              BattutaSpace.sm,
              BattutaSpace.lg,
              0,
            ),
            child: _RowsCard(
              children: [
                const AccountSection(),
                StageRow(
                  key: const ValueKey('supabase_config_tile'),
                  icon: Icons.dns_outlined,
                  label: l10n?.serverLabel ?? 'Server',
                  subtitle:
                      l10n?.supabaseConfigSubtitle ??
                      'Configure Project URL & Anon Key',
                  onTap: () => SupabaseConfigDialog.show(context),
                ),
                if (isAdmin) ...[
                  StageRow(
                    key: const ValueKey('gemini_api_key_tile'),
                    icon: Icons.key,
                    label: l10n?.geminiApiKeyLabel ?? 'Gemini API Key',
                    subtitle: apiKeyState.when(
                      data: (s) => s.isConfigured
                          ? '${s.maskedKey} (${s.isUserCustom ? (l10n?.customLabel ?? 'Custom') : (l10n?.devEnvLabel ?? 'Dev .env')})'
                          : (l10n?.geminiKeyNotConfigured ??
                                'Not configured — tap to enter key'),
                      loading: () => l10n?.loadingStatus ?? 'Loading status...',
                      error: (_, _) =>
                          l10n?.errorLoadingKey ?? 'Error loading key',
                    ),
                    onTap: () => ApiKeyDialog.show(context),
                  ),
                  StageRow(
                    key: const ValueKey('omr_debug_logs_tile'),
                    icon: Icons.receipt_long_outlined,
                    label: l10n?.omrDiagnosticLogs ?? 'OMR Diagnostic Logs',
                    subtitle:
                        l10n?.omrDiagnosticLogsSubtitle ??
                        'Inspect Gemini requests, latencies & responses',
                    onTap: () => OmrLogViewerModal.show(context),
                  ),
                ],
              ],
            ),
          ),

          // ── Workspace Resources & Quota ──
          const WorkspaceUsageGroup(),

          // ── About ──
          StageGroup(
            title: l10n?.aboutSection ?? 'About',
            children: [
              StageRow(
                key: const ValueKey('licenses_tile'),
                icon: Icons.code,
                label: l10n?.licensesLabel ?? 'Licenses',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Battuta',
                  applicationVersion: _appVersion,
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(BattutaSpace.lg),
                    child: Icon(
                      Icons.music_note,
                      size: 48,
                      color: brand.accentInk,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Footer ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BattutaSpace.lg,
              BattutaSpace.lg,
              BattutaSpace.lg,
              0,
            ),
            child: Column(
              children: [
                Text(
                  'Battuta $_appVersion',
                  key: const ValueKey('settings_version'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: brand.inkMuted),
                ),
                const SizedBox(height: BattutaSpace.xs),
                Text(
                  l10n?.footerAttribution ?? 'Made with ♪ for worship teams',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: brand.inkDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _languageName(AppLanguageOption option, AppLocalizations? l10n) =>
    switch (option) {
      AppLanguageOption.system => l10n?.languageSystemDefault ?? 'System',
      AppLanguageOption.english => l10n?.languageEnglish ?? 'English',
      AppLanguageOption.spanish => l10n?.languageSpanish ?? 'Español',
    };

Future<void> _showLanguageSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _LanguageSheet(),
    );

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
    final selected = ref.watch(appLanguageOptionProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          BattutaSpace.lg,
          0,
          BattutaSpace.lg,
          BattutaSpace.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: BattutaSpace.sm),
              child: Text(
                l10n?.languageLabel ?? 'Language',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: brand.ink,
                ),
              ),
            ),
            _RowsCard(
              children: [
                for (final option in AppLanguageOption.values)
                  StageRow(
                    key: ValueKey('language_option_${option.name}'),
                    label: _languageName(option, l10n),
                    trailing: option == selected
                        ? Icon(Icons.check, size: 20, color: brand.accentInk)
                        : const SizedBox(width: 20),
                    onTap: () {
                      ref
                          .read(appLanguageOptionProvider.notifier)
                          .setLanguage(option);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A bordered card of hairline-separated rows (a standalone [StageGroup]
/// body, used where the group already has its own header).
class _RowsCard extends StatelessWidget {
  const _RowsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BattutaRadius.mdAll,
        border: Border.all(color: brand.border),
      ),
      child: ClipRRect(
        borderRadius: BattutaRadius.mdAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: brand.border),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Sync state, last sync time and the "Sync now" action.
class _SyncStatusCard extends ConsumerWidget {
  const _SyncStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
    final syncState = ref.watch(cloudSyncProvider);
    final synced = syncState.lastSyncedAt?.toLocal();
    final time = synced == null
        ? ''
        : '${synced.hour.toString().padLeft(2, '0')}:${synced.minute.toString().padLeft(2, '0')}';

    final title = switch (syncState.status) {
      CloudSyncStatus.syncing => l10n?.syncingStatus ?? 'Syncing…',
      CloudSyncStatus.success => l10n?.syncedStatusLabel ?? 'Synced',
      CloudSyncStatus.offline => l10n?.syncOfflineTitle ?? 'Offline',
      CloudSyncStatus.error => l10n?.syncErrorTooltip ?? 'Sync error',
      CloudSyncStatus.idle => l10n?.readyToSync ?? 'Ready to sync',
    };
    final note = switch (syncState.status) {
      CloudSyncStatus.syncing =>
        l10n?.synchronizingDatabase ??
            'Synchronizing local Drift database with cloud…',
      CloudSyncStatus.success when synced != null =>
        l10n?.syncLastSyncedAt(time) ?? 'Last synced at $time',
      CloudSyncStatus.offline =>
        l10n?.offlineCached ?? 'Offline: Local changes safely cached',
      CloudSyncStatus.error when syncState.errorMessage != null =>
        syncState.errorMessage!,
      _ => l10n?.syncSavedOnDevice ?? 'Everything is also saved on this device',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BattutaSpace.lg),
      child: StageCard(
        key: const ValueKey('supabase_sync_status_tile'),
        child: Row(
          children: [
            const StageIconTile(icon: Icons.cloud_outlined, size: 40),
            const SizedBox(width: BattutaSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: brand.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: TextStyle(fontSize: 13, color: brand.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BattutaSpace.sm),
            if (syncState.isSyncing)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              OutlinedButton(
                key: const ValueKey('sync_now_btn'),
                onPressed: () =>
                    ref.read(cloudSyncProvider.notifier).triggerSync(),
                child: Text(l10n?.syncNow ?? 'Sync now'),
              ),
          ],
        ),
      ),
    );
  }
}
