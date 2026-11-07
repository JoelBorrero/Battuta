# Step Spec: TASK-104 Polyphonic Chord Stack Model & Shared-Stem Layout Calculator

## Exact Files to Create / Modify
- `lib/features/score/domain/entities/polyphonic_voice_cluster.dart` (Create)
- `lib/features/score/domain/entities/note_event.dart` (Extend backward-compatibly with pitches/isChord)
- `lib/features/score/domain/services/chord_stem_layout_calculator.dart` (Create)
- `test/features/score/chord_stem_layout_calculator_test.dart` (Create)

## Domain Architecture
- `PolyphonicVoiceCluster`:
  - `id`: String
  - `pitches`: List<Pitch> (sorted)
  - `rhythmicValue`: RhythmicValue
  - `tickOffset`: int, `isTied`: bool, `lyric`: String?, `velocity`: int
  - `isChord`, `isRest`, `lowestPitch`, `highestPitch`
  - `toJson()`, `fromJson()`, `operator ==`, `hashCode`
- `NoteEvent`:
  - Add `List<Pitch> get pitches => pitch != null ? [pitch!] : const [];`
  - Add `bool get isChord => false;`
- `ChordStemLayoutCalculator`:
  - Standard reference line: Treble Clef B4 (`diatonicStepIndex = 34`).
  - `calculateStemDirection(List<Pitch> pitches)`:
    - Farthest note from B4 determines stem direction (below B4 -> up; above B4 -> down; tie -> down).
  - `calculateLayout(List<Pitch> pitches)`:
    - Computes `StemDirection`.
    - Detects diatonic unisons (diff == 0) and seconds (diff == 1).
    - Shifts noteheads:
      - Stem Up: lower note normal, upper note shifts right.
      - Stem Down: upper note normal, lower note shifts left.
      - Thirds/Triads: no shift (all normal).
    - Returns `ChordStemLayout` with notehead placements, stem direction, and bounds.

## Tests
- Stem direction: single notes below B4 (up), above B4 (down), middle B4 (down).
- Stem direction for chords: chord predominantly below B4 (up), chord predominantly above B4 (down), equidistant (down).
- Unisons: second notehead shifted right.
- Seconds: C4+D4 stem up (D4 shifted right), C4+D4 stem down (C4 shifted left).
- Triads: C4-E4-G4 (all normal, zero horizontal offset).
- Multi-note clusters: alternating second offset avoiding collisions.
- PolyphonicVoiceCluster serialization and entity behavior.
