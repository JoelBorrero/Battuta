import 'dart:typed_data';

import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/presentation/services/tone_synthesizer.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAudioTonePlayer implements AudioTonePlayer {
  final List<Uint8List> played = [];
  bool stopped = false;
  bool disposed = false;

  @override
  Future<void> playBytes(Uint8List bytes) async {
    played.add(bytes);
    stopped = false;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  void dispose() {
    disposed = true;
  }
}

void main() {
  late FakeAudioTonePlayer fakePlayer;
  late ToneSynthesizer synthesizer;

  setUp(() {
    fakePlayer = FakeAudioTonePlayer();
    synthesizer = ToneSynthesizer(player: fakePlayer);
  });

  group('ToneSynthesizer', () {
    test(
      'synthesizeWav generates valid 16-bit PCM RIFF/WAVE header and samples',
      () {
        final wav = synthesizer.synthesizeWav(
          frequencyHz: 440.0, // A4
          duration: const Duration(milliseconds: 100),
        );

        expect(wav.length, greaterThan(44));

        // RIFF chunk descriptor
        final riff = String.fromCharCodes(wav.sublist(0, 4));
        expect(riff, equals('RIFF'));

        final wave = String.fromCharCodes(wav.sublist(8, 12));
        expect(wave, equals('WAVE'));

        // fmt subchunk
        final fmt = String.fromCharCodes(wav.sublist(12, 16));
        expect(fmt, equals('fmt '));

        final byteData = ByteData.sublistView(wav);
        final subchunk1Size = byteData.getUint32(16, Endian.little);
        expect(subchunk1Size, equals(16)); // 16 for PCM

        final audioFormat = byteData.getUint16(20, Endian.little);
        expect(audioFormat, equals(1)); // 1 = PCM

        final numChannels = byteData.getUint16(22, Endian.little);
        expect(numChannels, equals(1)); // Mono

        final sampleRate = byteData.getUint32(24, Endian.little);
        expect(sampleRate, equals(44100));

        final bitsPerSample = byteData.getUint16(34, Endian.little);
        expect(bitsPerSample, equals(16));

        // data subchunk
        final dataHeader = String.fromCharCodes(wav.sublist(36, 40));
        expect(dataHeader, equals('data'));

        final dataSize = byteData.getUint32(40, Endian.little);
        expect(dataSize, equals(wav.length - 44));
      },
    );

    test(
      'playPitch sends synthesized audio to player and caches result',
      () async {
        final a4 = Pitch.parse('A4');
        await synthesizer.playPitch(a4);

        expect(fakePlayer.played.length, equals(1));
        final firstBytes = fakePlayer.played.first;

        // Second play with same pitch uses cache
        await synthesizer.playPitch(a4);
        expect(fakePlayer.played.length, equals(2));
        expect(fakePlayer.played[1], same(firstBytes));
      },
    );

    test('toggleMute prevents audio playback when muted', () async {
      expect(synthesizer.isMuted, isFalse);

      synthesizer.toggleMute();
      expect(synthesizer.isMuted, isTrue);

      final c4 = Pitch.parse('C4');
      await synthesizer.playPitch(c4);
      expect(fakePlayer.played, isEmpty);

      synthesizer.toggleMute();
      expect(synthesizer.isMuted, isFalse);

      await synthesizer.playPitch(c4);
      expect(fakePlayer.played.length, equals(1));
    });

    test('stop delegates to player', () async {
      await synthesizer.stop();
      expect(fakePlayer.stopped, isTrue);
    });

    test('dispose cleans up resources', () {
      synthesizer.dispose();
      expect(fakePlayer.disposed, isTrue);
    });
  });
}
