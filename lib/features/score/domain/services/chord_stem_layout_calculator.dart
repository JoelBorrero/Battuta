/// Battuta — Polyphonic Chord Stem & Shared-Stem Layout Calculator.
///
/// Implements standard Western musical engraving rules (Gould / Stone)
/// for polyphonic chords and note clusters sharing a single stem:
/// - Stem direction determined by extreme distance from treble middle line B4
/// - Collision detection and horizontal notehead offset rules for diatonic seconds
/// - Reverse-side displacement based on stem direction (Stem Up -> Upper right; Stem Down -> Lower left)
/// - Clean vertical alignment for thirds, triads, and wider intervals.
library;

import 'package:flutter/foundation.dart';

import '../entities/pitch.dart';

/// Direction of the shared musical stem.
enum StemDirection {
  /// Stem points upwards from right side of notehead.
  up,

  /// Stem points downwards from left side of notehead.
  down,
}

/// Horizontal displacement direction of a notehead to prevent collision.
enum NoteheadOffsetDirection {
  /// Notehead is placed on the normal side of the stem.
  none,

  /// Notehead is displaced to the left of the normal stem side.
  left,

  /// Notehead is displaced to the right of the normal stem side.
  right,
}

/// Layout placement metadata for an individual notehead within a chord stack.
@immutable
class NoteheadPlacement {
  const NoteheadPlacement({
    required this.pitch,
    required this.diatonicStepFromB4,
    required this.offsetDirection,
    required this.offsetFactor,
  });

  /// The musical pitch.
  final Pitch pitch;

  /// Diatonic step offset relative to treble clef middle line B4 (B4 = 0, C5 = +1, A4 = -1).
  final int diatonicStepFromB4;

  /// Horizontal displacement direction.
  final NoteheadOffsetDirection offsetDirection;

  /// Multiplier of notehead width (-1.0 for left, 0.0 for none, +1.0 for right).
  final double offsetFactor;

  /// Whether this notehead required horizontal displacement to avoid collision.
  bool get isShifted => offsetDirection != NoteheadOffsetDirection.none;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteheadPlacement &&
          runtimeType == other.runtimeType &&
          pitch == other.pitch &&
          diatonicStepFromB4 == other.diatonicStepFromB4 &&
          offsetDirection == other.offsetDirection &&
          offsetFactor == other.offsetFactor;

  @override
  int get hashCode =>
      Object.hash(pitch, diatonicStepFromB4, offsetDirection, offsetFactor);

  @override
  String toString() =>
      'NoteheadPlacement(${pitch.scientificNotation}, stepB4: $diatonicStepFromB4, offset: $offsetDirection)';
}

/// Computed geometry layout result for a polyphonic chord stack.
@immutable
class ChordStemLayout {
  const ChordStemLayout({
    required this.stemDirection,
    required this.placements,
    required this.lowestPitch,
    required this.highestPitch,
    required this.extremeDistanceAboveB4,
    required this.extremeDistanceBelowB4,
    required this.averageDistanceFromB4,
    required this.hasCollisions,
  });

  /// Direction of the shared stem.
  final StemDirection stemDirection;

  /// Individual layout placements for all notes in the chord (sorted ascending).
  final List<NoteheadPlacement> placements;

  /// Lowest pitch in the chord stack.
  final Pitch lowestPitch;

  /// Highest pitch in the chord stack.
  final Pitch highestPitch;

  /// Distance in diatonic steps above middle line B4 for the highest note.
  final int extremeDistanceAboveB4;

  /// Distance in diatonic steps below middle line B4 for the lowest note.
  final int extremeDistanceBelowB4;

  /// Mean diatonic step distance of all notes from middle line B4.
  final double averageDistanceFromB4;

  /// True if any noteheads had to be shifted to avoid adjacent-second collisions.
  final bool hasCollisions;

