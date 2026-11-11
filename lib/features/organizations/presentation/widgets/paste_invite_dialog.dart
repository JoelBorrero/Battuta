/// "Paste invite link or code": the way to join without opening a link
/// (desktop, or a code sent by message).
library;

import 'package:battuta/features/organizations/domain/services/invite_link_parser.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Asks for an invite link or token and returns the parsed token, or `null`
/// when cancelled.
Future<String?> showPasteInviteDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const _PasteInviteDialog(),
    );

class _PasteInviteDialog extends StatefulWidget {
  const _PasteInviteDialog();

  @override
  State<_PasteInviteDialog> createState() => _PasteInviteDialogState();
}

class _PasteInviteDialogState extends State<_PasteInviteDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final token = parseInviteInput(_controller.text);
    if (token == null) {
      setState(
        () => _error = AppLocalizations.of(context)!.joinPasteInvalid,
      );
      return;
    }
    Navigator.of(context).pop(token);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.joinPasteTitle),
      content: SingleChildScrollView(
        child: TextField(
          key: const ValueKey('paste_invite_field'),
          controller: _controller,
          autofocus: true,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: l10n.joinPasteLabel,
            hintText: 'battuta://join/…',
            errorText: _error,
            errorMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('paste_invite_submit_btn'),
          onPressed: _submit,
          child: Text(l10n.joinPasteSubmit),
        ),
      ],
    );
  }
}
