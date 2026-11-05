/// Battuta — Live session page (placeholder).
///
/// A coming-soon placeholder for the live-session feature that will
/// allow band members to connect in real-time, share a synchronized
/// lead sheet, and coordinate tempo and section cues.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder page for the upcoming live-session feature.
///
/// Displays a centered illustration with a brief description of
/// the feature. This will be replaced with the full implementation
/// once the real-time collaboration backend is ready.
class LiveSessionPage extends ConsumerWidget {
  /// Creates a [LiveSessionPage].
  const LiveSessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Live Session')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon ──
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.music_note,
                  size: 56,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(height: 32),

              // ── Title ──
              Text(
                'Live Session',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // ── Subtitle ──
              Text(
                'Coming soon — connect with your band in real-time',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),

              const SizedBox(height: 32),

              // ── Feature preview chips ──
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _FeatureChip(
                    icon: Icons.sync,
                    label: 'Synced lead sheets',
                  ),
                  _FeatureChip(
                    icon: Icons.people_outline,
                    label: 'Band connect',
                  ),
                  _FeatureChip(
                    icon: Icons.timer_outlined,
                    label: 'Tempo control',
                  ),
                  _FeatureChip(
                    icon: Icons.queue_music,
                    label: 'Section cues',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

/// A small chip previewing an upcoming feature.
class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(icon, size: 16, color: colorScheme.primary),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelMedium,
      side: BorderSide(color: colorScheme.outlineVariant),
      backgroundColor: colorScheme.surface,
    );
  }
}