  NoteheadPlacement? getPlacementFor(Pitch pitch) {
    for (final p in placements) {
      if (p.pitch == pitch) return p;
    }
    return null;
  }
}

/// Pure Dart geometry calculator for polyphonic chord stems and notehead layout.
abstract final class ChordStemLayoutCalculator {
  /// Diatonic step index of treble clef middle line B4 (octave 4 * 7 + step 6 = 34).
  static const int trebleMiddleLineB4Index = 34;

  /// Computes the standard stem direction for a list of [pitches].
  ///
  /// Engraving rule (Gould / Stone):
  /// - The note farthest from the middle line (B4) decides the stem direction.
  /// - If the farthest note is above B4, stem points DOWN.
  /// - If the farthest note is below B4, stem points UP.
  /// - If equidistant or on B4, stem defaults to DOWN.
  static StemDirection calculateStemDirection(
    List<Pitch> pitches, {
    int referenceLineIndex = trebleMiddleLineB4Index,
  }) {
    if (pitches.isEmpty) return StemDirection.down;

    var maxAbove = 0;
    var maxBelow = 0;

    for (final pitch in pitches) {
      final diff = pitch.diatonicStepIndex - referenceLineIndex;
      if (diff > 0 && diff > maxAbove) {
        maxAbove = diff;
      } else if (diff < 0 && (-diff) > maxBelow) {
        maxBelow = -diff;
      }
    }

    if (maxAbove > maxBelow) {
      return StemDirection.down;
    } else if (maxBelow > maxAbove) {
      return StemDirection.up;
    } else {
      // Equidistant or all on middle line -> standard default is DOWN
      return StemDirection.down;
    }
  }

