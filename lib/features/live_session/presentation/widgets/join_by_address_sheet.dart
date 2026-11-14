/// Battuta — "Join by address" sheet: type `192.168.1.20`, `ip:port` or
/// paste a `battuta-live://` link.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/live_session/presentation/widgets/live_connect_texts.dart';
import 'package:battuta/features/sync/domain/models/live_join_address.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Shows the sheet; resolves to the parsed address, or `null` if dismissed.
Future<LiveJoinAddress?> showJoinByAddressSheet(BuildContext context) =>
    showModalBottomSheet<LiveJoinAddress>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => const JoinByAddressSheet(),
    );

class JoinByAddressSheet extends StatefulWidget {
  const JoinByAddressSheet({super.key});

  @override
  State<JoinByAddressSheet> createState() => _JoinByAddressSheetState();
}

class _JoinByAddressSheetState extends State<JoinByAddressSheet> {
  final _controller = TextEditingController();
  LiveJoinAddressError? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    try {
      final address = LiveJoinAddress.parse(_controller.text);
      Navigator.of(context).pop(address);
    } on LiveJoinAddressException catch (e) {
      setState(() => _error = e.reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n?.liveJoinByAddress ?? 'Join by address',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('live_address_field'),
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              autocorrect: false,
              enableSuggestions: false,
              onSubmitted: (_) => _submit(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              style: TextStyle(
                fontFamily: AppTheme.monoFontFamily,
                fontFamilyFallback: AppTheme.monoFontFallbacks,
                color: brand.ink,
              ),
              decoration: InputDecoration(
                labelText: l10n?.liveAddressLabel ?? 'Address',
                hintText:
                    l10n?.liveAddressHint ??
                    '192.168.1.20 or 192.168.1.20:47320',
                helperText:
                    l10n?.liveAddressHelp ??
                    'You can also paste a battuta-live:// link.',
                helperMaxLines: 2,
                errorText: _error == null
                    ? null
                    : liveAddressErrorText(l10n, _error!),
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('live_address_join'),
              style: FilledButton.styleFrom(
                backgroundColor: brand.accent,
                foregroundColor: brand.onAccent,
                minimumSize: const Size(44, 48),
              ),
              onPressed: _submit,
              child: Text(l10n?.liveJoinAction ?? 'Join'),
            ),
          ],
        ),
      ),
    );
  }
}
