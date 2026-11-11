/// Admin management of the recurring schedules of the active organization.
library;

import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/services/service_calendar_builder.dart';
import 'package:battuta/features/team/presentation/providers/calendar_actions.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:battuta/features/team/presentation/widgets/calendar_support.dart';
import 'package:battuta/features/team/presentation/widgets/service_form_dialog.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showRecurringSchedulesSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _SchedulesSheet(),
    );

class _SchedulesSheet extends ConsumerWidget {
  const _SchedulesSheet();

  Future<void> _stop(
    BuildContext context,
    WidgetRef ref,
    RecurringSchedule schedule,
  ) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(today.year, today.month, today.day),
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 3),
    );
    if (picked == null || !context.mounted) return;
    final result = await ref
        .read(calendarActionsProvider)
        .setScheduleEnd(schedule, picked);
    if (context.mounted) reportResult(context, result);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RecurringSchedule schedule,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteScheduleAction),
        content: Text(l10n.deleteScheduleConfirm(schedule.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirm_delete_schedule_btn'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteScheduleAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(calendarActionsProvider)
        .deleteSchedule(schedule);
    if (context.mounted) reportResult(context, result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final schedules = ref.watch(activeSchedulesProvider).value ?? const [];
    final materialLocalizations = MaterialLocalizations.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              l10n.recurringSchedules,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (schedules.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.noSchedulesYet),
              ),
            for (final schedule in schedules)
              Builder(
                builder: (context) {
                  // Paused, or stopped from a date: both resume the same way.
                  final running =
                      schedule.isActive && schedule.disabledAfter == null;
                  return Container(
                    key: ValueKey('schedule_item_${schedule.id}'),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: brand.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.scheduleSummary(
                            schedule.recurrence.localizedName(context),
                            materialLocalizations.formatTimeOfDay(
                              TimeOfDay(
                                hour: schedule.minuteOfDay ~/ 60,
                                minute: schedule.minuteOfDay % 60,
                              ),
                            ),
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            StatusTag(
                              label: schedule.isActive
                                  ? l10n.scheduleActiveLabel
                                  : l10n.schedulePausedLabel,
                              color: schedule.isActive
                                  ? statusColor(
                                      context,
                                      AssignmentStatus.confirmed,
                                    )
                                  : brand.inkMuted,
                            ),
                            if (schedule.disabledAfter != null)
                              StatusTag(
                                label: l10n.scheduleEndsLabel(
                                  materialLocalizations.formatMediumDate(
                                    schedule.disabledAfter!.toLocal(),
                                  ),
                                ),
                                color: brand.accentInk,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            TextButton.icon(
                              key: ValueKey('schedule_edit_${schedule.id}'),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(44, 44),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: Text(l10n.editService),
                              onPressed: () => showServiceFormDialog(
                                context,
                                schedule: schedule,
                              ),
                            ),
                            TextButton.icon(
                              key: ValueKey('schedule_pause_${schedule.id}'),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(44, 44),
                              ),
                              icon: Icon(
                                running
                                    ? Icons.pause_circle_outline
                                    : Icons.play_circle_outline,
                                size: 18,
                              ),
                              label: Text(
                                running
                                    ? l10n.pauseScheduleAction
                                    : l10n.resumeScheduleAction,
                              ),
                              onPressed: () async {
                                final actions = ref.read(
                                  calendarActionsProvider,
                                );
                                final result = running
                                    ? await actions.setScheduleActive(
                                        schedule,
                                        active: false,
                                      )
                                    : await actions.resumeSchedule(schedule);
                                if (context.mounted) {
                                  reportResult(context, result);
                                }
                              },
                            ),
                            TextButton.icon(
                              key: ValueKey('schedule_stop_${schedule.id}'),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(44, 44),
                              ),
                              icon: const Icon(
                                Icons.event_busy_outlined,
                                size: 18,
                              ),
                              label: Text(l10n.stopScheduleAction),
                              onPressed: () => _stop(context, ref, schedule),
                            ),
                            TextButton.icon(
                              key: ValueKey('schedule_delete_${schedule.id}'),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(44, 44),
                                foregroundColor: theme.colorScheme.error,
                              ),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: Text(l10n.deleteScheduleAction),
                              onPressed: () => _delete(context, ref, schedule),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            OutlinedButton.icon(
              key: const ValueKey('add_schedule_btn'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48)),
              icon: const Icon(Icons.add),
              label: Text(l10n.addServiceRehearsal),
              onPressed: () => showServiceFormDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}
