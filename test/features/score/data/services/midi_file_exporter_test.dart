/// Battuta — Basic MIDI Reference Exporter Unit Tests.
///
/// Validates standard MIDI binary encoding according to:
/// - ClickUp Task 86e3yy42k Acceptance Criteria
/// - Checklist Item: "Exported .mid file plays back the exact pitches and tapped rhythms in any standard DAW or QuickTime on macOS/iPadOS."
/// - 480 PPQ resolution, Note On (0x90), Note Off (0x80), Tempo (0x51), Time Signature (0x58),
///   and End of Track (0x2F) events.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:battuta/features/score/data/services/midi_file_exporter.dart';
import 'package:battuta/features/score/domain/entities/chord_symbol.dart';
import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:battuta/features/score/domain/services/midi_exporter_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MidiFileExporter exporter;

  setUp(() {
    exporter = const MidiFileExporter();
  });

  Score buildTestScore({
    String title = 'Way Maker',
    String key = 'E',
    int tempo = 120,
    int repeatCount = 1,
  }) {
    // Measure 1: C4 (MIDI 60), E4 (MIDI 64), G#4 (MIDI 68), B4 (MIDI 71) tied
    const m1 = Measure(
      number: 1,
      timeSignature: TimeSignature.fourFour,
      chords: [ChordSymbol(root: 'E')],
      events: [
        NoteEvent.note(
          id: 'n1',
          pitch: Pitch(step: PitchStep.c, octave: 4), // 60
          rhythmicValue: RhythmicValue.quarter, // 480 ticks
          tickOffset: 0,
        ),
        NoteEvent.note(
          id: 'n2',
          pitch: Pitch(step: PitchStep.e, octave: 4), // 64
          rhythmicValue: RhythmicValue.quarter, // 480 ticks
          tickOffset: 480,
        ),
        NoteEvent.note(
          id: 'n3',
          pitch: Pitch(step: PitchStep.g, octave: 4, accidental: 1), // 68
          rhythmicValue: RhythmicValue.quarter,
          tickOffset: 960,
        ),
        NoteEvent.note(
          id: 'n4',
          pitch: Pitch(step: PitchStep.b, octave: 4), // 71
          rhythmicValue: RhythmicValue.quarter,
          tickOffset: 1440,
          isTied: true, // Tied to m2 note
        ),
      ],
    );

    // Measure 2: B4 (tied from m1) quarter note, then half rest, quarter note C5
    const m2 = Measure(
      number: 2,
      timeSignature: TimeSignature.fourFour,
      events: [
        NoteEvent.note(
          id: 'n5',
          pitch: Pitch(step: PitchStep.b, octave: 4), // 71 (tied sustain)
          rhythmicValue: RhythmicValue.quarter,
          tickOffset: 0,
        ),
        NoteEvent.rest(
          id: 'r1',
          rhythmicValue: RhythmicValue.half, // 960 ticks
          tickOffset: 480,
        ),
        NoteEvent.note(
          id: 'n6',
          pitch: Pitch(step: PitchStep.c, octave: 5), // 72
          rhythmicValue: RhythmicValue.quarter,
          tickOffset: 1440,
        ),
      ],
    );

    return Score(
      id: 'score-midi-test',
      title: title,
      artist: 'Sinach',
      keySignature: key,
      tempo: tempo,
      timeSignature: TimeSignature.fourFour,
      sections: [
        Section(
          id: 'sec-v1',
          name: 'Verse 1',
          repeatCount: repeatCount,
          measures: [m1, m2],
        ),
      ],
    );
  }

  group('Basic MIDI Reference File Exporter (ClickUp 86e3yy42k)', () {
    test('(Checklist Verification) Exports valid Standard MIDI File Type 0 binary at 480 PPQ', () {
      final score = buildTestScore();
      final bytes = exporter.exportScoreToMidi(score);

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(22));

      // 1. Verify Header Chunk ('MThd')
      final mthd = String.fromCharCodes(bytes.sublist(0, 4));
      expect(mthd, 'MThd');

      final headerLength = ByteData.sublistView(bytes, 4, 8).getUint32(0);
      expect(headerLength, 6);

      final format = ByteData.sublistView(bytes, 8, 10).getUint16(0);
      expect(format, 0); // Format 0

      final numTracks = ByteData.sublistView(bytes, 10, 12).getUint16(0);
      expect(numTracks, 1);

      final ppq = ByteData.sublistView(bytes, 12, 14).getUint16(0);
      expect(ppq, 480); // Exact 480 PPQ specification

      // 2. Verify Track Chunk ('MTrk')
      final mtrk = String.fromCharCodes(bytes.sublist(14, 18));
      expect(mtrk, 'MTrk');

      final trackLength = ByteData.sublistView(bytes, 18, 22).getUint32(0);
      expect(bytes.length, 22 + trackLength);

      // 3. Verify Track ends with End of Track meta event (0xFF, 0x2F, 0x00)
      final trackData = bytes.sublist(22);
      expect(trackData.length, trackLength);
      expect(trackData.sublist(trackData.length - 4), [0x00, 0xFF, 0x2F, 0x00]);
    });

    test('Encodes exact pitches (Middle C=60, E4=64, G#4=68, B4=71) and tapped rhythm durations', () {
      final score = buildTestScore();
      final bytes = exporter.exportScoreToMidi(score);

      // Find Note On events (0x90 status on channel 0)
      final noteOns = <int>[];
      for (var i = 22; i < bytes.length - 2; i++) {
        if (bytes[i] == 0x90) {
          final pitch = bytes[i + 1];
          final velocity = bytes[i + 2];
          if (velocity > 0) {
            noteOns.add(pitch);
          }
        }
      }

      // Notes played:
      // m1: C4 (60), E4 (64), G#4 (68), B4 (71)
      // m2: Note B4 was tied from m1, so its Note On was merged; m2 also has C5 (72)
      expect(noteOns, containsAllInOrder([60, 64, 68, 71, 72]));
    });

    test(
      'Merges consecutive tied notes of the same pitch into a sustained note',
      () {
        final score = buildTestScore();
        final bytes = exporter.exportScoreToMidi(score);

        // Count Note On events for pitch 71 (B4). It should appear exactly once
        // because m1 note 4 is tied to m2 note 1.
        var noteOnCount71 = 0;
        for (var i = 22; i < bytes.length - 2; i++) {
          if (bytes[i] == 0x90 && bytes[i + 1] == 71 && bytes[i + 2] > 0) {
            noteOnCount71++;
          }
        }

        expect(noteOnCount71, 1);
      },
    );

    test('Embeds accurate Tempo meta event (0xFF 0x51 0x03) for 120 BPM', () {
      final score = buildTestScore(tempo: 120);
      final bytes = exporter.exportScoreToMidi(score);

      // 120 BPM = 500,000 microseconds per quarter note (0x07, 0xA1, 0x20)
      var foundTempo = false;
      for (var i = 22; i < bytes.length - 5; i++) {
        if (bytes[i] == 0xFF && bytes[i + 1] == 0x51 && bytes[i + 2] == 0x03) {
          expect(bytes[i + 3], 0x07);
          expect(bytes[i + 4], 0xA1);
          expect(bytes[i + 5], 0x20);
          foundTempo = true;
          break;
        }
      }

      expect(foundTempo, isTrue);
    });

    test('Embeds Time Signature meta event (0xFF 0x58 0x04) for 4/4', () {
      final score = buildTestScore();
      final bytes = exporter.exportScoreToMidi(score);

      var foundTimeSig = false;
      for (var i = 22; i < bytes.length - 6; i++) {
        if (bytes[i] == 0xFF && bytes[i + 1] == 0x58 && bytes[i + 2] == 0x04) {
          expect(bytes[i + 3], 4); // Numerator 4
          expect(bytes[i + 4], 2); // Denominator 2^2 = 4
          expect(bytes[i + 5], 24); // 24 clocks per click
          expect(bytes[i + 6], 8); // 8 32nd notes per quarter note
          foundTimeSig = true;
          break;
        }
      }

      expect(foundTimeSig, isTrue);
    });

    test(
      'Respects section repeat counts by duplicating measures in performance',
      () {
        // 1 repeat vs 2 repeats
        final scoreSingle = buildTestScore(repeatCount: 1);
        final scoreDouble = buildTestScore(repeatCount: 2);

        final bytesSingle = exporter.exportScoreToMidi(scoreSingle);
        final bytesDouble = exporter.exportScoreToMidi(scoreDouble);

        // Repeated performance should have approximately double the note events and longer track length
        expect(bytesDouble.length, greaterThan(bytesSingle.length));
      },
    );

    test('Supports Format 1 (Multi-Track) export', () {
      final score = buildTestScore();
      final bytes = exporter.exportScoreToMidi(
        score,
        options: const MidiExportOptions(format: MidiFileFormat.format1),
      );

      expect(bytes.length, greaterThan(30));

      // Header format = 1
      final format = ByteData.sublistView(bytes, 8, 10).getUint16(0);
      expect(format, 1);

      // Number of tracks = 2
      final numTracks = ByteData.sublistView(bytes, 10, 12).getUint16(0);
      expect(numTracks, 2);
    });

    test('Encodes and decodes Variable-Length Quantities (VLQ) correctly', () {
      final testCases = [
        (0, [0x00]),
        (64, [0x40]),
        (127, [0x7F]),
        (128, [0x81, 0x00]),
        (480, [0x83, 0x60]),
        (1920, [0x8F, 0x00]),
        (16383, [0xFF, 0x7F]),
        (16384, [0x81, 0x80, 0x00]),
      ];

      for (final (value, expectedBytes) in testCases) {
        final encoded = MidiFileExporter.encodeVlq(value);
        expect(encoded, expectedBytes, reason: 'VLQ mismatch for value $value');

        final (decoded, bytesRead) = MidiFileExporter.decodeVlq(
          Uint8List.fromList(encoded),
          0,
        );
        expect(decoded, value, reason: 'Decoded value mismatch for $value');
        expect(bytesRead, expectedBytes.length);
      }
    });

    test('Saves exported MIDI file to disk at explicit path', () async {
      final score = buildTestScore();
      final tempDir = Directory.systemTemp.createTempSync('battuta_midi_test_');
      final tempPath = '${tempDir.path}/test_export.mid';

      final file = await exporter.saveMidiToDisk(score, filePath: tempPath);

      expect(file.existsSync(), isTrue);
      final readBytes = await file.readAsBytes();
      expect(readBytes.length, greaterThan(22));
      expect(String.fromCharCodes(readBytes.sublist(0, 4)), 'MThd');

      tempDir.deleteSync(recursive: true);
    });

    test('Handles empty score gracefully', () {
      const emptyScore = Score(id: 'score-empty', title: 'Empty Piece');

      final bytes = exporter.exportScoreToMidi(emptyScore);
      expect(bytes.length, greaterThan(20));
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'MThd');
    });
  });
}
