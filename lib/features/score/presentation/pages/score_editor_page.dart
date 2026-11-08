/// Battuta — Score & Musical Notation Editor Page.
///
/// An interactive sheet music editor combining [StaffCanvas] with vertical
/// drag-and-snap pitch manipulation and [RhythmToolbar] for rhythm assignment.
library;

import 'package:battuta/features/repertoire/domain/entities/song_score_mapper.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/presentation/providers/rhythm_editor_controller.dart';
import 'package:battuta/features/score/presentation/rendering/rendered_note_box.dart';
import 'package:battuta/features/score/presentation/services/score_preview_player.dart';
import 'package:battuta/features/score/presentation/services/tone_synthesizer.dart';
import 'package:battuta/features/score/presentation/widgets/rhythm_toolbar.dart';
import 'package:battuta/features/score/presentation/widgets/score_playback_bar.dart';
import 'package:battuta/features/score/presentation/widgets/staff_canvas.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen interactive musical score & staff notation editor.
class ScoreEditorPage extends ConsumerStatefulWidget {
  const ScoreEditorPage({required this.songId, super.key, this.synthesizer});

  final String songId;
  final ToneSynthesizer? synthesizer;

  @override
  ConsumerState<ScoreEditorPage> createState() => _ScoreEditorPageState();
}

class _ScoreEditorPageState extends ConsumerState<ScoreEditorPage> {
  RhythmEditorController? _controller;
  ScorePreviewPlayer? _previewPlayer;
  ToneSynthesizer? _synthesizer;
  Score? _activeScore;
  bool _isSaving = false;

  void _initScore(Score score) {
    if (_activeScore == null) {
      _activeScore = score;
      _synthesizer ??= widget.synthesizer ?? ToneSynthesizer();
      _synthesizer!.preWarm();
      _controller = RhythmEditorController(initialScore: score);
      _controller!.addListener(_onControllerChanged);
      _previewPlayer = ScorePreviewPlayer(
        score: score,
        synthesizer: _synthesizer,
      );
      _previewPlayer!.addListener(_onPreviewPlayerChanged);
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      final updatedScore = _controller?.state.score;
      if (updatedScore != null && updatedScore != _activeScore) {
        setState(() {
          _activeScore = updatedScore;
        });
        _previewPlayer?.updateScore(updatedScore);
      } else {
        setState(() {});
      }
    }
  }

