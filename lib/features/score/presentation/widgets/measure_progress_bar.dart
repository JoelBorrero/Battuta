/// Battuta — MeasureProgressBar widget.
///
/// Displays real-time rhythmic capacity metrics for the active measure,
/// indicating remaining tick capacity, completion status, or overflow warnings.
library;

import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:flutter/material.dart';

/// Real-time visual progress bar tracking active measure capacity.
class MeasureProgressBar extends StatelessWidget {
  const MeasureProgressBar({required this.measure, super.key});

  /// The active measure whose capacity is displayed.
  final Measure? measure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (measure == null) {
      return const SizedBox.shrink();
    }

    final totalTicks = measure!.totalTicks;
    final maxTicks = measure!.maxTicks;
    final fillRatio = measure!.fillRatio;
    final isComplete = measure!.isComplete;
    final hasOverflow = measure!.hasOverflow;

    final Color statusColor;
    final String statusLabel;

    if (hasOverflow) {
      statusColor = Colors.red;
      statusLabel = 'Overflow: +${totalTicks - maxTicks}t';
    } else if (isComplete) {
      statusColor = Colors.green;
      statusLabel = 'Complete (${totalTicks}t)';
    } else {
      statusColor = theme.colorScheme.primary;
      statusLabel = '$totalTicks / ${maxTicks}t';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Measure #${measure!.number} (${measure!.timeSignature})',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isComplete)
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.green,
                    )
                  else if (hasOverflow)
                    const Icon(Icons.warning, size: 14, color: Colors.red),
                  if (isComplete || hasOverflow) const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fillRatio,
              minHeight: 6,
              backgroundColor: theme.colorScheme.outlineVariant.withValues(
                alpha: 0.3,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
