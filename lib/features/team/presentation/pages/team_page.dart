/// Battuta — Team Members & Band Calendar Page.
///
/// Provides complete band and worship team roster management,
/// multi-instrument role assignments, vocal tessituras, and a calendar-based
/// service scheduling system with recurring periodic Sunday services.
library;

import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/features/team/domain/entities/recurring_schedule.dart';
import 'package:battuta/features/team/domain/entities/schedule_alert.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/entities/team_group.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/features/team/presentation/providers/recurring_schedules_provider.dart';
import 'package:battuta/features/team/presentation/providers/schedule_alerts_provider.dart';
import 'package:battuta/features/team/presentation/providers/service_calendar_provider.dart';
import 'package:battuta/features/team/presentation/providers/team_group_provider.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
import 'package:battuta/features/team/presentation/widgets/admin_schedule_alerts_banner.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
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
    final nameController = TextEditingController(
      text: memberToEdit?.name ?? '',
    );
    final notesController = TextEditingController(
      text: memberToEdit?.notes ?? '',
    );

    // Multi-role selection: defaults to Keys (an instrument) for new members
    final selectedRoles = <TeamRole>{...?memberToEdit?.roles};
    if (selectedRoles.isEmpty) {
      selectedRoles.add(TeamRole.keys);
    }

    // Arrangement groups multi-membership
    final availableGroups = ref.read(teamGroupsProvider);
    final selectedGroups = <String>{...?memberToEdit?.groupIds};

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
    var isAdmin = memberToEdit?.isAdmin ?? false;

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
                        isExpanded: true,
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
                                child: Text(
                                  '${v.displayName} (${v.rangeLabel})',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            })
                            .toList(),
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
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
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
                                      color: theme.colorScheme.onSurfaceVariant,
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
                      isExpanded: true,
                      initialValue: selectedAvailability,
                      decoration: const InputDecoration(
                        labelText: 'General Availability',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event_available_outlined),
                      ),
                      items: AvailabilityStatus.values.map((a) {
                        return DropdownMenuItem(
                          value: a,
                          child: Text(
                            a.displayName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
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
                    const SizedBox(height: 14),

                    // Arrangement Groups / Sub-teams (N:M Membership)
                    if (availableGroups.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Arrangement Groups / Sub-teams',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${selectedGroups.length} assigned',
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
                        'Member can belong to multiple rotating teams:',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: availableGroups.map((g) {
                          final isSelected = selectedGroups.contains(g.id);
                          return FilterChip(
                            key: ValueKey('member_dialog_group_chip_${g.id}'),
                            avatar: CircleAvatar(
                              radius: 5,
                              backgroundColor: Color(g.colorValue),
                            ),
                            label: Text(g.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedGroups.add(g.id);
                                } else {
                                  selectedGroups.remove(g.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Administrator permissions toggle
                    SwitchListTile.adaptive(
                      key: const ValueKey('member_admin_switch'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Administrator Role',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Grants authority to create songs, schedule services, and assign musician replacements.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: isAdmin,
                      onChanged: (val) {
                        setDialogState(() => isAdmin = val);
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
                        isAdmin: isAdmin,
                        groupIds: selectedGroups.toList(),
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      );

                      ref
                          .read(teamMembersProvider.notifier)
                          .updateMember(updatedMember);
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Updated ${updatedMember.name}'),
                        ),
                      );
                    } else {
                      final newMember = TeamMember(
                        id: 'member_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        roles: rolesToSave,
                        vocalRange: vocalToSave,
                        availability: selectedAvailability,
                        isAdmin: isAdmin,
                        groupIds: selectedGroups.toList(),
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
      text:
          eventToEdit?.notes ??
          'Soundcheck 7:45 AM. Lead sheet package in Battuta.',
    );

    var selectedType = eventToEdit?.type ?? ServiceType.sundayService;
    var selectedRecurrence = eventToEdit?.recurrence ?? EventRecurrence.weekly;
    var selectedDate =
        eventToEdit?.dateTime ??
        DateTime.now().add(Duration(days: (7 - DateTime.now().weekday) % 7));
    var selectedTime = TimeOfDay(
      hour: eventToEdit?.dateTime.hour ?? 9,
      minute: eventToEdit?.dateTime.minute ?? 0,
    );
    var seriesCount = 1;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Edit Service Event' : 'Add Service / Rehearsal',
              ),
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
                      isExpanded: true,
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
                              Expanded(
                                child: Text(
                                  t.displayName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
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
                      isExpanded: true,
                      initialValue: selectedRecurrence,
                      decoration: const InputDecoration(
                        labelText: 'Recurrence Schedule',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      items: EventRecurrence.values.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(
                            r.displayName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRecurrence = val);
                        }
                      },
                    ),
                    if (selectedRecurrence.isRepeating && !isEditing) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        key: const ValueKey('series_count_dropdown'),
                        isExpanded: true,
                        initialValue: seriesCount,
                        decoration: const InputDecoration(
                          labelText: 'Occurrences to Generate',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.date_range_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text(
                              '1 service (Single date only)',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 4,
                            child: Text(
                              '4 occurrences (~1 month)',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 6,
                            child: Text(
                              '6 occurrences (~1.5 months)',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 12,
                            child: Text(
                              '12 occurrences (~3 months)',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 24,
                            child: Text(
                              '24 occurrences (~6 months)',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => seriesCount = val);
                          }
                        },
                      ),
                    ],
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
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 30),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
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
                  key: ValueKey(
                    isEditing ? 'save_service_btn' : 'add_service_btn',
                  ),
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
                      ref
                          .read(serviceCalendarProvider.notifier)
                          .updateEvent(updated);
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Updated ${updated.title}')),
                      );
                    } else if (selectedRecurrence.isRepeating &&
                        seriesCount > 1) {
                      final newSchedule = RecurringSchedule(
                        id: 'series_${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        type: selectedType,
                        recurrence: selectedRecurrence,
                        time: selectedTime,
                        location: locationController.text.trim(),
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                        lookaheadCount: seriesCount,
                      );
                      ref
                          .read(recurringSchedulesProvider.notifier)
                          .addSchedule(newSchedule);
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Configured recurring schedule for $title (showing next $seriesCount events)!',
                          ),
                        ),
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
                      ref
                          .read(serviceCalendarProvider.notifier)
                          .addEvent(newEvent);
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Scheduled ${newEvent.title}!')),
                      );
                    }
                  },
                  child: Text(
                    isEditing
                        ? 'Save Changes'
                        : (!isEditing &&
                                  selectedRecurrence.isRepeating &&
                                  seriesCount > 1
                              ? 'Create Series ($seriesCount)'
                              : 'Create Service'),
                  ),
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
                      isExpanded: true,
                      initialValue: selectedMember,
                      decoration: const InputDecoration(
                        labelText: 'Band Member',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: members.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(
                            '${m.name} (${m.role.shortName})',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
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
                      isExpanded: true,
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Role for Service',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.music_note),
                      ),
                      items: TeamRole.values.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(
                            r.displayName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
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
                      isExpanded: true,
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Attendance Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle_outline),
                      ),
                      items: AssignmentStatus.values.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(
                            s.displayName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
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
                    ref
                        .read(serviceCalendarProvider.notifier)
                        .assignMember(
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

  // ═══════════════════════════════════════════════════════════════════════════
  // ASSIGN GROUP TO SERVICE DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

  void _showAssignGroupDialog(ServiceEvent event) {
    final groups = ref.read(teamGroupsProvider);
    final members = ref.read(teamMembersProvider);

    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No arrangement groups created yet.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Assign Group to Service'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: groups.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final group = groups[index];
                final groupMembers = members
                    .where((m) => m.groupIds.contains(group.id))
                    .toList();
                final unavailableCount = groupMembers
                    .where((m) => m.availability == AvailabilityStatus.unavailable)
                    .length;

                return ListTile(
                  key: ValueKey('assign_group_item_${group.id}'),
                  leading: CircleAvatar(
                    backgroundColor:
                        Color(group.colorValue).withValues(alpha: 0.2),
                    child: Icon(Icons.groups, color: Color(group.colorValue)),
                  ),
                  title: Text(
                    group.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${groupMembers.length} members'
                    '${unavailableCount > 0 ? " • $unavailableCount unavailable" : ""}',
                    style: TextStyle(
                      color: unavailableCount > 0 ? AppTheme.stageRed : null,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ref.read(serviceCalendarProvider.notifier).assignGroup(
                          eventId: event.id,
                          groupMembers: groupMembers,
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Assigned ${group.name} (${groupMembers.length} members) to ${event.formattedDate}!',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN ALERTS & FIND COVER WORKFLOW
  // ═══════════════════════════════════════════════════════════════════════════

  void _handleAlertFindCover(ScheduleAlert alert) {
    final events = ref.read(serviceCalendarProvider);
    final event = events.where((e) => e.id == alert.eventId).firstOrNull;
    if (event == null) return;

    final assignment = event.assignments
            .where((a) => a.memberId == alert.memberId)
            .firstOrNull ??
        ServiceAssignment(
          memberId: alert.memberId,
          role: alert.role,
          status: AssignmentStatus.declined,
        );

    _showReplaceMemberDialog(event: event, assignment: assignment);
  }

  void _showAdminAlertsModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (modalCtx) {
        return Consumer(
          builder: (context, ref, _) {
            final alerts = ref.watch(adminScheduleAlertsProvider);
            final theme = Theme.of(context);

            return SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppTheme.stageAmber,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Coverage Alerts (${alerts.length})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(modalCtx).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (alerts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No pending scheduling gaps. All services are covered!',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: alerts.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (_, index) {
                            final alert = alerts[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              alert.memberName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.stageAmber
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                alert.role.shortName,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.stageAmber,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${alert.eventTitle} • ${alert.reason}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.tonal(
                                    key: ValueKey(
                                      'modal_find_cover_btn_${alert.id}',
                                    ),
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: AppTheme.stageAmber
                                          .withValues(alpha: 0.2),
                                      foregroundColor: AppTheme.stageAmber,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(modalCtx).pop();
                                      _handleAlertFindCover(alert);
                                    },
                                    child: const Text(
                                      'Find Cover',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REPLACE MUSICIAN / SUBSTITUTE DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

  void _showReplaceMemberDialog({
    required ServiceEvent event,
    required ServiceAssignment assignment,
  }) {
    final members = ref.read(teamMembersProvider);
    final currentAssignedMember = members.cast<TeamMember?>().firstWhere(
      (m) => m?.id == assignment.memberId,
      orElse: () => null,
    );

    final alreadyAssignedIds = event.assignments.map((a) => a.memberId).toSet();
    final availableCandidates =
        members.where((m) => m.id != assignment.memberId).toList();

    if (availableCandidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other team members available to substitute.'),
        ),
      );
      return;
    }

    // Pre-select candidate who plays this role and isn't in lineup yet, if possible
    TeamMember selectedSubstitute = availableCandidates.firstWhere(
      (m) =>
          m.roles.contains(assignment.role) &&
          !alreadyAssignedIds.contains(m.id),
      orElse: () => availableCandidates.firstWhere(
        (m) => !alreadyAssignedIds.contains(m.id),
        orElse: () => availableCandidates.first,
      ),
    );

    TeamRole selectedRole = assignment.role;
    AssignmentStatus selectedStatus = AssignmentStatus.confirmed;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Assign Musician Replacement'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.stageRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.stageRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_off_outlined,
                            color: AppTheme.stageRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cannot Attend: ${currentAssignedMember?.name ?? "Musician"}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Role: ${assignment.role.displayName} • ${event.formattedDate}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Substitute Musician:',
                      style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<TeamMember>(
                      key: const ValueKey('replacement_member_dropdown'),
                      isExpanded: true,
                      initialValue: selectedSubstitute,
                      decoration: const InputDecoration(
                        labelText: 'Substitute Musician',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_add),
                      ),
                      items: availableCandidates.map((m) {
                        final playsRole = m.roles.contains(assignment.role);
                        final isInLineup = alreadyAssignedIds.contains(m.id);
                        final roleNote = playsRole
                            ? '★ Plays ${assignment.role.shortName}'
                            : (isInLineup ? '(In Lineup)' : m.role.shortName);

                        return DropdownMenuItem(
                          value: m,
                          child: Text(
                            '${m.name} — $roleNote',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (m) {
                        if (m != null) {
                          setDialogState(() {
                            selectedSubstitute = m;
                            if (m.roles.contains(assignment.role)) {
                              selectedRole = assignment.role;
                            } else {
                              selectedRole = m.role;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TeamRole>(
                      key: const ValueKey('replacement_role_dropdown'),
                      isExpanded: true,
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Role',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.music_note),
                      ),
                      items: TeamRole.values.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(
                            r.displayName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
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
                      key: const ValueKey('replacement_status_dropdown'),
                      isExpanded: true,
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Attendance Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle_outline),
                      ),
                      items: AssignmentStatus.values.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(
                            s.displayName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
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
                  key: const ValueKey('confirm_replacement_btn'),
                  onPressed: () {
                    ref.read(serviceCalendarProvider.notifier).replaceMember(
                          eventId: event.id,
                          oldMemberId: assignment.memberId,
                          newMemberId: selectedSubstitute.id,
                          role: selectedRole,
                          status: selectedStatus,
                        );
                    Navigator.of(dialogCtx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Replaced ${currentAssignedMember?.name ?? "musician"} with ${selectedSubstitute.name} for ${event.formattedDate}!',
                        ),
                      ),
                    );
                  },
                  child: const Text('Confirm Replacement'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAssignmentActionsModal({
    required ServiceEvent event,
    required ServiceAssignment assignment,
    required TeamMember? member,
    required bool isAdmin,
  }) {
    final memberName = member?.name ?? 'Musician';
    final currentMemberId = ref.read(currentMemberIdProvider);
    final isCurrentMember = currentMemberId == assignment.memberId;

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$memberName • ${assignment.role.displayName}',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${event.title} (${event.formattedDate})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (isAdmin || isCurrentMember) ...[
                  ListTile(
                    leading:
                        const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Confirm Attendance'),
                    onTap: () {
                      ref.read(serviceCalendarProvider.notifier).assignMember(
                            eventId: event.id,
                            memberId: assignment.memberId,
                            role: assignment.role,
                            status: AssignmentStatus.confirmed,
                          );
                      Navigator.of(ctx).pop();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.cancel_outlined,
                      color: AppTheme.stageRed,
                    ),
                    title: const Text('Mark Unavailable / Cannot Attend'),
                    subtitle:
                        const Text('Flags date so admin can set a replacement'),
                    onTap: () {
                      ref.read(serviceCalendarProvider.notifier).assignMember(
                            eventId: event.id,
                            memberId: assignment.memberId,
                            role: assignment.role,
                            status: AssignmentStatus.declined,
                          );
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
                if (isAdmin) ...[
                  ListTile(
                    key: const ValueKey('action_find_replacement'),
                    leading: const Icon(
                      Icons.swap_horiz,
                      color: AppTheme.amberAccent,
                    ),
                    title: const Text('Find Replacement / Substitute'),
                    subtitle: const Text(
                      'Assign another team member to take this spot',
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showReplaceMemberDialog(
                        event: event,
                        assignment: assignment,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.stageRed,
                    ),
                    title: const Text('Remove from Lineup'),
                    onTap: () {
                      ref
                          .read(serviceCalendarProvider.notifier)
                          .removeMemberAssignment(
                            eventId: event.id,
                            memberId: assignment.memberId,
                          );
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showActiveUserSwitcherModal(List<TeamMember> members) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final currentMemberId = ref.watch(currentMemberIdProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Active User Profile',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                Text(
                  'Switch active user to preview musician permissions vs administrator capabilities.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                for (final member in members) ...[
                  ListTile(
                    key: ValueKey('switch_user_${member.id}'),
                    leading: CircleAvatar(
                      backgroundColor: member.isAdmin
                          ? AppTheme.amberAccent.withValues(alpha: 0.2)
                          : Theme.of(ctx).colorScheme.primaryContainer,
                      child: Icon(
                        member.isAdmin ? Icons.shield : Icons.person,
                        size: 18,
                        color: member.isAdmin
                            ? AppTheme.amberAccent
                            : Theme.of(ctx).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (member.isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.amberAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color:
                                    AppTheme.amberAccent.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.amberAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '${member.roles.map((r) => r.displayName).join(", ")} • ${member.availability.displayName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: currentMemberId == member.id
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      ref
                          .read(currentMemberIdProvider.notifier)
                          .setMemberId(member.id);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Active user: ${member.name} (${member.isAdmin ? 'Administrator' : 'Musician'})',
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECURRING EVENT SERIES SINGLE-INSTANCE MANAGEMENT MODAL
  // ═══════════════════════════════════════════════════════════════════════════

  void _showRecurringSeriesModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetCtx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final schedules = ref.watch(recurringSchedulesProvider);
            final theme = Theme.of(ctx);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.repeat, color: Color(0xFFE5A93C)),
                        const SizedBox(width: 8),
                        Text(
                          'Recurring Service Schedules',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(bottomSheetCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Each repetitive event is a single recurring instance. Adjust the rolling lookahead (X events ahead), or set a cutoff date to stop generating new events.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (schedules.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No recurring schedules configured yet.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      )
                    else
                      for (final schedule in schedules) ...[
                        Card(
                          key: ValueKey('recurring_card_${schedule.id}'),
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          color: schedule.isActive
                              ? theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3)
                              : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: schedule.isActive
                                  ? const Color(0xFFE5A93C)
                                      .withValues(alpha: 0.4)
                                  : theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      schedule.type.icon,
                                      size: 18,
                                      color: schedule.isActive
                                          ? const Color(0xFFE5A93C)
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        schedule.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          decoration: schedule.isActive
                                              ? null
                                              : TextDecoration.lineThrough,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        schedule.recurrence.shortName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Switch.adaptive(
                                      key: ValueKey(
                                        'recurring_switch_${schedule.id}',
                                      ),
                                      value: schedule.isActive,
                                      onChanged: (_) {
                                        ref
                                            .read(
                                              recurringSchedulesProvider.notifier,
                                            )
                                            .toggleActive(schedule.id);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${schedule.location} • ${schedule.time.format(ctx)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Divider(height: 1),
                                const SizedBox(height: 8),

                                if (!schedule.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.pause_circle_outline,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Schedule Paused — no occurrences generated',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else ...[
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      // Lookahead count selector
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Show: ',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          DropdownButton<int>(
                                            key: ValueKey(
                                              'lookahead_dropdown_${schedule.id}',
                                            ),
                                            value: schedule.lookaheadCount,
                                            isDense: true,
                                            items: const [
                                              DropdownMenuItem(
                                                value: 2,
                                                child: Text('2 ahead'),
                                              ),
                                              DropdownMenuItem(
                                                value: 4,
                                                child: Text('4 ahead'),
                                              ),
                                              DropdownMenuItem(
                                                value: 6,
                                                child: Text('6 ahead'),
                                              ),
                                              DropdownMenuItem(
                                                value: 8,
                                                child: Text('8 ahead'),
                                              ),
                                              DropdownMenuItem(
                                                value: 12,
                                                child: Text('12 ahead'),
                                              ),
                                            ],
                                            onChanged: (val) {
                                              if (val != null) {
                                                ref
                                                    .read(
                                                      recurringSchedulesProvider
                                                          .notifier,
                                                    )
                                                    .setLookaheadCount(
                                                      schedule.id,
                                                      val,
                                                    );
                                              }
                                            },
                                          ),
                                        ],
                                      ),

                                      // Cutoff disable date
                                      if (schedule.disabledAfter == null)
                                        OutlinedButton.icon(
                                          key: ValueKey(
                                            'set_cutoff_btn_${schedule.id}',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.event_busy,
                                            size: 14,
                                          ),
                                          label: const Text(
                                            'Disable Since Date...',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          onPressed: () async {
                                            final now = DateTime.now();
                                            final picked = await showDatePicker(
                                              context: ctx,
                                              initialDate: now.add(
                                                const Duration(days: 14),
                                              ),
                                              firstDate: now,
                                              lastDate: now.add(
                                                const Duration(days: 730),
                                              ),
                                            );
                                            if (picked != null) {
                                              ref
                                                  .read(
                                                    recurringSchedulesProvider
                                                        .notifier,
                                                  )
                                                  .setDisabledDate(
                                                    schedule.id,
                                                    picked,
                                                  );
                                            }
                                          },
                                        )
                                      else
                                        InputChip(
                                          key: ValueKey(
                                            'cutoff_chip_${schedule.id}',
                                          ),
                                          backgroundColor: AppTheme.stageRed
                                              .withValues(alpha: 0.1),
                                          side: BorderSide(
                                            color: AppTheme.stageRed.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                          avatar: const Icon(
                                            Icons.event_busy,
                                            size: 14,
                                            color: AppTheme.stageRed,
                                          ),
                                          label: Text(
                                            'Disabled from ${schedule.disabledAfter!.year}-${schedule.disabledAfter!.month.toString().padLeft(2, '0')}-${schedule.disabledAfter!.day.toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.stageRed,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          onDeleted: () {
                                            ref
                                                .read(
                                                  recurringSchedulesProvider
                                                      .notifier,
                                                )
                                                .setDisabledDate(
                                                  schedule.id,
                                                  null,
                                                );
                                          },
                                          deleteIcon: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: AppTheme.stageRed,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],

                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const ValueKey('add_recurring_pattern_btn'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Repetitive Schedule Rule'),
                        onPressed: () {
                          Navigator.of(bottomSheetCtx).pop();
                          _showServiceDialog();
                        },
                      ),
                    ),
                  ],
                ),
              ),
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
    final currentMember = ref.watch(currentMemberProvider);
    final isAdmin = ref.watch(isCurrentUserAdminProvider);

    final upcomingEvents = events.where((e) => e.isUpcoming).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final nextEvent = upcomingEvents.isNotEmpty ? upcomingEvents.first : null;

    final scheduledCount = nextEvent != null
        ? nextEvent.assignments
              .where((a) => a.status != AssignmentStatus.declined)
              .length
        : 0;

    final availableCount = members.length - scheduledCount;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.worshipTeamTitle ?? 'Worship Team & Band',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            key: const ValueKey('active_user_switcher_btn'),
            icon: Icon(
              isAdmin ? Icons.shield_outlined : Icons.person_outline,
              color: isAdmin ? AppTheme.amberAccent : theme.colorScheme.primary,
            ),
            tooltip: currentMember != null
                ? (l10n?.activeProfileTooltip(currentMember.name, isAdmin ? 'Admin' : 'Musician') ??
                    'Active Profile: ${currentMember.name} (${isAdmin ? 'Admin' : 'Musician'})')
                : (l10n?.switchActiveProfileTooltip ?? 'Switch active user profile'),
            onPressed: () => _showActiveUserSwitcherModal(members),
          ),
          if (isAdmin) ...[
            Consumer(
              builder: (context, ref, _) {
                final alertCount = ref.watch(pendingAlertCountProvider);
                return Badge(
                  isLabelVisible: alertCount > 0,
                  label: Text('$alertCount'),
                  backgroundColor: AppTheme.stageRed,
                  offset: const Offset(-4, 4),
                  child: IconButton(
                    key: const ValueKey('admin_alerts_bell_btn'),
                    icon: Icon(
                      alertCount > 0
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: alertCount > 0 ? AppTheme.stageAmber : null,
                    ),
                    tooltip: alertCount > 0
                        ? (l10n?.coverageAlertsCountTooltip(alertCount) ??
                            '$alertCount cover alert${alertCount > 1 ? 's' : ''}')
                        : (l10n?.coverageAlertsTooltip ?? 'Musician Coverage Alerts'),
                    onPressed: () => _showAdminAlertsModal(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(_selectedTabIndex == 0 ? Icons.person_add : Icons.event),
              tooltip: _selectedTabIndex == 0
                  ? (l10n?.addTeamMemberTooltip ?? 'Add team member')
                  : (l10n?.addServiceEventTooltip ?? 'Add service event'),
              onPressed: _selectedTabIndex == 0
                  ? () => _showMemberDialog()
                  : () => _showServiceDialog(),
            ),
          ],
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
                    label: Text('${l10n?.teamRosterTab ?? "Team Roster"} (${members.length})'),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text('${l10n?.bandCalendarTab ?? "Band Calendar"} (${upcomingEvents.length})'),
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
                    isAdmin: isAdmin,
                  ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              tooltip: _selectedTabIndex == 0
                  ? (l10n?.addTeamMemberTooltip ?? 'Add team member')
                  : (l10n?.addServiceEventTooltip ?? 'Add service event'),
              onPressed: _selectedTabIndex == 0
                  ? () => _showMemberDialog()
                  : () => _showServiceDialog(),
              icon: Icon(_selectedTabIndex == 0 ? Icons.person_add : Icons.event),
              label: Text(_selectedTabIndex == 0
                  ? (l10n?.addMusician ?? 'Add Member')
                  : (l10n?.addService ?? 'New Service')),
            )
          : null,
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
    final groups = ref.watch(teamGroupsProvider);
    final groupMap = {for (final g in groups) g.id: g};

    final filteredMembers = members.where((m) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Vocals') {
        return m.hasVocalRole || m.vocalRange != VocalTessitura.none;
      }
      if (_selectedFilter == 'Band') {
        return m.hasInstrumentRole;
      }
      if (_selectedFilter == 'Scheduled') {
        return events.any(
          (e) => e.assignments.any(
            (a) => a.memberId == m.id && a.status != AssignmentStatus.declined,
          ),
        );
      }
      if (_selectedFilter.startsWith('group:')) {
        final targetGroupId = _selectedFilter.substring(6);
        return m.groupIds.contains(targetGroupId);
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

        // Filter Chips (Role Categories & Rotating Arrangement Groups)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in ['All', 'Scheduled', 'Vocals', 'Band'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    key: ValueKey('filter_chip_${filter.toLowerCase()}'),
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter);
                      }
                    },
                  ),
                ),
              for (final group in groups)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    key: ValueKey('filter_chip_group_${group.id}'),
                    avatar: CircleAvatar(
                      radius: 5,
                      backgroundColor: Color(group.colorValue),
                    ),
                    label: Text(group.name),
                    selected: _selectedFilter == 'group:${group.id}',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = 'group:${group.id}');
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
              groupMap: groupMap,
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
    required Map<String, TeamGroup> groupMap,
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
    final statusColor = isScheduled ? nextAssignment.status.color : Colors.blue;
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
          overflow: TextOverflow.ellipsis,
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
                if (member.isAdmin)
                  Container(
                    key: ValueKey('admin_badge_${member.id}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.amberAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.amberAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 11,
                          color: AppTheme.amberAccent,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.amberAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                for (final groupId in member.groupIds)
                  if (groupMap.containsKey(groupId))
                    Container(
                      key: ValueKey('member_group_badge_${member.id}_$groupId'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Color(groupMap[groupId]!.colorValue)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Color(groupMap[groupId]!.colorValue)
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        groupMap[groupId]!.name.split(' (').first,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(groupMap[groupId]!.colorValue),
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
                  ref
                      .read(teamMembersProvider.notifier)
                      .removeMember(member.id);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)?.editMember ?? 'Edit Member'),
                    ],
                  ),
                ),
                if (nextEvent != null)
                  PopupMenuItem(
                    value: 'schedule',
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)?.scheduleForService ?? 'Schedule for Service'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Remove Member',
                        style: TextStyle(color: Colors.red),
                      ),
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
    required bool isAdmin,
  }) {
    final memberMap = {for (final m in members) m.id: m};

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Admin Coverage Alerts Banner (Attendance Gaps / Missing Musicians)
        if (isAdmin)
          AdminScheduleAlertsBanner(
            onFindCover: _handleAlertFindCover,
          ),

        // Quick Actions Bar
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'Periodic & Upcoming Services (${events.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isAdmin)
                  OutlinedButton.icon(
                    key: const ValueKey('recurring_schedules_btn'),
                    icon: const Icon(Icons.repeat, size: 16),
                    label: Text(AppLocalizations.of(context)?.recurringSchedules ?? 'Recurring Schedules'),
                    onPressed: _showRecurringSeriesModal,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Musician View',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
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
                  Text(AppLocalizations.of(context)?.noUpcomingServices ?? 'No upcoming services scheduled.'),
                  const SizedBox(height: 8),
                  if (isAdmin)
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context)?.scheduleFirstService ?? 'Schedule First Service'),
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
              isAdmin: isAdmin,
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
    required bool isAdmin,
  }) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
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
                              Flexible(
                                child: Text(
                                  event.formattedTime,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
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
                                color: isSunday
                                    ? const Color(0xFFE5A93C)
                                    : theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${event.type.shortName} • ${event.recurrence.shortName}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSunday
                                        ? const Color(0xFFE5A93C)
                                        : theme.colorScheme.primary,
                                  ),
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
                              Flexible(
                                child: Text(
                                  event.location,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Event Menu (Admins only)
                if (isAdmin)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showServiceDialog(eventToEdit: event);
                      } else if (val == 'delete') {
                        ref
                            .read(serviceCalendarProvider.notifier)
                            .deleteEvent(event.id);
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
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete Service',
                              style: TextStyle(color: Colors.red),
                            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Band Lineup (${event.assignments.length})',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isAdmin)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        key: ValueKey('assign_group_btn_${event.id}'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        icon: const Icon(Icons.group_add_outlined, size: 16),
                        label: Text(AppLocalizations.of(context)?.assignGroup ?? 'Assign Group'),
                        onPressed: () => _showAssignGroupDialog(event),
                      ),
                      TextButton.icon(
                        key: ValueKey('assign_musician_btn_${event.id}'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        icon: const Icon(Icons.person_add_alt_1, size: 16),
                        label: Text(AppLocalizations.of(context)?.assignMusician ?? 'Assign Musician'),
                        onPressed: () => _showAssignMemberDialog(event),
                      ),
                    ],
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
                children: [
                  for (final assignment in event.assignments) ...[
                    () {
                      final member = memberMap[assignment.memberId];
                      final memberName = member?.name ?? 'Musician';
                      final roleName = assignment.role.shortName;
                      final isDeclined =
                          assignment.status == AssignmentStatus.declined;

                      return InputChip(
                        key: ValueKey(
                          'lineup_chip_${event.id}_${assignment.memberId}',
                        ),
                        backgroundColor: isDeclined
                            ? AppTheme.stageRed.withValues(alpha: 0.12)
                            : null,
                        side: isDeclined
                            ? const BorderSide(
                                color: AppTheme.stageRed,
                                width: 1,
                              )
                            : null,
                        avatar: Icon(
                          isDeclined
                              ? Icons.person_off_outlined
                              : _getRoleIcon(assignment.role),
                          size: 14,
                          color: isDeclined
                              ? AppTheme.stageRed
                              : assignment.status.color,
                        ),
                        label: Text(
                          '$memberName ($roleName)${isDeclined ? " • Can't attend" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDeclined ? AppTheme.stageRed : null,
                            fontWeight: isDeclined
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        deleteIcon:
                            isAdmin ? const Icon(Icons.close, size: 14) : null,
                        onDeleted: isAdmin
                            ? () {
                                ref
                                    .read(serviceCalendarProvider.notifier)
                                    .removeMemberAssignment(
                                      eventId: event.id,
                                      memberId: assignment.memberId,
                                    );
                              }
                            : null,
                        onPressed: () => _showAssignmentActionsModal(
                          event: event,
                          assignment: assignment,
                          member: member,
                          isAdmin: isAdmin,
                        ),
                      );
                    }(),
                    if (assignment.status == AssignmentStatus.declined &&
                        isAdmin)
                      ActionChip(
                        key: ValueKey(
                          'replace_btn_${event.id}_${assignment.memberId}',
                        ),
                        avatar: const Icon(
                          Icons.swap_horiz,
                          size: 14,
                          color: AppTheme.amberAccent,
                        ),
                        label: Text(
                          'Replace ${(memberMap[assignment.memberId]?.name ?? "Musician").split(" ").first}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.amberAccent,
                          ),
                        ),
                        onPressed: () => _showReplaceMemberDialog(
                          event: event,
                          assignment: assignment,
                        ),
                      ),
                  ],
                ],
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
