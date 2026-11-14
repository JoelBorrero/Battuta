/// One service of the Calendar tab: when and where, and its lineup.
library;

import 'package:battuta/app/design_system/components/stage_surfaces.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/presentation/providers/calendar_actions.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:battuta/features/team/presentation/widgets/assign_member_sheet.dart';
import 'package:battuta/features/team/presentation/widgets/calendar_support.dart';
import 'package:battuta/features/team/presentation/widgets/service_form_dialog.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ServiceEventCard extends ConsumerWidget {
  const ServiceEventCard({
    required this.event,
    required this.isNext,
    required this.canEdit,
    super.key,
  });

  final ServiceEvent event;
  final bool isNext;

  /// Whether the viewer may change the service and its lineup (an admin of
  /// an organization that is not archived).
  final bool canEdit;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteService),
        content: Text(l10n.deleteServiceConfirm(event.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirm_delete_service_btn'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteService),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref.read(calendarActionsProvider).deleteEvent(event);
    if (context.mounted) reportResult(context, result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final names = ref.watch(memberNamesProvider);
    final bandName = event.bandId == null
        ? null
        : (ref.watch(activeBandsProvider).value ?? const [])
              .where((b) => b.id == event.bandId)
              .map((b) => b.name)
              .firstOrNull;
    final materialLocalizations = MaterialLocalizations.of(context);
    final setlistTitle = event.setlistId == null
        ? null
        : (ref.watch(setlistsProvider).value ?? const [])
              .where((s) => s.id == event.setlistId)
              .map((s) => s.title)
              .firstOrNull;

    Widget info(IconData icon, String text, {Color? color}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? brand.inkMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: color ?? brand.inkMuted),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: StageCard(
        key: ValueKey('service_card_${event.id}'),
        padding: const EdgeInsets.all(14),
        selected: isNext,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 56,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        materialLocalizations.formatTimeOfDay(
                          TimeOfDay.fromDateTime(event.dateTime),
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isNext ? brand.accentInk : brand.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isNext) ...[
                        const SizedBox(height: 4),
                        StatusTag(
                          label: l10n.nextServiceBadge,
                          color: brand.accentInk,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          if (bandName != null)
                            info(Icons.layers_outlined, bandName),
                          info(
                            event.type.icon,
                            event.recurrence.isRepeating
                                ? '${event.type.localizedShortName(context)} • ${event.recurrence.localizedShortName(context)}'
                                : event.type.localizedShortName(context),
                            color: brand.accentInk,
                          ),
                          if (event.location != null)
                            info(Icons.location_on_outlined, event.location!),
                          if (setlistTitle != null)
                            info(Icons.queue_music_outlined, setlistTitle),
                        ],
                      ),
                    ],
                  ),
                ),
                if (canEdit)
                  PopupMenuButton<String>(
                    key: ValueKey('event_menu_${event.id}'),
                    constraints: const BoxConstraints(minWidth: 44),
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (value == 'edit') {
                        showServiceFormDialog(context, event: event);
                      } else if (value == 'delete') {
                        _delete(context, ref);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        key: ValueKey('event_edit_${event.id}'),
                        value: 'edit',
                        child: Text(l10n.editService),
                      ),
                      if (!event.isProjected)
                        PopupMenuItem(
                          key: ValueKey('event_delete_${event.id}'),
                          value: 'delete',
                          child: Text(
                            l10n.deleteService,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            if (event.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                event.notes!,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: brand.inkMuted,
                ),
              ),
            ],
            if (event.setlistId != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  key: ValueKey('go_live_btn_${event.id}'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    foregroundColor: brand.accentInk,
                    side: BorderSide(color: brand.accent),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(l10n.livePerfGoLive),
                  onPressed: () =>
                      context.push(AppRoutes.performSetlist(event.setlistId!)),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Divider(height: 1, color: brand.borderSubtle),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '${l10n.bandLineupTitle} (${event.assignments.length})',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (canEdit)
                  TextButton.icon(
                    key: ValueKey('assign_musician_btn_${event.id}'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                    ),
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: Text(
                      l10n.assignMusician,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => pickAndAssign(context, ref, event),
                  ),
              ],
            ),
            if (event.assignments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  l10n.noMusiciansAssignedYet,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: brand.inkMuted,
                  ),
                ),
              ),
            for (final assignment in event.assignments)
              _LineupRow(
                event: event,
                assignment: assignment,
                name: names[assignment.memberId] ?? l10n.lineupMemberUnknown,
                canEdit: canEdit,
              ),
          ],
        ),
      ),
    );
  }
}

class _LineupRow extends ConsumerWidget {
  const _LineupRow({
    required this.event,
    required this.assignment,
    required this.name,
    required this.canEdit,
  });

  final ServiceEvent event;
  final ServiceAssignment assignment;
  final String name;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final brand = BattutaBrand.of(context);
    final status = assignment.status;
    final color = statusColor(context, status);
    final needsCover =
        status == AssignmentStatus.declined || status == AssignmentStatus.away;

    return Container(
      key: ValueKey('lineup_row_${assignment.id}'),
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(statusIcon(status), size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name (${instrumentLabel(context, assignment.instrument)})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  statusLabel(l10n, status) +
                      (assignment.declineReason == null
                          ? ''
                          : ' · ${l10n.declinedReasonLine(assignment.declineReason!)}'),
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
            ),
          ),
          if (canEdit && needsCover)
            TextButton(
              key: ValueKey('cover_btn_${assignment.id}'),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                foregroundColor: brand.accentInk,
              ),
              onPressed: () => pickAndReassign(context, ref, event, assignment),
              child: Text(l10n.findCover),
            ),
          if (canEdit)
            IconButton(
              key: ValueKey('unassign_btn_${assignment.id}'),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: const Icon(Icons.close, size: 18),
              tooltip: l10n.removeFromLineupAction,
              onPressed: () async {
                final result = await ref
                    .read(calendarActionsProvider)
                    .unassign(assignment.id);
                if (context.mounted) reportResult(context, result);
              },
            ),
        ],
      ),
    );
  }
}
