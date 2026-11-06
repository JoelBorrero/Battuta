/// Battuta — Key-Aware Pitch-Shifted Reference Audio Player Interface.
///
/// Abstract contract for v1.2 reference audio playback with:
/// - Real-time pitch shifting in semitones (-12 to +12)
/// - Variable playback rate / speed control (0.5x to 2.0x) without altering pitch
/// - Section-linked practice loops and boundary seeking.
library;

import 'dart:async';

/// Playback status for reference audio player.
enum AudioPlayerStatus {
  /// No audio loaded.
  idle,

  /// Buffering or decoding audio.
  loading,

  /// Playing audio.
  playing,

  /// Playback paused.
  paused,

  /// Playback stopped and rewound.
  stopped,

  /// Playback reached the end of the track.
  completed,

  /// Audio decoding or stream error.
  error,
}

/// Represents an immutable practice loop range in an audio track.
class AudioPracticeLoop {
  /// Creates an [AudioPracticeLoop].
  AudioPracticeLoop({
    required this.start,
    required this.end,
    this.sectionId,
    this.name,
  }) : assert(end > start, 'Loop end must be greater than start');

  /// Start timestamp of loop range.
  final Duration start;

  /// End timestamp of loop range.
  final Duration end;

  /// Optional section ID linked to this loop.
  final String? sectionId;

  /// Optional display name (e.g. `"Bridge Solo Practice"`).
  final String? name;

  /// Total duration of loop segment.
  Duration get duration => end - start;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioPracticeLoop &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          sectionId == other.sectionId &&
          name == other.name;

  @override
  int get hashCode =>
      start.hashCode ^ end.hashCode ^ sectionId.hashCode ^ name.hashCode;

  @override
  String toString() =>
      'AudioPracticeLoop(start: $start, end: $end, sectionId: $sectionId)';
}

/// Abstract contract for v1.2 key-aware reference audio player with
/// real-time pitch shifting and practice loops.
///
/// Designed to compile in pure Dart with zero external plugin dependencies.
abstract class PitchShiftedAudioPlayer {
  /// Current playback status.
  AudioPlayerStatus get status;

  /// Stream of playback status changes.
  Stream<AudioPlayerStatus> get statusStream;

  /// Current playback position.
  Duration get position;

  /// Stream of continuous playback position updates.
  Stream<Duration> get positionStream;

  /// Total duration of loaded audio file.
  Duration get duration;

  /// Stream of audio duration changes.
  Stream<Duration> get durationStream;

  /// Playback speed multiplier (e.g. 0.5 to 2.0, 1.0 is normal).
  double get playbackRate;

  /// Pitch shift in semitones (-12 to +12, 0 is original key).
  int get pitchShiftSemitones;

  /// Current active practice loop range, or null if looping is disabled.
  AudioPracticeLoop? get practiceLoop;

  /// Whether loop playback is currently active.
  bool get isLooping;

  /// Loads an audio file from [uriOrFilePath].
  Future<void> loadAudio(String uriOrFilePath);

  /// Starts or resumes playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Stops playback and rewinds to loop start or beginning.
  Future<void> stop();

  /// Seeks to [position] in the audio track.
  Future<void> seek(Duration position);

  /// Sets the playback speed without changing pitch (time-stretching).
  Future<void> setPlaybackRate(double rate);

  /// Sets pitch transposition in semitones without changing tempo.
  Future<void> setPitchShift(int semitones);

  /// Configures an active practice loop range between [start] and [end].
  Future<void> setPracticeLoop(AudioPracticeLoop loop);

  /// Clears the active practice loop and resumes normal playback.
  Future<void> clearPracticeLoop();

  /// Releases audio decoders and system hardware resources.
  Future<void> dispose();
}
