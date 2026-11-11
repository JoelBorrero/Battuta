/// Admin-only management of the bands of the active organization.
library;

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/team/domain/entities/team_group.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Band colors offered by the editor (stage amber first).
const List<int> bandColorChoices = [
  Band.defaultColorValue,
  0xFF4A90E2,
  0xFF50E3C2,
  0xFFE35D6A,
  0xFF9B6BDF,
  0xFF7ED957,
];

Future<void> showBandsSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => const _BandsSheet(),
);

class _BandsSheet extends ConsumerWidget {
  const _BandsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final groups = ref.watch(teamGroupsProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              l10n.manageBandsAction,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (groups.isEmpty) Text(l10n.noArrangementGroupsYet),
            for (final group in groups)
              ListTile(
                key: ValueKey('band_item_${group.id}'),
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 10,
                  backgroundColor: Color(group.colorValue),
                ),
                title: Text(group.name, overflow: TextOverflow.ellipsis),
                subtitle: group.description == null
                    ? null
                    : Text(group.description!, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: ValueKey('band_edit_${group.id}'),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: l10n.editBandAction,
                      onPressed: () => showBandDialog(context, group: group),
                    ),
                    IconButton(
                      key: ValueKey('band_delete_${group.id}'),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      tooltip: l10n.deleteBandAction,
                      onPressed: () => _delete(context, ref, group),
                    ),
                  ],
                ),
              ),
            const Divider(),
            OutlinedButton.icon(
              key: const ValueKey('add_band_btn'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48)),
              icon: const Icon(Icons.add),
              label: Text(l10n.newBandAction),
              onPressed: () => showBandDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TeamGroup group,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteBandAction),
        content: Text(l10n.deleteBandConfirm(group.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirm_delete_band_btn'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteBandAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref.read(rosterActionsProvider).deleteBand(group.id);
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(backendErrorMessage(l10n, failure))),
      ),
      (_) {},
    );
  }
}

/// Creates a band, or renames / recolors [group].
Future<void> showBandDialog(BuildContext context, {TeamGroup? group}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _BandDialog(group: group),
    );

class _BandDialog extends ConsumerStatefulWidget {
  const _BandDialog({this.group});

  final TeamGroup? group;

  @override
  ConsumerState<_BandDialog> createState() => _BandDialogState();
}

class _BandDialogState extends ConsumerState<_BandDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.group?.name ?? '',
  );
  late int _color = widget.group?.colorValue ?? Band.defaultColorValue;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.backendErrorInvalidName);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final actions = ref.read(rosterActionsProvider);
    final existing = widget.group;
    final result = existing == null
        ? await actions.createBand(name, colorValue: _color)
        : await actions.updateBand(
            existing.copyWith(name: name, colorValue: _color),
          );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = backendErrorMessage(l10n, failure);
      }),
      (_) => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        widget.group == null ? l10n.newBandAction : l10n.editBandAction,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('band_name_field'),
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.bandNameLabel,
                errorText: _error,
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in bandColorChoices)
                  InkWell(
                    key: ValueKey('band_color_$value'),
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _color = value),
                    child: SizedBox.square(
                      dimension: 44,
                      child: Center(
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(value),
                          child: _color == value
                              ? const Icon(Icons.check, size: 16)
                              : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('band_save_btn'),
          onPressed: _saving ? null : _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
