/// Battuta — Gemini OMR Schema B: Pitch-Only Melodic Extraction.
///
/// Defines the structured JSON schema for extracting melodic pitch sequences
/// and chord symbols from sheet music images while ignoring rhythmic durations,
/// assuming Treble Clef (G4).
library;

import 'package:google_generative_ai/google_generative_ai.dart';

/// Schema definition for Gemini OMR Schema B ('Pitch-Only' Melodic Extraction).
///
/// Instructs Gemini to:
/// 1. Assume Treble Clef (clave de sol / G4).
/// 2. Extract noteheads in visual left-to-right order per measure (`secuencia_notas`).
/// 3. Extract chord symbols (`acordes`).
/// 4. Provide warnings (`advertencia`) for dense ledger lines, low confidence, or ambiguous accidentals.
class PitchOnlySchema {
  PitchOnlySchema._();

  /// System instruction guiding Gemini's pitch extraction behavior.
  static const String systemInstruction = '''
You are an expert musicologist and pitch-recognition OMR assistant specialized in melody and chord transcription.
Analyze the provided sheet music image or melodic snippet and extract noteheads and chord symbols while IGNORING rhythmic durations.
Guidelines:
1. Clef Assumption: Assume Treble Clef (clave de sol en 2da línea / G4 = 392.00 Hz) unless an explicit clef is clearly shown.
2. Noteheads: Transcribe melodic noteheads strictly in visual left-to-right order per measure into "secuencia_notas" using scientific pitch notation (e.g. "C4", "D4", "F#4", "Bb4", "G5").
3. Chords: Identify any chord symbols written above each measure into "acordes" (e.g. ["G", "D/F#", "Em7"]).
4. Measure Numbering: Keep 1-based sequential measure numbers ("numero").
5. Section & Warnings: Return the section name ("seccion", e.g. "Verse 1", "Chorus", "Melody Snippet") and assumed clef ("clave_asumida", e.g. "G4 (Treble Clef)"). If there are dense ledger lines (above or below staff), damaged scans, or ambiguous accidentals, report an advisory warning in "advertencia".
6. Output Format: Produce strict JSON adhering to the provided schema.
''';

  /// Structured output [Schema] for Schema B.
  static final Schema schema = Schema.object(
    description: 'Pitch-only melodic and chord extraction for a musical snippet or section',
    properties: {
      'seccion': Schema.string(
        description: 'Name or header of this section (e.g. "Intro", "Verse 1", "Snippet")',
        nullable: true,
      ),
      'clave_asumida': Schema.string(
        description: 'Assumed musical clef, typically "G4" (Treble Clef)',
        nullable: true,
      ),
      'advertencia': Schema.string(
        description: 'Section-level warning for dense ledger lines, low resolution, or ambiguous notation',
        nullable: true,
      ),
      'compases': Schema.array(
        description: 'Ordered measures with pitch sequence and chords',
        items: Schema.object(
          description: 'A single measure with pitches in left-to-right order',
          properties: {
            'numero': Schema.integer(description: '1-based measure index'),
            'acordes': Schema.array(
              description: 'Chord symbols present in this measure',
              items: Schema.string(
                description: 'Chord symbol (e.g. "G", "D/F#", "Am7")',
              ),
              nullable: true,
            ),
            'secuencia_notas': Schema.array(
              description: 'Scientific pitch strings in left-to-right order (e.g. ["C4", "E4", "G4"])',
              items: Schema.string(
                description:
                    'Scientific pitch notation, e.g. "C4", "D#4", "Bb4", "A5"',
              ),
            ),
            'advertencia': Schema.string(
              description: 'Measure-level warning (e.g. dense ledger lines, ambiguous pitch)',
              nullable: true,
            ),
          },
          requiredProperties: ['numero', 'secuencia_notas'],
        ),
      ),
    },
    requiredProperties: ['compases'],
  );
}
