/// Battuta — Live sessions found on the local network, with the
/// "Join by address" fallback underneath.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/sync/domain/models/live_session.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class NearbySessionsList extends StatelessWidget {
  const NearbySessionsList({
    required this.sessions,
    required this.searching,
    required this.timedOut,
    required this.onJoin,
    required this.onJoinByAddress,
    super.key,
  });

  final List<LiveSession> sessions;

  /// Browsing is on and nothing has appeared yet.
  final bool searching;

  /// Nothing appeared for 5 seconds.
  final bool timedOut;
  final ValueChanged<LiveSession> onJoin;
  final VoidCallback onJoinByAddress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);

    final joinRow = StageRow(
      key: const ValueKey('live_join_by_address'),
      icon: Icons.link,
      label: l10n?.liveJoinByAddress ?? 'Join by address',
      onTap: onJoinByAddress,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sessions.isNotEmpty)
          StageGroup(
            margin: EdgeInsets.zero,
            title: l10n?.liveNearbySessions ?? 'Nearby sessions',
            children: [
              for (final session in sessions)
                StageRow(
                  key: ValueKey('live_session_${session.id}'),
                  icon: Icons.cell_tower,
                  label: session.name,
                  subtitle: session.isCompatible
                      ? (session.directorName.isEmpty
                            ? null
                            : session.directorName)
                      : (l10n?.liveSessionIncompatible ??
                            'Needs a newer Battuta'),
                  trailing: session.isCompatible
                      ? StageStatusPill(
                          label: l10n?.liveJoinAction ?? 'Join',
                          active: true,
                          tone: brand.accent,
                        )
                      : null,
                  onTap: session.isCompatible ? () => onJoin(session) : null,
                ),
            ],
          )
        else if (timedOut)
          SizedBox(
            key: const ValueKey('live_no_sessions'),
            height: 300,
            child: StageEmptyState(
              icon: Icons.wifi_tethering_off,
              title: l10n?.liveNoSessionsFound ?? 'No sessions found nearby',
              message: l10n?.liveNoSessionsHint ?? 'Ask the host for the address, or check that you are on the same Wi-Fi.',
            ),
          )
        else
          StageCard(
            key: const ValueKey('live_searching'),
            child: Row(
              children: [
                Icon(Icons.wifi_tethering, size: 20, color: brand.inkMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    searching
                        ? (l10n?.liveSearching ?? 'Looking for sessions…')
                        : (l10n?.liveNearbySessions ?? 'Nearby sessions'),
                    style: TextStyle(fontSize: 15, color: brand.inkMuted),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        StageGroup(margin: EdgeInsets.zero, children: [joinRow]),
      ],
    );
  }
}
