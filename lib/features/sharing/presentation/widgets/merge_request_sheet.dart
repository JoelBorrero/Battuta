/// Asks to merge two copies of the same song.
///
/// * From a song I created: pick the song it duplicates; its versions would
///   move under the one I pick.
/// * From a song somebody else created: pick one of my own songs that is the
///   same song; my song's versions would move under this one.
///
/// The creator of the other song approves. Online only. A request that is
/// already pending between the two songs cannot be sent again.
library;

import 'dart:async';

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:battuta/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the merge sheet of song [songWorkId] ([title]). [createdByMe] says
/// whether I created that song (see `Song.canEditTitleBy`).
Future<void> showMergeRequestSheet(
  BuildContext context, {
  required String songWorkId,
  required String title,
  required bool createdByMe,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (_) => MergeRequestSheet(
    songWorkId: songWorkId,
    title: title,
    createdByMe: createdByMe,
  ),
);

class MergeRequestSheet extends ConsumerStatefulWidget {
  const MergeRequestSheet({
    required this.songWorkId,
    required this.title,
    required this.createdByMe,
    this.debounce = const Duration(milliseconds: 350),
    super.key,
  });

  final String songWorkId;
  final String title;
  final bool createdByMe;
  final Duration debounce;

  @override
  ConsumerState<MergeRequestSheet> createState() => _MergeRequestSheetState();
}

class _MergeRequestSheetState extends ConsumerState<MergeRequestSheet> {
  final _query = TextEditingController();
  Timer? _debounce;
  int _request = 0;
  bool _loading = true;
  Object? _error;
  String? _sendError;
  List<SongWork> _results = const [];
  final Set<String> _sending = {};

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, _search);
  }

  Future<void> _search() async {
    if (ref.read(currentAccountIdProvider) == null) {
      setState(() => _loading = false);
      return;
    }
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(songSharingRepositoryProvider)
        .searchSongs(_query.text, onlyMine: !widget.createdByMe);
    if (!mounted || request != _request) return;
    setState(() {
      _loading = false;
      result.fold(
        (failure) {
          _error = failure;
          _results = const [];
        },
        (found) => _results = [
          for (final song in found)
            if (song.id != widget.songWorkId) song,
        ],
      );
    });
  }

  Future<void> _send(SongWork other) async {
    final l10n = AppLocalizations.of(context)!;
    // The song I created is merged into the other one; when somebody else
    // created this song, my own song is merged into it.
    final sourceTitle = widget.createdByMe ? widget.title : other.title;
    final targetTitle = widget.createdByMe ? other.title : widget.title;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.mergeConfirmTitle),
        content: Text(l10n.mergeConfirmBody(sourceTitle, targetTitle)),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('merge_confirm_btn'),
            style: FilledButton.styleFrom(minimumSize: const Size(44, 44)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.mergeRequestAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _sending.add(other.id);
      _sendError = null;
    });
    final result = await ref
        .read(songSharingRepositoryProvider)
        .requestMerge(
          sourceSongId: widget.createdByMe ? widget.songWorkId : other.id,
          targetSongId: widget.createdByMe ? other.id : widget.songWorkId,
        );
    if (!mounted) return;
    setState(() => _sending.remove(other.id));
    result.fold(
      (failure) =>
          setState(() => _sendError = backendErrorMessage(l10n, failure)),
      (request) {
        ref.invalidate(pendingMergeRequestsProvider);
        final merged = request.status == MergeRequestStatus.accepted;
        if (merged) {
          // Both songs were mine (or the other creator left): merged at once.
          ref.invalidate(repertoireProvider);
          unawaited(ref.read(cloudSyncProvider.notifier).triggerSync());
        }
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(content: Text(merged ? l10n.mergeDone : l10n.mergeSent)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final signedIn = ref.watch(currentAccountIdProvider) != null;
    final pending = ref.watch(pendingMergeRequestsProvider).value ?? const [];

    Widget body;
    if (!signedIn) {
      body = _Message(l10n.mergeSignIn, key: const ValueKey('merge_sign_in'));
    } else if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      final offline =
          _error is Failure &&
          (_error! as Failure).errorCode == BackendErrorCode.offline;
      body = _Message(
        offline ? l10n.mergeNeedsInternet : backendErrorMessage(l10n, _error!),
        key: const ValueKey('merge_error'),
        retry: _search,
        retryLabel: l10n.retry,
      );
    } else if (_results.isEmpty) {
      body = _Message(l10n.mergeNoResults, key: const ValueKey('merge_empty'));
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _results.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final song = _results[index];
          final isPending = pending.any(
            (r) => r.isPending && r.connects(widget.songWorkId, song.id),
          );
          return ConstrainedBox(
            key: ValueKey('merge_candidate_${song.id}'),
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (song.artist.isNotEmpty)
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: brand.inkMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isPending)
                  Flexible(
                    child: Text(
                      l10n.mergePendingBadge,
                      key: ValueKey('merge_pending_${song.id}'),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: brand.accentInk,
                      ),
                    ),
                  )
                else
                  TextButton(
                    key: ValueKey('merge_request_${song.id}'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                    ),
                    onPressed: _sending.contains(song.id)
                        ? null
                        : () => _send(song),
                    child: Text(
                      l10n.mergeRequestAction,
                      textAlign: TextAlign.end,
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.mergeSheetTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  widget.createdByMe
                      ? l10n.mergeIntroMine(widget.title)
                      : l10n.mergeIntroOther(widget.title),
                  key: const ValueKey('merge_intro'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: brand.inkMuted,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  key: const ValueKey('merge_search_field'),
                  controller: _query,
                  onChanged: _onQueryChanged,
                  onSubmitted: (_) => _search(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: l10n.mergeSearchLabel,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              if (_sendError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    _sendError!,
                    key: const ValueKey('merge_send_error'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.retry, this.retryLabel, super.key});

  final String text;
  final VoidCallback? retry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          if (retry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(44, 44)),
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel ?? ''),
            ),
          ],
        ],
      ),
    ),
  );
}
