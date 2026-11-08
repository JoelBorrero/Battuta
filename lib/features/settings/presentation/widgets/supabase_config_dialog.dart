/// Battuta — Supabase Configuration Dialog.
///
/// Modal allowing musicians and directors to enter custom Supabase project credentials
/// or clear custom overrides to fall back to environment defaults.
library;

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
  ConsumerState<SupabaseConfigDialog> createState() => _SupabaseConfigDialogState();
}

class _SupabaseConfigDialogState extends ConsumerState<SupabaseConfigDialog> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentConfig() async {
    final configService = ref.read(supabaseConfigServiceProvider);
    final url = await configService.getActiveUrl();
    final key = await configService.getActiveAnonKey();
    if (mounted) {
      setState(() {
        _urlController.text = url ?? '';
        _keyController.text = key ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    final url = _urlController.text.trim();
    final key = _keyController.text.trim();

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() => _errorMessage = 'URL must begin with https:// or http://');
      return;
    }
    if (key.isEmpty) {
      setState(() => _errorMessage = 'Anon public key cannot be empty');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final configService = ref.read(supabaseConfigServiceProvider);
      await configService.setCustomConfig(url: url, anonKey: key);

      final clientManager = ref.read(supabaseClientManagerProvider);
      await clientManager.initialize(customUrl: url, customAnonKey: key);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _saving = false;
        });
      }
    }
  }

  Future<void> _handleClear() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final configService = ref.read(supabaseConfigServiceProvider);
      await configService.clearCustomConfig();

      final clientManager = ref.read(supabaseClientManagerProvider);
      await clientManager.initialize();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n?.supabaseProjectSetup ?? 'Supabase Project Setup'),
      content: SingleChildScrollView(
        child: SizedBox(
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
                l10n?.supabaseConfigExplanation ??
                    'Enter your Supabase project endpoint and anon public key to enable cloud sync.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
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
                  hintText: 'eyJhbGciOiJIUzI1NiIsIn...',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
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
