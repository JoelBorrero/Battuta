/// Battuta — StaffPitchMapper.
///
/// Maps scientific musical pitches to exact vertical (Y) coordinates relative
/// to the bottom line (E4) of the Treble Clef staff, and calculates ledger line
/// positions for notes <= C4 or >= A5.
library;

import 'package:battuta/features/score/domain/entities/pitch.dart';

/// Pitch-to-coordinate mapper and ledger line calculator for Treble Clef notation.
abstract final class StaffPitchMapper {
  /// Diatonic step index for the bottom line of Treble Clef (E4 = 30).
  static const int e4DiatonicStepIndex = 30;

  /// Diatonic step index for Middle C (C4 = 28). Notes <= C4 require bottom ledger lines.
  static const int c4DiatonicStepIndex = 28;

  /// Diatonic step index for A5 (A5 = 40). Notes >= A5 require top ledger lines.
  static const int a5DiatonicStepIndex = 40;

  /// Returns the diatonic step offset of [pitch] relative to the Treble Clef bottom line (E4).
  ///
  /// - E4 returns 0 (Line 1)
  /// - F4 returns 1 (Space 1)
  /// - G4 returns 2 (Line 2)
  /// - B4 returns 4 (Line 3, middle line)
  /// - F5 returns 8 (Line 5, top line)
  /// - C4 returns -2 (first ledger line below staff)
  /// - A5 returns 10 (first ledger line above staff)
  static int stepFromE4(Pitch pitch) =>
      pitch.diatonicStepIndex - e4DiatonicStepIndex;

  /// Calculates the vertical Y-coordinate for [pitch] on a staff where the bottom line (E4)
  /// is located at [staffBottomY].
  static double yCoordinateForPitch(
    Pitch pitch, {
    required double staffBottomY,
    required double lineSpacing,
  }) {
    final step = stepFromE4(pitch);
    final stepHeight = lineSpacing / 2.0;
    return staffBottomY - (step * stepHeight);
  }

  /// Whether [pitch] requires ledger lines (<= C4 below staff, or >= A5 above staff).
  static bool needsLedgerLines(Pitch pitch) {
    final step = stepFromE4(pitch);
    return step <= -2 || step >= 10;
  }

  /// Returns a list of vertical Y-coordinates where ledger lines must be drawn for [pitch].
  ///
  /// For notes below staff (<= C4, step <= -2):
  ///   Ledger lines are drawn at even steps -2, -4, ... down to the note position.
  /// For notes above staff (>= A5, step >= 10):
  ///   Ledger lines are drawn at even steps 10, 12, ... up to the note position.
  static List<double> calculateLedgerLineYOffsets(
    Pitch pitch, {
    required double staffBottomY,
    required double lineSpacing,
  }) {
    final step = stepFromE4(pitch);
    final stepHeight = lineSpacing / 2.0;
    final offsets = <double>[];

    if (step <= -2) {
      // Bottom ledger lines: steps -2, -4, ... down to step (if even) or step + 1 (if odd)
      final limitStep = step.isEven ? step : step + 1;
      for (var s = -2; s >= limitStep; s -= 2) {
        offsets.add(staffBottomY - (s * stepHeight));
      }
    } else if (step >= 10) {
      // Top ledger lines: steps 10, 12, ... up to step (if even) or step - 1 (if odd)
      final limitStep = step.isEven ? step : step - 1;
      for (var s = 10; s <= limitStep; s += 2) {
        offsets.add(staffBottomY - (s * stepHeight));
      }
    }

    return offsets;
  }

  /// Reverse mapping: maps a vertical [y] coordinate back to the closest diatonic [Pitch].
  ///
  /// Snaps continuous touch/drag coordinates to standard diatonic staff positions.
  static Pitch pitchForYCoordinate(
    double y, {
    required double staffBottomY,
    required double lineSpacing,
    int accidental = 0,
  }) {
    final stepHeight = lineSpacing / 2.0;
    final rawStep = (staffBottomY - y) / stepHeight;
    final step = rawStep.round();
    final targetDiatonicIndex = e4DiatonicStepIndex + step;

    final targetOctave = (targetDiatonicIndex / 7).floor();
    final targetStep = PitchStep.fromIndex(targetDiatonicIndex);

    return Pitch(
      step: targetStep,
      accidental: accidental,
      octave: targetOctave,
    );
  }
}
