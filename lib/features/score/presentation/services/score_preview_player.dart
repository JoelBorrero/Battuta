/// Battuta — Score Melody & Tempo Preview Player.
///
/// Sequences musical score events in real time based on tempo (BPM),
/// rhythmic values (ticks), and pitch frequencies, driving live cursor tracking
/// and audio playback across measures and sections.
library;

import 'dart:async';

import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/presentation/providers/rhythm_editor_controller.dart';
import 'package:battuta/features/score/presentation/services/tone_synthesizer.dart';
import 'package:flutter/foundation.dart';

/// Single sequenced note or rest in the score playback timeline.
class PlayableScoreEvent {
  const PlayableScoreEvent({
    required this.cursor,
    required this.pitch,
    required this.isRest,
    required this.duration,
    required this.measureNumber,
    required this.label,
  });

  final RhythmCursor cursor;
  final Pitch? pitch;
  final bool isRest;
  final Duration duration;
  final int measureNumber;
  final String label;
}

/// Controller managing real-time playback of a [Score] with tempo synchronization.
class ScorePreviewPlayer extends ChangeNotifier {
  ScorePreviewPlayer({required this.score, ToneSynthesizer? synthesizer})
    : _synthesizer = synthesizer ?? ToneSynthesizer() {
    _buildPlaylist();
  }

  Score score;

  final ToneSynthesizer _synthesizer;
  ToneSynthesizer get synthesizer => _synthesizer;

  int? _tempoOverride;
  int get tempo => _tempoOverride ?? score.tempo;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  int _currentIndex = 0;
  Timer? _playbackTimer;

  List<PlayableScoreEvent> _events = [];
  List<PlayableScoreEvent> get events => List.unmodifiable(_events);

  /// Toggles mute state on the synthesizer and notifies listeners.
  bool toggleMute() {
    final result = _synthesizer.toggleMute();
    notifyListeners();
    return result;
  }

  /// The active [RhythmCursor] corresponding to the currently playing note.
  RhythmCursor? get currentCursor =>
      (_currentIndex >= 0 && _currentIndex < _events.length)
      ? _events[_currentIndex].cursor
      : null;

  /// Display string for the currently playing note (e.g. `"C4"`, `"Rest"`).
  String? get currentPlayingLabel =>
      (_currentIndex >= 0 && _currentIndex < _events.length)
      ? _events[_currentIndex].label
      : null;

  /// Current measure number being auditioned.
  int? get currentMeasureNumber =>
      (_currentIndex >= 0 && _currentIndex < _events.length)
      ? _events[_currentIndex].measureNumber
      : null;

  /// Playback progress ratio from 0.0 to 1.0.
  double get progress =>
      _events.isEmpty ? 0.0 : (_currentIndex / _events.length).clamp(0.0, 1.0);

  /// Updates the score and refreshes the playback playlist.
  void updateScore(Score newScore) {
    if (newScore == score) return;
    final wasPlaying = _isPlaying;
    if (wasPlaying) {
      pause();
    }
    score = newScore;
    _buildPlaylist();
    if (wasPlaying) {
      play();
    } else {
      notifyListeners();
    }
  }

  /// Sets a temporary tempo override in BPM.
  void setTempo(int bpm) {
    if (bpm > 0 && bpm <= 400) {
      _tempoOverride = bpm;
      _buildPlaylist();
      notifyListeners();
    }
  }

  void _buildPlaylist() {
    final list = <PlayableScoreEvent>[];
    final bpm = tempo > 0 ? tempo : 120;
    final msPerQuarter = 60000.0 / bpm;

    for (final section in score.sections) {
      for (final measure in section.measures) {
        for (var i = 0; i < measure.events.length; i++) {
          final event = measure.events[i];
          final ticks = event.rhythmicValue.ticks;

          // If ticks is 0 (unassigned note), default to 1 beat (quarter note duration)
          final durationMs = ticks > 0
              ? (ticks / 480.0) * msPerQuarter
              : msPerQuarter;

          final label = event.isRest
              ? 'Rest'
              : (event.pitch?.scientificNotation ?? 'Note');

          list.add(
            PlayableScoreEvent(
              cursor: RhythmCursor(
                sectionId: section.id,
                measureNumber: measure.number,
                eventIndex: i,
              ),
              pitch: event.pitch,
              isRest: event.isRest,
              duration: Duration(milliseconds: durationMs.round()),
              measureNumber: measure.number,
              label: label,
            ),
          );
        }
      }
    }

    _events = list;
    if (_currentIndex >= _events.length) {
      _currentIndex = 0;
    }
  }

  /// Toggles playback between play and pause.
  void togglePlay() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  /// Starts or resumes score playback from the current position.
  void play() {
    if (_events.isEmpty) return;
    if (_currentIndex >= _events.length) {
      _currentIndex = 0;
    }

    _isPlaying = true;
    notifyListeners();
    _playNext();
  }

  void _playNext() {
    if (!_isPlaying) return;

    if (_currentIndex >= _events.length) {
      // Reached the end of the score
      stop();
      return;
    }

    final currentEvent = _events[_currentIndex];
    notifyListeners();

    // Sound generation: audition note if not a rest
    if (!currentEvent.isRest && currentEvent.pitch != null) {
      // 90% duration articulation to ensure distinct note separation
      final soundDuration = Duration(
        milliseconds: (currentEvent.duration.inMilliseconds * 0.88).round(),
      );
      _synthesizer.playPitch(currentEvent.pitch!, duration: soundDuration);
    }

    // Schedule next note advancement
    _playbackTimer?.cancel();
    _playbackTimer = Timer(currentEvent.duration, () {
      if (_isPlaying) {
        _currentIndex++;
        _playNext();
      }
    });
  }

  /// Pauses playback without resetting position.
  void pause() {
    _playbackTimer?.cancel();
    _isPlaying = false;
    _synthesizer.stop();
    notifyListeners();
  }

  /// Stops playback and rewinds to the beginning of the score.
  void stop() {
    _playbackTimer?.cancel();
    _isPlaying = false;
    _currentIndex = 0;
    _synthesizer.stop();
    notifyListeners();
  }

  /// Seeks playback position to the event matching [cursor].
  void seekToCursor(RhythmCursor cursor) {
    final idx = _events.indexWhere(
      (e) =>
          e.cursor.sectionId == cursor.sectionId &&
          e.cursor.measureNumber == cursor.measureNumber &&
          e.cursor.eventIndex == cursor.eventIndex,
    );

    if (idx != -1) {
      _currentIndex = idx;
      if (!_isPlaying) {
        // Audition the selected note once
        final ev = _events[idx];
        if (!ev.isRest && ev.pitch != null) {
          _synthesizer.playPitch(ev.pitch!);
        }
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _synthesizer.dispose();
    super.dispose();
  }
}
