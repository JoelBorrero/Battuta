/// Battuta — Post-MVP Abstract Module Interfaces Unit Tests.
///
/// Validates domain layer contracts according to:
/// - ClickUp Task 86e3yy42q Acceptance Criteria
/// - Checklist Item: "Interfaces compile cleanly in domain layer with zero external plugin dependencies."
/// - LiveSyncService (v1.1), PitchShiftedAudioPlayer (v1.2), QuantizationInputEngine (v1.3).
library;

import 'dart:async';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:battuta/features/score/domain/services/post_mvp_interfaces.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test mock implementation of [LiveSyncService] demonstrating v1.1 extensibility.
class MockLiveSyncService implements LiveSyncService {
  LiveSyncStatus _status = LiveSyncStatus.disconnected;
  LiveSyncMode _mode = LiveSyncMode.follower;
  String? _activeSectionId;
  String? _queuedSectionId;

  final _statusController = StreamController<LiveSyncStatus>.broadcast();
  final _activeSectionController = StreamController<String>.broadcast();
  final _queuedSectionController = StreamController<String>.broadcast();

  final List<String> callLog = [];

  @override
  LiveSyncStatus get status => _status;

  @override
  Stream<LiveSyncStatus> get statusStream => _statusController.stream;

  @override
  LiveSyncMode get mode => _mode;

  @override
  String? get activeSectionId => _activeSectionId;

  @override
  Stream<String> get activeSectionStream => _activeSectionController.stream;

  @override
  String? get queuedSectionId => _queuedSectionId;

  @override
  Stream<String> get queuedSectionStream => _queuedSectionController.stream;

  @override
  Future<void> connect(String host, int port, {String? token}) async {
    callLog.add('connect($host, $port)');
    _status = LiveSyncStatus.connected;
    _statusController.add(_status);
  }

  @override
  Future<void> disconnect() async {
    callLog.add('disconnect()');
    _status = LiveSyncStatus.disconnected;
    _statusController.add(_status);
  }

  @override
  void setSyncMode(LiveSyncMode mode) {
    _mode = mode;
  }

  @override
  Future<void> queueNextSection(String sectionId, {String? externalSyncId}) async {
    callLog.add('queueNextSection($sectionId, $externalSyncId)');
    _queuedSectionId = sectionId;
    _queuedSectionController.add(sectionId);
  }

  @override
  Future<void> jumpNowSection(String sectionId, {String? externalSyncId}) async {
    callLog.add('jumpNowSection($sectionId, $externalSyncId)');
    _activeSectionId = sectionId;
    _activeSectionController.add(sectionId);
    _queuedSectionId = null;
  }

  @override
  Future<void> clearQueuedSection() async {
    callLog.add('clearQueuedSection()');
    _queuedSectionId = null;
  }

  void dispose() {
    _statusController.close();
    _activeSectionController.close();
    _queuedSectionController.close();
  }
}

/// Test mock implementation of [PitchShiftedAudioPlayer] demonstrating v1.2 extensibility.
class MockPitchShiftedAudioPlayer implements PitchShiftedAudioPlayer {
  AudioPlayerStatus _status = AudioPlayerStatus.idle;
  Duration _position = Duration.zero;
  final Duration _duration = const Duration(minutes: 4, seconds: 12);
  double _playbackRate = 1.0;
  int _pitchShiftSemitones = 0;
  AudioPracticeLoop? _practiceLoop;

  final _statusController = StreamController<AudioPlayerStatus>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();

  final List<String> callLog = [];

  @override
  AudioPlayerStatus get status => _status;

  @override
  Stream<AudioPlayerStatus> get statusStream => _statusController.stream;

  @override
  Duration get position => _position;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Duration get duration => _duration;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  double get playbackRate => _playbackRate;

  @override
  int get pitchShiftSemitones => _pitchShiftSemitones;

  @override
  AudioPracticeLoop? get practiceLoop => _practiceLoop;

  @override
  bool get isLooping => _practiceLoop != null;

  @override
  Future<void> loadAudio(String uriOrFilePath) async {
    callLog.add('loadAudio($uriOrFilePath)');
    _status = AudioPlayerStatus.paused;
    _statusController.add(_status);
  }

