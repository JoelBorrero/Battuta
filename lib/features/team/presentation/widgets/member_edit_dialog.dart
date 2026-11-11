/// Edit dialog of one roster member.
///
/// Everyone edits their own instruments, pitch range and notes; admins also
/// edit another member's profile, role (admin) and bands. A failure keeps the
/// dialog open with the localized message; nothing is applied optimistically.
library;

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/features/team/domain/entities/team_group.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

IconData teamRoleIcon(TeamRole role) => switch (role) {
  TeamRole.director => Icons.menu_book,
  TeamRole.leadVocal => Icons.mic,
  TeamRole.backingVocal => Icons.mic_none,
  TeamRole.acousticGuitar => Icons.music_note,
  TeamRole.electricGuitar => Icons.bolt,
  TeamRole.bass => Icons.graphic_eq,
  TeamRole.keys => Icons.piano,
  TeamRole.synth => Icons.tune,
  TeamRole.drums => Icons.album_outlined,
  TeamRole.sound => Icons.headphones,
};

class MemberEditDialog extends ConsumerStatefulWidget {
  const MemberEditDialog({
    required this.member,
    required this.groups,
    required this.isAdmin,
    super.key,
  });

  final TeamMember member;
  final List<TeamGroup> groups;

  /// Whether the signed-in user is an admin of the organization.
  final bool isAdmin;

  static Future<bool?> show(
    BuildContext context, {
    required TeamMember member,
    required List<TeamGroup> groups,
    required bool isAdmin,
  }) => showDialog<bool>(
    context: context,
    builder: (_) =>
        MemberEditDialog(member: member, groups: groups, isAdmin: isAdmin),
  );

  @override
  ConsumerState<MemberEditDialog> createState() => _MemberEditDialogState();
}

class _MemberEditDialogState extends ConsumerState<MemberEditDialog> {
  late final Set<TeamRole> _roles = {...widget.member.roles};
  late VocalTessitura _range = widget.member.vocalRange;
  late bool _isAdmin = widget.member.isAdmin;
  late final Set<String> _bandIds = {...widget.member.groupIds};
  late final TextEditingController _notes = TextEditingController(
    text: widget.member.notes ?? '',
  );
  late TeamMember _original = widget.member;
  bool _saving = false;
  bool _savedPartly = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  bool get _hasVocalRole => _roles.any((r) => r.isVocal);

  void _toggleRole(TeamRole role) {
    setState(() {
      if (!_roles.remove(role)) _roles.add(role);
      if (!_hasVocalRole) {
        _range = VocalTessitura.none;
      } else if (_range == VocalTessitura.none) {
        _range = VocalTessitura.soprano;
      }
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _saving = true;
      _error = null;
    });
    if (_savedPartly) {
      // Earlier writes went through: diff the retry against the server.
      final fresh = ref
          .read(teamMembersProvider)
          .where((m) => m.id == _original.id);
      if (fresh.isNotEmpty) _original = fresh.first;
    }
    final result = await ref
        .read(rosterActionsProvider)
        .saveMember(
          original: _original,
          roles: [
            for (final role in TeamRole.values)
              if (_roles.contains(role)) role,
          ],
          tessitura: _hasVocalRole ? _range : VocalTessitura.none,
          notes: _notes.text,
          isAdmin: _isAdmin,
          bandIds: _bandIds,
          canEditRoleAndBands: widget.isAdmin,
        );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        final reason = backendErrorMessage(l10n, failure.cause);
        _error = switch (failure.step) {
          null => reason,
          MemberSaveStep.role => l10n.memberSavePartialRole(reason),
          MemberSaveStep.bands => l10n.memberSavePartialBands(reason),
        };
        _savedPartly = _savedPartly || failure.step != null;
      }),
      (_) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.updatedMemberSuccess(widget.member.name)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.editTeamMember),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.member.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.member.username != null)
              Text(
                '@${widget.member.username}',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const ValueKey('member_dialog_error'),
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.rolesInstrumentsLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final role in TeamRole.values)
                  FilterChip(
                    key: ValueKey('role_chip_${role.name}'),
                    avatar: Icon(teamRoleIcon(role), size: 16),
                    label: Text(role.localizedName(context)),
                    selected: _roles.contains(role),
                    onSelected: (_) => _toggleRole(role),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_hasVocalRole)
              DropdownButtonFormField<VocalTessitura>(
                key: const ValueKey('vocal_tessitura_dropdown'),
                isExpanded: true,
                initialValue: _range == VocalTessitura.none
                    ? VocalTessitura.soprano
                    : _range,
                decoration: InputDecoration(
                  labelText: l10n.vocalTessituraRange,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.record_voice_over_outlined),
                ),
                items: [
                  for (final v in VocalTessitura.values)
                    if (v != VocalTessitura.none)
                      DropdownMenuItem(
                        value: v,
                        child: Text(
                          '${v.displayName} (${v.rangeLabel})',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _range = v);
                },
              )
            else
              Text(
                l10n.vocalTessituraDiscardedSubtitle,
                key: const ValueKey('vocal_range_discarded_info'),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('member_notes_field'),
              controller: _notes,
              decoration: InputDecoration(
                labelText: l10n.notesAssignmentLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note_alt_outlined),
              ),
            ),
            if (widget.isAdmin && widget.groups.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                l10n.bandsLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final g in widget.groups)
                    FilterChip(
                      key: ValueKey('member_dialog_group_chip_${g.id}'),
                      avatar: CircleAvatar(
                        radius: 5,
                        backgroundColor: Color(g.colorValue),
                      ),
                      label: Text(g.name),
                      selected: _bandIds.contains(g.id),
                      onSelected: (on) => setState(
                        () => on ? _bandIds.add(g.id) : _bandIds.remove(g.id),
                      ),
                    ),
                ],
              ),
            ],
            if (widget.isAdmin)
              SwitchListTile.adaptive(
                key: const ValueKey('member_admin_switch'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.administratorRole,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l10n.administratorRoleSubtitle),
                value: _isAdmin,
                onChanged: (v) => setState(() => _isAdmin = v),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('save_member_btn'),
          onPressed: _saving ? null : _save,
          child: Text(l10n.saveChanges),
        ),
      ],
    );
  }
}
