/// Modal dialog for viewing, entering, and clearing the Gemini API key.
library;

import 'package:battuta/core/services/api_key_service.dart';
import 'package:battuta/features/settings/presentation/providers/api_key_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Displays the Gemini API key entry and management dialog.
class ApiKeyDialog extends ConsumerStatefulWidget {
  const ApiKeyDialog({super.key});

  /// Helper to show the dialog.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const ApiKeyDialog(),
    );
  }

  @override
  ConsumerState<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends ConsumerState<ApiKeyDialog> {
  late final TextEditingController _controller;
  bool _obscureText = true;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final key = _controller.text.trim();
    if (!ApiKeyService.isValidKey(key)) {
      setState(() {
        _errorMessage =
            'API key must be at least 20 characters with no spaces.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    try {
      await ref.read(apiKeyNotifierProvider.notifier).setCustomKey(key);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.geminiApiKeySaved ?? 'Gemini API key saved securely.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save key: $e';
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleClear() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.removeApiKeyTitle ?? 'Remove API Key?'),
        content: const Text(
          'This will delete your custom API key from secure storage. '
          'AI-powered features may be unavailable unless a fallback key exists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n?.delete ?? 'Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(apiKeyNotifierProvider.notifier).clearCustomKey();
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.customApiKeyRemoved ?? 'Custom API key removed.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _controller.text = text;
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final apiKeyState = ref.watch(apiKeyNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.key),
          const SizedBox(width: 8),
          Text(l10n?.geminiApiKeyLabel ?? 'Gemini API Key'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A Google Gemini API key is required for Optical Music Recognition '
              '(OMR) and smart sheet-music extraction. Keys are stored encrypted '
              'in your device Keychain / KeyStore.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Current status banner
            apiKeyState.when(
              data: (state) {
                final sourceLabel = switch (state.source) {
                  ApiKeySource.userSecureStorage =>
                    'Custom key (Secure Storage)',
                  ApiKeySource.envFile => 'Development key (.env file)',
                  ApiKeySource.none => 'None configured',
                };

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: state.isConfigured
                        ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                        : colorScheme.errorContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: state.isConfigured
                          ? colorScheme.primary.withValues(alpha: 0.2)
                          : colorScheme.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.isConfigured
                            ? Icons.check_circle
                            : Icons.warning_amber,
                        size: 20,
                        color: state.isConfigured
                            ? colorScheme.primary
                            : colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.maskedKey,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              sourceLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text(
                'Error loading key state: $err',
                style: TextStyle(color: colorScheme.error),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _controller,
              obscureText: _obscureText,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Enter new API Key',
                hintText: 'AIzaSy...',
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      tooltip: _obscureText ? 'Show key' : 'Hide key',
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.paste),
                      tooltip: 'Paste from clipboard',
                      onPressed: _handlePaste,
                    ),
                  ],
                ),
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Get a free Gemini API key from Google AI Studio (aistudio.google.com).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Show clear button only if user custom key is currently set
        if (apiKeyState.value?.isUserCustom ?? false)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            onPressed: _isSaving ? null : _handleClear,
            child: Text(l10n?.removeKey ?? 'Remove Key'),
          ),
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n?.saveKey ?? 'Save Key'),
        ),
      ],
    );
  }
}