  @override
  Future<void> play() async {
    callLog.add('play()');
    _status = AudioPlayerStatus.playing;
    _statusController.add(_status);
  }

  @override
  Future<void> pause() async {
    callLog.add('pause()');
    _status = AudioPlayerStatus.paused;
    _statusController.add(_status);
  }

  @override
  Future<void> stop() async {
    callLog.add('stop()');
    _status = AudioPlayerStatus.stopped;
    _statusController.add(_status);
  }

  @override
  Future<void> seek(Duration position) async {
    callLog.add('seek($position)');
    _position = position;
    _positionController.add(_position);
  }

  @override
  Future<void> setPlaybackRate(double rate) async {
    callLog.add('setPlaybackRate($rate)');
    _playbackRate = rate;
  }

  @override
  Future<void> setPitchShift(int semitones) async {
    callLog.add('setPitchShift($semitones)');
    _pitchShiftSemitones = semitones;
  }

  @override
  Future<void> setPracticeLoop(AudioPracticeLoop loop) async {
    callLog.add('setPracticeLoop($loop)');
    _practiceLoop = loop;
  }

  @override
  Future<void> clearPracticeLoop() async {
    callLog.add('clearPracticeLoop()');
    _practiceLoop = null;
  }

  @override
  Future<void> dispose() async {
    _statusController.close();
    _positionController.close();
    _durationController.close();
  }
}

/// Reference implementation of [QuantizationInputEngine] demonstrating v1.3 tap snapping.
class ReferenceQuantizationEngine implements QuantizationInputEngine {
  const ReferenceQuantizationEngine();

  @override
  int snapTickToGrid(
    int rawTick,
    QuantizationGrid grid, {
    double strength = 1.0,
  }) {
    final step = grid.ticks;
    final nearest = ((rawTick + (step / 2)) ~/ step) * step;
    if (strength >= 1.0) return nearest;
    if (strength <= 0.0) return rawTick;
    return (rawTick + (nearest - rawTick) * strength).round();
  }

  @override
  NoteEvent quantizeInput(
    RawMusicalInput input, {
    required QuantizationGrid grid,
    required TimeSignature timeSignature,
    double strength = 1.0,
  }) {
    final snappedTick = snapTickToGrid(input.rawTick, grid, strength: strength);
    final clampedTick = snappedTick.clamp(0, timeSignature.maxTicks - grid.ticks);

    return NoteEvent(
      id: 'quantized-${input.timestamp.millisecondsSinceEpoch}',
      pitch: input.pitch,
      rhythmicValue: grid.rhythmicValue,
      tickOffset: clampedTick,
      velocity: input.velocity,
    );
  }

  @override
  List<NoteEvent> quantizeSequence(
    List<RawMusicalInput> inputs, {
    required QuantizationGrid grid,
    required TimeSignature timeSignature,
    double strength = 1.0,
  }) {
    return inputs
        .map((input) => quantizeInput(
              input,
              grid: grid,
              timeSignature: timeSignature,
              strength: strength,
            ))
        .toList();
  }
}

