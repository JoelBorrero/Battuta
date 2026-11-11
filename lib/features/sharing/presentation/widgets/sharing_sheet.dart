/// The sharing sheet of one of my versions: its name, who can see it and, for
/// "My organizations", which of my organizations.
///
/// Saving works offline: the change is stored on the device and the next sync
/// pushes it.
library;

import 'dart:async';

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/sharing/presentation/widgets/visibility_text.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the sharing sheet of the version [songId] (read fresh from the
/// device, so the sheet never starts from a stale copy).
Future<void> showSharingSheet(
  BuildContext context,
  WidgetRef ref,
  String songId,
) async {
  final result = await ref.read(songRepositoryProvider).getSongById(songId);
  final song = result.fold((_) => null, (song) => song);
  if (song == null || !context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => SharingSheet(song: song),
  );
}

class SharingSheet extends ConsumerStatefulWidget {
  const SharingSheet({required this.song, super.key});

  final Song song;

  @override
  ConsumerState<SharingSheet> createState() => _SharingSheetState();
}

class _SharingSheetState extends ConsumerState<SharingSheet> {
  late final TextEditingController _label;
  late SongVisibility _visibility;
  late final Set<String> _shared;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.song.label);
    _visibility = widget.song.visibility;
    _shared = {...widget.song.sharedOrganizationIds};
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  /// Organizations I can still share with: active memberships, not archived.
  List<Organization> _organizations({bool watch = false}) {
    final all =
        (watch
                ? ref.watch(myOrganizationsProvider)
                : ref.read(myOrganizationsProvider))
            .value ??
        const <Organization>[];
    return [
      for (final o in all)
        if (o.archivedAt == null) o,
    ];
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // An organization I left since is dropped from the shares.
    final active = {for (final o in _organizations()) o.id};
    final shares = [
      for (final id in _shared)
        if (active.contains(id)) id,
    ];
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(songRepositoryProvider)
        .updateSharing(
          widget.song.id,
          label: _label.text,
          visibility: _visibility,
          sharedOrganizationIds: shares,
        );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = backendErrorMessage(l10n, failure);
      }),
      (_) {
        ref.invalidate(repertoireProvider);
        unawaited(ref.read(cloudSyncProvider.notifier).triggerSync());
        navigator.pop();
        messenger.showSnackBar(SnackBar(content: Text(l10n.sharingSaved)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final organizations = _organizations(watch: true);
    final activeShares = [
      for (final o in organizations)
        if (_shared.contains(o.id)) o.id,
    ];
    final needsPick =
        _visibility == SongVisibility.organizations && activeShares.isEmpty;
    final canSave = !_saving && !needsPick && _label.text.trim().isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            BattutaSpace.lg,
            0,
            BattutaSpace.lg,
            BattutaSpace.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.sharingSheetTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: BattutaSpace.md),
              TextField(
                key: const ValueKey('sharing_label_field'),
                controller: _label,
                maxLength: 100,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.sharingLabelField,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: BattutaSpace.sm),
              Text(
                l10n.sharingWhoCanSee,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: brand.inkMuted,
                ),
              ),
              const SizedBox(height: BattutaSpace.sm),
              for (final option in SongVisibility.values) ...[
                _VisibilityOption(
                  key: ValueKey('sharing_option_${option.name}'),
                  visibility: option,
                  title: switch (option) {
                    SongVisibility.private => l10n.sharingPrivateTitle,
                    SongVisibility.organizations =>
                      l10n.sharingOrganizationsTitle,
                    SongVisibility.public => l10n.sharingPublicTitle,
                  },
                  hint: switch (option) {
                    SongVisibility.private => l10n.sharingPrivateHint,
                    SongVisibility.organizations =>
                      l10n.sharingOrganizationsHint,
                    SongVisibility.public => l10n.sharingPublicHint,
                  },
                  selected: _visibility == option,
                  onTap: () => setState(() => _visibility = option),
                ),
                const SizedBox(height: BattutaSpace.sm),
              ],
              if (_visibility == SongVisibility.organizations) ...[
                const SizedBox(height: BattutaSpace.xs),
                Text(
                  l10n.sharingPickOrganizations,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: brand.inkMuted,
                  ),
                ),
                if (organizations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: BattutaSpace.sm,
                    ),
                    child: Text(
                      l10n.sharingNoOrganizations,
                      key: const ValueKey('sharing_no_orgs'),
                    ),
                  )
                else
                  for (final organization in organizations)
                    CheckboxListTile(
                      key: ValueKey('sharing_org_${organization.id}'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _shared.contains(organization.id),
                      title: Text(
                        organization.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onChanged: (checked) => setState(() {
                        if (checked ?? false) {
                          _shared.add(organization.id);
                        } else {
                          _shared.remove(organization.id);
                        }
                      }),
                    ),
                if (needsPick && organizations.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: BattutaSpace.sm),
                    child: Text(
                      l10n.sharingPickOne,
                      key: const ValueKey('sharing_pick_one'),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
              ],
              const SizedBox(height: BattutaSpace.sm),
              Text(
                l10n.sharingSyncNote,
                key: const ValueKey('sharing_sync_note'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: brand.inkMuted,
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: BattutaSpace.sm),
                  child: Text(
                    _error!,
                    key: const ValueKey('sharing_error'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: BattutaSpace.md),
              FilledButton(
                key: const ValueKey('sharing_save_btn'),
                style: FilledButton.styleFrom(minimumSize: const Size(44, 48)),
                onPressed: canSave ? _save : null,
                child: Text(l10n.sharingSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  const _VisibilityOption({
    required this.visibility,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final SongVisibility visibility;
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: BattutaPressable(
        onTap: onTap,
        builder: (context, pressed) => DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? brand.accentWash
                : (pressed ? brand.cardRaised : brand.card),
            borderRadius: BattutaRadius.smAll,
            border: Border.all(
              color: selected ? brand.accent : brand.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.all(BattutaSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    visibilityIcon(visibility),
                    size: 20,
                    color: selected ? brand.accentInk : brand.inkMuted,
                  ),
                  const SizedBox(width: BattutaSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: brand.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, size: 20, color: brand.accentInk),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
