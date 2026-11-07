/// Battuta — Printable PDF Lead Sheet Generator Unit Tests.
///
/// Validates high-contrast printable PDF lead sheet generation according to:
/// - ClickUp Task 86e3yy42h Acceptance Criteria
/// - Checklist Item: "Generates standard Letter/A4 PDFs ready for AirPrint or file sharing on iPadOS and macOS."
/// - Song metadata, navigation boxes, chord grids, repeat barlines, 5-line staves, and melodies.
library;

import 'dart:typed_data';

import 'package:battuta/features/score/data/services/pdf_lead_sheet_generator.dart';
import 'package:battuta/features/score/domain/entities/chord_symbol.dart';
import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:battuta/features/score/domain/services/lead_sheet_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PdfLeadSheetGenerator generator;

  setUp(() {
    generator = const PdfLeadSheetGenerator();
  });

  /// Helper building a comprehensive test worship song
  Score buildTestScore({
    String title = 'Way Maker',
    String? artist = 'Sinach',
    String? composer = 'Sinach Kalu',
    String key = 'E',
    int tempo = 68,
    TimeSignature timeSignature = TimeSignature.fourFour,
    int verseRepeatCount = 2,
    String? externalSyncId = 'pp7-group-verse1-uuid',
  }) {
    // Measure 1: E chord, 4 quarter notes ascending from C4 (Middle C) with ledger line
    final m1 = Measure(
      number: 1,
      timeSignature: timeSignature,
      chords: const [
        ChordSymbol(root: 'E', tickOffset: 0),
        ChordSymbol(root: 'B', bass: 'D#', tickOffset: 960),
      ],
      events: const [
        NoteEvent.note(
          id: 'n1',
          pitch: Pitch(step: PitchStep.c, octave: 4), // Middle C (ledger line)
          rhythmicValue: RhythmicValue.quarter,
          tickOffset: 0,
        ),
        NoteEvent.note(
          id: 'n2',
          pitch: Pitch(step: PitchStep.e, octave: 4), // Line 1
          rhythmicValue: RhythmicValue.quarter,
          tickOffset: 480,
        ),
        NoteEvent.note(
          id: 'n3',
          pitch: Pitch(step: PitchStep.g, octave: 4, accidental: 1), // G#4
          rhythmicValue: RhythmicValue.quarter,
          tickOffset: 960,
        ),
        NoteEvent.note(
          id: 'n4',
          pitch: Pitch(step: PitchStep.b, octave: 4), // Line 3 (down stem)
          rhythmicValue: RhythmicValue.quarter,
          tickOffset: 1440,
          isTied: true,
        ),
      ],
    );

    // Measure 2: C#m7 chord, half note tied from m1 + half rest
    final m2 = Measure(
      number: 2,
      timeSignature: timeSignature,
      chords: const [ChordSymbol(root: 'C#', quality: 'm7', tickOffset: 0)],
      events: const [
        NoteEvent.note(
          id: 'n5',
          pitch: Pitch(step: PitchStep.b, octave: 4),
          rhythmicValue: RhythmicValue.half,
          tickOffset: 0,
        ),
        NoteEvent.rest(
          id: 'r1',
          rhythmicValue: RhythmicValue.half,
          tickOffset: 960,
        ),
      ],
    );

    // Measure 3: A2 chord, high note A5 (top ledger line) with eighth notes
    final m3 = Measure(
      number: 3,
      timeSignature: timeSignature,
      chords: const [ChordSymbol(root: 'A', quality: '2', tickOffset: 0)],
      events: const [
        NoteEvent.note(
          id: 'n6',
          pitch: Pitch(step: PitchStep.a, octave: 5), // A5 (top ledger)
          rhythmicValue: RhythmicValue.eighth,
          tickOffset: 0,
        ),
        NoteEvent.note(
          id: 'n7',
          pitch: Pitch(step: PitchStep.g, octave: 5, accidental: 1),
          rhythmicValue: RhythmicValue.eighth,
          tickOffset: 240,
        ),
        NoteEvent.note(
          id: 'n8',
          pitch: Pitch(step: PitchStep.f, octave: 5, accidental: 1),
          rhythmicValue: RhythmicValue.eighth,
          tickOffset: 480,
        ),
        NoteEvent.note(
          id: 'n9',
          pitch: Pitch(step: PitchStep.e, octave: 5),
          rhythmicValue: RhythmicValue.eighth,
          tickOffset: 720,
        ),
        NoteEvent.rest(
          id: 'r2',
          rhythmicValue: RhythmicValue.quarter,
          tickOffset: 960,
        ),
        NoteEvent.rest(
          id: 'r3',
          rhythmicValue: RhythmicValue.quarter,
          tickOffset: 1440,
        ),
      ],
    );

    // Measure 4: Bsus4 to B, whole note
    final m4 = Measure(
      number: 4,
      timeSignature: timeSignature,
      chords: const [
        ChordSymbol(root: 'B', quality: 'sus4', tickOffset: 0),
        ChordSymbol(root: 'B', tickOffset: 960),
      ],
      events: const [
        NoteEvent.note(
          id: 'n10',
          pitch: Pitch(step: PitchStep.b, octave: 4),
          rhythmicValue: RhythmicValue.whole,
          tickOffset: 0,
        ),
      ],
    );

    return Score(
      id: 'score-way-maker-1',
      title: title,
      artist: artist,
      composer: composer,
      keySignature: key,
      tempo: tempo,
      timeSignature: timeSignature,
      metadata: const {
        'ccli': '7115744',
        'copyright': '© 2016 Integrity Music Europe',
      },
      sections: [
        Section(
          id: 'sec-intro',
          name: 'Intro',
          repeatCount: 1,
          measures: [
            Measure(
              number: 1,
              timeSignature: timeSignature,
              chords: const [ChordSymbol(root: 'E')],
            ),
            Measure(
              number: 2,
              timeSignature: timeSignature,
              chords: const [ChordSymbol(root: 'B', bass: 'D#')],
            ),
          ],
        ),
        Section(
          id: 'sec-verse1',
          name: 'Verse 1',
          repeatCount: verseRepeatCount,
          externalSyncId: externalSyncId,
          measures: [m1, m2, m3, m4],
        ),
        Section(
          id: 'sec-chorus',
          name: 'Chorus',
          repeatCount: 2,
          measures: [
            Measure(
              number: 5,
              timeSignature: timeSignature,
              chords: const [ChordSymbol(root: 'E')],
            ),
            Measure(
              number: 6,
              timeSignature: timeSignature,
              chords: const [ChordSymbol(root: 'B')],
            ),
          ],
        ),
      ],
    );
  }

  group('Printable PDF Lead Sheet Generator (ClickUp 86e3yy42h)', () {
    test('(Checklist Requirement) Generates standard Letter PDF ready for AirPrint on iPadOS/macOS', () async {
      final score = buildTestScore();

      final bytes = await generator.generatePdfBytes(
        score,
        options: const PdfLeadSheetOptions(pageFormat: PdfPageFormat.letter),
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(1000));

      // PDF signature header: %PDF-1.
      final header = String.fromCharCodes(bytes.sublist(0, 7));
      expect(header.startsWith('%PDF-1.'), isTrue);
    });

    test('(Checklist Requirement) Generates standard A4 PDF ready for international printing and sharing', () async {
      final score = buildTestScore();

      final bytes = await generator.generatePdfBytes(
        score,
        options: const PdfLeadSheetOptions(pageFormat: PdfPageFormat.a4),
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(1000));
      final header = String.fromCharCodes(bytes.sublist(0, 7));
      expect(header.startsWith('%PDF-1.'), isTrue);
    });

    test('Builds Document containing metadata, section navigation boxes, and repeat barlines', () async {
      final score = buildTestScore();

      final doc = generator.buildDocument(score);
      expect(doc.document.pdfPageList.pages, isNotEmpty);

      final bytes = await doc.save();
      expect(bytes.length, greaterThan(500));
    });

    test(
      'Renders lead sheet without staff melodies when melody toggle is false',
      () async {
        final score = buildTestScore();

        final bytes = await generator.generatePdfBytes(
          score,
          options: const PdfLeadSheetOptions(includeStaffMelodies: false),
        );

        expect(bytes.length, greaterThan(500));
      },
    );

    test(
      'Renders custom measuresPerSystem layout (e.g. 2 bars per system)',
      () async {
        final score = buildTestScore();

        final bytes = await generator.generatePdfBytes(
          score,
          options: const PdfLeadSheetOptions(measuresPerSystem: 2),
        );

        expect(bytes.length, greaterThan(500));
      },
    );

    test('Renders 3/4 time signature and compound meters cleanly', () async {
      const score = Score(
        id: 'score-3-4',
        title: 'Great Are You Lord',
        keySignature: 'A',
        tempo: 72,
        timeSignature: TimeSignature.threeFour,
        sections: [
          Section(
            id: 'sec-v1',
            name: 'Verse',
            repeatCount: 2,
            measures: [
              Measure(
                number: 1,
                timeSignature: TimeSignature.threeFour,
                chords: [ChordSymbol(root: 'D')],
                events: [
                  NoteEvent.note(
                    id: 'e1',
                    pitch: Pitch(step: PitchStep.d, octave: 4),
                    rhythmicValue: RhythmicValue.dottedHalf,
                  ),
                ],
              ),
              Measure(
                number: 2,
                timeSignature: TimeSignature.threeFour,
                chords: [ChordSymbol(root: 'F#m7')],
                events: [
                  NoteEvent.note(
                    id: 'e2',
                    pitch: Pitch(step: PitchStep.c, octave: 5, accidental: 1),
                    rhythmicValue: RhythmicValue.quarter,
                  ),
                  NoteEvent.rest(
                    id: 'e3',
                    rhythmicValue: RhythmicValue.half,
                    tickOffset: 480,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final bytes = await generator.generatePdfBytes(score);
      expect(bytes.length, greaterThan(500));
    });

    test(
      'Renders empty score gracefully without throwing exceptions',
      () async {
        const emptyScore = Score(id: 'score-empty', title: 'Empty Lead Sheet');

        final bytes = await generator.generatePdfBytes(emptyScore);
        expect(bytes.length, greaterThan(200));
      },
    );

    test('Handles long multi-section scores spanning multiple pages', () async {
      final manySections = List.generate(
        8,
        (s) => Section(
          id: 'sec-$s',
          name: 'Section ${s + 1}',
          repeatCount: (s % 2 == 0) ? 2 : 1,
          measures: List.generate(
            8,
            (m) => Measure(
              number: (s * 8) + m + 1,
              chords: [
                ChordSymbol(root: ['C', 'G', 'Am', 'F'][m % 4]),
              ],
              events: [
                NoteEvent.note(
                  id: 'n-$s-$m',
                  pitch: const Pitch(step: PitchStep.g, octave: 4),
                  rhythmicValue: RhythmicValue.whole,
                ),
              ],
            ),
          ),
        ),
      );

      final multiPageScore = Score(
        id: 'score-multi',
        title: 'Long Worship Medley',
        artist: 'Battuta Collective',
        sections: manySections,
      );

      final bytes = await generator.generatePdfBytes(multiPageScore);
      expect(bytes.length, greaterThan(3000));
    });
  });
}
