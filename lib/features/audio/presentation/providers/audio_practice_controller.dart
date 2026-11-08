/// Battuta — Key-Aware Audio Practice Controller & State.
///
/// Drives the interactive rehearsal player bar with:
/// - Real-time playback scrubbing
/// - Pitch-shifting in semitones (-6 to +6)
/// - Variable speed control (0.5x to 1.5x)
/// - Metronome pulse synchronization with song tempo
/// - Section practice looping (Intro, Verse, Chorus, etc.)
/// - Song-specific audio attachment management (real vs demo)
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
    this.loopPointA,
    this.loopPointB,
  });

  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double speed;
  final int pitchSemitones;
  final bool metronomeEnabled;
  final String? activeLoopSection;
  final String? audioSourceTitle;
  final Duration? loopPointA;
  final Duration? loopPointB;

  bool get isAbLoopActive => loopPointA != null && loopPointB != null;

  AudioPracticeState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? speed,
    int? pitchSemitones,
    bool? metronomeEnabled,
    String? activeLoopSection,
    String? audioSourceTitle,
    Duration? loopPointA,
    Duration? loopPointB,
    bool clearLoop = false,
    bool clearAbLoop = false,
    bool clearAudioSource = false,
  }) {
    return AudioPracticeState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      pitchSemitones: pitchSemitones ?? this.pitchSemitones,
      metronomeEnabled: metronomeEnabled ?? this.metronomeEnabled,
      activeLoopSection: clearLoop
          ? null
          : (activeLoopSection ?? this.activeLoopSection),
      audioSourceTitle: clearAudioSource
          ? null
          : (audioSourceTitle ?? this.audioSourceTitle),
      loopPointA: clearAbLoop ? null : (loopPointA ?? this.loopPointA),
      loopPointB: clearAbLoop ? null : (loopPointB ?? this.loopPointB),
    );
  }
}

final audioPracticeControllerProvider =
    NotifierProvider<AudioPracticeNotifier, AudioPracticeState>(
      AudioPracticeNotifier.new,
    );

class AudioPracticeNotifier extends Notifier<AudioPracticeState> {
  Timer? _playbackTimer;
  final Map<String, String> _attachedAudioBySong = {};

  @override
  AudioPracticeState build() {
    ref.onDispose(() {
      _playbackTimer?.cancel();
    });
    return const AudioPracticeState();
  }

  /// Whether the specified song has an attached audio track (or is populated via demo mode).
  bool hasAudioForSong(String songId, {required bool isDemo}) {
    if (isDemo) return true;
    return _attachedAudioBySong.containsKey(songId);
  }

  /// Resolves the audio source title for a song.
  String? getAudioSourceTitle(
    String songId, {
    required bool isDemo,
    String? defaultDemoTitle,
  }) {
    if (_attachedAudioBySong.containsKey(songId)) {
      return _attachedAudioBySong[songId];
    }
    if (isDemo) {
      return defaultDemoTitle ?? 'Acoustic_Guide_Track.mp3';
    }
    return null;
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
      final newPosMs = state.position.inMilliseconds + deltaMs;

      // Check A-B loop boundary
      if (state.isAbLoopActive &&
          state.loopPointB != null &&
          newPosMs >= state.loopPointB!.inMilliseconds) {
        seek(state.loopPointA ?? Duration.zero);
        return;
      }

      // Check track duration end
      if (newPosMs >= state.duration.inMilliseconds) {
        state = state.copyWith(
          isPlaying: false,
          position: state.duration,
        );
        timer.cancel();
        return;
      }

      state = state.copyWith(position: Duration(milliseconds: newPosMs));
    });
  }

  void pause() {
    state = state.copyWith(isPlaying: false);
    _playbackTimer?.cancel();
  }

  void togglePlay() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void seek(Duration newPosition) {
    final clampedMs = newPosition.inMilliseconds.clamp(
      0,
      state.duration.inMilliseconds,
    );
    state = state.copyWith(position: Duration(milliseconds: clampedMs));
  }

  void setSpeed(double newSpeed) {
    state = state.copyWith(speed: newSpeed.clamp(0.5, 1.5));
  }

  void setPitchSemitones(int semitones) {
    state = state.copyWith(pitchSemitones: semitones.clamp(-6, 6));
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

  void attachAudioSource(String sourceName, {String? songId}) {
    if (songId != null) {
      _attachedAudioBySong[songId] = sourceName;
    }
    state = state.copyWith(audioSourceTitle: sourceName);
  }

  void detachAudioSource(String songId) {
    _attachedAudioBySong.remove(songId);
    _playbackTimer?.cancel();
    state = state.copyWith(
      isPlaying: false,
      clearAudioSource: true,
      position: Duration.zero,
      clearLoop: true,
      clearAbLoop: true,
    );
  }

  void setLoopPointA([Duration? position]) {
    final pos = position ?? state.position;
    if (state.loopPointB != null && pos >= state.loopPointB!) {
      state = state.copyWith(loopPointA: pos, clearAbLoop: true);
      state = state.copyWith(loopPointA: pos);
    } else {
      state = state.copyWith(loopPointA: pos);
    }
  }

  void setLoopPointB([Duration? position]) {
    final pos = position ?? state.position;
    final pointA = state.loopPointA ?? Duration.zero;
    if (pos > pointA) {
      state = state.copyWith(loopPointA: pointA, loopPointB: pos);
    } else {
      // If position is before A, set B as A + 1 sec
      state = state.copyWith(
        loopPointA: pointA,
        loopPointB: pointA + const Duration(seconds: 1),
      );
    }
  }

  void clearAbLoop() {
    state = state.copyWith(clearAbLoop: true);
  }
}
