/// Battuta — the start of a performance on the Live tab: pick an upcoming
/// service or a setlist and play it on this device.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Upcoming services shown at most; the rest are in the Calendar tab.
const int _maxServices = 3;

/// Setlists shown at most.
const int _maxSetlists = 6;

class PerformanceStartCard extends ConsumerWidget {
  const PerformanceStartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
    final setlists = [...(ref.watch(setlistsProvider).value ?? const [])]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final byId = {for (final s in setlists) s.id: s};
    final services = [
      for (final event in ref.watch(allServiceEventsProvider))
        if (event.setlistId != null && byId.containsKey(event.setlistId)) event,
    ].take(_maxServices).toList();

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: brand.inkMuted,
        ),
      ),
    );

    return StageCard(
      key: const ValueKey('live_start_card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            (l10n?.livePerfHubTitle ?? 'Start a session').toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: brand.inkMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n?.livePerfHubIntro ?? 'Play a setlist with the chart scrolling at the tempo of each song.',
            style: const TextStyle(fontSize: 13),
          ),
          if (services.isNotEmpty) ...[
            label(l10n?.livePerfHubServices ?? 'Upcoming services'),
            for (final event in services)
              _StartRow(
                key: ValueKey('live_start_service_${event.id}'),
                title: event.title,
                subtitle: _when(context, event),
                onTap: () =>
                    context.push(AppRoutes.performSetlist(event.setlistId!)),
              ),
          ],
          label(l10n?.livePerfHubSetlists ?? 'Setlists'),
          if (setlists.isEmpty)
            Text(
              l10n?.livePerfHubNoSetlists ??
                  'No setlists yet. Build one in Repertoire to play it here.',
              key: const ValueKey('live_start_empty'),
              style: TextStyle(fontSize: 13, color: brand.inkMuted),
            )
          else
            for (final setlist in setlists.take(_maxSetlists))
              _StartRow(
                key: ValueKey('live_start_setlist_${setlist.id}'),
                title: setlist.title,
                subtitle: _songs(l10n, setlist),
                onTap: setlist.items.isEmpty
                    ? null
                    : () => context.push(AppRoutes.performSetlist(setlist.id)),
              ),
        ],
      ),
    );
  }

  static String _songs(AppLocalizations? l10n, Setlist setlist) =>
      l10n?.livePerfSongCount(setlist.songCount) ??
      '${setlist.songCount} songs';

  static String _when(BuildContext context, ServiceEvent event) {
    final material = MaterialLocalizations.of(context);
    return '${material.formatMediumDate(event.dateTime)} · '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(event.dateTime))}';
  }
}

class _StartRow extends StatelessWidget {
  const _StartRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: BattutaPressable(
        onTap: onTap,
        semanticLabel: title,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: brand.cardRaised,
            borderRadius: BorderRadius.circular(BattutaRadius.sm),
            border: Border.all(color: brand.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: onTap == null ? brand.inkMuted : brand.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: brand.inkMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.play_arrow,
                size: 22,
                color: onTap == null ? brand.inkMuted : brand.accentInk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
