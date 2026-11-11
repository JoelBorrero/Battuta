/// Forking a version into my library: asks for a name, forks (online through
/// the backend, offline as a local copy) and opens the copy in the editor.
library;

import 'dart:async';

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Asks how to name the copy of a version called [sourceLabel]. Returns the
/// name, or `null` when cancelled.
Future<String?> showForkDialog(BuildContext context, String sourceLabel) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<String>(
    context: context,
    builder: (_) =>
        _ForkDialog(initialLabel: l10n.forkDefaultLabel(sourceLabel)),
  );
}

/// The whole fork flow for version [versionId]. [cachedSource] is the version
/// when it is on this device, which lets the fork work offline.
Future<void> forkVersionFlow(
  BuildContext context,
  WidgetRef ref, {
  required String versionId,
  required String sourceLabel,
  Song? cachedSource,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final label = await showForkDialog(context, sourceLabel);
  if (label == null) return;

  final result = await ref
      .read(songSharingRepositoryProvider)
      .forkVersion(versionId, label: label, cachedSource: cachedSource);
  result.fold(
    (failure) => messenger.showSnackBar(
      SnackBar(content: Text(backendErrorMessage(l10n, failure))),
    ),
    (forked) {
      ref.invalidate(repertoireProvider);
      // Online forks already reached the backend; an offline one is pushed
      // (with its lineage) by the next sync.
      unawaited(ref.read(cloudSyncProvider.notifier).triggerSync());
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            forked.madeOffline ? l10n.forkDoneOffline : l10n.forkDone,
          ),
        ),
      );
      unawaited(router.push(AppRoutes.songEditor(forked.song.id)));
    },
  );
}

class _ForkDialog extends StatefulWidget {
  const _ForkDialog({required this.initialLabel});

  final String initialLabel;

  @override
  State<_ForkDialog> createState() => _ForkDialogState();
}

class _ForkDialogState extends State<_ForkDialog> {
  late final TextEditingController _label = TextEditingController(
    text: widget.initialLabel,
  );

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.forkDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.forkDialogBody),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('fork_label_field'),
              controller: _label,
              autofocus: true,
              maxLength: 100,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.forkLabelField,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('fork_confirm_btn'),
          style: FilledButton.styleFrom(minimumSize: const Size(44, 44)),
          onPressed: _label.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_label.text.trim()),
          child: Text(l10n.forkConfirm),
        ),
      ],
    );
  }
}
