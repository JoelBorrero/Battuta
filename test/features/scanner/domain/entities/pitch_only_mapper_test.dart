import 'package:battuta/features/scanner/domain/entities/pitch_only_mapper.dart';
import 'package:battuta/features/scanner/domain/entities/pitch_only_schema.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PitchOnlySchema & PitchOnlyMapper (Checklist Requirements)', () {
    test('PitchOnlySchema defines structured JSON schema properties', () {
      expect(PitchOnlySchema.schema.properties, isNotNull);
      expect(PitchOnlySchema.schema.properties!.containsKey('seccion'), isTrue);
      expect(
        PitchOnlySchema.schema.properties!.containsKey('clave_asumida'),
        isTrue,
      );
      expect(
        PitchOnlySchema.schema.properties!.containsKey('compases'),
        isTrue,
      );
      expect(PitchOnlySchema.systemInstruction, contains('Treble Clef'));
      expect(PitchOnlySchema.systemInstruction, contains('secuencia_notas'));
    });

    test('Deterministically extracts seccion, clave_asumida, compases (numero, acordes, secuencia_notas, advertencia)', () {
      final jsonPayload = {
        'seccion': 'Verse 1',
        'clave_asumida': 'G4 (Treble Clef)',
        'advertencia': 'Dense ledger lines detected above staff on beat 3',
        'compases': [
          {
            'numero': 1,
            'acordes': ['G', 'C'],
            'secuencia_notas': ['G4', 'B4', 'D5', 'G5'],
            'advertencia': 'High G5 has double ledger line',
          },
          {
            'numero': 2,
            'acordes': ['D'],
            'secuencia_notas': ['F#4', 'A4', 'D5'],
          },
        ],
      };

      final result = PitchOnlyMapper.mapToResult(
        jsonPayload,
        timeSignature: TimeSignature.fourFour,
      );

      // 1. Returns seccion
      expect(result.sectionName, equals('Verse 1'));

      // 2. Returns clave_asumida
      expect(result.assumedClef, equals('G4 (Treble Clef)'));

      // 3. Section and measure level advertencia (dense ledger lines)
      expect(
        result.warning,
        equals('Dense ledger lines detected above staff on beat 3'),
      );
      expect(
        result.measureWarnings[1],
        equals('High G5 has double ledger line'),
      );
      expect(result.measureWarnings[2], isNull);

      // 4. Compases list
      expect(result.measures.length, equals(2));
      final m1 = result.measures[0];
      expect(m1.number, equals(1));
      expect(m1.timeSignature, equals(TimeSignature.fourFour));

      // 5. Acordes
      expect(m1.chords.length, equals(2));
      expect(m1.chords[0].text, equals('G'));
      expect(m1.chords[1].text, equals('C'));

      // 6. Automatically populates Measure objects via Measure.fromGeminiPitchList
      expect(m1.events.length, equals(4));
      expect(m1.events[0].pitch?.scientificNotation, equals('G4'));
      expect(m1.events[1].pitch?.scientificNotation, equals('B4'));
      expect(m1.events[2].pitch?.scientificNotation, equals('D5'));
      expect(m1.events[3].pitch?.scientificNotation, equals('G5'));

      // Unassigned rhythmic value check (ready for tap-first editor)
      for (final event in m1.events) {
        expect(event.rhythmicValue, equals(RhythmicValue.unassigned));
        expect(event.rhythmicValue.ticks, equals(0));
      }
      expect(m1.unassignedCount, equals(4));
      expect(m1.hasUnassignedEvents, isTrue);

      final m2 = result.measures[1];
      expect(m2.number, equals(2));
      expect(m2.chords.length, equals(1));
      expect(m2.chords[0].text, equals('D'));
      expect(m2.events.length, equals(3));
      expect(m2.events[0].pitch?.scientificNotation, equals('F#4'));

      // Convert to Section entity check
      final section = result.toSection(id: 'verse-1');
      expect(section.id, equals('verse-1'));
      expect(section.name, equals('Verse 1'));
      expect(section.measures.length, equals(2));
    });

    test('Handles chords defined as objects with positioning', () {
      final jsonPayload = {
        'seccion': 'Chorus',
        'clave_asumida': 'G4',
        'compases': [
          {
            'numero': 1,
            'acordes': [
              {'cifrado': 'Em7', 'posicion_pulso': 1.0, 'tick_offset': 0},
              {'cifrado': 'Cadd9', 'posicion_pulso': 3.0, 'tick_offset': 960},
            ],
            'secuencia_notas': ['E4', 'G4', 'B4'],
          },
        ],
      };

      final result = PitchOnlyMapper.mapToResult(jsonPayload);
      final m1 = result.measures.first;
      expect(m1.chords.length, equals(2));
      expect(m1.chords[0].text, equals('Em7'));
      expect(m1.chords[0].tickOffset, equals(0));
      expect(m1.chords[1].text, equals('Cadd9'));
      expect(m1.chords[1].tickOffset, equals(960));
    });

    test('Handles graceful fallbacks on empty or partial JSON', () {
      final result = PitchOnlyMapper.mapToResult({});
      expect(result.sectionName, equals('Extracted Section'));
      expect(result.assumedClef, equals('G4 (Treble Clef)'));
      expect(result.measures, isEmpty);
      expect(result.warning, isNull);
      expect(result.measureWarnings, isEmpty);
      expect(result.totalMeasures, equals(0));
      expect(result.totalNotes, equals(0));
    });
  });
}
