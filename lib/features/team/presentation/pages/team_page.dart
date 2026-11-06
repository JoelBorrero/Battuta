/// Battuta — Team Members Page.
///
/// Provides complete band and worship team roster management,
/// showing multi-instrument roles, vocal tessitura ranges, and scheduling statuses.
library;

import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The main team roster screen.
class TeamPage extends ConsumerStatefulWidget {
  const TeamPage({super.key});

  @override
  ConsumerState<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends ConsumerState<TeamPage> {
  String _selectedFilter = 'All';

  void _showMemberDialog({TeamMember? memberToEdit}) {
    final isEditing = memberToEdit != null;
    final nameController =
        TextEditingController(text: memberToEdit?.name ?? '');
    final notesController =
        TextEditingController(text: memberToEdit?.notes ?? '');

    // Multi-role selection: defaults to Keys (an instrument) for new members
    final selectedRoles = <TeamRole>{
      ...?memberToEdit?.roles,
    };
    if (selectedRoles.isEmpty) {
      selectedRoles.add(TeamRole.keys);
    }

    // Vocal tessitura: if only instruments are selected, discard (none)
    VocalTessitura selectedRange;
    if (isEditing) {
      selectedRange = memberToEdit.vocalRange;
    } else {
      final hasVocal = selectedRoles.any((r) => r.isVocal);
      selectedRange = hasVocal ? VocalTessitura.soprano : VocalTessitura.none;
    }

    AvailabilityStatus selectedAvailability =
        memberToEdit?.availability ?? AvailabilityStatus.available;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final theme = Theme.of(dialogCtx);
            final hasVocalRole = selectedRoles.any((r) => r.isVocal);

            void toggleRole(TeamRole role) {
              setDialogState(() {
                if (selectedRoles.contains(role)) {
                  if (selectedRoles.length > 1) {
                    selectedRoles.remove(role);
                  }
                } else {
                  selectedRoles.add(role);
                }

                // Automatic vocal tessitura discard logic:
                // When selecting only instruments, vocal tessitura is automatically discarded.
                final nowHasVocal = selectedRoles.any((r) => r.isVocal);
                if (!nowHasVocal) {
                  selectedRange = VocalTessitura.none;
                } else if (selectedRange == VocalTessitura.none) {
                  selectedRange = VocalTessitura.soprano;
                }
              });
            }

            return AlertDialog(
              title: Text(isEditing ? 'Edit Team Member' : 'Add Team Member'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: !isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Multi-Role Selection Section ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Roles & Instruments *',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${selectedRoles.length} selected',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to toggle roles (e.g. Pianist + Singer + Guitarist):',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: TeamRole.values.map((r) {
                        final isSelected = selectedRoles.contains(r);
                        return FilterChip(
                          key: ValueKey('role_chip_${r.name}'),
                          avatar: Icon(
                            _getRoleIcon(r),
                            size: 16,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          label: Text(r.displayName),
                          selected: isSelected,
                          onSelected: (_) => toggleRole(r),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── Vocal Tessitura Section ──
                    if (hasVocalRole) ...[
                      DropdownButtonFormField<VocalTessitura>(
                        key: const ValueKey('vocal_tessitura_dropdown'),
                        initialValue: selectedRange == VocalTessitura.none
                            ? VocalTessitura.soprano
                            : selectedRange,
                        decoration: const InputDecoration(
                          labelText: 'Vocal Tessitura (Range)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.record_voice_over_outlined),
                        ),
                        items: VocalTessitura.values
                            .where((v) => v != VocalTessitura.none)
                            .map((v) {
                          return DropdownMenuItem(
                            value: v,
                            child: Text('${v.displayName} (${v.rangeLabel})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedRange = val);
                          }
                        },
                      ),
                    ] else ...[
                      Container(
                        key: const ValueKey('vocal_range_discarded_info'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.music_off_outlined,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vocal Tessitura: Discarded (Instrumental)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Automatically omitted because only instruments or production roles are selected.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // ── Availability Status ──
                    DropdownButtonFormField<AvailabilityStatus>(
                      initialValue: selectedAvailability,
                      decoration: const InputDecoration(
                        labelText: 'Availability Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event_available_outlined),
                      ),
                      items: AvailabilityStatus.values.map((a) {
                        return DropdownMenuItem(
                          value: a,
                          child: Text(a.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedAvailability = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Notes / Assignment ──
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Assignment',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: ValueKey(
                    isEditing ? 'save_member_btn' : 'add_member_btn',
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final rolesToSave = selectedRoles.isEmpty
                        ? [TeamRole.keys]
                        : selectedRoles.toList();

                    final vocalToSave = rolesToSave.any((r) => r.isVocal)
                        ? (selectedRange == VocalTessitura.none
                            ? VocalTessitura.soprano
                            : selectedRange)
                        : VocalTessitura.none;

                    if (isEditing) {
                      final updatedMember = memberToEdit.copyWith(
                        name: name,
                        roles: rolesToSave,
                        vocalRange: vocalToSave,
                        availability: selectedAvailability,
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      );

                      ref
                          .read(teamMembersProvider.notifier)
                          .updateMember(updatedMember);
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Updated ${updatedMember.name}')),
                      );
                    } else {
                      final newMember = TeamMember(
                        id: 'member_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        roles: rolesToSave,
                        vocalRange: vocalToSave,
                        availability: selectedAvailability,
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      );

                      ref
                          .read(teamMembersProvider.notifier)
                          .addMember(newMember);
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added $name to the team!')),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Add Member'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddMemberDialog() => _showMemberDialog();

  void _showEditMemberDialog(TeamMember member) =>
      _showMemberDialog(memberToEdit: member);

  static IconData _getRoleIcon(TeamRole role) {
    return switch (role) {
      TeamRole.director => Icons.menu_book,
      TeamRole.leadVocal => Icons.mic,
      TeamRole.backingVocal => Icons.mic_none,
      TeamRole.acousticGuitar => Icons.music_note,
      TeamRole.electricGuitar => Icons.bolt,
      TeamRole.bass => Icons.graphic_eq,
      TeamRole.keys => Icons.piano,
      TeamRole.drums => Icons.album_outlined,
      TeamRole.sound => Icons.headphones,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final members = ref.watch(teamMembersProvider);

    final scheduledCount = members
        .where((m) => m.availability == AvailabilityStatus.scheduled)
        .length;
    final availableCount = members
        .where((m) => m.availability == AvailabilityStatus.available)
        .length;

    final filteredMembers = members.where((m) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Vocals') {
        return m.hasVocalRole || m.vocalRange != VocalTessitura.none;
      }
      if (_selectedFilter == 'Band') {
        return m.hasInstrumentRole;
      }
      if (_selectedFilter == 'Scheduled') {
        return m.availability == AvailabilityStatus.scheduled;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worship Team & Band'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add team member',
            onPressed: _showAddMemberDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Summary Status Card ──
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      count: '${members.length}',
                      label: 'Total Roster',
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _SummaryStat(
                      count: '$scheduledCount',
                      label: 'Scheduled',
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _SummaryStat(
                      count: '$availableCount',
                      label: 'Available',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Filter Chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in ['All', 'Scheduled', 'Vocals', 'Band'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: _selectedFilter == filter,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilter = filter);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Members List ──
          if (filteredMembers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No team members match this filter.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            for (final member in filteredMembers)
              _MemberCard(
                member: member,
                onTap: () => _showEditMemberDialog(member),
                onEdit: () => _showEditMemberDialog(member),
                onStatusTap: () => ref
                    .read(teamMembersProvider.notifier)
                    .cycleAvailability(member.id),
                onDelete: () => ref
                    .read(teamMembersProvider.notifier)
                    .removeMember(member.id),
              ),

          const SizedBox(height: 48),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add team member',
        onPressed: _showAddMemberDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.count,
    required this.label,
    required this.color,
  });

  final String count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.onTap,
    required this.onEdit,
    required this.onStatusTap,
    required this.onDelete,
  });

  final TeamMember member;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onStatusTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final statusColor = switch (member.availability) {
      AvailabilityStatus.scheduled => Colors.green,
      AvailabilityStatus.available => Colors.blue,
      AvailabilityStatus.unavailable => Colors.grey,
    };

    final initials = member.name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            initials.isEmpty ? '?' : initials,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          member.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final role in member.roles)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      role.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (member.vocalRange != VocalTessitura.none)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5A93C).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFE5A93C).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      member.vocalRange.rangeLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE5A93C),
                      ),
                    ),
                  ),
              ],
            ),
            if (member.notes != null) ...[
              const SizedBox(height: 4),
              Text(
                member.notes!,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              key: ValueKey('member_status_${member.id}'),
              onTap: onStatusTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  member.availability.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              key: ValueKey('member_menu_${member.id}'),
              icon: const Icon(Icons.more_vert, size: 20),
              tooltip: 'Member options',
              onSelected: (val) {
                if (val == 'edit') {
                  onEdit();
                } else if (val == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Member'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove Member',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
