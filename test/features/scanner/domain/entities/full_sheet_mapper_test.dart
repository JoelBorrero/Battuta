import 'package:battuta/features/scanner/domain/entities/full_sheet_mapper.dart';
import 'package:battuta/features/scanner/domain/entities/full_sheet_schema.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FullSheetSchema & FullSheetMapper (Checklist Requirements)', () {
    test('FullSheetSchema defines structured JSON schema properties', () {
      expect(FullSheetSchema.schema, isNotNull);
      expect(
        FullSheetSchema.systemInstruction,
        contains('Optical Music Recognition'),
      );
    });

    test('Deterministically extracts metadatos (titulo, artista, tonalidad_indicada, copyright) and secciones (Pentagrama, Cifrado de acordes with casilla/ritmo, Cajas de navegacion)', () {
      final geminiJson = {
        'metadatos': {
          'titulo': 'Build My Life',
          'artista': 'Housefires & Pat Barrett',
          'tonalidad_indicada': 'G',
          'tempo_bpm': 68,
          'compas': '4/4',
          'copyright': '© 2016 Barrett Daddy Music / Capitol CMG Genesis',
        },
        'secciones': [
          {
            'nombre': 'Intro',
            'caja_navegacion': '[Intro]',
            'repeticiones': 1,
            'compases': [
              {
                'numero': 1,
                'compas': '4/4',
                'acordes': [
                  {'cifrado': 'G', 'posicion_pulso': 1.0, 'tick_offset': 0},
                  {'cifrado': 'C/G', 'posicion_pulso': 3.0, 'tick_offset': 960},
                ],
                'notas': [
                  {'tono': 'rest', 'duracion': 'whole', 'duracion_ticks': 1920},
                ],
              },
            ],
          },
          {
            'nombre': 'Verse 1',
            'caja_navegacion': '[A]',
            'repeticiones': 1,
            'compases': [
              {
                'numero': 2,
                'casilla_ritmo': '1.',
                'acordes': [
                  {'cifrado': 'G', 'tick_offset': 0},
                ],
                'notas': [
                  {
                    'tono': 'D4',
                    'duracion': 'half',
                    'duracion_ticks': 960,
                    'letra': 'Wor-',
                    'ligadura': false,
                  },
                  {
                    'tono': 'B4',
                    'duracion': 'half',
                    'duracion_ticks': 960,
                    'letra': 'thy',
                    'ligadura': true,
                  },
                ],
              },
            ],
          },
        ],
      };

      // Map directly into a valid Dart Score instance
      final score = FullSheetMapper.mapToScore(
        geminiJson,
        scoreId: 'score-omr-1',
      );

      // Verify Score entity
      expect(score, isA<Score>());
      expect(score.id, equals('score-omr-1'));

      // 1. Verify Metadata
      expect(score.title, equals('Build My Life'));
      expect(score.artist, equals('Housefires & Pat Barrett'));
      expect(score.keySignature, equals('G'));
      expect(score.tempo, equals(68));
      expect(score.timeSignature, equals(TimeSignature.fourFour));
      expect(
        score.metadata['copyright'],
        equals('© 2016 Barrett Daddy Music / Capitol CMG Genesis'),
      );

      // 2. Verify Sections & Navigation Boxes
      expect(score.sections.length, equals(2));

      final intro = score.sections[0];
      expect(intro.id, equals('sec-[Intro]'));
      expect(intro.name, equals('Intro'));
      expect(intro.repeatCount, equals(1));
      expect(intro.measures.length, equals(1));

      final verse = score.sections[1];
      expect(verse.id, equals('sec-[A]'));
      expect(verse.name, equals('Verse 1'));
      expect(verse.measures.length, equals(1));

      // 3. Verify Measures, Chords & Notes
      final introM1 = intro.measures[0];
      expect(introM1.number, equals(1));
      expect(introM1.chords.length, equals(2));
      expect(introM1.chords[0].root, equals('G'));
      expect(introM1.chords[0].tickOffset, equals(0));
      expect(introM1.chords[1].root, equals('C'));
      expect(introM1.chords[1].bass, equals('G'));
      expect(introM1.chords[1].tickOffset, equals(960));
      expect(introM1.events.length, equals(1));
      expect(introM1.events[0].isRest, isTrue);

      final verseM2 = verse.measures[0];
      expect(verseM2.number, equals(2));
      expect(verseM2.chords.length, equals(1));
      expect(verseM2.chords[0].root, equals('G'));
      expect(verseM2.events.length, equals(2));

      // Note 1
      expect(verseM2.events[0].pitch?.scientificNotation, equals('D4'));
      expect(verseM2.events[0].ticks, equals(960));
      expect(verseM2.events[0].lyric, equals('Wor-'));
      expect(verseM2.events[0].isTied, isFalse);

      // Note 2 (tied)
      expect(verseM2.events[1].pitch?.scientificNotation, equals('B4'));
      expect(verseM2.events[1].ticks, equals(960));
      expect(verseM2.events[1].lyric, equals('thy'));
      expect(verseM2.events[1].isTied, isTrue);
    });

    test('handles fallback defaults gracefully on partial JSON', () {
      final minimalJson = <String, dynamic>{};
      final score = FullSheetMapper.mapToScore(minimalJson);

      expect(score.title, equals('Untitled Lead Sheet'));
      expect(score.artist, isNull);
      expect(score.keySignature, equals('C'));
      expect(score.tempo, equals(120));
      expect(score.timeSignature, equals(TimeSignature.fourFour));
      expect(score.sections, isEmpty);
    });
  });
}
