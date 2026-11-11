/// The versions of one song: cached ones at once, the backend's when it
/// answers. Each row opens (read-only unless mine) or forks.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/widgets/version_owner_text.dart';
import 'package:battuta/features/sharing/domain/entities/song_version_row.dart';
import 'package:battuta/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:battuta/features/sharing/presentation/widgets/fork_version_flow.dart';
import 'package:battuta/features/sharing/presentation/widgets/visibility_text.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SongVersionsSection extends ConsumerWidget {
  const SongVersionsSection({
    required this.songWorkId,
    required this.title,
    this.currentVersionId,
    super.key,
  });

  /// The song whose versions are listed.
  final String songWorkId;

  /// The heading ("Other versions", "Versions").
  final String title;

  /// A version to leave out (the one being viewed).
  final String? currentVersionId;

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    SongVersionRow row,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    if (!row.isCached) {
      final result = await ref
          .read(songSharingRepositoryProvider)
          .openVersion(row.versionId);
      final failure = result.fold((f) => f, (_) => null);
      if (failure != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              failure.errorCode == BackendErrorCode.offline
                  ? l10n.versionNeedsInternet
                  : backendErrorMessage(l10n, failure),
            ),
          ),
        );
        return;
      }
      ref.invalidate(repertoireProvider);
    }
    final pins = ref.read(pinnedVersionsProvider)..pin(row.versionId);
    try {
      await router.push(AppRoutes.songDetail(row.versionId));
    } finally {
      pins.release(row.versionId);
    }
  }

  Song? _cached(WidgetRef ref, String versionId) {
    for (final song in ref.read(repertoireProvider).value ?? const <Song>[]) {
      if (song.id == versionId) return song;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final me = ref.watch(currentAccountIdProvider);
    final state = ref.watch(songVersionsProvider(songWorkId));
    final rows = [
      for (final row in state.rows)
        if (row.versionId != currentVersionId) row,
    ];
    final labels = {for (final row in state.rows) row.versionId: row.label};
    final failure = state.failure;

    return Column(
      key: const ValueKey('song_versions_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (state.loading)
          Padding(
            key: const ValueKey('versions_loading'),
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.versionsLoading,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: brand.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (failure != null)
          Padding(
            key: const ValueKey('versions_failure'),
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              failure.errorCode == BackendErrorCode.offline
                  ? l10n.versionsOfflineNote
                  : backendErrorMessage(l10n, failure),
              style: theme.textTheme.bodySmall?.copyWith(color: brand.inkMuted),
            ),
          ),
        if (rows.isEmpty && !state.loading)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.versionsEmpty,
              key: const ValueKey('versions_empty'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: brand.inkMuted,
              ),
            ),
          ),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _VersionRowTile(
              row: row,
              mine: row.isMine(me),
              parentLabel: labels[row.forkedFromVersionId],
              onOpen: () => _open(context, ref, row),
              onFork: () => forkVersionFlow(
                context,
                ref,
                versionId: row.versionId,
                sourceLabel: row.label,
                cachedSource: _cached(ref, row.versionId),
              ),
            ),
          ),
      ],
    );
  }
}

class _VersionRowTile extends StatelessWidget {
  const _VersionRowTile({
    required this.row,
    required this.mine,
    required this.parentLabel,
    required this.onOpen,
    required this.onFork,
  });

  final SongVersionRow row;
  final bool mine;
  final String? parentLabel;
  final VoidCallback onOpen;
  final VoidCallback onFork;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final owner = mine
        ? l10n.versionYours
        : (row.ownerName == null && row.ownerId == null
              ? null
              : ownedByText(l10n, row));

    return DecoratedBox(
      key: ValueKey('version_row_${row.versionId}'),
      decoration: brand.cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: BattutaPressable(
              onTap: onOpen,
              semanticLabel: l10n.versionOpenTooltip(row.label),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (owner != null)
                        Text(
                          owner,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: brand.inkMuted,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Badge(
                            key: ValueKey(
                              'version_visibility_${row.versionId}',
                            ),
                            icon: visibilityIcon(row.visibility),
                            text: visibilityBadgeText(l10n, row.visibility),
                          ),
                          _Badge(text: l10n.songKeyBadge(row.key)),
                          if (row.forkedFromVersionId != null)
                            _Badge(
                              key: ValueKey('version_fork_${row.versionId}'),
                              icon: Icons.call_split,
                              text: parentLabel == null
                                  ? l10n.versionFork
                                  : l10n.versionForkOf(parentLabel!),
                            ),
                          if (row.isCached)
                            _Badge(
                              icon: Icons.download_done,
                              text: l10n.versionOnDevice,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            key: ValueKey('fork_version_${row.versionId}'),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            tooltip: l10n.forkTooltip(row.label),
            icon: Icon(Icons.call_split, color: brand.accentInk),
            onPressed: onFork,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.icon, super.key});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(BattutaRadius.xs)),
        border: Border.all(color: brand.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: brand.inkMuted),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: brand.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
