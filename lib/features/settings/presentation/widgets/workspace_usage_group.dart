/// Settings "Workspace Resources & Quota" group: pool name and tier, AI
/// credits and cloud storage as meter rows. Colours come from the brand roles
/// so the card reads in both Stage (dark) and Rehearsal (light).
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/workspace/domain/entities/workspace_usage.dart';
import 'package:battuta/features/workspace/presentation/providers/workspace_usage_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkspaceUsageGroup extends ConsumerWidget {
  const WorkspaceUsageGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
    final usage = ref.watch(workspaceUsageProvider);

    return StageGroup(
      key: const ValueKey('workspace_usage_card'),
      title: l10n?.workspaceResourcesSection ?? 'Workspace Resources & Quota',
      children: usage.when(
        data: (u) => [
          _PoolRow(usage: u),
          _MeterRow(
            icon: Icons.auto_awesome,
            tone: brand.accentInk,
            fill: brand.accent,
            label: l10n?.geminiAiCredits ?? 'Gemini AI Credits',
            value: u.formattedCredits,
            ratio: u.creditsRatio,
            caption:
                l10n?.billingPeriodScans(u.geminiScansCount) ??
                '${u.geminiScansCount} full lead-sheet scans this billing period',
          ),
          _MeterRow(
            icon: Icons.cloud_outlined,
            tone: brand.info,
            fill: brand.info,
            label: l10n?.cloudStorage ?? 'Cloud Storage',
            value: u.formattedStorage,
            ratio: u.storageRatio,
            caption:
                l10n?.storageTracksCount(u.filesUploadedCount) ??
                '${u.filesUploadedCount} scores and audio tracks stored',
          ),
        ],
        loading: () => const [
          Padding(
            padding: EdgeInsets.all(BattutaSpace.lg),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ],
        error: (error, stack) => [
          Padding(
            padding: const EdgeInsets.all(BattutaSpace.lg),
            child: Text(
              l10n?.workspaceMetricsUnavailable ??
                  'Workspace metrics unavailable',
              style: TextStyle(fontSize: 14, color: brand.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoolRow extends StatelessWidget {
  const _PoolRow({required this.usage});

  final WorkspaceUsage usage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BattutaSpace.lg,
        vertical: BattutaSpace.md,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: BattutaSpace.sm,
        runSpacing: BattutaSpace.xs,
        children: [
          Text(
            l10n?.activeWorkspacePool ?? 'ACTIVE WORKSPACE POOL',
            style: TextStyle(
              color: brand.inkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: brand.accentWash,
              borderRadius: BorderRadius.circular(BattutaRadius.xs),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BattutaSpace.sm,
                vertical: 3,
              ),
              child: Text(
                '${usage.workspaceName} • ${usage.tier}',
                style: TextStyle(
                  color: brand.accentInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeterRow extends StatelessWidget {
  const _MeterRow({
    required this.icon,
    required this.tone,
    required this.fill,
    required this.label,
    required this.value,
    required this.ratio,
    required this.caption,
  });

  final IconData icon;
  final Color tone;
  final Color fill;
  final String label;
  final String value;
  final double ratio;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Padding(
      padding: const EdgeInsets.all(BattutaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: tone),
              const SizedBox(width: BattutaSpace.sm),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: brand.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: BattutaSpace.sm),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(color: brand.inkMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: brand.cardRaised,
              valueColor: AlwaysStoppedAnimation<Color>(fill),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: BattutaSpace.xs),
          Text(caption, style: TextStyle(color: brand.inkMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
