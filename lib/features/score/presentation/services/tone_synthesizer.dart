/// Battuta — Tone Synthesizer & Audio Audition Service.
///
/// Generates 16-bit PCM WAV audio samples in memory with harmonic overtones
/// and an organic ADSR envelope (attack, decay, sustain, release), providing
/// instantaneous low-latency sound feedback when noteheads are tapped, dragged,
/// or sequenced in the score editor.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';

/// Contract for underlying audio playback to allow platform-independent unit testing.
abstract class AudioTonePlayer {
  Future<void> playBytes(Uint8List bytes);
  Future<void> stop();
  void dispose();
}

/// Production [AudioTonePlayer] using [AudioPlayer] with low-latency mode.
class SystemAudioTonePlayer implements AudioTonePlayer {
  SystemAudioTonePlayer({this.customPlayer});

  final AudioPlayer? customPlayer;
  AudioPlayer? _player;
  bool _configured = false;

  Future<AudioPlayer> _ensurePlayer() async {
    _player ??= customPlayer ?? AudioPlayer();
    if (!_configured) {
      try {
        await _player!.setPlayerMode(PlayerMode.lowLatency);
        _configured = true;
      } catch (_) {
        // Platform or testing environment fallback
      }
    }
    return _player!;
  }

  @override
  Future<void> playBytes(Uint8List bytes) async {
    try {
      final player = await _ensurePlayer();
      await player.play(BytesSource(bytes, mimeType: 'audio/wav'));
    } catch (_) {
      // Safe fallback for environments without audio hardware
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      _player?.dispose();
    } catch (_) {}
  }
}

/// Synthesizes acoustic musical tones for pitch auditioning and score playback.
class ToneSynthesizer {
  ToneSynthesizer({
    AudioTonePlayer? player,
    this.sampleRate = 44100,
  }) : player = player ?? SystemAudioTonePlayer();

  final AudioTonePlayer player;
  final int sampleRate;

  /// Cache of synthesized WAV bytes keyed by midiNumber and duration in milliseconds.
  final Map<String, Uint8List> _cache = {};

  /// Whether sound feedback is currently muted.
  bool isMuted = false;

  /// Toggles mute state and returns the new state.
  bool toggleMute() {
    isMuted = !isMuted;
    if (isMuted) {
      stop();
    }
    return isMuted;
  }

  /// Synthesizes a valid 16-bit Mono PCM WAV file for [frequencyHz].
  Uint8List synthesizeWav({
    required double frequencyHz,
    required Duration duration,
    double volume = 0.85,
  }) {
    final numSamples =
        (sampleRate * (duration.inMicroseconds / 1000000.0)).round();
    final dataSize = numSamples * 2; // 16-bit mono = 2 bytes per sample
    final totalFileSize = 36 + dataSize;

    final byteData = ByteData(44 + dataSize);

    // ── 1. RIFF Header ──
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, totalFileSize, Endian.little);
    byteData.setUint8(8, 0x57); // 'W'
    byteData.setUint8(9, 0x41); // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'

    // ── 2. fmt Subchunk ──
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6D); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    byteData.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    byteData.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
    byteData.setUint32(24, sampleRate, Endian.little); // SampleRate
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    byteData.setUint16(32, 2, Endian.little); // BlockAlign
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample

    // ── 3. data Subchunk ──
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, dataSize, Endian.little);

    // ── 4. Waveform Synthesis with Harmonics and ADSR ──
    final totalSeconds = duration.inMicroseconds / 1000000.0;
    const attackTime = 0.008; // 8ms linear attack to eliminate clicks
    const releaseTime = 0.015; // 15ms linear release
    final sustainTime =
        math.max(0.001, totalSeconds - attackTime - releaseTime);

    final omega = 2.0 * math.pi * frequencyHz;

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;

      // Amplitude Envelope (ADSR)
      double envelope;
      if (t < attackTime) {
        envelope = t / attackTime;
      } else if (t < totalSeconds - releaseTime) {
        final relT = (t - attackTime) / sustainTime;
        envelope = math.exp(-2.5 * relT);
      } else {
        final relT = (totalSeconds - t) / releaseTime;
        envelope = math.max(0.0, relT * math.exp(-2.5));
      }

      // Harmonic synthesis (Warm Electric Piano / Rhodes tone)
      final fundamental = math.sin(omega * t);
      final harmonic2 = 0.35 * math.sin(2.0 * omega * t);
      final harmonic3 = 0.15 * math.sin(3.0 * omega * t);

      final combined = (fundamental + harmonic2 + harmonic3) / 1.5;
      final sample = (combined * envelope * volume * 32760.0)
          .clamp(-32767.0, 32767.0)
          .round();

      byteData.setInt16(44 + (i * 2), sample, Endian.little);
    }

    return byteData.buffer.asUint8List();
  }

  /// Auditions a [pitch] with organic tone harmonics.
  Future<void> playPitch(
    Pitch pitch, {
    Duration duration = const Duration(milliseconds: 320),
    double volume = 0.85,
  }) async {
    if (isMuted) return;

    final key = '${pitch.midiNumber}_${duration.inMilliseconds}';
    final wavBytes = _cache.putIfAbsent(
      key,
      () => synthesizeWav(
        frequencyHz: pitch.frequencyHz,
        duration: duration,
        volume: volume,
      ),
    );

    await player.playBytes(wavBytes);
  }

  /// Stops any currently playing tone.
  Future<void> stop() async {
    await player.stop();
  }

  /// Cleans up resources.
  void dispose() {
    player.dispose();
    _cache.clear();
  }
}