  /// Calculates complete layout including stem direction and notehead offset rules.
  static ChordStemLayout calculateLayout(
    List<Pitch> pitches, {
    int referenceLineIndex = trebleMiddleLineB4Index,
  }) {
    if (pitches.isEmpty) {
      throw ArgumentError(
        'Cannot calculate chord layout for empty pitches list',
      );
    }

    // 1. Sort pitches ascending from lowest to highest
    final sortedPitches = List<Pitch>.from(pitches)
      ..sort((a, b) => a.compareTo(b));

    final lowest = sortedPitches.first;
    final highest = sortedPitches.last;

    final extremeAbove = highest.diatonicStepIndex > referenceLineIndex
        ? highest.diatonicStepIndex - referenceLineIndex
        : 0;
    final extremeBelow = lowest.diatonicStepIndex < referenceLineIndex
        ? referenceLineIndex - lowest.diatonicStepIndex
        : 0;

    final totalDiff = sortedPitches.fold<int>(
      0,
      (sum, p) => sum + (p.diatonicStepIndex - referenceLineIndex),
    );
    final avgDist = totalDiff / sortedPitches.length;

    // 2. Determine stem direction
    final stemDir = calculateStemDirection(
      sortedPitches,
      referenceLineIndex: referenceLineIndex,
    );

    // 3. Resolve notehead offsets for adjacent seconds and unisons
    final placements = <NoteheadPlacement>[];
    var hasCollisions = false;

    if (stemDir == StemDirection.up) {
      // For Stem UP: Normal position is left of the stem.
      // When a second occurs (diff == 1), lower note stays normal, upper note shifts RIGHT.
      // For ascending sequence, we track if previous note was shifted.
      bool previousWasShifted = false;

      for (var i = 0; i < sortedPitches.length; i++) {
        final current = sortedPitches[i];
        final stepFromB4 = current.diatonicStepIndex - referenceLineIndex;

        if (i == 0) {
          // Lowest note is always on the normal side
          placements.add(
            NoteheadPlacement(
              pitch: current,
              diatonicStepFromB4: stepFromB4,
              offsetDirection: NoteheadOffsetDirection.none,
              offsetFactor: 0.0,
            ),
          );
          previousWasShifted = false;
        } else {
          final prev = sortedPitches[i - 1];
          final diff = current.diatonicStepIndex - prev.diatonicStepIndex;

          if (diff == 0) {
            // Unison: shift right
            hasCollisions = true;
            placements.add(
              NoteheadPlacement(
                pitch: current,
                diatonicStepFromB4: stepFromB4,
                offsetDirection: NoteheadOffsetDirection.right,
                offsetFactor: 1.0,
              ),
            );
            previousWasShifted = true;
          } else if (diff == 1) {
            // Diatonic second
            hasCollisions = true;
            if (!previousWasShifted) {
              // Current note shifts right
              placements.add(
                NoteheadPlacement(
                  pitch: current,
                  diatonicStepFromB4: stepFromB4,
                  offsetDirection: NoteheadOffsetDirection.right,
                  offsetFactor: 1.0,
                ),
              );
              previousWasShifted = true;
            } else {
              // Previous was shifted right, so this one can sit on normal side
              placements.add(
                NoteheadPlacement(
                  pitch: current,
                  diatonicStepFromB4: stepFromB4,
                  offsetDirection: NoteheadOffsetDirection.none,
                  offsetFactor: 0.0,
                ),
              );
              previousWasShifted = false;
            }
          } else {
            // Third or larger interval (diff >= 2): normal side
            placements.add(
              NoteheadPlacement(
                pitch: current,
                diatonicStepFromB4: stepFromB4,
                offsetDirection: NoteheadOffsetDirection.none,
                offsetFactor: 0.0,
              ),
            );
            previousWasShifted = false;
          }
        }
      }
    } else {
      // For Stem DOWN: Normal position is right of the stem.
      // When a second occurs (diff == 1), upper note stays normal, lower note shifts LEFT.
      // We process from highest down to lowest to resolve offsets cleanly.
      final reversedOffsets = <NoteheadOffsetDirection>[];
      bool previousWasShifted = false;

      for (var i = sortedPitches.length - 1; i >= 0; i--) {
        if (i == sortedPitches.length - 1) {
          // Highest note sits on normal side
          reversedOffsets.add(NoteheadOffsetDirection.none);
          previousWasShifted = false;
        } else {
          final current = sortedPitches[i];
          final above = sortedPitches[i + 1];
          final diff = above.diatonicStepIndex - current.diatonicStepIndex;

          if (diff == 0) {
            hasCollisions = true;
            reversedOffsets.add(NoteheadOffsetDirection.left);
            previousWasShifted = true;
          } else if (diff == 1) {
            hasCollisions = true;
            if (!previousWasShifted) {
              // Lower note shifts left
              reversedOffsets.add(NoteheadOffsetDirection.left);
              previousWasShifted = true;
            } else {
              reversedOffsets.add(NoteheadOffsetDirection.none);
              previousWasShifted = false;
            }
          } else {
            reversedOffsets.add(NoteheadOffsetDirection.none);
            previousWasShifted = false;
          }
        }
      }

      // Re-align with ascending order
      final offsets = reversedOffsets.reversed.toList();
      for (var i = 0; i < sortedPitches.length; i++) {
        final p = sortedPitches[i];
        final stepFromB4 = p.diatonicStepIndex - referenceLineIndex;
        final dir = offsets[i];
        final factor = dir == NoteheadOffsetDirection.left
            ? -1.0
            : (dir == NoteheadOffsetDirection.right ? 1.0 : 0.0);

        placements.add(
          NoteheadPlacement(
            pitch: p,
            diatonicStepFromB4: stepFromB4,
            offsetDirection: dir,
            offsetFactor: factor,
          ),
        );
      }
    }

    return ChordStemLayout(
      stemDirection: stemDir,
      placements: placements,
      lowestPitch: lowest,
      highestPitch: highest,
      extremeDistanceAboveB4: extremeAbove,
      extremeDistanceBelowB4: extremeBelow,
      averageDistanceFromB4: avgDist,
      hasCollisions: hasCollisions,
    );
  }
}
