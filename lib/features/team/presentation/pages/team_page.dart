/// Battuta — Team Roster & Band Calendar Page.
///
/// The Roster tab (members and bands) and the Calendar tab (services,
/// lineups, answers and absences) of the active organization.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/widgets/inbox_button.dart';
import 'package:battuta/features/organizations/presentation/widgets/invitation_card.dart';
import 'package:battuta/features/organizations/presentation/widgets/invite_sheet.dart';
import 'package:battuta/features/organizations/presentation/widgets/organization_switcher.dart';
import 'package:battuta/features/profile/presentation/widgets/profile_avatar_button.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
import 'package:battuta/features/team/presentation/providers/team_tab_request_provider.dart';
import 'package:battuta/features/team/presentation/widgets/calendar_view.dart';
import 'package:battuta/features/team/presentation/widgets/roster_view.dart';
import 'package:battuta/features/team/presentation/widgets/service_form_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    // A request made before this page existed (e.g. from the inbox).
    final request = ref.read(teamTabRequestProvider);
    if (request != null) {
      _selectedTabIndex = request.index;
      Future(() => ref.read(teamTabRequestProvider.notifier).clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(teamTabRequestProvider, (_, next) {
      if (next == null) return;
      setState(() => _selectedTabIndex = next.index);
      ref.read(teamTabRequestProvider.notifier).clear();
    });
    final members = ref.watch(teamMembersProvider);
    final upcomingCount = ref.watch(serviceCalendarProvider).length;
    final isAdmin = ref.watch(isCurrentUserAdminProvider);
    final signedIn = ref.watch(currentAccountIdProvider) != null;
    final organization = ref.watch(activeOrganizationProvider);
    final brand = BattutaBrand.of(context);
    final l10n = AppLocalizations.of(context)!;
    final showCalendar = _selectedTabIndex == 1;
    final canSchedule =
        organization != null &&
        organization.isAdmin &&
        !organization.isArchived;

    return Scaffold(
      appBar: StageAppBar.large(
        title: l10n.teamTitle,
        actions: [
          if (isAdmin && signedIn && !showCalendar)
            IconButton(
              key: const ValueKey('invite_btn'),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: const Icon(Icons.person_add_alt_outlined),
              tooltip: l10n.inviteAction,
              onPressed: () => showInviteSheet(context),
            ),
          const InboxButton(),
          if (isAdmin && signedIn)
            Consumer(
              builder: (context, ref, _) {
                final alertCount = ref.watch(pendingAlertCountProvider);
                return Badge(
                  isLabelVisible: alertCount > 0,
                  label: Text('$alertCount'),
                  backgroundColor: brand.danger,
                  offset: const Offset(-4, 4),
                  child: IconButton(
                    key: const ValueKey('admin_alerts_bell_btn'),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: Icon(
                      alertCount > 0
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: alertCount > 0 ? brand.accent : null,
                    ),
                    tooltip: alertCount > 0
                        ? l10n.coverageAlertsCountTooltip(alertCount)
                        : l10n.coverageAlertsTooltip,
                    // The alerts are the top of the Calendar tab.
                    onPressed: () => setState(() => _selectedTabIndex = 1),
                  ),
                );
              },
            ),
          const ProfileAvatarButton(),
        ],
      ),
      floatingActionButton: showCalendar && canSchedule
          ? FloatingActionButton(
              key: const ValueKey('new_service_btn'),
              tooltip: l10n.addService,
              onPressed: () => showServiceFormDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          if (signedIn) const InvitationsBanner(),
          if (signedIn && organization != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: brand.ink,
                  ),
                  child: const OrganizationSwitcherButton(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: StageSegmentedControl<int>(
              segments: [
                StageSegment(
                  value: 0,
                  label: '${l10n.teamRosterTab} (${members.length})',
                ),
                StageSegment(
                  value: 1,
                  label: '${l10n.bandCalendarTab} ($upcomingCount)',
                ),
              ],
              selected: _selectedTabIndex,
              onChanged: (value) => setState(() => _selectedTabIndex = value),
            ),
          ),
          Expanded(
            child: showCalendar ? const CalendarView() : const RosterView(),
          ),
        ],
      ),
    );
  }
}
