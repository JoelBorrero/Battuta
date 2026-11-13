/// The repertoire of one organization: members read it, admins curate it.
///
/// [OrgRepertoireView] is a sliver: the Repertoire page scrolls it together
/// with its header.
library;

import 'dart:async';

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_scope_providers.dart';
import 'package:battuta/features/repertoire/presentation/widgets/add_to_repertoire_sheet.dart';
import 'package:battuta/features/repertoire/presentation/widgets/version_owner_text.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A sliver listing the repertoire of [organization].
class OrgRepertoireView extends ConsumerWidget {
  const OrgRepertoireView({required this.organization, super.key});

  final Organization organization;

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    RepertoireEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeFromRepertoireTitle),
        content: Text(l10n.removeFromRepertoireConfirm(entry.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirm_remove_from_repertoire'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.removeFromRepertoireAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await ref
        .read(organizationRepertoireRepositoryProvider)
        .removeFromRepertoire(organization.id, entry.versionId);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.fold(
            (failure) => backendErrorMessage(l10n, failure),
            (_) => l10n.removeFromRepertoireDone(entry.title),
          ),
        ),
      ),
    );
  }

  /// Opens the version if it is on this device; otherwise pulls it first.
  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    RepertoireEntry entry,
  ) async {
    bool isLocal() =>
        ref
            .read(repertoireProvider)
            .value
            ?.any((song) => song.id == entry.versionId) ??
        false;
    if (!isLocal()) {
      await ref.read(cloudSyncProvider.notifier).triggerSync();
      if (!context.mounted || !isLocal()) return;
    }
    unawaited(context.push(AppRoutes.songDetail(entry.versionId)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localIds = {
      for (final song in ref.watch(repertoireProvider).value ?? const [])
        song.id,
    };
    final syncing = ref.watch(
      cloudSyncProvider.select((state) => state.isSyncing),
    );
    final entriesAsync = ref.watch(
      organizationRepertoireProvider(organization.id),
    );
    final isAdmin = organization.isAdmin;

    return entriesAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: StageEmptyState(
          icon: Icons.error_outline,
          tone: theme.colorScheme.error,
          title: l10n.failedToLoadRepertoire,
          message: backendErrorMessage(l10n, error),
          actions: [
            FilledButton.icon(
              onPressed: () => ref.invalidate(
                organizationRepertoireProvider(organization.id),
              ),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: StageEmptyState(
              icon: Icons.library_music_outlined,
              title: l10n.orgRepertoireEmptyTitle,
              message: isAdmin
                  ? l10n.orgRepertoireEmptyAdminHint
                  : l10n.orgRepertoireEmptyMemberHint,
              actions: [
                if (isAdmin)
                  FilledButton.icon(
                    key: const ValueKey('empty_add_to_repertoire'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addToRepertoireAction),
                    onPressed: () =>
                        showAddToRepertoireSheet(context, organization),
                  ),
              ],
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            BattutaSpace.lg,
            BattutaSpace.md,
            BattutaSpace.lg,
            96,
          ),
          sliver: SliverList.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return BattutaEntrance(
                index: index,
                child: _EntryCard(
                  key: ValueKey('repertoire_entry_${entry.versionId}'),
                  entry: entry,
                  isLocal: localIds.contains(entry.versionId),
                  syncing: syncing,
                  onOpen: () => _open(context, ref, entry),
                  onRemove: isAdmin
                      ? () => _confirmRemove(context, ref, entry)
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.isLocal,
    required this.syncing,
    required this.onOpen,
    this.onRemove,
    super.key,
  });

  final RepertoireEntry entry;

  /// Whether the version is already on this device (else it opens as
  /// "Song not found").
  final bool isLocal;
  final bool syncing;
  final VoidCallback onOpen;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);

    return StageCard(
      onTap: onOpen,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: BattutaSpace.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: brand.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (entry.artist.isNotEmpty) ...[
                  const SizedBox(height: BattutaSpace.xxs),
                  Text(
                    entry.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: brand.inkMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: BattutaSpace.xs),
                Text(
                  '${entry.label} · ${ownedByText(l10n, entry)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: brand.inkMuted,
                  ),
                ),
                if (!isLocal)
                  Padding(
                    padding: const EdgeInsets.only(top: BattutaSpace.xxs),
                    child: Text(
                      syncing
                          ? l10n.repertoireEntrySyncing
                          : l10n.repertoireEntryAfterSync,
                      key: ValueKey('entry_pending_${entry.versionId}'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: brand.accentInk,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: BattutaSpace.md),
          StageKeyPill(entry.key),
          if (onRemove != null)
            IconButton(
              key: ValueKey('remove_entry_${entry.versionId}'),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: Icon(
                Icons.remove_circle_outline,
                size: 20,
                color: brand.danger,
              ),
              tooltip: l10n.removeFromRepertoireAction,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
