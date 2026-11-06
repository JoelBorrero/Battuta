/// Battuta — Team Members & Band Calendar Page.
///
/// Provides complete band and worship team roster management,
/// multi-instrument role assignments, vocal tessituras, and a calendar-based
/// service scheduling system with recurring periodic Sunday services.
library;

import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/features/team/presentation/providers/service_calendar_provider.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The main team roster and band calendar screen.
class TeamPage extends ConsumerStatefulWidget {
  const TeamPage({super.key});

  @override
  ConsumerState<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends ConsumerState<TeamPage> {
  int _selectedTabIndex = 0; // 0: Roster, 1: Calendar & Services
  String _selectedFilter = 'All';

  // ═══════════════════════════════════════════════════════════════════════════
  // TEAM MEMBER DIALOG (ADD / EDIT)
  // ═══════════════════════════════════════════════════════════════════════════

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

                    // Multi-role selection
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

                    // Vocal Tessitura Section
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

                    // Availability Status
                    DropdownButtonFormField<AvailabilityStatus>(
                      initialValue: selectedAvailability,
                      decoration: const InputDecoration(
                        labelText: 'General Availability',
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

                    // Notes
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

  // ═══════════════════════════════════════════════════════════════════════════
  // SERVICE EVENT DIALOG (ADD / EDIT)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showServiceDialog({ServiceEvent? eventToEdit}) {
    final isEditing = eventToEdit != null;
    final titleController = TextEditingController(
      text: eventToEdit?.title ?? 'Sunday Morning Worship',
    );
    final locationController = TextEditingController(
      text: eventToEdit?.location ?? 'Main Sanctuary',
    );
    final notesController = TextEditingController(
      text: eventToEdit?.notes ?? 'Soundcheck 7:45 AM. Lead sheet package in Battuta.',
    );

    var selectedType = eventToEdit?.type ?? ServiceType.sundayService;
    var selectedRecurrence =
        eventToEdit?.recurrence ?? EventRecurrence.weekly;
    var selectedDate = eventToEdit?.dateTime ??
        DateTime.now().add(Duration(days: (7 - DateTime.now().weekday) % 7));
    var selectedTime = TimeOfDay(
      hour: eventToEdit?.dateTime.hour ?? 9,
      minute: eventToEdit?.dateTime.minute ?? 0,
    );

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Service Event' : 'Add Service / Rehearsal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Service Title *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.church_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ServiceType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Service Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ServiceType.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(t.icon, size: 18),
                              const SizedBox(width: 8),
                              Text(t.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<EventRecurrence>(
                      initialValue: selectedRecurrence,
                      decoration: const InputDecoration(
                        labelText: 'Recurrence Schedule',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      items: EventRecurrence.values.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(r.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRecurrence = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogCtx,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time, size: 16),
                            label: Text(selectedTime.format(dialogCtx)),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: dialogCtx,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setDialogState(() => selectedTime = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location / Venue',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Call Time & Instructions',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
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
                  key: ValueKey(isEditing ? 'save_service_btn' : 'add_service_btn'),
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    final eventDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    if (isEditing) {
                      final updated = eventToEdit.copyWith(
                        title: title,
                        dateTime: eventDateTime,
                        type: selectedType,
                        recurrence: selectedRecurrence,
                        location: locationController.text.trim(),
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      );
                      ref.read(serviceCalendarProvider.notifier).updateEvent(updated);
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Updated ${updated.title}')),
                      );
                    } else {
                      final newEvent = ServiceEvent(
                        id: 'event_${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        dateTime: eventDateTime,
                        type: selectedType,
                        recurrence: selectedRecurrence,
                        location: locationController.text.trim(),
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      );
                      ref.read(serviceCalendarProvider.notifier).addEvent(newEvent);
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Scheduled ${newEvent.title}!')),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Create Service'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ASSIGN MEMBER TO SERVICE DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

  void _showAssignMemberDialog(ServiceEvent event) {
    final members = ref.read(teamMembersProvider);
    if (members.isEmpty) return;

    var selectedMember = members.first;
    var selectedRole = selectedMember.role;
    var selectedStatus = AssignmentStatus.confirmed;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('Assign Musician to ${event.formattedDate}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<TeamMember>(
                      initialValue: selectedMember,
                      decoration: const InputDecoration(
                        labelText: 'Band Member',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: members.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text('${m.name} (${m.role.shortName})'),
                        );
                      }).toList(),
                      onChanged: (m) {
                        if (m != null) {
                          setDialogState(() {
                            selectedMember = m;
                            selectedRole = m.role;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TeamRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Role for Service',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.music_note),
                      ),
                      items: TeamRole.values.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(r.displayName),
                        );
                      }).toList(),
                      onChanged: (r) {
                        if (r != null) {
                          setDialogState(() => selectedRole = r);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AssignmentStatus>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Attendance Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle_outline),
                      ),
                      items: AssignmentStatus.values.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(s.displayName),
                        );
                      }).toList(),
                      onChanged: (s) {
                        if (s != null) {
                          setDialogState(() => selectedStatus = s);
                        }
                      },
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
                  key: const ValueKey('confirm_assign_member_btn'),
                  onPressed: () {
                    ref.read(serviceCalendarProvider.notifier).assignMember(
                          eventId: event.id,
                          memberId: selectedMember.id,
                          role: selectedRole,
                          status: selectedStatus,
                        );
                    Navigator.of(dialogCtx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Assigned ${selectedMember.name} to ${event.title}!',
                        ),
                      ),
                    );
                  },
                  child: const Text('Assign to Lineup'),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
    final events = ref.watch(serviceCalendarProvider);

    final upcomingEvents = events.where((e) => e.isUpcoming).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final nextEvent = upcomingEvents.isNotEmpty ? upcomingEvents.first : null;

    final scheduledCount = nextEvent != null
        ? nextEvent.assignments
            .where((a) => a.status != AssignmentStatus.declined)
            .length
        : 0;

    final availableCount = members.length - scheduledCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worship Team & Band'),
        actions: [
          IconButton(
            icon: Icon(_selectedTabIndex == 0 ? Icons.person_add : Icons.event),
            tooltip: _selectedTabIndex == 0 ? 'Add team member' : 'Add service event',
            onPressed: _selectedTabIndex == 0
                ? () => _showMemberDialog()
                : () => _showServiceDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── View Mode Switcher: Roster vs Calendar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    icon: const Icon(Icons.people_outline),
                    label: Text('Team Roster (${members.length})'),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text('Band Calendar (${upcomingEvents.length})'),
                  ),
                ],
                selected: {_selectedTabIndex},
                onSelectionChanged: (val) {
                  setState(() => _selectedTabIndex = val.first);
                },
              ),
            ),
          ),

          // ── Active Tab View ──
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildRosterView(
                    theme: theme,
                    members: members,
                    events: upcomingEvents,
                    nextEvent: nextEvent,
                    scheduledCount: scheduledCount,
                    availableCount: availableCount < 0 ? 0 : availableCount,
                  )
                : _buildCalendarView(
                    theme: theme,
                    members: members,
                    events: upcomingEvents,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: _selectedTabIndex == 0 ? 'Add team member' : 'Add service event',
        onPressed: _selectedTabIndex == 0
            ? () => _showMemberDialog()
            : () => _showServiceDialog(),
        icon: Icon(_selectedTabIndex == 0 ? Icons.person_add : Icons.event),
        label: Text(_selectedTabIndex == 0 ? 'Add Member' : 'New Service'),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROSTER VIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRosterView({
    required ThemeData theme,
    required List<TeamMember> members,
    required List<ServiceEvent> events,
    required ServiceEvent? nextEvent,
    required int scheduledCount,
    required int availableCount,
  }) {
    final filteredMembers = members.where((m) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Vocals') {
        return m.hasVocalRole || m.vocalRange != VocalTessitura.none;
      }
      if (_selectedFilter == 'Band') {
        return m.hasInstrumentRole;
      }
      if (_selectedFilter == 'Scheduled') {
        return events.any((e) => e.assignments.any(
            (a) => a.memberId == m.id && a.status != AssignmentStatus.declined));
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Summary Status Card
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
                    label: nextEvent != null
                        ? 'Next: ${nextEvent.formattedDate}'
                        : 'Scheduled',
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

        // Filter Chips
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

        // Member Cards
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
            _buildMemberCard(
              theme: theme,
              member: member,
              events: events,
              nextEvent: nextEvent,
            ),

        const SizedBox(height: 64),
      ],
    );
  }

  Widget _buildMemberCard({
    required ThemeData theme,
    required TeamMember member,
    required List<ServiceEvent> events,
    required ServiceEvent? nextEvent,
  }) {
    // Find next assignment for this member
    ServiceAssignment? nextAssignment;
    ServiceEvent? assignedEvent;

    for (final e in events) {
      final match = e.assignments.where((a) => a.memberId == member.id);
      if (match.isNotEmpty) {
        nextAssignment = match.first;
        assignedEvent = e;
        break;
      }
    }

    final isScheduled = nextAssignment != null;
    final statusColor = isScheduled
        ? nextAssignment.status.color
        : Colors.blue;
    final statusText = isScheduled
        ? nextAssignment.status.displayName
        : 'Available';

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
        onTap: () => _showMemberDialog(memberToEdit: member),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            // Assigned roles badges
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final role in member.roles)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            // Upcoming date info
            const SizedBox(height: 4),
            if (isScheduled && assignedEvent != null)
              Text(
                '📅 Next: ${assignedEvent.formattedDate} (${nextAssignment.role.displayName})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              )
            else
              Text(
                'Not currently scheduled for upcoming services',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Calendar-driven scheduling badge
            InkWell(
              key: ValueKey('member_status_${member.id}'),
              onTap: () {
                ref
                    .read(serviceCalendarProvider.notifier)
                    .cycleMemberStatusForNextService(member.id, member.role);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusText,
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
                  _showMemberDialog(memberToEdit: member);
                } else if (val == 'schedule' && nextEvent != null) {
                  _showAssignMemberDialog(nextEvent);
                } else if (val == 'delete') {
                  ref.read(teamMembersProvider.notifier).removeMember(member.id);
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
                if (nextEvent != null)
                  const PopupMenuItem(
                    value: 'schedule',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Schedule for Service'),
                      ],
                    ),
                  ),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // BAND CALENDAR VIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCalendarView({
    required ThemeData theme,
    required List<TeamMember> members,
    required List<ServiceEvent> events,
  }) {
    final memberMap = {for (final m in members) m.id: m};

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Quick Actions Bar
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Periodic & Upcoming Services (${events.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Auto-Sundays'),
                  onPressed: () {
                    ref
                        .read(serviceCalendarProvider.notifier)
                        .generatePeriodicSundays(count: 4);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Auto-generated next 4 Sunday services!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  const Text('No upcoming services scheduled.'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Schedule First Service'),
                    onPressed: () => _showServiceDialog(),
                  ),
                ],
              ),
            ),
          )
        else
          for (var i = 0; i < events.length; i++)
            _buildServiceEventCard(
              theme: theme,
              event: events[i],
              isNextService: i == 0,
              memberMap: memberMap,
            ),

        const SizedBox(height: 64),
      ],
    );
  }

  Widget _buildServiceEventCard({
    required ThemeData theme,
    required ServiceEvent event,
    required bool isNextService,
    required Map<String, TeamMember> memberMap,
  }) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    final monthStr = months[event.dateTime.month - 1];
    final dayStr = '${event.dateTime.day}';
    final dayOfWeek = days[event.dateTime.weekday - 1];

    final isSunday = event.type == ServiceType.sundayService;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isNextService
              ? const Color(0xFFE5A93C)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isNextService ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Date Box + Title & Times + Overflow Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Stamp Badge
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isNextService
                        ? const Color(0xFFE5A93C).withValues(alpha: 0.2)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isNextService
                          ? const Color(0xFFE5A93C)
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayOfWeek,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isNextService
                              ? const Color(0xFFE5A93C)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        dayStr,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isNextService
                              ? const Color(0xFFE5A93C)
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        monthStr,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isNextService)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5A93C),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'NEXT SERVICE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                event.formattedTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                event.type.icon,
                                size: 14,
                                color: isSunday ? const Color(0xFFE5A93C) : theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${event.type.shortName} • ${event.recurrence.shortName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSunday ? const Color(0xFFE5A93C) : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                event.location,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Event Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showServiceDialog(eventToEdit: event);
                    } else if (val == 'delete') {
                      ref.read(serviceCalendarProvider.notifier).deleteEvent(event.id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Service'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Service', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (event.notes != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  event.notes!,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Band Lineup Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Band Lineup (${event.assignments.length})',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                  label: const Text('Assign Musician'),
                  onPressed: () => _showAssignMemberDialog(event),
                ),
              ],
            ),
            const SizedBox(height: 4),

            if (event.assignments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No musicians assigned yet. Tap "Assign Musician" to schedule band members.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: event.assignments.map((assignment) {
                  final member = memberMap[assignment.memberId];
                  final memberName = member?.name ?? 'Musician';
                  final roleName = assignment.role.shortName;

                  return InputChip(
                    avatar: Icon(
                      _getRoleIcon(assignment.role),
                      size: 14,
                      color: assignment.status.color,
                    ),
                    label: Text(
                      '$memberName ($roleName)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      ref
                          .read(serviceCalendarProvider.notifier)
                          .removeMemberAssignment(
                            eventId: event.id,
                            memberId: assignment.memberId,
                          );
                    },
                  );
                }).toList(),
              ),
          ],
        ),
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
