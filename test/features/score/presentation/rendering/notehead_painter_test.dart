import 'dart:ui';

import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:battuta/features/score/presentation/rendering/notehead_painter.dart';
import 'package:battuta/features/score/presentation/rendering/staff_metrics.dart';
import 'package:battuta/features/score/presentation/rendering/staff_pitch_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StaffPitchMapper (C4 to B5 + Ledger Lines)', () {
    test('stepFromE4 calculates correct diatonic steps relative to bottom line',
        () {
      // Notes below staff
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('A3')), equals(-4));
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('B3')), equals(-3));
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('C4')), equals(-2)); // Middle C
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('D4')), equals(-1)); // Below Line 1

      // 5-line staff lines and spaces
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('E4')), equals(0)); // Line 1
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('F4')), equals(1)); // Space 1
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('G4')), equals(2)); // Line 2
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('A4')), equals(3)); // Space 2
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('B4')), equals(4)); // Line 3 (center)
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('C5')), equals(5)); // Space 3
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('D5')), equals(6)); // Line 4
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('E5')), equals(7)); // Space 4
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('F5')), equals(8)); // Line 5 (top)

      // Notes above staff
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('G5')), equals(9)); // Above Line 5
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('A5')), equals(10)); // First ledger line
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('B5')), equals(11));
      expect(StaffPitchMapper.stepFromE4(Pitch.parse('C6')), equals(12)); // Second ledger line
    });

    test('yCoordinateForPitch calculates exact vertical coordinates', () {
      const staffBottomY = 100.0;
      const lineSpacing = 10.0;

      // E4 is at staffBottomY
      expect(
        StaffPitchMapper.yCoordinateForPitch(
          Pitch.parse('E4'),
          staffBottomY: staffBottomY,
          lineSpacing: lineSpacing,
        ),
        equals(100.0),
      );

      // F5 (top line) is at staffBottomY - (8 * 5) = 60.0
      expect(
        StaffPitchMapper.yCoordinateForPitch(
          Pitch.parse('F5'),
          staffBottomY: staffBottomY,
          lineSpacing: lineSpacing,
        ),
        equals(60.0),
      );

      // C4 (Middle C) is at staffBottomY - (-2 * 5) = 110.0
      expect(
        StaffPitchMapper.yCoordinateForPitch(
          Pitch.parse('C4'),
          staffBottomY: staffBottomY,
          lineSpacing: lineSpacing,
        ),
        equals(110.0),
      );

      // A5 is at staffBottomY - (10 * 5) = 50.0
      expect(
        StaffPitchMapper.yCoordinateForPitch(
          Pitch.parse('A5'),
          staffBottomY: staffBottomY,
          lineSpacing: lineSpacing,
        ),
        equals(50.0),
      );
    });

    test('needsLedgerLines is true for notes <= C4 and >= A5', () {
      expect(StaffPitchMapper.needsLedgerLines(Pitch.parse('C4')), isTrue);
      expect(StaffPitchMapper.needsLedgerLines(Pitch.parse('B3')), isTrue);
      expect(StaffPitchMapper.needsLedgerLines(Pitch.parse('A3')), isTrue);

      expect(StaffPitchMapper.needsLedgerLines(Pitch.parse('D4')), isFalse);
      expect(StaffPitchMapper.needsLedgerLines(Pitch.parse('E4')), isFalse);
      expect(StaffPitchMapper.needsLedgerLines(Pitch.parse('B4')), isFalse);
      expect(StaffPitchMapper.needsLedgerLines(Pitch.parse('F5')), isFalse);
      expect(StaffPitchMapper.needsLedgerLines(Pitch.parse('G5')), isFalse);

      expect(StaffPitchMapper.needsLedgerLines(Pitch.parse('A5')), isTrue);
      expect(StaffPitchMapper.needsLedgerLines(Pitch.parse('B5')), isTrue);
      expect(StaffPitchMapper.needsLedgerLines(Pitch.parse('C6')), isTrue);
    });

    test('calculateLedgerLineYOffsets generates correct ledger line positions',
        () {
      const staffBottomY = 100.0;
      const lineSpacing = 10.0;

      // C4 requires 1 ledger line at step -2 (Y = 110.0)
      final c4Offsets = StaffPitchMapper.calculateLedgerLineYOffsets(
        Pitch.parse('C4'),
        staffBottomY: staffBottomY,
        lineSpacing: lineSpacing,
      );
      expect(c4Offsets, equals([110.0]));

      // A3 requires 2 ledger lines at steps -2 and -4 (Y = 110.0 and 120.0)
      final a3Offsets = StaffPitchMapper.calculateLedgerLineYOffsets(
        Pitch.parse('A3'),
        staffBottomY: staffBottomY,
        lineSpacing: lineSpacing,
      );
      expect(a3Offsets, equals([110.0, 120.0]));

      // A5 requires 1 ledger line at step 10 (Y = 50.0)
      final a5Offsets = StaffPitchMapper.calculateLedgerLineYOffsets(
        Pitch.parse('A5'),
        staffBottomY: staffBottomY,
        lineSpacing: lineSpacing,
      );
      expect(a5Offsets, equals([50.0]));

      // C6 requires 2 ledger lines at steps 10 and 12 (Y = 50.0 and 40.0)
      final c6Offsets = StaffPitchMapper.calculateLedgerLineYOffsets(
        Pitch.parse('C6'),
        staffBottomY: staffBottomY,
        lineSpacing: lineSpacing,
      );
      expect(c6Offsets, equals([50.0, 40.0]));

      // In-staff note returns empty ledger line list
      expect(
        StaffPitchMapper.calculateLedgerLineYOffsets(
          Pitch.parse('G4'),
          staffBottomY: staffBottomY,
          lineSpacing: lineSpacing,
        ),
        isEmpty,
      );
    });

    test('pitchForYCoordinate snaps continuous Y back to closest diatonic pitch',
        () {
      const staffBottomY = 100.0;
      const lineSpacing = 10.0;

      // Snap Y = 100.0 -> E4
      expect(
        StaffPitchMapper.pitchForYCoordinate(
          100.0,
          staffBottomY: staffBottomY,
          lineSpacing: lineSpacing,
        ).scientificNotation,
        equals('E4'),
      );

      // Snap Y = 60.0 -> F5
      expect(
        StaffPitchMapper.pitchForYCoordinate(
          60.0,
          staffBottomY: staffBottomY,
          lineSpacing: lineSpacing,
        ).scientificNotation,
        equals('F5'),
      );

      // Snap Y = 110.0 -> C4
      expect(
        StaffPitchMapper.pitchForYCoordinate(
          110.0,
          staffBottomY: staffBottomY,
          lineSpacing: lineSpacing,
        ).scientificNotation,
        equals('C4'),
      );
    });
  });

  group('NoteheadPainter Rendering (Checklist Requirements)', () {
    test('renders assigned and unassigned notes, ledger lines, and warning badges',
        () {
      final measure = Measure(
        number: 1,
        timeSignature: TimeSignature.fourFour,
        events: [
          // Middle C4 (requires bottom ledger line)
          NoteEvent.note(
            id: 'e1',
            pitch: Pitch.parse('C4'),
            rhythmicValue: RhythmicValue.quarter,
            tickOffset: 0,
          ),
          // High A5# (requires top ledger line + sharp accidental)
          NoteEvent.note(
            id: 'e2',
            pitch: Pitch.parse('A#5'),
            rhythmicValue: RhythmicValue.eighth,
            tickOffset: 480,
          ),
          // Neutral unassigned pitch-only note (checklist visual style)
          NoteEvent.note(
            id: 'e3',
            pitch: Pitch.parse('E4'),
            rhythmicValue: RhythmicValue.unassigned,
            tickOffset: 0,
          ),
          // Rest
          const NoteEvent.rest(
            id: 'e4',
            rhythmicValue: RhythmicValue.quarter,
            tickOffset: 960,
          ),
        ],
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      NoteheadPainter.paintMeasureNotes(
        canvas,
        measure: measure,
        measureLeft: 20.0,
        measureRight: 200.0,
        staffBottomY: 100.0,
        metrics: const StaffMetrics(),
        measureWarning: 'Dense ledger lines detected above staff',
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
    });

    test('paintMeasureNotes renders selected note with halo, border, and pitch badge', () {
      final measure = Measure(
        number: 1,
        timeSignature: TimeSignature.fourFour,
        events: [
          NoteEvent.note(
            id: 'e1',
            pitch: Pitch.parse('C4'),
            rhythmicValue: RhythmicValue.quarter,
            tickOffset: 0,
          ),
          NoteEvent.note(
            id: 'e2',
            pitch: Pitch.parse('F#5'),
            rhythmicValue: RhythmicValue.half,
            tickOffset: 480,
          ),
          const NoteEvent.rest(
            id: 'e3',
            rhythmicValue: RhythmicValue.quarter,
            tickOffset: 1440,
          ),
        ],
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Paint with event 0 selected and dragging
      NoteheadPainter.paintMeasureNotes(
        canvas,
        measure: measure,
        measureLeft: 20.0,
        measureRight: 200.0,
        staffBottomY: 100.0,
        metrics: const StaffMetrics(),
        selectedEventIndex: 0,
        isDragging: true,
      );

      // Paint with event 2 (rest) selected
      NoteheadPainter.paintMeasureNotes(
        canvas,
        measure: measure,
        measureLeft: 20.0,
        measureRight: 200.0,
        staffBottomY: 100.0,
        metrics: const StaffMetrics(),
        selectedEventIndex: 2,
        isDragging: false,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
    });
  });
}
