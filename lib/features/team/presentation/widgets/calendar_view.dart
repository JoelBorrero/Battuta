/// The Calendar tab: services of the active organization and band, the
/// member's own assignments and absences, and the admin's tools.
library;

import 'package:battuta/app/design_system/components/stage_empty_state.dart';
import 'package:battuta/app/design_system/components/stage_surfaces.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/app/theme/battuta_tokens.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/widgets/organization_switcher.dart';
import 'package:battuta/features/team/domain/entities/schedule_alert.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:battuta/features/team/presentation/widgets/admin_schedule_alerts_banner.dart';
import 'package:battuta/features/team/presentation/widgets/assign_member_sheet.dart';
import 'package:battuta/features/team/presentation/widgets/month_grid.dart';
import 'package:battuta/features/team/presentation/widgets/my_calendar_sections.dart';
import 'package:battuta/features/team/presentation/widgets/recurring_schedules_sheet.dart';
import 'package:battuta/features/team/presentation/widgets/service_event_card.dart';
import 'package:battuta/features/team/presentation/widgets/service_form_dialog.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  // Until the user picks a day or browses months, the selection and the
  // visible month follow "today" (so they move on at midnight).
  DateTime? _picked;
  DateTime? _browsedMonth;
  final Map<DateTime, GlobalKey> _dayHeaders = {};

  void _findCover(ScheduleAlert alert) {
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

  void _shiftMonth(DateTime month, int delta) =>
      setState(() => _browsedMonth = DateTime(month.year, month.month + delta));

  void _select(DateTime day) {
    setState(() {
      _picked = day;
      _browsedMonth = DateTime(day.year, day.month);
    });
    // Bring the services of that day into view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _dayHeaders[day]?.currentContext;
      if (target == null || !mounted) return;
      Scrollable.ensureVisible(
        target,
        duration: BattutaMotion.resolve(context, BattutaMotion.bar),
        curve: BattutaMotion.downbeat,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brand = BattutaBrand.of(context);
    final material = MaterialLocalizations.of(context);
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
    final today = ref.watch(calendarClockProvider)();
    final selected = _picked ?? dateOnly(today);
    final month = _browsedMonth ?? DateTime(today.year, today.month);

    final byDay = <DateTime, List<MapEntry<int, ServiceEvent>>>{};
    for (var i = 0; i < events.length; i++) {
      byDay
          .putIfAbsent(dateOnly(events[i].dateTime), () => [])
          .add(MapEntry(i, events[i]));
    }
    _dayHeaders.removeWhere((day, _) => !byDay.containsKey(day));

    Widget dayHeader(DateTime day) => StageSectionHeader(
      key: _dayHeaders.putIfAbsent(day, GlobalKey.new),
      title: material.formatFullDate(day),
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
    );

    final selectedHasServices = byDay.containsKey(selected);

    // Built eagerly (one organization's upcoming services is a short list), so
    // every date header has a context for `Scrollable.ensureVisible`.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (organization.isAdmin)
            AdminScheduleAlertsBanner(onFindCover: _findCover),
          const MyServicesSection(),
          const MyAbsencesSection(),
          MonthGrid(
            month: month,
            today: today,
            selected: selected,
            markedDays: byDay.keys.toSet(),
            onSelect: _select,
            onPreviousMonth: () => _shiftMonth(month, -1),
            onNextMonth: () => _shiftMonth(month, 1),
          ),
          StageSectionHeader(
            title: '${l10n.periodicServicesTitle} (${events.length})',
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 0),
            trailing: canEdit
                ? IconButton(
                    key: const ValueKey('recurring_schedules_btn'),
                    constraints: const BoxConstraints(
                      minWidth: BattutaSpace.minTouchTarget,
                      minHeight: BattutaSpace.minTouchTarget,
                    ),
                    color: brand.accentInk,
                    icon: const Icon(Icons.repeat, size: 20),
                    tooltip: l10n.recurringSchedules,
                    onPressed: () => showRecurringSchedulesSheet(context),
                  )
                : null,
          ),
          if (events.isNotEmpty && !selectedHasServices) ...[
            dayHeader(selected),
            Text(
              l10n.noServicesOnDay,
              key: const ValueKey('no_services_on_day'),
              style: TextStyle(fontSize: 13, color: brand.inkMuted),
            ),
          ],
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    size: 48,
                    color: brand.inkMuted,
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
            for (final MapEntry(key: day, value: dayEvents)
                in byDay.entries) ...[
              dayHeader(day),
              for (final MapEntry(key: index, value: event) in dayEvents)
                ServiceEventCard(
                  event: event,
                  isNext: index == 0,
                  canEdit: canEdit,
                ),
            ],
        ],
      ),
    );
  }
}
