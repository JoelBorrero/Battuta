/// Battuta — Admin Schedule Alerts Banner Widget.
///
/// Prominently displays scheduling gaps and missing musician notifications
/// to Administrators with a 1-tap "Find Cover" replacement workflow.
library;

import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/features/team/domain/entities/schedule_alert.dart';
import 'package:battuta/features/team/presentation/providers/schedule_alerts_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminScheduleAlertsBanner extends ConsumerWidget {
  const AdminScheduleAlertsBanner({
    super.key,
    required this.onFindCover,
  });

  /// Callback when the Admin taps "Find Cover" for a specific alert.
  final void Function(ScheduleAlert alert) onFindCover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(adminScheduleAlertsProvider);
    if (alerts.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1711) : const Color(0xFFFFF9F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.stageAmber.withValues(alpha: 0.8),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.stageAmber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Scheduling Attention Needed (${alerts.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.stageAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final alert in alerts) ...[
            _AlertItemRow(
              alert: alert,
              onFindCover: () => onFindCover(alert),
              onDismiss: () =>
                  ref.read(dismissedAlertsProvider.notifier).dismiss(alert.id),
            ),
            if (alert != alerts.last)
              Divider(
                height: 16,
                color: AppTheme.stageAmber.withValues(alpha: 0.2),
              ),
          ],
        ],
      ),
    );
  }
}

class _AlertItemRow extends StatelessWidget {
  const _AlertItemRow({
    required this.alert,
    required this.onFindCover,
    required this.onDismiss,
  });

  final ScheduleAlert alert;
  final VoidCallback onFindCover;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Text(
              alert.memberName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.stageAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                alert.role.shortName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.stageAmber,
                ),
              ),
            ),
            Text(
              '• ${alert.eventTitle}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          alert.reason,
          style: TextStyle(
            fontSize: 12,
            color: Colors.red.shade400,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                minimumSize: const Size(60, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
            ),
            FilledButton.tonal(
              key: ValueKey('find_cover_btn_${alert.id}'),
              onPressed: onFindCover,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.stageAmber.withValues(alpha: 0.2),
                foregroundColor: AppTheme.stageAmber,
                minimumSize: const Size(100, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_search_outlined, size: 16),
                  SizedBox(width: 4),
                  Text('Find Cover', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