  void _onPreviewPlayerChanged() {
    if (mounted) {
      if (_previewPlayer != null && _previewPlayer!.isPlaying) {
        final cur = _previewPlayer!.currentCursor;
        if (cur != null && cur != _controller?.state.cursor) {
          _controller?.setCursor(
            sectionId: cur.sectionId,
            measureNumber: cur.measureNumber,
            eventIndex: cur.eventIndex,
          );
        }
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _previewPlayer?.removeListener(_onPreviewPlayerChanged);
    _previewPlayer?.dispose();
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    if (widget.synthesizer == null) {
      _synthesizer?.dispose();
    }
    super.dispose();
  }

  void _onNoteTapped(RenderedNoteBox note) {
    // Audition sound on note tap
    _synthesizer?.playPitch(note.pitch);

    // Sync editing cursor
    _controller?.setCursor(
      sectionId: note.sectionId,
      measureNumber: note.measureNumber,
      eventIndex: note.eventIndex,
    );
  }

  void _onNotePitchChanged(
    String sectionId,
    int measureNumber,
    int eventIndex,
    Pitch newPitch,
  ) {
    if (_activeScore == null) return;

    // Instant sound audition as note snaps to new pitch
    _synthesizer?.playPitch(newPitch);

    final updatedSections = _activeScore!.sections.map((section) {
      if (section.id != sectionId) return section;

      final updatedMeasures = section.measures.map((measure) {
        if (measure.number != measureNumber) return measure;

        final updatedEvents = List.of(measure.events);
        if (eventIndex >= 0 && eventIndex < updatedEvents.length) {
          final oldEvent = updatedEvents[eventIndex];
          updatedEvents[eventIndex] = oldEvent.copyWith(pitch: newPitch);
        }

        return measure.copyWith(events: updatedEvents);
      }).toList();

      return section.copyWith(measures: updatedMeasures);
    }).toList();

    final newScore = _activeScore!.copyWith(sections: updatedSections);
    setState(() {
      _activeScore = newScore;
      _controller?.setScore(newScore);
      _previewPlayer?.updateScore(newScore);
      _controller?.setCursor(
        sectionId: sectionId,
        measureNumber: measureNumber,
        eventIndex: eventIndex,
      );
    });
  }

  Future<void> _saveNotation() async {
    final l10n = AppLocalizations.of(context);
    final scoreToSave = _controller?.state.score ?? _activeScore;
    if (scoreToSave == null) return;
    setState(() => _isSaving = true);

    try {
      final updatedSong = scoreToSave.toSong();
      await ref.read(repertoireProvider.notifier).updateSong(updatedSong);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.notationSavedSuccess ?? 'Notation changes saved to Song!',
            ),
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.failedToSaveScore(e.toString()) ?? 'Failed to save score: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildHintBanner(ThemeData theme) {
    final activeEvent = _controller?.state.activeEvent;
    final activeMeasure = _controller?.state.activeMeasure;

    final String infoText;
    if (activeEvent != null && activeMeasure != null) {
      final pitchText = activeEvent.pitch != null
          ? 'Pitch: ${activeEvent.pitch!.scientificNotation}'
          : (activeEvent.isRest ? 'Rest' : 'Note');
      final rhythmText = activeEvent.rhythmicValue.isUnassigned
          ? 'Unassigned rhythm'
          : '${activeEvent.rhythmicValue.name} (${activeEvent.rhythmicValue.ticks}t)';
      infoText =
          'Selected: M${activeMeasure.number} • $pitchText • $rhythmText. Drag noteheads vertically to change pitch (C4–B5), or tap toolbar to assign rhythm.';
    } else {
      infoText = 'Tap or drag any notehead to select. Drag noteheads vertically to change pitch (C4–B5). Use the toolbar below to assign rhythmic values.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            activeEvent != null ? Icons.music_note : Icons.touch_app,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(infoText, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final songAsync = ref.watch(songByIdProvider(widget.songId));
    final l10n = AppLocalizations.of(context);

    return songAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n?.scoreEditor ?? 'Score Editor')),
        body: Center(child: Text('Error loading song: $e')),
      ),
      data: (song) {
        if (song == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n?.scoreEditor ?? 'Score Editor')),
            body: Center(child: Text(l10n?.songNotFound ?? 'Song not found')),
          );
        }

        final score = song.toScore();
        _initScore(score);

        return Scaffold(
          appBar: AppBar(
            title: Text('${_activeScore?.title ?? song.title} (Notation)'),
            actions: [
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveNotation,
                icon: const Icon(Icons.check),
                label: Text(l10n?.save ?? 'Save'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Dynamic Selected Note / Instructions Banner
              _buildHintBanner(theme),

              // Audio Playback & Sound Control Bar
              if (_previewPlayer != null)
                ScorePlaybackBar(player: _previewPlayer!),

              // Staff Canvas
              Expanded(
                child: _activeScore != null
                    ? StaffCanvas(
                        score: _controller?.state.score ?? _activeScore!,
                        selectedCursor: _controller?.state.cursor,
                        onNotePitchChanged: _onNotePitchChanged,
                        onNoteTapped: _onNoteTapped,
                      )
                    : const SizedBox.shrink(),
              ),

              // Rhythm Toolbar
              if (_controller != null)
                SafeArea(
                  top: false,
                  child: RhythmToolbar(controller: _controller!),
                ),
            ],
          ),
        );
      },
    );
  }
}
