/// Battuta — Team Roster & Band Calendar Page.
///
/// The Roster tab (members and bands) and the Calendar tab (services,
/// lineups, answers and absences) of the active organization.
library;

import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/widgets/inbox_button.dart';
import 'package:battuta/features/organizations/presentation/widgets/invitation_card.dart';
import 'package:battuta/features/organizations/presentation/widgets/organization_switcher.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
import 'package:battuta/features/team/presentation/providers/team_tab_request_provider.dart';
import 'package:battuta/features/team/presentation/widgets/calendar_view.dart';
import 'package:battuta/features/team/presentation/widgets/roster_view.dart';
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
    final l10n = AppLocalizations.of(context);
    final showCalendar = _selectedTabIndex == 1;

    return Scaffold(
      appBar: AppBar(
        title: OrganizationSwitcherButton(
          fallbackTitle: l10n?.worshipTeamTitle ?? 'Worship Team & Band',
        ),
        actions: [
          const InboxButton(),
          if (isAdmin && signedIn)
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
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: Icon(
                      alertCount > 0
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: alertCount > 0 ? AppTheme.stageAmber : null,
                    ),
                    tooltip: alertCount > 0
                        ? (l10n?.coverageAlertsCountTooltip(alertCount) ??
                              '$alertCount cover alerts')
                        : (l10n?.coverageAlertsTooltip ??
                              'Musician Coverage Alerts'),
                    // The alerts are the top of the Calendar tab.
                    onPressed: () => setState(() => _selectedTabIndex = 1),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (signedIn) const InvitationsBanner(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    icon: const Icon(Icons.people_outline),
                    label: Text(
                      '${l10n?.teamRosterTab ?? "Team Roster"} (${members.length})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      '${l10n?.bandCalendarTab ?? "Band Calendar"} ($upcomingCount)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                selected: {_selectedTabIndex},
                onSelectionChanged: (val) {
                  setState(() => _selectedTabIndex = val.first);
                },
              ),
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
