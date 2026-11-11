/// Picker that puts a member on a service, or finds cover for a slot.
library;

import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/features/team/presentation/providers/calendar_actions.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:battuta/features/team/presentation/widgets/calendar_support.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The member and instrument an administrator picked.
typedef MemberPick = ({String memberId, String instrument});

/// Opens the picker for [event].
///
/// With [coverFor] (an instrument) it finds cover for that slot: the
/// instrument is fixed and only available members who play it are listed
/// at first. Otherwise the administrator also picks the instrument.
Future<MemberPick?> showAssignMemberSheet(
  BuildContext context, {
  required ServiceEvent event,
  String? coverFor,
}) => showModalBottomSheet<MemberPick>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _AssignSheet(event: event, coverFor: coverFor),
);

class _AssignSheet extends ConsumerStatefulWidget {
  const _AssignSheet({required this.event, this.coverFor});

  final ServiceEvent event;
  final String? coverFor;

  @override
  ConsumerState<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends ConsumerState<_AssignSheet> {
  /// Members without an absence that day, from the server; `null` until it
  /// answers (or when offline, then the cached absences decide).
  Set<String>? _availableIds;
  late bool _onlyAvailable = widget.coverFor != null;
  late bool _onlyPlays = widget.coverFor != null;
  late String? _instrument = widget.coverFor;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final result = await ref
        .read(calendarActionsProvider)
        .availableOn(widget.event.dateTime);
    if (!mounted) return;
    result.fold(
      (_) {},
      (available) => setState(
        () => _availableIds = {for (final m in available) m.memberId},
      ),
    );
  }

  bool _isAway(TeamMember member, List<MemberAbsence> absences) {
    final ids = _availableIds;
    if (ids != null) return !ids.contains(member.id);
    return absences.any(
      (a) => a.memberId == member.id && a.covers(widget.event.dateTime),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final members = ref.watch(assignableMembersProvider);
    final absences = ref.watch(activeAbsencesProvider).value ?? const [];
    final assigned = {for (final a in widget.event.assignments) a.memberId};
    final instrument = _instrument;

    final visible = [
      for (final member in members)
        if ((!_onlyAvailable || !_isAway(member, absences)) &&
            (!_onlyPlays ||
                instrument == null ||
                member.instruments.contains(instrument)))
          member,
    ];

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.coverFor == null
                    ? l10n.assignPickerTitle(widget.event.title)
                    : l10n.findCover,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.coverFor == null) ...[
                Text(
                  l10n.assignInstrumentLabel,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final role in TeamRole.values)
                      ChoiceChip(
                        key: ValueKey('assign_instrument_${role.name}'),
                        label: Text(role.localizedShortName(context)),
                        selected: _instrument == role.name,
                        onSelected: (on) =>
                            setState(() => _instrument = on ? role.name : null),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    key: const ValueKey('assign_filter_available'),
                    label: Text(l10n.availableOnlyFilter),
                    selected: _onlyAvailable,
                    onSelected: (on) => setState(() => _onlyAvailable = on),
                  ),
                  if (instrument != null)
                    FilterChip(
                      key: const ValueKey('assign_filter_plays'),
                      label: Text(
                        l10n.playsInstrumentFilter(
                          instrumentLabel(context, instrument),
                        ),
                      ),
                      selected: _onlyPlays,
                      onSelected: (on) => setState(() => _onlyPlays = on),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: visible.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            members.isEmpty
                                ? l10n.noMembersForService
                                : l10n.noMembersMatch,
                          ),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final member in visible)
                            ListTile(
                              key: ValueKey('member_option_${member.id}'),
                              contentPadding: EdgeInsets.zero,
                              minTileHeight: 56,
                              title: Text(
                                member.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  for (final role in member.roles)
                                    Text(
                                      role.localizedShortName(context),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  if (_isAway(member, absences))
                                    StatusTag(
                                      label: l10n.memberAwayThatDay,
                                      color: statusColor(
                                        context,
                                        AssignmentStatus.away,
                                      ),
                                    ),
                                  if (assigned.contains(member.id))
                                    StatusTag(
                                      label: l10n.memberAlreadyAssigned,
                                      color: statusColor(
                                        context,
                                        AssignmentStatus.scheduled,
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () => Navigator.of(context).pop((
                                memberId: member.id,
                                instrument:
                                    _instrument ??
                                    member.instruments.firstOrNull ??
                                    TeamRole.keys.name,
                              )),
                            ),
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

/// Picks a member for [event] and adds them to the lineup.
Future<void> pickAndAssign(
  BuildContext context,
  WidgetRef ref,
  ServiceEvent event,
) async {
  final pick = await showAssignMemberSheet(context, event: event);
  if (pick == null || !context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final name = ref.read(memberNamesProvider)[pick.memberId] ?? '';
  final result = await ref
      .read(calendarActionsProvider)
      .assign(event, pick.memberId, pick.instrument);
  if (context.mounted) {
    reportResult(context, result, success: l10n.memberAssignedSuccess(name));
  }
}

/// Finds cover for [assignment] of [event] and hands the slot over.
Future<void> pickAndReassign(
  BuildContext context,
  WidgetRef ref,
  ServiceEvent event,
  ServiceAssignment assignment,
) async {
  final pick = await showAssignMemberSheet(
    context,
    event: event,
    coverFor: assignment.instrument,
  );
  if (pick == null || !context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final name = ref.read(memberNamesProvider)[pick.memberId] ?? '';
  final result = await ref
      .read(calendarActionsProvider)
      .reassign(assignment.id, pick.memberId);
  if (context.mounted) {
    reportResult(context, result, success: l10n.memberReassignedSuccess(name));
  }
}
