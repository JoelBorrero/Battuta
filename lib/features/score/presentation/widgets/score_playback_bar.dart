/// Battuta — Score Playback & Audio Preview Bar.
///
/// Stage-ready audio controls providing real-time score auditioning, tempo
/// display, sound feedback mute toggle, and synchronized playback tracking.
library;

import 'package:battuta/features/score/presentation/services/score_preview_player.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Floating or docked playback control bar for previewing musical notation.
class ScorePlaybackBar extends StatelessWidget {
  const ScorePlaybackBar({required this.player, super.key});

  /// The active [ScorePreviewPlayer] orchestrating timeline playback.
  final ScorePreviewPlayer player;

  void _showTempoDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    var selectedTempo = player.tempo;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n?.playbackTempo ?? 'Playback Tempo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$selectedTempo BPM',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                min: 40,
                max: 240,
                divisions: 200,
                value: selectedTempo.toDouble(),
                onChanged: (val) {
                  setDialogState(() => selectedTempo = val.round());
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in [60, 80, 96, 120, 140])
                    ActionChip(
                      label: Text('$t BPM'),
                      onPressed: () {
                        setDialogState(() => selectedTempo = t);
                      },
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                player.setTempo(selectedTempo);
                Navigator.of(ctx).pop();
              },
              child: Text(l10n?.setTempo ?? 'Set Tempo'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final isPlaying = player.isPlaying;
        final playingLabel = player.currentPlayingLabel;
        final measureNum = player.currentMeasureNumber;
        final isMuted = player.synthesizer.isMuted;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.6,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPlaying
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Play / Pause Button
                IconButton.filled(
                  key: const Key('score_play_pause_btn'),
                  visualDensity: VisualDensity.compact,
                  iconSize: 22,
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  tooltip: isPlaying
                      ? (l10n?.pauseMelody ?? 'Pause Melody')
                      : (l10n?.playMelody ?? 'Play / Preview Melody'),
                  onPressed: player.togglePlay,
                ),

                const SizedBox(width: 4),

                // Stop / Rewind Button
                IconButton(
                  key: const Key('score_stop_btn'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.stop),
                  tooltip: l10n?.stopRewind ?? 'Stop & Rewind',
                  onPressed: player.stop,
                ),

                const SizedBox(width: 8),

                // Status & Note Playing Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.7,
                          )
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPlaying
                          ? theme.colorScheme.primary.withValues(alpha: 0.4)
                          : theme.colorScheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPlaying ? Icons.music_note : Icons.graphic_eq,
                        size: 14,
                        color: isPlaying
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPlaying
                            ? 'M$measureNum: $playingLabel'
                            : (l10n?.scoreAudioPreview ?? 'Score Audio Preview'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPlaying
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Tempo Badge (tap to adjust)
                InkWell(
                  key: const Key('score_tempo_btn'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showTempoDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.speed,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${player.tempo} BPM',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Sound Feedback / Mute Toggle Button
                IconButton(
                  key: const Key('score_mute_btn'),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    isMuted ? Icons.volume_off : Icons.volume_up,
                    color: isMuted ? Colors.grey : theme.colorScheme.primary,
                  ),
                  tooltip: isMuted
                      ? (l10n?.unmuteSound ?? 'Unmute Note Sound Feedback')
                      : (l10n?.muteSound ?? 'Mute Note Sound Feedback'),
                  onPressed: player.toggleMute,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
