import 'package:battuta/features/score/domain/entities/chord_symbol.dart';
import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:battuta/features/score/presentation/rendering/rendered_note_box.dart';
import 'package:battuta/features/score/presentation/widgets/staff_canvas.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testMeasure = Measure(
    number: 1,
    timeSignature: TimeSignature.fourFour,
    events: [
      NoteEvent.note(
        id: 'e1',
        pitch: Pitch.parse('E4'), // Bottom line of Treble Clef
        rhythmicValue: RhythmicValue.quarter,
        tickOffset: 0,
      ),
      NoteEvent.note(
        id: 'e2',
        pitch: Pitch.parse('G4'), // Line 2 of Treble Clef
        rhythmicValue: RhythmicValue.quarter,
        tickOffset: 480,
      ),
    ],
    chords: [ChordSymbol.parse('C')],
  );

  final testScore = Score(
    id: 'score-1',
    title: 'Drag Test Score',
    sections: [
      Section(id: 'sec-1', name: 'Verse', measures: [testMeasure]),
    ],
  );

  group('Measure.dragPitchAt & Score.updateNotePitch', () {
    test('Measure.dragPitchAt updates pitch and preserves rhythm', () {
      final updated = testMeasure.dragPitchAt(0, Pitch.parse('F#4'));

      expect(updated.events[0].pitch?.scientificNotation, equals('F#4'));
      expect(updated.events[0].rhythmicValue, equals(RhythmicValue.quarter));
      expect(updated.events[0].tickOffset, equals(0));
      expect(updated.events[1].pitch?.scientificNotation, equals('G4'));
    });

    test('Measure.dragPitchAt throws RangeError on invalid index', () {
      expect(
        () => testMeasure.dragPitchAt(5, Pitch.parse('C4')),
        throwsRangeError,
      );
    });

    test('Score.updateNotePitch updates pitch immutably', () {
      final updatedScore = testScore.updateNotePitch(
        sectionId: 'sec-1',
        measureNumber: 1,
        eventIndex: 0,
        newPitch: Pitch.parse('A4'),
      );

      final m = updatedScore.sections.first.measures.first;
      expect(m.events[0].pitch?.scientificNotation, equals('A4'));
      expect(m.events[1].pitch?.scientificNotation, equals('G4'));
    });
  });

  group('SpatialNoteIndex (Touch Targets & Hit-Testing)', () {
    test('registers notes and hit-tests within Apple HIG touch target', () {
      final index = SpatialNoteIndex();

      const box = RenderedNoteBox(
        noteId: 'e1',
        sectionId: 'sec-1',
        measureNumber: 1,
        eventIndex: 0,
        bounds: Rect.fromLTWH(100, 100, 16, 12),
        center: Offset(108, 106),
        staffBottomY: 106,
        lineSpacing: 10,
        pitch: Pitch.middleC,
      );

      index.register(box);
      expect(index.count, equals(1));

      // Direct hit on notehead center
      final directHit = index.findNoteAt(const Offset(108, 106));
      expect(directHit?.noteId, equals('e1'));

      // Hit slightly outside visual notehead but within 44x44 touch target
      final touchTargetHit = index.findNoteAt(const Offset(120, 115));
      expect(touchTargetHit?.noteId, equals('e1'));

      // Far outside
      final miss = index.findNoteAt(const Offset(200, 200));
      expect(miss, isNull);

      index.clear();
      expect(index.count, equals(0));
    });
  });

  group('Vertical Drag-and-Snap GestureDetector (Checklist Verification)', () {
    testWidgets(
      'Dragging a notehead vertically snaps mathematically to lines and spaces in real time',
      (tester) async {
        final spatialIndex = SpatialNoteIndex();
        Pitch? lastDraggedPitch;
        var pitchChangeCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: StaffCanvas(
                  score: testScore,
                  spatialIndex: spatialIndex,
                  onNotePitchChanged:
                      (sectionId, measureNumber, eventIndex, newPitch) {
                        lastDraggedPitch = newPitch;
                        pitchChangeCount++;
                      },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(spatialIndex.count, equals(2));
        final firstNoteBox = spatialIndex.allNotes[0];
        expect(firstNoteBox.pitch.scientificNotation, equals('E4'));

        // Start drag on the first notehead center
        final startPoint = firstNoteBox.center;
        final gesture = await tester.startGesture(
          startPoint,
          kind: PointerDeviceKind.touch,
        );
        await tester.pump();

        // Drag up by 10 logical pixels (2 half-staff-spaces: E4 -> F4 -> G4)
        await gesture.moveBy(const Offset(0, -10));
        await tester.pump();

        // Verify mathematical snap
        expect(pitchChangeCount, greaterThan(0));
        expect(lastDraggedPitch, isNotNull);
        // Moving up 10px with lineSpacing 10 (stepHeight 5) moves 2 diatonic steps up from E4 -> G4!
        expect(lastDraggedPitch?.scientificNotation, equals('G4'));

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  });
}
