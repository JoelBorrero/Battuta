import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/polyphonic_voice_cluster.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/services/chord_stem_layout_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PolyphonicVoiceCluster Domain Tests', () {
    test('sorts pitches ascending and exposes chord properties', () {
      final cluster = PolyphonicVoiceCluster(
        id: 'cluster-1',
        pitches: [Pitch.parse('G4'), Pitch.parse('C4'), Pitch.parse('E4')],
        rhythmicValue: RhythmicValue.quarter,
      );

      expect(cluster.isChord, isTrue);
      expect(cluster.isRest, isFalse);
      expect(cluster.pitches.map((p) => p.scientificNotation).toList(), [
        'C4',
        'E4',
        'G4',
      ]);
      expect(cluster.lowestPitch?.scientificNotation, 'C4');
      expect(cluster.highestPitch?.scientificNotation, 'G4');
    });

    test('serializes to and from JSON', () {
      final cluster = PolyphonicVoiceCluster(
        id: 'cluster-json',
        pitches: [Pitch.parse('C4'), Pitch.parse('G4')],
        rhythmicValue: RhythmicValue.half,
        tickOffset: 480,
        lyric: 'Praise',
      );

      final json = cluster.toJson();
      final restored = PolyphonicVoiceCluster.fromJson(json);

      expect(restored, equals(cluster));
      expect(restored.lyric, 'Praise');
      expect(restored.tickOffset, 480);
    });

    test('converts to individual NoteEvents', () {
      final cluster = PolyphonicVoiceCluster(
        id: 'c_split',
        pitches: [Pitch.parse('C4'), Pitch.parse('E4')],
        rhythmicValue: RhythmicValue.quarter,
      );

      final notes = cluster.toNoteEvents();
      expect(notes.length, 2);
      expect(notes[0].pitch?.scientificNotation, 'C4');
      expect(notes[1].pitch?.scientificNotation, 'E4');
    });
  });

  group('ChordStemLayoutCalculator Tests', () {
    test(
      'single note stem direction follows treble clef B4 middle line rule',
      () {
        // Below B4 -> stem UP
        final a4 = [Pitch.parse('A4')];
        final c4 = [Pitch.parse('C4')];
        expect(
          ChordStemLayoutCalculator.calculateStemDirection(a4),
          StemDirection.up,
        );
        expect(
          ChordStemLayoutCalculator.calculateStemDirection(c4),
          StemDirection.up,
        );

        // On B4 -> stem DOWN (standard default)
        final b4 = [Pitch.parse('B4')];
        expect(
          ChordStemLayoutCalculator.calculateStemDirection(b4),
          StemDirection.down,
        );

        // Above B4 -> stem DOWN
        final c5 = [Pitch.parse('C5')];
        final e5 = [Pitch.parse('E5')];
        expect(
          ChordStemLayoutCalculator.calculateStemDirection(c5),
          StemDirection.down,
        );
        expect(
          ChordStemLayoutCalculator.calculateStemDirection(e5),
          StemDirection.down,
        );
      },
    );

    test('chord stem direction decided by extreme distance from B4', () {
      // C4 (step 28, -6 from B4=34) and G4 (step 32, -2 from B4) -> extreme below (6 > 0) -> stem UP
      final cMajorLow = [
        Pitch.parse('C4'),
        Pitch.parse('E4'),
        Pitch.parse('G4'),
      ];
      final layoutLow = ChordStemLayoutCalculator.calculateLayout(cMajorLow);
      expect(layoutLow.stemDirection, StemDirection.up);
      expect(layoutLow.extremeDistanceBelowB4, 6);
      expect(layoutLow.extremeDistanceAboveB4, 0);

      // D5 (step 36, +2 from B4) and A5 (step 40, +6 from B4) -> extreme above (6 > 0) -> stem DOWN
      final highChord = [
        Pitch.parse('D5'),
        Pitch.parse('F5'),
        Pitch.parse('A5'),
      ];
      final layoutHigh = ChordStemLayoutCalculator.calculateLayout(highChord);
      expect(layoutHigh.stemDirection, StemDirection.down);
      expect(layoutHigh.extremeDistanceAboveB4, 6);

      // Equidistant: G4 (-2 from B4) and D5 (+2 from B4) -> tie breaks to stem DOWN
      final equidistant = [Pitch.parse('G4'), Pitch.parse('D5')];
      final layoutEq = ChordStemLayoutCalculator.calculateLayout(equidistant);
      expect(layoutEq.stemDirection, StemDirection.down);
    });

    test(
      'Triads and Thirds require zero horizontal offset (no collisions)',
      () {
        // C4 - E4 - G4 (thirds)
        final triad = [Pitch.parse('C4'), Pitch.parse('E4'), Pitch.parse('G4')];
        final layout = ChordStemLayoutCalculator.calculateLayout(triad);

        expect(layout.hasCollisions, isFalse);
        for (final p in layout.placements) {
          expect(p.offsetDirection, NoteheadOffsetDirection.none);
          expect(p.offsetFactor, 0.0);
          expect(p.isShifted, isFalse);
        }
      },
    );

    test(
      'Adjacent second (C4 + D4) with stem UP shifts upper note to the right',
      () {
        // C4 and D4 are diatonic second apart. Both below B4 -> stem UP.
        final secondUp = [Pitch.parse('C4'), Pitch.parse('D4')];
        final layout = ChordStemLayoutCalculator.calculateLayout(secondUp);

        expect(layout.stemDirection, StemDirection.up);
        expect(layout.hasCollisions, isTrue);

        final c4Placement = layout.getPlacementFor(secondUp[0])!;
        final d4Placement = layout.getPlacementFor(secondUp[1])!;

        // Lower note (C4) stays on normal side
        expect(c4Placement.offsetDirection, NoteheadOffsetDirection.none);
        expect(c4Placement.offsetFactor, 0.0);

        // Upper note (D4) shifts right (reverse side)
        expect(d4Placement.offsetDirection, NoteheadOffsetDirection.right);
        expect(d4Placement.offsetFactor, 1.0);
        expect(d4Placement.isShifted, isTrue);
      },
    );

    test(
      'Adjacent second (C5 + D5) with stem DOWN shifts lower note to the left',
      () {
        // C5 and D5 are diatonic second apart. Both above B4 -> stem DOWN.
        final secondDown = [Pitch.parse('C5'), Pitch.parse('D5')];
        final layout = ChordStemLayoutCalculator.calculateLayout(secondDown);

        expect(layout.stemDirection, StemDirection.down);
        expect(layout.hasCollisions, isTrue);

        final c5Placement = layout.getPlacementFor(secondDown[0])!;
        final d5Placement = layout.getPlacementFor(secondDown[1])!;

        // Upper note (D5) stays on normal side
        expect(d5Placement.offsetDirection, NoteheadOffsetDirection.none);
        expect(d5Placement.offsetFactor, 0.0);

        // Lower note (C5) shifts left (reverse side)
        expect(c5Placement.offsetDirection, NoteheadOffsetDirection.left);
        expect(c5Placement.offsetFactor, -1.0);
        expect(c5Placement.isShifted, isTrue);
      },
    );

    test('Cluster of 3 consecutive seconds alternates noteheads', () {
      // C4, D4, E4 with stem UP
      final cluster = [Pitch.parse('C4'), Pitch.parse('D4'), Pitch.parse('E4')];
      final layout = ChordStemLayoutCalculator.calculateLayout(cluster);

      expect(layout.stemDirection, StemDirection.up);
      expect(layout.hasCollisions, isTrue);

      final p0 = layout.placements[0]; // C4
      final p1 = layout.placements[1]; // D4
      final p2 = layout.placements[2]; // E4

      expect(p0.offsetDirection, NoteheadOffsetDirection.none);
      expect(p1.offsetDirection, NoteheadOffsetDirection.right);
      expect(p2.offsetDirection, NoteheadOffsetDirection.none);
    });

    test('Unison pitches shift second notehead to the right', () {
      final unisons = [Pitch.parse('E4'), Pitch.parse('E4')];
      final layout = ChordStemLayoutCalculator.calculateLayout(unisons);

      expect(layout.hasCollisions, isTrue);
      expect(
        layout.placements[0].offsetDirection,
        NoteheadOffsetDirection.none,
      );
      expect(
        layout.placements[1].offsetDirection,
        NoteheadOffsetDirection.right,
      );
    });
  });
}
