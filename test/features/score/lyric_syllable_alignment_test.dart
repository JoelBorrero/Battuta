import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:battuta/features/score/domain/services/lyric_syllable_tokenizer.dart';
import 'package:battuta/features/score/presentation/rendering/notehead_painter.dart';
import 'package:battuta/features/score/presentation/rendering/staff_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LyricSyllableTokenizer Unit Tests', () {
    test('tokenizes standard hyphenated words with trailing hyphens', () {
      final tokens = LyricSyllableTokenizer.tokenize('A-la-ba-ré');
      expect(tokens, ['A-', 'la-', 'ba-', 'ré']);
    });

    test('performs Spanish synalepha (sinalefa) combining adjacent vowels', () {
      // Exactly from TASK-105 specification: "Glo-ria al Se-ñor" -> ["Glo-", "ria al", "Se-", "ñor"]
      final tokens = LyricSyllableTokenizer.tokenize('Glo-ria al Se-ñor');
      expect(tokens, ['Glo-', 'ria al', 'Se-', 'ñor']);
    });

    test('supports explicit elisions with ~ and _ characters', () {
      final tokensTilde = LyricSyllableTokenizer.tokenize('paz~eterna Dios');
      expect(tokensTilde, ['paz eterna', 'Dios']);

      final tokensUnderscore = LyricSyllableTokenizer.tokenize(
        'luz_infinita hoy',
      );
      expect(tokensUnderscore, ['luz infinita', 'hoy']);
    });

    test(
      'aligns syllables 1:1 against sounding notes and skips musical rests',
      () {
        // Create a measure with: Note, Rest, Note, Note, Note (4 notes, 1 rest)
        final measure = Measure(
          number: 1,
          timeSignature: TimeSignature.commonTime,
          events: [
            NoteEvent.note(
              id: 'n1',
              pitch: Pitch.parse('C4'),
              rhythmicValue: RhythmicValue.quarter,
              tickOffset: 0,
            ),
            const NoteEvent.rest(
              id: 'r1',
              rhythmicValue: RhythmicValue.quarter,
              tickOffset: 480,
            ),
            NoteEvent.note(
              id: 'n2',
              pitch: Pitch.parse('D4'),
              rhythmicValue: RhythmicValue.quarter,
              tickOffset: 960,
            ),
            NoteEvent.note(
              id: 'n3',
              pitch: Pitch.parse('E4'),
              rhythmicValue: RhythmicValue.quarter,
              tickOffset: 1440,
            ),
            NoteEvent.note(
              id: 'n4',
              pitch: Pitch.parse('F4'),
              rhythmicValue: RhythmicValue.quarter,
              tickOffset: 1920,
            ),
          ],
        );

        final aligned = LyricSyllableTokenizer.alignLyricsToMeasure(
          measure,
          'Glo-ria al Se-ñor',
        );

        expect(aligned.events.length, 5);

        // Note 1: "Glo-"
        expect(aligned.events[0].isNote, isTrue);
        expect(aligned.events[0].lyric, 'Glo-');

        // Rest: null lyric
        expect(aligned.events[1].isRest, isTrue);
        expect(aligned.events[1].lyric, isNull);

        // Note 2: "ria al" (sinalefa)
        expect(aligned.events[2].isNote, isTrue);
        expect(aligned.events[2].lyric, 'ria al');

        // Note 3: "Se-"
        expect(aligned.events[3].isNote, isTrue);
        expect(aligned.events[3].lyric, 'Se-');

        // Note 4: "ñor"
        expect(aligned.events[4].isNote, isTrue);
        expect(aligned.events[4].lyric, 'ñor');
      },
    );

    test('handles empty or blank lyric input cleanly', () {
      expect(LyricSyllableTokenizer.tokenize(''), isEmpty);
      expect(LyricSyllableTokenizer.tokenize('   '), isEmpty);
    });
  });

  group('Lyric Presentation & Canvas Tests', () {
    testWidgets(
      'NoteheadPainter paints aligned lyric syllables below staff bottom ledger boundary',
      (tester) async {
        // Create measure with aligned lyrics including low C4 note (ledger line below staff)
        final measure = Measure(
          number: 1,
          timeSignature: TimeSignature.commonTime,
          events: [
            NoteEvent.note(
              id: 'n1',
              pitch: Pitch.parse('C4'), // Low note below staff
              rhythmicValue: RhythmicValue.quarter,
              tickOffset: 0,
              lyric: 'Glo-',
            ),
            NoteEvent.note(
              id: 'n2',
              pitch: Pitch.parse('G4'),
              rhythmicValue: RhythmicValue.quarter,
              tickOffset: 480,
              lyric: 'ria',
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: const Size(400, 300),
                painter: _TestMeasurePainter(measure: measure),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}

class _TestMeasurePainter extends CustomPainter {
  _TestMeasurePainter({required this.measure});

  final Measure measure;

  @override
  void paint(Canvas canvas, Size size) {
    NoteheadPainter.paintMeasureNotes(
      canvas,
      measure: measure,
      measureLeft: 20.0,
      measureRight: 380.0,
      staffBottomY: 150.0,
      metrics: const StaffMetrics(),
      showLyrics: true,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
