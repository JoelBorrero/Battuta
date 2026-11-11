/// Battuta — Supabase Configuration Dialog.
///
/// Modal allowing musicians and directors to enter custom Supabase project credentials
/// or clear custom overrides to fall back to environment defaults. When `.env`
/// names a remote and a local server, both are offered as one-tap choices.
///
/// Saving checks that the server answers before storing it, then says whether
/// the app is connected or needs a restart: the Supabase SDK keeps the server
/// it started with until the app is reopened.
library;

import 'package:battuta/core/services/supabase_client_manager.dart';
import 'package:battuta/core/services/supabase_config_service.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SupabaseConfigDialog extends ConsumerStatefulWidget {
  const SupabaseConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const SupabaseConfigDialog(),
    );
  }

  @override
  ConsumerState<SupabaseConfigDialog> createState() =>
      _SupabaseConfigDialogState();
}

class _SupabaseConfigDialogState extends ConsumerState<SupabaseConfigDialog> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;
  List<SupabasePreset> _presets = const [];

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onFieldsChanged);
    _keyController.addListener(_onFieldsChanged);
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  /// Rebuilds so the preset choice follows what is typed.
  void _onFieldsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCurrentConfig() async {
    final configService = ref.read(supabaseConfigServiceProvider);
    final url = await configService.getActiveUrl();
    final key = await configService.getActiveAnonKey();
    final presets = configService.presets();
    if (mounted) {
      setState(() {
        _urlController.text = url ?? '';
        _keyController.text = key ?? '';
        _presets = presets;
        _loading = false;
      });
    }
  }

  SupabasePresetKind? get _selectedPreset {
    final url = _urlController.text.trim();
    final key = _keyController.text.trim();
    for (final preset in _presets) {
      if (preset.url == url && preset.key == key) return preset.kind;
    }
    return null;
  }

  void _applyPreset(SupabasePresetKind kind) {
    final preset = _presets.firstWhere((p) => p.kind == kind);
    _urlController.text = preset.url;
    _keyController.text = preset.key;
    setState(() => _errorMessage = null);
  }

  static String _host(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;
    final url = _urlController.text.trim();
    final key = _keyController.text.trim();

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() => _errorMessage = l10n.supabaseUrlInvalid);
      return;
    }
    if (key.isEmpty) {
      setState(() => _errorMessage = l10n.supabaseKeyEmpty);
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final configService = ref.read(supabaseConfigServiceProvider);
    final reachable = await configService.checkReachable(url: url, key: key);
    if (!mounted) return;
    if (!reachable) {
      setState(() {
        _errorMessage = l10n.supabaseUnreachable(_host(url));
        _saving = false;
      });
      return;
    }

    try {
      await configService.setCustomConfig(url: url, anonKey: key);
      await ref
          .read(supabaseClientManagerProvider)
          .initialize(customUrl: url, customAnonKey: key);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _saving = false;
        });
      }
      return;
    }
    if (mounted) _closeWithResult(url);
  }

  Future<void> _handleClear() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final configService = ref.read(supabaseConfigServiceProvider);
      await configService.clearCustomConfig();
      await ref.read(supabaseClientManagerProvider).initialize();
      final url = await configService.getActiveUrl();
      if (mounted) _closeWithResult(url ?? '');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _saving = false;
        });
      }
    }
  }

  /// Closes the dialog and says where the app now syncs: connected when the
  /// running client already uses [url], otherwise saved for the next launch.
  void _closeWithResult(String url) {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final active = SupabaseClientManager.activeUrl;
    final connected = active != null && active == url;
    Navigator.of(context).pop();
    messenger?.showSnackBar(
      SnackBar(
        key: ValueKey(
          connected ? 'supabase_connected_snack' : 'supabase_restart_snack',
        ),
        content: Text(
          connected
              ? l10n.supabaseConnectedTo(_host(url))
              : l10n.supabaseSavedRestart(_host(url)),
        ),
        duration: Duration(seconds: connected ? 3 : 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selected = _selectedPreset;

    return AlertDialog(
      scrollable: true,
      title: Text(l10n?.supabaseProjectSetup ?? 'Supabase Project Setup'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            Text(
              l10n?.supabaseConfigExplanation ?? 'Enter your Supabase project endpoint and anon public key to enable cloud sync.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (_presets.length > 1 && l10n != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in _presets)
                    ChoiceChip(
                      key: ValueKey('supabase_preset_${preset.kind.name}'),
                      avatar: Icon(
                        preset.kind == SupabasePresetKind.remote
                            ? Icons.cloud_outlined
                            : Icons.computer_outlined,
                        size: 18,
                      ),
                      label: Text(
                        preset.kind == SupabasePresetKind.remote
                            ? l10n.supabasePresetRemote
                            : l10n.supabasePresetLocal,
                      ),
                      selected: selected == preset.kind,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: _saving
                          ? null
                          : (_) => _applyPreset(preset.kind),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  key: const ValueKey('supabase_config_error'),
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            TextField(
              key: const ValueKey('supabase_config_url_field'),
              controller: _urlController,
              decoration: InputDecoration(
                labelText: l10n?.projectUrlLabel ?? 'Project URL',
                hintText: 'https://xyzcompany.supabase.co',
                prefixIcon: const Icon(Icons.link),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('supabase_config_key_field'),
              controller: _keyController,
              decoration: InputDecoration(
                labelText: l10n?.anonPublicKeyLabel ?? 'Anon Public Key',
                hintText: 'sb_publishable_…',
                prefixIcon: const Icon(Icons.key_outlined),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('supabase_config_restore_btn'),
          onPressed: _saving ? null : _handleClear,
          child: Text(l10n?.restoreDefault ?? 'Restore Default'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          key: const ValueKey('supabase_config_save_btn'),
          onPressed: _saving ? null : _handleSave,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n?.saveAndConnect ?? 'Save & Connect'),
        ),
      ],
    );
  }
}
