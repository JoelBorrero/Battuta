/// The "deactivate account" confirmation: the username (or email) must be
/// typed before the button enables.
library;

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/features/auth/presentation/providers/account_notice_provider.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks for confirmation, then deactivates the account (which signs out and
/// shows the notice). A failure (e.g. offline) is reported in a snackbar.
Future<void> confirmDeactivateAccount(
  BuildContext context,
  WidgetRef ref, {
  required String confirmWord,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _DeactivateDialog(confirmWord: confirmWord),
  );
  if (confirmed != true || !context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(authRepositoryProvider).deactivateAccount();
    ref.read(accountNoticeProvider.notifier).show(AccountNotice.deactivated);
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text(backendErrorMessage(l10n, error))),
    );
  }
}

class _DeactivateDialog extends StatefulWidget {
  const _DeactivateDialog({required this.confirmWord});

  final String confirmWord;

  @override
  State<_DeactivateDialog> createState() => _DeactivateDialogState();
}

class _DeactivateDialogState extends State<_DeactivateDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final matches = _controller.text.trim() == widget.confirmWord;
    return AlertDialog(
      title: Text(l10n.accountDeactivateTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.accountDeactivateExplanation),
            const SizedBox(height: 12),
            Text(l10n.accountDeactivateTypeToConfirm(widget.confirmWord)),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('deactivate_confirm_field'),
              controller: _controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('deactivate_confirm_btn'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(l10n.accountDeactivateAction),
        ),
      ],
    );
  }
}
