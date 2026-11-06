import 'dart:ui';

import 'package:battuta/features/score/domain/entities/chord_symbol.dart';
import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:battuta/features/score/presentation/rendering/section_layout_index.dart';
import 'package:battuta/features/score/presentation/rendering/staff_metrics.dart';
import 'package:battuta/features/score/presentation/rendering/staff_painter.dart';
import 'package:battuta/features/score/presentation/widgets/staff_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testScore = Score(
    id: 'score-1',
    title: 'Way Maker',
    artist: 'Sinach',
    sections: [
      Section(
        id: 'sec-intro',
        name: 'Intro',
        externalSyncId: 'propresenter-uuid-intro',
        repeatCount: 1,
        measures: [
          Measure(
            number: 1,
            timeSignature: TimeSignature.fourFour,
            chords: [
              ChordSymbol.parse('F', tickOffset: 0),
              ChordSymbol.parse('C/E', tickOffset: 960),
            ],
            events: [
              NoteEvent.note(
                id: 'm1-e1',
                pitch: Pitch.parse('F4'),
                rhythmicValue: RhythmicValue.half,
                tickOffset: 0,
              ),
              NoteEvent.note(
                id: 'm1-e2',
                pitch: Pitch.parse('G4'),
                rhythmicValue: RhythmicValue.half,
                tickOffset: 960,
              ),
            ],
          ),
          Measure(
            number: 2,
            timeSignature: TimeSignature.fourFour,
            chords: [
              ChordSymbol.parse('G', tickOffset: 0),
            ],
            events: [
              NoteEvent.note(
                id: 'm2-e1',
                pitch: Pitch.parse('A4'),
                rhythmicValue: RhythmicValue.whole,
                tickOffset: 0,
              ),
            ],
          ),
        ],
      ),
      Section(
        id: 'sec-interludio',
        name: 'Interludio',
        repeatCount: 2,
        measures: [
          Measure(
            number: 3,
            timeSignature: TimeSignature.fourFour,
            chords: [
              ChordSymbol.parse('Am7', tickOffset: 0),
            ],
          ),
          Measure(
            number: 4,
            timeSignature: TimeSignature.fourFour,
            chords: [
              ChordSymbol.parse('G', tickOffset: 0),
            ],
          ),
        ],
      ),
    ],
  );

  group('StaffMetrics & Geometry Calculations', () {
    test('StaffMetrics defaults and copyWith', () {
      const metrics = StaffMetrics();
      expect(metrics.lineSpacing, equals(10.0));
      expect(metrics.staffHeight, equals(40.0));
      expect(metrics.measuresPerSystem, equals(4));
      expect(metrics.selectedNoteColor, equals(const Color(0xFFE5A93C)));

      final updated = metrics.copyWith(
        measuresPerSystem: 3,
        lineSpacing: 12.0,
        selectedNoteColor: const Color(0xFFFFB800),
      );
      expect(updated.measuresPerSystem, equals(3));
      expect(updated.lineSpacing, equals(12.0));
      expect(updated.staffHeight, equals(48.0));
      expect(updated.selectedNoteColor, equals(const Color(0xFFFFB800)));

      // Theme-adaptive metrics
      final darkMetrics = StaffMetrics.fromTheme(ThemeData.dark());
      expect(darkMetrics.selectedNoteColor, isNotNull);
      final lightMetrics = StaffMetrics.fromTheme(ThemeData.light());
      expect(lightMetrics.selectedNoteColor, isNotNull);
    });
  });

  group('SectionLayoutIndex (Checklist Requirements)', () {
    test(
        'Registers vertical Y-offsets and retrieves via section ID, sync ID, and name',
        () {
      final index = SectionLayoutIndex();

      index.register(
        sectionId: 'sec-intro',
        yOffset: 24.0,
        externalSyncId: 'propresenter-intro-123',
        name: 'Intro',
      );
      index.register(
        sectionId: 'sec-chorus',
        yOffset: 250.0,
        name: 'Chorus',
      );

      // Lookup by sectionId
      expect(index.getYOffset('sec-intro'), equals(24.0));
      expect(index.getYOffset('sec-chorus'), equals(250.0));

      // Lookup by externalSyncId (v1.1 stage presentation sync)
      expect(index.getYOffset('propresenter-intro-123'), equals(24.0));

      // Lookup by name (case-insensitive)
      expect(index.getYOffset('intro'), equals(24.0));
      expect(index.getYOffset('INTRO'), equals(24.0));
      expect(index.getYOffset('Chorus'), equals(250.0));

      // Non-existent
      expect(index.getYOffset('non-existent'), isNull);

      // Maps
      expect(index.allOffsets.length, equals(2));
      expect(index.length, equals(2));

      index.clear();
      expect(index.length, equals(0));
    });
  });

  group('StaffPainter Rendering', () {
    test('paints staves, barlines, chords, and section headers without error',
        () {
      final layoutIndex = SectionLayoutIndex();
      final painter = StaffPainter(
        score: testScore,
        layoutIndex: layoutIndex,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();

      // Check section headers registered in layoutIndex
      expect(layoutIndex.getYOffset('sec-intro'), isNotNull);
      expect(layoutIndex.getYOffset('sec-interludio'), isNotNull);
      expect(layoutIndex.getYOffset('propresenter-uuid-intro'), isNotNull);
    });

    test('calculateTotalHeight calculates positive non-zero height', () {
      final height = StaffPainter.calculateTotalHeight(testScore, 800);
      expect(height, greaterThan(150.0));
    });

    test('shouldRepaint returns true when score or metrics change', () {
      final painter1 = StaffPainter(score: testScore);
      final painter2 = StaffPainter(score: testScore);
      expect(painter1.shouldRepaint(painter2), isFalse);

      final modifiedScore = testScore.copyWith(title: 'New Title');
      final painter3 = StaffPainter(score: modifiedScore);
      expect(painter1.shouldRepaint(painter3), isTrue);
    });
  });

  group('StaffCanvas Widget', () {
    testWidgets(
        'StaffCanvas renders CustomPaint, registers layout, and supports scrollToSection',
        (tester) async {
      SectionLayoutIndex? capturedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: StaffCanvas(
                score: testScore,
                onLayoutReady: (index) {
                  capturedIndex = index;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(StaffCanvas), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(capturedIndex, isNotNull);
      expect(capturedIndex!.getYOffset('sec-intro'), isNotNull);
      expect(capturedIndex!.getYOffset('sec-interludio'), isNotNull);

      // Verify programmatic scrolling to section
      final canvasState =
          tester.state<StaffCanvasState>(find.byType(StaffCanvas));
      await canvasState.scrollToSection('sec-interludio',
          duration: Duration.zero);
      await tester.pumpAndSettle();
    });

    test('StaffPainter shouldRepaint triggers on selection change', () {
      final painter1 = StaffPainter(
        score: testScore,
        selectedSectionId: 'sec-intro',
        selectedMeasureNumber: 1,
        selectedEventIndex: 0,
      );

      final painter2 = StaffPainter(
        score: testScore,
        selectedSectionId: 'sec-intro',
        selectedMeasureNumber: 1,
        selectedEventIndex: 1, // Different event index
      );

      expect(painter1.shouldRepaint(painter2), isTrue);

      final painter3 = StaffPainter(
        score: testScore,
        selectedSectionId: 'sec-intro',
        selectedMeasureNumber: 1,
        selectedEventIndex: 0,
        isDragging: true, // Different drag state
      );

      expect(painter1.shouldRepaint(painter3), isTrue);
    });
  });
}
