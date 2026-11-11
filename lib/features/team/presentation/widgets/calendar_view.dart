/// The Calendar tab: services of the active organization and band, the
/// member's own assignments and absences, and the admin's tools.
library;

import 'package:battuta/app/design_system/components/stage_empty_state.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/widgets/organization_switcher.dart';
import 'package:battuta/features/team/domain/entities/schedule_alert.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:battuta/features/team/presentation/widgets/admin_schedule_alerts_banner.dart';
import 'package:battuta/features/team/presentation/widgets/assign_member_sheet.dart';
import 'package:battuta/features/team/presentation/widgets/my_calendar_sections.dart';
import 'package:battuta/features/team/presentation/widgets/recurring_schedules_sheet.dart';
import 'package:battuta/features/team/presentation/widgets/service_event_card.dart';
import 'package:battuta/features/team/presentation/widgets/service_form_dialog.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CalendarView extends ConsumerWidget {
  const CalendarView({super.key});

  void _findCover(BuildContext context, WidgetRef ref, ScheduleAlert alert) {
    for (final event in ref.read(allServiceEventsProvider)) {
      if (event.id != alert.eventId) continue;
      for (final assignment in event.assignments) {
        if (assignment.id == alert.assignmentId) {
          pickAndReassign(context, ref, event, assignment);
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final signedIn = ref.watch(currentAccountIdProvider) != null;
    final organization = ref.watch(activeOrganizationProvider);

    if (!signedIn) {
      return StageEmptyState(
        icon: Icons.calendar_month_outlined,
        title: l10n.calendarSignInTitle,
        message: l10n.calendarSignInMessage,
        actions: [
          FilledButton(
            key: const ValueKey('calendar_sign_in_btn'),
            style: FilledButton.styleFrom(minimumSize: const Size(44, 48)),
            onPressed: () => context.push(AppRoutes.signIn),
            child: Text(l10n.welcomeSignIn),
          ),
        ],
      );
    }

    if (organization == null) {
      return StageEmptyState(
        icon: Icons.groups_outlined,
        title: l10n.noOrganizationsYet,
        message: l10n.noOrganizationInvitesNote,
        actions: [
          FilledButton.icon(
            key: const ValueKey('calendar_create_org_btn'),
            style: FilledButton.styleFrom(minimumSize: const Size(44, 48)),
            icon: const Icon(Icons.add),
            label: Text(l10n.createOrganizationAction),
            onPressed: () => showCreateOrganizationDialog(context),
          ),
          OutlinedButton.icon(
            key: const ValueKey('calendar_join_org_btn'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48)),
            icon: const Icon(Icons.link),
            label: Text(l10n.joinWithLinkAction),
            onPressed: () => joinWithPastedInvite(context),
          ),
        ],
      );
    }

    final canEdit = organization.isAdmin && !organization.isArchived;
    final events = ref.watch(serviceCalendarProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (organization.isAdmin)
          AdminScheduleAlertsBanner(
            onFindCover: (alert) => _findCover(context, ref, alert),
          ),
        const MyServicesSection(),
        const MyAbsencesSection(),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                '${l10n.periodicServicesTitle} (${events.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (canEdit)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('recurring_schedules_btn'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(44, 44),
                      ),
                      icon: const Icon(Icons.repeat, size: 16),
                      label: Text(l10n.recurringSchedules),
                      onPressed: () => showRecurringSchedulesSheet(context),
                    ),
                    FilledButton.icon(
                      key: const ValueKey('new_service_btn'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(44, 44),
                      ),
                      icon: const Icon(Icons.event, size: 16),
                      label: Text(l10n.addService),
                      onPressed: () => showServiceFormDialog(context),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(l10n.noUpcomingServices, textAlign: TextAlign.center),
                if (canEdit) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const ValueKey('schedule_first_service_btn'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(44, 48),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.scheduleFirstService),
                    onPressed: () => showServiceFormDialog(context),
                  ),
                ],
              ],
            ),
          )
        else
          for (var i = 0; i < events.length; i++)
            ServiceEventCard(
              event: events[i],
              isNext: i == 0,
              canEdit: canEdit,
            ),
        const SizedBox(height: 32),
      ],
    );
  }
}
