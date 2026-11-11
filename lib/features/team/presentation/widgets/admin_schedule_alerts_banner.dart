/// Battuta — Admin Schedule Alerts Banner Widget.
///
/// Shows the lineup gaps of upcoming services (a member declined or is away)
/// to administrators, with a one-tap "Find cover" that opens the picker of
/// available members.
library;

import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/features/team/domain/entities/schedule_alert.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:battuta/features/team/presentation/widgets/calendar_support.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminScheduleAlertsBanner extends ConsumerWidget {
  const AdminScheduleAlertsBanner({required this.onFindCover, super.key});

  /// Called when the admin taps "Find cover" for [ScheduleAlert].
  final void Function(ScheduleAlert alert) onFindCover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(adminScheduleAlertsProvider);
    if (alerts.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final brand = BattutaBrand.of(context);

    return Container(
      key: const ValueKey('schedule_alerts_banner'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: brand.accentWash,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: brand.accent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: brand.accentInk,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.schedulingAttentionNeeded(alerts.length),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: brand.accentInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final alert in alerts)
            _AlertRow(
              alert: alert,
              onFindCover: () => onFindCover(alert),
              onDismiss: () =>
                  ref.read(dismissedAlertsProvider.notifier).dismiss(alert.id),
            ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.alert,
    required this.onFindCover,
    required this.onDismiss,
  });

  final ScheduleAlert alert;
  final VoidCallback onFindCover;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final role = instrumentLabel(context, alert.instrument);
    final materialLocalizations = MaterialLocalizations.of(context);
    final message = switch (alert.kind) {
      ScheduleAlertKind.declined => l10n.cantAttendCoverNeededFor(role),
      ScheduleAlertKind.absent => l10n.alertAwayCoverNeeded(role),
    };

    return Padding(
      key: ValueKey('alert_${alert.id}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${alert.memberName} · ${alert.eventTitle}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            '${materialLocalizations.formatMediumDate(alert.eventDate)} · $message',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
          ),
          if (alert.reason != null)
            Text(
              l10n.declinedReasonLine(alert.reason!),
              style: const TextStyle(fontSize: 12),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                key: ValueKey('alert_dismiss_${alert.assignmentId}'),
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                onPressed: onDismiss,
                child: Text(l10n.dismissAction),
              ),
              FilledButton(
                key: ValueKey('alert_cover_${alert.assignmentId}'),
                style: FilledButton.styleFrom(minimumSize: const Size(44, 44)),
                onPressed: onFindCover,
                child: Text(l10n.findCover),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
