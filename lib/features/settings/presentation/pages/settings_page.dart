/// Battuta — Settings page.
///
/// Provides app-level configuration options including theme selection,
/// API key management (placeholder), version display, and about info.
library;

import 'package:battuta/features/settings/presentation/providers/api_key_provider.dart';
import 'package:battuta/features/settings/presentation/widgets/api_key_dialog.dart';
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
                selected: const {ThemeMode.system},
                onSelectionChanged: (modes) {
                  // TODO: Wire to a theme-mode provider.
                },
              ),
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
