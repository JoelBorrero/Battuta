import 'dart:typed_data';

import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:battuta/features/score/presentation/providers/rhythm_editor_controller.dart';
import 'package:battuta/features/score/presentation/services/score_preview_player.dart';
import 'package:battuta/features/score/presentation/services/tone_synthesizer.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAudioTonePlayer implements AudioTonePlayer {
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
  late MockAudioTonePlayer mockAudio;
  late ToneSynthesizer synthesizer;
  late Score testScore;
  late ScorePreviewPlayer previewPlayer;

  setUp(() {
    mockAudio = MockAudioTonePlayer();
    synthesizer = ToneSynthesizer(player: mockAudio);

    testScore = Score(
      id: 'score-preview-1',
      title: 'Amazing Grace',
      tempo: 120, // 120 BPM: 1 quarter = 500ms
      timeSignature: TimeSignature.fourFour,
      sections: [
        Section(
          id: 'sec-1',
          name: 'Verse',
          measures: [
            Measure(
              number: 1,
              timeSignature: TimeSignature.fourFour,
              events: [
                NoteEvent.note(
                  id: 'n1',
                  pitch: Pitch.parse('C4'),
                  rhythmicValue: RhythmicValue.quarter, // 480t -> 500ms
                  tickOffset: 0,
                ),
                NoteEvent.note(
                  id: 'n2',
                  pitch: Pitch.parse('E4'),
                  rhythmicValue: RhythmicValue.half, // 960t -> 1000ms
                  tickOffset: 480,
                ),
                const NoteEvent.rest(
                  id: 'r1',
                  rhythmicValue: RhythmicValue.quarter, // 480t -> 500ms
                  tickOffset: 1440,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    previewPlayer = ScorePreviewPlayer(
      score: testScore,
      synthesizer: synthesizer,
    );
  });

  tearDown(() {
    previewPlayer.dispose();
  });

  group('ScorePreviewPlayer', () {
    test('builds playlist with correct duration calculations from tempo', () {
      expect(previewPlayer.events.length, equals(3));

      // Note 1: C4 Quarter (500ms at 120 BPM)
      final n1 = previewPlayer.events[0];
      expect(n1.pitch?.scientificNotation, equals('C4'));
      expect(n1.duration.inMilliseconds, equals(500));
      expect(n1.isRest, isFalse);

      // Note 2: E4 Half (1000ms at 120 BPM)
      final n2 = previewPlayer.events[1];
      expect(n2.pitch?.scientificNotation, equals('E4'));
      expect(n2.duration.inMilliseconds, equals(1000));

      // Rest: 500ms
      final r1 = previewPlayer.events[2];
      expect(r1.isRest, isTrue);
      expect(r1.duration.inMilliseconds, equals(500));
    });

    test('play, pause, and stop state transitions and audio triggering', () {
      expect(previewPlayer.isPlaying, isFalse);
      expect(previewPlayer.currentCursor?.eventIndex, equals(0));

      // Start playback
      previewPlayer.play();
      expect(previewPlayer.isPlaying, isTrue);
      expect(mockAudio.played.length, equals(1)); // C4 played

      // Pause playback
      previewPlayer.pause();
      expect(previewPlayer.isPlaying, isFalse);
      expect(mockAudio.stopped, isTrue);

      // Resume
      previewPlayer.play();
      expect(previewPlayer.isPlaying, isTrue);

      // Stop resets to start
      previewPlayer.stop();
      expect(previewPlayer.isPlaying, isFalse);
      expect(previewPlayer.currentCursor?.eventIndex, equals(0));
      expect(previewPlayer.progress, equals(0.0));
    });

    test('seekToCursor updates active note and auditions tone', () {
      const targetCursor = RhythmCursor(
        sectionId: 'sec-1',
        measureNumber: 1,
        eventIndex: 1,
      );

      previewPlayer.seekToCursor(targetCursor);
      expect(previewPlayer.currentCursor?.eventIndex, equals(1));
      expect(previewPlayer.currentPlayingLabel, equals('E4'));
      expect(mockAudio.played.length, equals(1));
    });

    test('setTempo recalculates note durations in real time', () {
      previewPlayer.setTempo(60); // 60 BPM -> 1 quarter note = 1000ms
      expect(previewPlayer.tempo, equals(60));
      expect(previewPlayer.events[0].duration.inMilliseconds, equals(1000));
      expect(previewPlayer.events[1].duration.inMilliseconds, equals(2000));
    });

    test('toggleMute toggles mute and notifies listeners', () {
      var notified = false;
      previewPlayer.addListener(() => notified = true);

      final isMuted = previewPlayer.toggleMute();
      expect(isMuted, isTrue);
      expect(notified, isTrue);
      expect(previewPlayer.synthesizer.isMuted, isTrue);
    });
  });
}
