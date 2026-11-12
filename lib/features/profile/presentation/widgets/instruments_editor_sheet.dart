/// Bottom sheet where I choose my instruments in one organization. Pitch
/// range and notes stay as they are (the roster dialog edits those).
library;

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/profile/presentation/providers/profile_providers.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/features/team/presentation/widgets/member_edit_dialog.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the sheet; completes with `true` when the instruments were saved.
Future<bool?> showInstrumentsEditorSheet(
  BuildContext context, {
  required OrganizationMember member,
  required String organizationName,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => InstrumentsEditorSheet(
    member: member,
    organizationName: organizationName,
  ),
);

class InstrumentsEditorSheet extends ConsumerStatefulWidget {
  const InstrumentsEditorSheet({
    required this.member,
    required this.organizationName,
    super.key,
  });

  final OrganizationMember member;
  final String organizationName;

  @override
  ConsumerState<InstrumentsEditorSheet> createState() =>
      _InstrumentsEditorSheetState();
}

class _InstrumentsEditorSheetState
    extends ConsumerState<InstrumentsEditorSheet> {
  /// The stored instruments as roster entry: keeps the ones this app does not
  /// know when the known roles change.
  late final _entry = TeamMember(
    id: widget.member.id,
    name: '',
    instruments: widget.member.instruments,
  );
  late final Set<TeamRole> _roles = {..._entry.roles};
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(profileActionsProvider)
        .saveInstruments(
          widget.member,
          _entry.instrumentsFor([
            for (final role in TeamRole.values)
              if (_roles.contains(role)) role,
          ]),
        );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = backendErrorMessage(l10n, failure);
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.profileInstrumentsIn(widget.organizationName),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final role in TeamRole.values)
                  FilterChip(
                    key: ValueKey('instrument_chip_${role.name}'),
                    avatar: Icon(teamRoleIcon(role), size: 16),
                    label: Text(role.localizedName(context)),
                    selected: _roles.contains(role),
                    onSelected: _saving
                        ? null
                        : (on) => setState(
                            () => on ? _roles.add(role) : _roles.remove(role),
                          ),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const ValueKey('instruments_error'),
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(44, 48)),
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  key: const ValueKey('instruments_save_btn'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(44, 48),
                  ),
                  onPressed: _saving ? null : _save,
                  child: Text(l10n.saveChanges),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
