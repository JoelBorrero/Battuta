/// Battuta — Key-Aware Audio Practice Controller & State.
///
/// Drives the interactive rehearsal player bar with:
/// - Real-time playback scrubbing
/// - Pitch-shifting in semitones (-6 to +6)
/// - Variable speed control (0.5x to 1.5x)
/// - Metronome pulse synchronization with song tempo
/// - Section practice looping (Intro, Verse, Chorus, etc.)
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioPracticeState {
  const AudioPracticeState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = const Duration(minutes: 3, seconds: 30),
    this.speed = 1.0,
    this.pitchSemitones = 0,
    this.metronomeEnabled = false,
    this.activeLoopSection,
    this.audioSourceTitle,
  });

  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double speed;
  final int pitchSemitones;
  final bool metronomeEnabled;
  final String? activeLoopSection;
  final String? audioSourceTitle;

  AudioPracticeState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? speed,
    int? pitchSemitones,
    bool? metronomeEnabled,
    String? activeLoopSection,
    String? audioSourceTitle,
    bool clearLoop = false,
  }) {
    return AudioPracticeState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      pitchSemitones: pitchSemitones ?? this.pitchSemitones,
      metronomeEnabled: metronomeEnabled ?? this.metronomeEnabled,
      activeLoopSection:
          clearLoop ? null : (activeLoopSection ?? this.activeLoopSection),
      audioSourceTitle: audioSourceTitle ?? this.audioSourceTitle,
    );
  }
}

final audioPracticeControllerProvider =
    NotifierProvider<AudioPracticeNotifier, AudioPracticeState>(
  AudioPracticeNotifier.new,
);

class AudioPracticeNotifier extends Notifier<AudioPracticeState> {
  Timer? _playbackTimer;

  @override
  AudioPracticeState build() {
    ref.onDispose(() {
      _playbackTimer?.cancel();
    });
    return const AudioPracticeState();
  }

  void play() {
    if (state.isPlaying) return;
    state = state.copyWith(isPlaying: true);

    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!state.isPlaying) {
        timer.cancel();
        return;
      }

      final deltaMs = (250 * state.speed).round();
      var nextPos = state.position + Duration(milliseconds: deltaMs);

      if (nextPos >= state.duration) {
        nextPos = Duration.zero;
        state = state.copyWith(position: nextPos, isPlaying: false);
        timer.cancel();
      } else {
        state = state.copyWith(position: nextPos);
      }
    });
  }

  void pause() {
    _playbackTimer?.cancel();
    state = state.copyWith(isPlaying: false);
  }

  void togglePlay() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void seek(Duration newPosition) {
    final clamped = newPosition < Duration.zero
        ? Duration.zero
        : (newPosition > state.duration ? state.duration : newPosition);
    state = state.copyWith(position: clamped);
  }

  void setSpeed(double newSpeed) {
    state = state.copyWith(speed: newSpeed);
  }

  void setPitch(int semitones) {
    state = state.copyWith(pitchSemitones: semitones);
  }

  void toggleMetronome() {
    state = state.copyWith(metronomeEnabled: !state.metronomeEnabled);
  }

  void setLoop(String? sectionName) {
    if (sectionName == null) {
      state = state.copyWith(clearLoop: true);
    } else {
      state = state.copyWith(activeLoopSection: sectionName);
    }
  }

  void attachAudioSource(String sourceName) {
    state = state.copyWith(audioSourceTitle: sourceName);
  }
}
