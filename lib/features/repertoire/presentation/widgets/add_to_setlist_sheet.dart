/// Bottom sheet of the song detail page that adds the song to a setlist.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_scope_providers.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the sheet listing the setlists [song] can be added to.
Future<void> showAddToSetlistSheet(BuildContext context, Song song) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => AddToSetlistSheet(song: song),
  );
}

/// Lists the setlists the current user may edit and appends [song] to the one
/// that is tapped. A setlist that already holds the song is marked and inert.
class AddToSetlistSheet extends ConsumerWidget {
  const AddToSetlistSheet({required this.song, super.key});

  final Song song;

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    Setlist setlist,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // The sheet closes before the save ends: take everything that needs the
    // widget (ref, context) now.
    final notifier = ref.read(setlistsProvider.notifier);
    final container = ProviderScope.containerOf(context);
    final item = SetlistItem(
      id: 'item_${DateTime.now().microsecondsSinceEpoch}',
      songId: song.id,
      orderIndex: setlist.items.length,
    );
    final updated = setlist.copyWith(
      items: [...setlist.items, item],
      updatedAt: DateTime.now(),
    );
    navigator.pop();
    try {
      await notifier.updateSetlist(updated);
      container.invalidate(setlistByIdProvider(setlist.id));
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.addedToSetlist(setlist.title))),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(backendErrorMessage(l10n, e))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final brand = BattutaBrand.of(context);
    final isOrgAdmin = ref.watch(organizationAdminCheckProvider);
    final setlists = ref.watch(setlistsProvider).value ?? const <Setlist>[];

    // Personal setlists take my own versions; an organization's setlist takes
    // versions of its repertoire and is edited by its admins only.
    final myVersion =
        ref.watch(myLibraryProvider).value?.any((s) => s.id == song.id) ??
        false;
    bool canAddTo(Setlist s) {
      final organizationId = s.organizationId;
      if (organizationId == null) return myVersion;
      if (!isOrgAdmin(organizationId)) return false;
      final entries =
          ref.watch(organizationRepertoireProvider(organizationId)).value ??
          const <RepertoireEntry>[];
      return entries.any((e) => e.versionId == song.id);
    }

    final candidates = [
      for (final s in setlists)
        if (canAddTo(s)) s,
    ];

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            BattutaSpace.lg,
            BattutaSpace.md,
            BattutaSpace.lg,
            BattutaSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StageSectionHeader(
                title: l10n.addToSetlist,
                padding: const EdgeInsets.only(bottom: BattutaSpace.sm),
              ),
              if (candidates.isEmpty)
                Padding(
                  key: const ValueKey('add_to_setlist_empty'),
                  padding: const EdgeInsets.symmetric(
                    vertical: BattutaSpace.xl,
                  ),
                  child: Text(
                    l10n.addToSetlistEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: brand.inkMuted),
                  ),
                )
              else
                StageCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < candidates.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: brand.border),
                        _SetlistOption(
                          key: ValueKey('add_to_setlist_${candidates[i].id}'),
                          setlist: candidates[i],
                          alreadyAdded: candidates[i].items.any(
                            (item) => item.songId == song.id,
                          ),
                          onTap: () => _add(context, ref, candidates[i]),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetlistOption extends StatelessWidget {
  const _SetlistOption({
    required this.setlist,
    required this.alreadyAdded,
    required this.onTap,
    super.key,
  });

  final Setlist setlist;
  final bool alreadyAdded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StageRow(
      label: setlist.title,
      icon: Icons.queue_music,
      subtitle: alreadyAdded
          ? l10n.alreadyInSetlist
          : l10n.setlistSongsCount(setlist.items.length),
      trailing: alreadyAdded
          ? Icon(
              Icons.check_circle,
              size: 20,
              color: BattutaBrand.of(context).accentInk,
            )
          : null,
      onTap: alreadyAdded ? null : onTap,
    );
  }
}
