/// Battuta — Gemini OMR Schema A: Full Lead Sheet Structure.
///
/// Defines the structured JSON schema for extracting complete lead sheets
/// from sheet music images using Gemini 2.5/3 multimodal models.
library;

import 'package:google_generative_ai/google_generative_ai.dart';

/// Schema definition for Gemini OMR Schema A (Full Lead Sheet Structure).
///
/// Instructs Gemini to deterministically extract:
/// - **metadatos**: `titulo`, `artista`, `tonalidad_indicada`, `tempo_bpm`, `compas`, `copyright`
/// - **secciones**: `nombre`, `caja_navegacion`, `repeticiones`, and `compases`
/// - **compases**: `numero`, `compas`, `casilla_ritmo`, `acordes` (cifrado, tick_offset/posicion_pulso),
///   and `notas` (tono, duracion, letra, ligadura)
class FullSheetSchema {
  FullSheetSchema._();

  /// Prompt instructing Gemini how to transcribe the lead sheet image.
  static const String systemInstruction = '''
You are an expert musicologist and Optical Music Recognition (OMR) system specialized in church worship and modern lead sheets.
Analyze the provided sheet music image and extract the complete musical structure in structured JSON format according to the schema.
Guidelines:
1. Extract metadata: title (titulo), artist/composer (artista), indicated key (tonalidad_indicada, e.g. "C", "G#m", "Eb"), tempo (tempo_bpm), time signature (compas, e.g. "4/4"), and copyright/licensing info.
2. Group bars into sections: Intro, Verse 1, Verse 2, Chorus, Bridge, Outro, etc. Note any rehearsal letters or navigation boxes (caja_navegacion, e.g. "[A]", "[B]", "D.S. al Coda", "Fine").
3. For each measure (compas):
   - Record the 1-based measure number.
   - Record any volta brackets or endings (casilla_ritmo, e.g. "1.", "2.").
   - Transcribe all chord symbols (cifrado) with their approximate beat position or tick offset (480 ticks per quarter note).
   - Transcribe melodic notes with scientific pitch notation (e.g. "C4", "D#4", "Bb4", "F5") or "rest" for musical rests. Include lyrics (letra) and ties (ligadura) when present.
''';

  /// The Gemini structured output Schema for full lead sheet recognition.
  static final Schema schema = Schema.object(
    description: 'Complete lead sheet structure containing metadata, sections, chords, and staves',
    properties: {
      'metadatos': Schema.object(
        description: 'Lead sheet metadata',
        properties: {
          'titulo': Schema.string(description: 'Title of the song or piece'),
          'artista': Schema.string(
            description: 'Composer, artist, or worship band',
            nullable: true,
          ),
          'tonalidad_indicada': Schema.string(
            description:
                'Indicated key signature (e.g. "C", "G", "F#m", "Bb", "Eb")',
            nullable: true,
          ),
          'tempo_bpm': Schema.integer(
            description: 'Tempo in beats per minute, e.g. 72 or 120',
            nullable: true,
          ),
          'compas': Schema.string(
            description:
                'Primary time signature meter, e.g. "4/4", "3/4", "6/8"',
            nullable: true,
          ),
          'copyright': Schema.string(
            description: 'Copyright, CCLI license, or publication notice',
            nullable: true,
          ),
        },
        requiredProperties: ['titulo'],
      ),
      'secciones': Schema.array(
        description: 'Ordered musical sections of the arrangement',
        items: Schema.object(
          description: 'A discrete musical section (Verse, Chorus, etc.)',
          properties: {
            'nombre': Schema.string(
              description:
                  'Section name (e.g. "Intro", "Verse 1", "Chorus", "Bridge")',
            ),
            'caja_navegacion': Schema.string(
              description: 'Rehearsal mark or navigation box (e.g. "[A]", "[B]", "To Coda", "D.S.")',
              nullable: true,
            ),
            'repeticiones': Schema.integer(
              description: 'Repeat count for this section, default 1',
              nullable: true,
            ),
            'compases': Schema.array(
              description: 'Ordered measures within this section',
              items: Schema.object(
                description: 'A single musical measure / bar',
                properties: {
                  'numero': Schema.integer(
                    description: '1-based measure index',
                  ),
                  'compas': Schema.string(
                    description:
                        'Measure time signature if changed from primary meter',
                    nullable: true,
                  ),
                  'casilla_ritmo': Schema.string(
                    description:
                        'Volta bracket / repeat ending (e.g. "1.", "2.")',
                    nullable: true,
                  ),
                  'acordes': Schema.array(
                    description: 'Chords placed in this measure',
                    items: Schema.object(
                      description: 'A chord symbol with placement',
                      properties: {
                        'cifrado': Schema.string(
                          description: 'Chord symbol (e.g. "G", "Am7", "C#m7/G#", "D/F#")',
                        ),
                        'posicion_pulso': Schema.number(
                          description: 'Beat position in measure (1.0 for beat 1, 2.5 for beat 2 &)',
                          nullable: true,
                        ),
                        'tick_offset': Schema.integer(
                          description: 'Start offset within measure in MIDI ticks (480 ticks/quarter)',
                          nullable: true,
                        ),
                      },
                      requiredProperties: ['cifrado'],
                    ),
                  ),
                  'notas': Schema.array(
                    description: 'Melodic note events in this measure',
                    items: Schema.object(
                      description: 'Individual note or rest event',
                      properties: {
                        'tono': Schema.string(
                          description: 'Scientific pitch (e.g. "C4", "C#4", "Bb4", "F5") or "rest" for rests',
                        ),
                        'duracion': Schema.string(
                          description: 'Note duration name: whole, half, quarter, eighth, sixteenth',
                          nullable: true,
                        ),
                        'duracion_ticks': Schema.integer(
                          description: 'Duration in MIDI ticks (e.g. 480 for quarter, 240 for eighth)',
                          nullable: true,
                        ),
                        'letra': Schema.string(
                          description: 'Underlying vocal lyric syllable',
                          nullable: true,
                        ),
                        'ligadura': Schema.boolean(
                          description:
                              'Whether this note is tied to the next note',
                          nullable: true,
                        ),
                      },
                      requiredProperties: ['tono'],
                    ),
                  ),
                },
                requiredProperties: ['numero'],
              ),
            ),
          },
          requiredProperties: ['nombre'],
        ),
      ),
    },
    requiredProperties: ['metadatos', 'secciones'],
  );
}
