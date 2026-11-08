/// Battuta — Tone Synthesizer & Audio Audition Service.
///
/// Generates 16-bit PCM WAV audio samples in memory with harmonic overtones
/// and an organic ADSR envelope (attack, decay, sustain, release), providing
/// instantaneous low-latency sound feedback when noteheads are tapped, dragged,
/// or sequenced in the score editor.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Contract for underlying audio playback to allow platform-independent unit testing.
abstract class AudioTonePlayer {
  Future<void> playBytes(Uint8List bytes, {String? cacheKey});
  Future<void> stop();
  void dispose();
}

/// Production [AudioTonePlayer] using [AudioPlayer] with a round-robin player pool
/// and disk-backed audio caching for ultra-low latency hardware playback.
class SystemAudioTonePlayer implements AudioTonePlayer {
  SystemAudioTonePlayer({this.customPlayer, this.poolSize = 4});

  final AudioPlayer? customPlayer;
  final int poolSize;
  final List<AudioPlayer> _players = [];
  int _roundRobinIndex = 0;
  Directory? _cacheDir;
  final Map<String, String> _filePathCache = {};
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Resolve local temporary cache directory for synthesized tone WAV files
    if (!kIsWeb) {
      try {
        final baseDir = await getTemporaryDirectory();
        final synthDir = Directory('${baseDir.path}/battuta_synth_tones');
        if (!synthDir.existsSync()) {
          synthDir.createSync(recursive: true);
        }
        _cacheDir = synthDir;
      } catch (_) {
        try {
          _cacheDir = Directory.systemTemp.createTempSync('battuta_synth_');
        } catch (_) {
          _cacheDir = null;
        }
      }
    }

    // 2. Configure audio context to avoid ducking/stealing system audio
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );
    } catch (_) {}

    // 3. Initialize player pool
    if (customPlayer != null) {
      _players.add(customPlayer!);
    } else {
      for (var i = 0; i < poolSize; i++) {
        final p = AudioPlayer();
        try {
          await p.setPlayerMode(PlayerMode.lowLatency);
        } catch (_) {}
        _players.add(p);
      }
    }
  }

  @override
  Future<void> playBytes(Uint8List bytes, {String? cacheKey}) async {
    try {
      await _ensureInitialized();
      if (_players.isEmpty) return;

      final player = _players[_roundRobinIndex % _players.length];
      _roundRobinIndex++;

      // 1. Write tone bytes to disk cache
      String? filePath;
      if (_cacheDir != null && !kIsWeb) {
        final key = cacheKey ?? bytes.length.toString();
        filePath = _filePathCache[key];
        if (filePath == null || !File(filePath).existsSync()) {
          final file = File('${_cacheDir!.path}/tone_$key.wav');
          await file.writeAsBytes(bytes, flush: true);
          filePath = file.path;
          _filePathCache[key] = filePath;
        }
      }

      // 2. Stop player to reset native stream state before triggering new note
      try {
        await player.stop();
      } catch (_) {}

      // 3. Primary: Play via DeviceFileSource (supports low latency SoundPool & MediaPlayer)
      if (filePath != null) {
        try {
          await player.play(DeviceFileSource(filePath));
          return;
        } catch (_) {
          // If low-latency SoundPool playback fails, retry with MediaPlayer mode
          try {
            await player.setPlayerMode(PlayerMode.mediaPlayer);
            await player.play(DeviceFileSource(filePath));
            return;
          } catch (_) {}
        }
      }

      // 4. Secondary fallback: BytesSource with standard MediaPlayer mode
      try {
        await player.setPlayerMode(PlayerMode.mediaPlayer);
        await player.play(BytesSource(bytes, mimeType: 'audio/wav'));
      } catch (_) {}
    } catch (_) {
      // Safe fallback for environments without audio hardware
    }
  }

  @override
  Future<void> stop() async {
    for (final p in _players) {
      try {
        await p.stop();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    for (final p in _players) {
      try {
        p.dispose();
      } catch (_) {}
    }
    _players.clear();
    _filePathCache.clear();
  }
}

/// Synthesizes acoustic musical tones for pitch auditioning and score playback.
class ToneSynthesizer {
  ToneSynthesizer({AudioTonePlayer? player, this.sampleRate = 44100})
    : player = player ?? SystemAudioTonePlayer();

  final AudioTonePlayer player;
  final int sampleRate;

  /// Cache of synthesized WAV bytes keyed by midiNumber and duration in milliseconds.
  final Map<String, Uint8List> _cache = {};

  /// Whether sound feedback is currently muted.
  bool isMuted = false;

  /// Pre-synthesizes and caches common diatonic notes (C4 to B5) for instant response.
  void preWarm() {
    const commonPitches = [
      60, 62, 64, 65, 67, 69, 71, // C4 to B4
      72, 74, 76, 77, 79, 81, 83, // C5 to B5
    ];
    for (final midi in commonPitches) {
      final p = Pitch.fromMidi(midi);
      final key = '${p.midiNumber}_320';
      _cache.putIfAbsent(
        key,
        () => synthesizeWav(
          frequencyHz: p.frequencyHz,
          duration: const Duration(milliseconds: 320),
        ),
      );
    }
  }

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
    final numSamples = (sampleRate * (duration.inMicroseconds / 1000000.0))
        .round();
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
    final sustainTime = math.max(
      0.001,
      totalSeconds - attackTime - releaseTime,
    );

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

    await player.playBytes(wavBytes, cacheKey: key);
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
