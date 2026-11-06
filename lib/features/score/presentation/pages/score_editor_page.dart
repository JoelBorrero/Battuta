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
import 'package:battuta/features/score/presentation/widgets/rhythm_toolbar.dart';
import 'package:battuta/features/score/presentation/widgets/staff_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen interactive musical score & staff notation editor.
class ScoreEditorPage extends ConsumerStatefulWidget {
  const ScoreEditorPage({
    required this.songId,
    super.key,
  });

  final String songId;

  @override
  ConsumerState<ScoreEditorPage> createState() => _ScoreEditorPageState();
}

class _ScoreEditorPageState extends ConsumerState<ScoreEditorPage> {
  RhythmEditorController? _controller;
  Score? _activeScore;
  bool _isSaving = false;

  void _initScore(Score score) {
    if (_activeScore == null) {
      _activeScore = score;
      _controller = RhythmEditorController(initialScore: score);
    }
  }

  void _onNotePitchChanged(
    String sectionId,
    int measureNumber,
    int eventIndex,
    Pitch newPitch,
  ) {
    if (_activeScore == null) return;

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
    });
  }

  Future<void> _saveNotation() async {
    if (_activeScore == null) return;
    setState(() => _isSaving = true);

    try {
      final updatedSong = _activeScore!.toSong();
      await ref.read(repertoireProvider.notifier).updateSong(updatedSong);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notation changes saved to Song!')),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save score: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final songAsync = ref.watch(songByIdProvider(widget.songId));

    return songAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Score Editor')),
        body: Center(child: Text('Error loading song: $e')),
      ),
      data: (song) {
        if (song == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Score Editor')),
            body: const Center(child: Text('Song not found')),
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
                label: const Text('Save'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Hint Banner
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: theme.colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Drag noteheads vertically to change pitch (C4–B5). '
                        'Use the toolbar below to assign rhythmic values.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),

              // Staff Canvas
              Expanded(
                child: _activeScore != null
                    ? StaffCanvas(
                        score: _activeScore!,
                        onNotePitchChanged: _onNotePitchChanged,
                        onNoteTapped: (note) {
                          _controller?.setCursor(
                            sectionId: note.sectionId,
                            measureNumber: note.measureNumber,
                            eventIndex: note.eventIndex,
                          );
                        },
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
