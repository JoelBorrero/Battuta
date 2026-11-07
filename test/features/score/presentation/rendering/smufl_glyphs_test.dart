import 'dart:ui';

import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/presentation/rendering/smufl_glyphs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SmuflGlyphs Constants & Mapping', () {
    test('Font family is registered as Bravura', () {
      expect(SmuflGlyphs.fontFamily, equals('Bravura'));
    });

    test(
      'Standard SMuFL Unicode codepoints are correctly defined in PUA range',
      () {
        // Clefs
        expect(SmuflGlyphs.gClef, equals('\uE050'));
        expect(SmuflGlyphs.fClef, equals('\uE062'));
        expect(SmuflGlyphs.cClef, equals('\uE05C'));

        // Noteheads
        expect(SmuflGlyphs.noteheadBlack, equals('\uE0A4'));
        expect(SmuflGlyphs.noteheadHalf, equals('\uE0A3'));
        expect(SmuflGlyphs.noteheadWhole, equals('\uE0A2'));
        expect(SmuflGlyphs.noteheadDoubleWhole, equals('\uE0A0'));

        // Stems & Flags
        expect(SmuflGlyphs.stem, equals('\uE210'));
        expect(SmuflGlyphs.flag8thUp, equals('\uE240'));
        expect(SmuflGlyphs.flag8thDown, equals('\uE241'));
        expect(SmuflGlyphs.flag16thUp, equals('\uE242'));
        expect(SmuflGlyphs.flag16thDown, equals('\uE243'));

        // Accidentals
        expect(SmuflGlyphs.accidentalFlat, equals('\uE260'));
        expect(SmuflGlyphs.accidentalNatural, equals('\uE261'));
        expect(SmuflGlyphs.accidentalSharp, equals('\uE262'));
        expect(SmuflGlyphs.accidentalDoubleSharp, equals('\uE263'));
        expect(SmuflGlyphs.accidentalDoubleFlat, equals('\uE264'));

        // Rests
        expect(SmuflGlyphs.restWhole, equals('\uE4E3'));
        expect(SmuflGlyphs.restHalf, equals('\uE4E4'));
        expect(SmuflGlyphs.restQuarter, equals('\uE4E5'));
        expect(SmuflGlyphs.rest8th, equals('\uE4E6'));
        expect(SmuflGlyphs.rest16th, equals('\uE4E7'));

        // Repeats & Barlines
        expect(SmuflGlyphs.barlineSingle, equals('\uE030'));
        expect(SmuflGlyphs.barlineDouble, equals('\uE031'));
        expect(SmuflGlyphs.barlineFinal, equals('\uE032'));
        expect(SmuflGlyphs.repeatLeft, equals('\uE040'));
        expect(SmuflGlyphs.repeatRight, equals('\uE041'));
        expect(SmuflGlyphs.repeatDots, equals('\uE044'));

        // Fermatas & Articulations
        expect(SmuflGlyphs.fermataAbove, equals('\uE4C0'));
        expect(SmuflGlyphs.fermataBelow, equals('\uE4C1'));
        expect(SmuflGlyphs.augmentationDot, equals('\uE1E7'));
        expect(SmuflGlyphs.articAccentAbove, equals('\uE4A0'));
      },
    );

    test('glyphForNotehead returns proper notehead based on duration', () {
      expect(
        SmuflGlyphs.glyphForNotehead(RhythmicValue.whole),
        equals(SmuflGlyphs.noteheadWhole),
      );
      expect(
        SmuflGlyphs.glyphForNotehead(RhythmicValue.half),
        equals(SmuflGlyphs.noteheadHalf),
      );
      expect(
        SmuflGlyphs.glyphForNotehead(RhythmicValue.quarter),
        equals(SmuflGlyphs.noteheadBlack),
      );
      expect(
        SmuflGlyphs.glyphForNotehead(RhythmicValue.eighth),
        equals(SmuflGlyphs.noteheadBlack),
      );
      expect(
        SmuflGlyphs.glyphForNotehead(RhythmicValue.unassigned),
        equals(SmuflGlyphs.noteheadBlack),
      );
    });

    test('glyphForRest returns proper rest based on duration', () {
      expect(
        SmuflGlyphs.glyphForRest(RhythmicValue.whole),
        equals(SmuflGlyphs.restWhole),
      );
      expect(
        SmuflGlyphs.glyphForRest(RhythmicValue.half),
        equals(SmuflGlyphs.restHalf),
      );
      expect(
        SmuflGlyphs.glyphForRest(RhythmicValue.quarter),
        equals(SmuflGlyphs.restQuarter),
      );
      expect(
        SmuflGlyphs.glyphForRest(RhythmicValue.eighth),
        equals(SmuflGlyphs.rest8th),
      );
      expect(
        SmuflGlyphs.glyphForRest(RhythmicValue.sixteenth),
        equals(SmuflGlyphs.rest16th),
      );
    });

    test('glyphForAccidental maps sharp, flat, natural symbols', () {
      expect(
        SmuflGlyphs.glyphForAccidental('#'),
        equals(SmuflGlyphs.accidentalSharp),
      );
      expect(
        SmuflGlyphs.glyphForAccidental('♯'),
        equals(SmuflGlyphs.accidentalSharp),
      );
      expect(
        SmuflGlyphs.glyphForAccidental('b'),
        equals(SmuflGlyphs.accidentalFlat),
      );
      expect(
        SmuflGlyphs.glyphForAccidental('♭'),
        equals(SmuflGlyphs.accidentalFlat),
      );
      expect(
        SmuflGlyphs.glyphForAccidental('n'),
        equals(SmuflGlyphs.accidentalNatural),
      );
      expect(
        SmuflGlyphs.glyphForAccidental('♮'),
        equals(SmuflGlyphs.accidentalNatural),
      );
      expect(
        SmuflGlyphs.glyphForAccidental('##'),
        equals(SmuflGlyphs.accidentalDoubleSharp),
      );
      expect(
        SmuflGlyphs.glyphForAccidental('bb'),
        equals(SmuflGlyphs.accidentalDoubleFlat),
      );
      expect(SmuflGlyphs.glyphForAccidental(null), isNull);
      expect(SmuflGlyphs.glyphForAccidental('unknown'), isNull);
    });

    test('glyphForTimeSigDigit returns digits 0-9 and throws on invalid', () {
      expect(SmuflGlyphs.glyphForTimeSigDigit(0), equals(SmuflGlyphs.timeSig0));
      expect(SmuflGlyphs.glyphForTimeSigDigit(3), equals(SmuflGlyphs.timeSig3));
      expect(SmuflGlyphs.glyphForTimeSigDigit(4), equals(SmuflGlyphs.timeSig4));
      expect(SmuflGlyphs.glyphForTimeSigDigit(6), equals(SmuflGlyphs.timeSig6));
      expect(SmuflGlyphs.glyphForTimeSigDigit(9), equals(SmuflGlyphs.timeSig9));
      expect(() => SmuflGlyphs.glyphForTimeSigDigit(10), throwsArgumentError);
    });
  });

  group('SMuFL TextPainter Rendering & Scaling (Checklist Verification)', () {
    test('createPainter creates and layouts TextPainter correctly', () {
      final painter = SmuflGlyphs.createPainter(
        glyph: SmuflGlyphs.gClef,
        fontSize: 36.0,
      );

      expect(painter.text, isNotNull);
      final textSpan = painter.text! as TextSpan;
      expect(textSpan.text, equals(SmuflGlyphs.gClef));
      expect(textSpan.style?.fontFamily, equals('Bravura'));
      expect(textSpan.style?.fontSize, equals(36.0));
      expect(painter.width, greaterThan(0));
      expect(painter.height, greaterThan(0));
    });

    test('SMuFL glyphs render crisply via Flutter TextPainter at scale factors (Retina iPad 2.0x, 3.0x)', () {
      // 1.0x Scale
      final painter1x = SmuflGlyphs.createPainter(
        glyph: SmuflGlyphs.noteheadBlack,
        fontSize: 24.0,
        textScaler: const TextScaler.linear(1.0),
      );

      // 2.0x Scale (Retina iPad)
      final painter2x = SmuflGlyphs.createPainter(
        glyph: SmuflGlyphs.noteheadBlack,
        fontSize: 24.0,
        textScaler: const TextScaler.linear(2.0),
      );

      // 3.0x Scale (Super Retina / high-DPI displays)
      final painter3x = SmuflGlyphs.createPainter(
        glyph: SmuflGlyphs.noteheadBlack,
        fontSize: 24.0,
        textScaler: const TextScaler.linear(3.0),
      );

      expect(painter1x.width, greaterThan(0));
      expect(painter2x.width, greaterThan(painter1x.width));
      expect(painter3x.width, greaterThan(painter2x.width));

      // Paint onto a PictureRecorder canvas to verify no rendering exceptions
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      SmuflGlyphs.paintGlyph(
        canvas,
        const Offset(10, 10),
        glyph: SmuflGlyphs.gClef,
        fontSize: 48.0,
        textScaler: const TextScaler.linear(2.0),
      );

      SmuflGlyphs.paintGlyph(
        canvas,
        const Offset(60, 20),
        glyph: SmuflGlyphs.accidentalSharp,
        fontSize: 32.0,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
    });
  });
}
