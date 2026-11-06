/// Battuta — Team Members Page.
///
/// Provides complete band and worship team roster management,
/// showing instrument roles, vocal tessitura ranges, and scheduling statuses.
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

  void _showAddMemberDialog() {
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    TeamRole selectedRole = TeamRole.leadVocal;
    VocalTessitura selectedRange = VocalTessitura.soprano;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Add Team Member'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TeamRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role / Instrument',
                        border: OutlineInputBorder(),
                      ),
                      items: TeamRole.values.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(r.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRole = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<VocalTessitura>(
                      initialValue: selectedRange,
                      decoration: const InputDecoration(
                        labelText: 'Vocal Tessitura',
                        border: OutlineInputBorder(),
                      ),
                      items: VocalTessitura.values.map((v) {
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
                    const SizedBox(height: 12),
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
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final newMember = TeamMember(
                      id: 'member_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      role: selectedRole,
                      vocalRange: selectedRange,
                      availability: AvailabilityStatus.available,
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );

                    ref.read(teamMembersProvider.notifier).addMember(newMember);
                    Navigator.of(dialogCtx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added $name to the team!')),
                    );
                  },
                  child: const Text('Add Member'),
                ),
              ],
            );
          },
        );
      },
    );
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
        return m.role == TeamRole.leadVocal ||
            m.role == TeamRole.backingVocal ||
            m.vocalRange != VocalTessitura.none;
      }
      if (_selectedFilter == 'Band') {
        return m.role != TeamRole.leadVocal &&
            m.role != TeamRole.backingVocal &&
            m.role != TeamRole.sound;
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
    required this.onStatusTap,
    required this.onDelete,
  });

  final TeamMember member;
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
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            initials,
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    member.role.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (member.vocalRange != VocalTessitura.none)
                  Text(
                    member.vocalRange.rangeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
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
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (val) {
                if (val == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove Member', style: TextStyle(color: Colors.red)),
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
