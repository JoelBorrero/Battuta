/// A merge request: both song titles, who asks, and Accept / Decline for the
/// creator who has to answer. Reached from the inbox.
library;

import 'dart:async';

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:battuta/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MergeRequestPage extends ConsumerStatefulWidget {
  const MergeRequestPage({required this.requestId, super.key});

  final String requestId;

  @override
  ConsumerState<MergeRequestPage> createState() => _MergeRequestPageState();
}

class _MergeRequestPageState extends ConsumerState<MergeRequestPage> {
  bool _busy = false;
  String? _error;

  Future<void> _respond(SongMergeRequest request, bool accept) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(songSharingRepositoryProvider)
        .respondToMerge(request.id, accept: accept);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (failure) => setState(() => _error = backendErrorMessage(l10n, failure)),
      (answered) {
        ref.invalidate(mergeRequestProvider(request.id));
        ref.invalidate(pendingMergeRequestsProvider);
        if (accept) {
          // Cached versions move to the surviving song with the next sync.
          ref.invalidate(repertoireProvider);
          unawaited(ref.read(cloudSyncProvider.notifier).triggerSync());
          messenger.showSnackBar(SnackBar(content: Text(l10n.mergeAccepted)));
          unawaited(
            router.pushReplacement(AppRoutes.songPage(request.targetSongId)),
          );
        } else {
          messenger.showSnackBar(SnackBar(content: Text(l10n.mergeDeclined)));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final me = ref.watch(currentAccountIdProvider);
    final request = ref.watch(mergeRequestProvider(widget.requestId));

    final body = request.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => StageEmptyState(
        key: const ValueKey('merge_request_error'),
        icon: Icons.cloud_off_outlined,
        title: l10n.mergeRequestTitle,
        message: backendErrorMessage(l10n, error),
        tone: theme.colorScheme.error,
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(44, 44)),
            onPressed: () =>
                ref.invalidate(mergeRequestProvider(widget.requestId)),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
      data: (data) {
        final canAnswer = data.isPending && data.approverId == me;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DecoratedBox(
              decoration: brand.cardDecoration(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mergeRequestBody(
                        data.requesterName ?? l10n.mergeRequesterUnknown,
                        data.sourceTitle,
                        data.targetTitle,
                      ),
                      key: const ValueKey('merge_request_body'),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!data.isPending)
              Text(
                l10n.mergeAlreadyAnswered,
                key: const ValueKey('merge_request_answered'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: brand.inkMuted,
                ),
              )
            else if (canAnswer) ...[
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    key: const ValueKey('merge_request_send_error'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    key: const ValueKey('merge_accept_btn'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 48),
                    ),
                    onPressed: _busy ? null : () => _respond(data, true),
                    child: Text(l10n.mergeAccept),
                  ),
                  OutlinedButton(
                    key: const ValueKey('merge_decline_btn'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(120, 48),
                    ),
                    onPressed: _busy ? null : () => _respond(data, false),
                    child: Text(l10n.mergeDecline),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mergeRequestTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: body,
        ),
      ),
    );
  }
}