void main() {
  group('Post-MVP Abstract Module Interfaces (ClickUp 86e3yy42q)', () {
    group('LiveSyncService (v1.1 Live Stage Sync)', () {
      late MockLiveSyncService syncService;

      setUp(() {
        syncService = MockLiveSyncService();
      });

      tearDown(() {
        syncService.dispose();
      });

      test('(Checklist Verification) Connects and updates sync status stream',
          () async {
        expect(syncService.status, LiveSyncStatus.disconnected);

        final statusFuture = syncService.statusStream.first;
        await syncService.connect('192.168.1.100', 8080, token: 'pp7-secret');

        final newStatus = await statusFuture;
        expect(newStatus, LiveSyncStatus.connected);
        expect(syncService.callLog, contains('connect(192.168.1.100, 8080)'));
      });

      test(
          'Supports Queue Next (amber) preview and Jump Now with ProPresenter UUIDs',
          () async {
        syncService.setSyncMode(LiveSyncMode.director);
        expect(syncService.mode, LiveSyncMode.director);

        // Queue Next
        final queuedFuture = syncService.queuedSectionStream.first;
        await syncService.queueNextSection(
          'sec-chorus',
          externalSyncId: 'pp7-uuid-chorus-1',
        );
        expect(await queuedFuture, 'sec-chorus');
        expect(syncService.queuedSectionId, 'sec-chorus');

        // Jump Now
        final activeFuture = syncService.activeSectionStream.first;
        await syncService.jumpNowSection(
          'sec-chorus',
          externalSyncId: 'pp7-uuid-chorus-1',
        );
        expect(await activeFuture, 'sec-chorus');
        expect(syncService.activeSectionId, 'sec-chorus');
        expect(syncService.queuedSectionId, isNull);
      });
    });

    group('PitchShiftedAudioPlayer (v1.2 Reference Player & Practice Loops)', () {
      late MockPitchShiftedAudioPlayer audioPlayer;

      setUp(() {
        audioPlayer = MockPitchShiftedAudioPlayer();
      });

      tearDown(() {
        audioPlayer.dispose();
      });

      test('AudioPracticeLoop calculates duration and validates range bounds', () {
        final loop = AudioPracticeLoop(
          start: const Duration(seconds: 30),
          end: const Duration(seconds: 45),
          sectionId: 'sec-bridge',
          name: 'Bridge Solo',
        );

        expect(loop.duration, const Duration(seconds: 15));
        expect(loop.name, 'Bridge Solo');

        expect(
          () => AudioPracticeLoop(
            start: const Duration(seconds: 50),
            end: const Duration(seconds: 20),
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('Controls pitch shifting (semitones) and playback rate without error',
          () async {
        await audioPlayer.loadAudio('https://example.com/backing-track.mp3');
        expect(audioPlayer.status, AudioPlayerStatus.paused);

        await audioPlayer.setPitchShift(3); // Transpose +3 semitones (e.g. C to Eb)
        expect(audioPlayer.pitchShiftSemitones, 3);

        await audioPlayer.setPlaybackRate(0.85); // Slow down for rehearsal
        expect(audioPlayer.playbackRate, 0.85);

        final loop = AudioPracticeLoop(
          start: const Duration(seconds: 60),
          end: const Duration(seconds: 90),
        );
        await audioPlayer.setPracticeLoop(loop);
        expect(audioPlayer.isLooping, isTrue);
        expect(audioPlayer.practiceLoop, loop);

        await audioPlayer.clearPracticeLoop();
        expect(audioPlayer.isLooping, isFalse);
      });
    });

    group('QuantizationInputEngine (v1.3 Virtual Piano & Tap Quantization)', () {
      const engine = ReferenceQuantizationEngine();

      test('QuantizationGrid exposes standard 480 PPQ intervals', () {
        expect(QuantizationGrid.quarter.ticks, 480);
        expect(QuantizationGrid.eighth.ticks, 240);
        expect(QuantizationGrid.sixteenth.ticks, 120);
        expect(QuantizationGrid.eighthTriplet.ticks, 160);
        expect(QuantizationGrid.thirtySecond.ticks, 60);
      });

      test('snapTickToGrid correctly snaps continuous ticks to nearest subdivision',
          () {
        // Quarter note grid (480 ticks)
        expect(engine.snapTickToGrid(470, QuantizationGrid.quarter), 480);
        expect(engine.snapTickToGrid(15, QuantizationGrid.quarter), 0);
        expect(engine.snapTickToGrid(250, QuantizationGrid.quarter), 480);

        // Sixteenth note grid (120 ticks)
        expect(engine.snapTickToGrid(115, QuantizationGrid.sixteenth), 120);
        expect(engine.snapTickToGrid(185, QuantizationGrid.sixteenth), 240);
      });

      test('quantizeInput creates valid NoteEvent with snapped tick offset', () {
        final input = RawMusicalInput(
          timestamp: DateTime.now(),
          rawTick: 472, // Slight anticipation of Beat 2 (480)
          pitch: const Pitch(step: PitchStep.e, octave: 4),
          velocity: 95,
        );

        final note = engine.quantizeInput(
          input,
          grid: QuantizationGrid.quarter,
          timeSignature: TimeSignature.fourFour,
        );

        expect(note.tickOffset, 480); // Snapped to beat 2
        expect(note.pitch?.step, PitchStep.e);
        expect(note.rhythmicValue, RhythmicValue.quarter);
        expect(note.velocity, 95);
      });
    });
  });
}
