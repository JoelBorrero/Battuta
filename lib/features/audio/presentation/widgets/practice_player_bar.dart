/// Battuta — Practice Audio Player Bar.
///
/// An interactive rehearsal player with real-time audio scrubbing,
/// variable speed controls, pitch-shifting, section-practice loops,
/// and tempo-synchronized visual metronome.
library;

import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/features/audio/presentation/providers/audio_practice_controller.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PracticePlayerBar extends ConsumerWidget {
  const PracticePlayerBar({required this.song, super.key});

  final Song song;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showAttachAudioDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: 'Acoustic_Guide_Track.mp3');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Attach Reference Audio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select an audio file or paste a rehearsal reference link (MP3, WAV, M4A):',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Audio Track Source',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.audio_file),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(audioPracticeControllerProvider.notifier)
                    .attachAudioSource(controller.text.trim());
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Attach Track'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final audioState = ref.watch(audioPracticeControllerProvider);
    final notifier = ref.read(audioPracticeControllerProvider.notifier);

    final position = audioState.position;
    final duration = audioState.duration;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.slateBorder : AppTheme.pearlBorder,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Track Title & Quick Actions ──
            Row(
              children: [
                Icon(
                  Icons.headphones,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audioState.audioSourceTitle ??
                            '${song.title} (Practice Reference)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Tempo: ${song.tempo} BPM • Key: ${song.key}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Metronome Toggle
                IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    audioState.metronomeEnabled
                        ? Icons.timer
                        : Icons.timer_outlined,
                    color: audioState.metronomeEnabled
                        ? theme.colorScheme.primary
                        : null,
                  ),
                  tooltip: 'Metronome Click (${song.tempo} BPM)',
                  onPressed: notifier.toggleMetronome,
                ),

                // Attach audio button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_link),
                  tooltip: 'Attach Audio Track',
                  onPressed: () => _showAttachAudioDialog(context, ref),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Scrubber Slider ──
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: progress,
                onChanged: (val) {
                  final targetMs = (val * duration.inMilliseconds).round();
                  notifier.seek(Duration(milliseconds: targetMs));
                },
              ),
            ),

            // Timestamps
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (audioState.activeLoopSection != null)
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Looping: ${audioState.activeLoopSection}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    _formatDuration(duration),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Primary Controls ──
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Speed Selector
                  PopupMenuButton<double>(
                    tooltip: 'Playback Speed',
                    initialValue: audioState.speed,
                    onSelected: notifier.setSpeed,
                    itemBuilder: (_) => [
                      for (final s in [0.5, 0.75, 1.0, 1.25, 1.5])
                        PopupMenuItem(value: s, child: Text('$s× Speed')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.speed,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${audioState.speed}×',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Rewind 10s
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.replay_10),
                    tooltip: 'Rewind 10 seconds',
                    onPressed: () =>
                        notifier.seek(position - const Duration(seconds: 10)),
                  ),

                  // Play / Pause Button
                  IconButton.filled(
                    visualDensity: VisualDensity.compact,
                    iconSize: 32,
                    icon: Icon(
                      audioState.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    tooltip: audioState.isPlaying ? 'Pause' : 'Play',
                    onPressed: notifier.togglePlay,
                  ),

                  // Forward 10s
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.forward_10),
                    tooltip: 'Forward 10 seconds',
                    onPressed: () =>
                        notifier.seek(position + const Duration(seconds: 10)),
                  ),

                  const SizedBox(width: 4),

                  // Practice Loop Selector
                  PopupMenuButton<String?>(
                    tooltip: 'Loop Section',
                    onSelected: notifier.setLoop,
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: null,
                        child: Text('No Loop (Full Song)'),
                      ),
                      for (final section in song.sections)
                        PopupMenuItem(
                          value: section.name,
                          child: Text('Loop: ${section.name}'),
                        ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: audioState.activeLoopSection != null
                            ? theme.colorScheme.primaryContainer.withValues(
                                alpha: 0.6,
                              )
                            : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: audioState.activeLoopSection != null
                              ? theme.colorScheme.primary.withValues(alpha: 0.4)
                              : theme.colorScheme.outline.withValues(
                                  alpha: 0.2,
                                ),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.repeat,
                            size: 14,
                            color: audioState.activeLoopSection != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 70),
                            child: Text(
                              audioState.activeLoopSection ?? 'Loop',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: audioState.activeLoopSection != null
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── A/B Practice Loop Region Controls ──
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                // Loop Point A
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  child: OutlinedButton.icon(
                    key: const ValueKey('ab_loop_point_a_button'),
                    onPressed: () => notifier.setLoopPointA(),
                    icon: const Icon(Icons.pin_drop, size: 14),
                    label: Text(
                      audioState.loopPointA != null
                          ? 'A: ${_formatDuration(audioState.loopPointA!)}'
                          : 'Set A',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: audioState.loopPointA != null
                          ? AppTheme.amberAccent
                          : Colors.transparent,
                      foregroundColor: audioState.loopPointA != null
                          ? AppTheme.obsidianText
                          : theme.colorScheme.onSurface,
                      side: BorderSide(
                        color: audioState.loopPointA != null
                            ? AppTheme.amberAccent
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),

                // Loop Point B
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  child: OutlinedButton.icon(
                    key: const ValueKey('ab_loop_point_b_button'),
                    onPressed: () => notifier.setLoopPointB(),
                    icon: const Icon(Icons.flag, size: 14),
                    label: Text(
                      audioState.loopPointB != null
                          ? 'B: ${_formatDuration(audioState.loopPointB!)}'
                          : 'Set B',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: audioState.loopPointB != null
                          ? AppTheme.amberAccent
                          : Colors.transparent,
                      foregroundColor: audioState.loopPointB != null
                          ? AppTheme.obsidianText
                          : theme.colorScheme.onSurface,
                      side: BorderSide(
                        color: audioState.loopPointB != null
                            ? AppTheme.amberAccent
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),

                // Clear A/B Loop
                if (audioState.loopPointA != null ||
                    audioState.loopPointB != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    child: TextButton.icon(
                      key: const ValueKey('ab_loop_clear_button'),
                      onPressed: notifier.clearAbLoop,
                      icon: const Icon(Icons.clear, size: 14),
                      label: const Text(
                        'Clear Loop',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.stageRed,
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
