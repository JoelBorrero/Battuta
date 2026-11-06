/// Battuta — Virtual Piano & Real-Time Tap Quantization Engine Interface.
///
/// Abstract contract for v1.3 tap quantization and virtual piano input:
/// - Snapping continuous taps to musical grid ticks (480 PPQ)
/// - Quantizing raw inputs into validated NoteEvent entities
/// - Support for straight notes, dotted notes, and triplet subdivisions.
library;

import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';

/// Grid resolution subdivisions for rhythmic quantization at 480 PPQ.
enum QuantizationGrid {
  /// Quarter note (1 beat in 4/4 = 480 ticks).
  quarter(480),

  /// Dotted eighth note (360 ticks).
  dottedEighth(360),

  /// Eighth note (240 ticks).
  eighth(240),

  /// Eighth note triplet (160 ticks).
  eighthTriplet(160),

  /// Sixteenth note (120 ticks).
  sixteenth(120),

  /// Sixteenth note triplet (80 ticks).
  sixteenthTriplet(80),

  /// Thirty-second note (60 ticks).
  thirtySecond(60);

  const QuantizationGrid(this.ticks);

  /// Tick interval for this quantization subdivision at 480 PPQ.
  final int ticks;

  /// Corresponding [RhythmicValue] for this quantization subdivision.
  RhythmicValue get rhythmicValue => switch (this) {
        QuantizationGrid.quarter => RhythmicValue.quarter,
        QuantizationGrid.dottedEighth => RhythmicValue.dottedEighth,
        QuantizationGrid.eighth => RhythmicValue.eighth,
        QuantizationGrid.sixteenth => RhythmicValue.sixteenth,
        QuantizationGrid.thirtySecond => RhythmicValue.thirtySecond,
        _ => RhythmicValue.custom(ticks: ticks),
      };
}

/// Raw unquantized musical input event from touch, tap, or virtual piano.
class RawMusicalInput {
  /// Creates an immutable [RawMusicalInput].
  const RawMusicalInput({
    required this.timestamp,
    required this.rawTick,
    this.pitch,
    this.velocity = 80,
  })  : assert(rawTick >= 0, 'rawTick cannot be negative'),
        assert(velocity >= 1 && velocity <= 127,
            'velocity must be between 1 and 127');

  /// Wall-clock timestamp when tap occurred.
  final DateTime timestamp;

  /// Continuous unquantized tick offset.
  final int rawTick;

  /// Musical pitch, or null for rhythm-only tap.
  final Pitch? pitch;

  /// MIDI velocity (1-127).
  final int velocity;
}

/// Abstract contract for v1.3 Virtual Piano & Real-Time Tap Quantization Module.
///
/// Designed to compile in pure Dart with zero external plugin dependencies.
abstract class QuantizationInputEngine {
  /// Mathematical snap: calculates the nearest quantization grid tick.
  ///
  /// [strength] ranges from 0.0 (no snap) to 1.0 (hard snap).
  int snapTickToGrid(
    int rawTick,
    QuantizationGrid grid, {
    double strength = 1.0,
  });

  /// Quantizes an individual [RawMusicalInput] into a validated [NoteEvent].
  NoteEvent quantizeInput(
    RawMusicalInput input, {
    required QuantizationGrid grid,
    required TimeSignature timeSignature,
    double strength = 1.0,
  });

  /// Quantizes an entire sequence of continuous taps into a clean, measure-bounded
  /// sequence of [NoteEvent] objects with rests filling any unplayed spaces.
  List<NoteEvent> quantizeSequence(
    List<RawMusicalInput> inputs, {
    required QuantizationGrid grid,
    required TimeSignature timeSignature,
    double strength = 1.0,
  });
}
