import 'package:battuta/features/repertoire/data/datasources/la_cuerda_service.dart';
import 'package:battuta/features/repertoire/data/datasources/scraped_song_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleLaCuerdaTxt = '''
=====================================================================
|             TABLATURAS Y ACORDES DE MÚSICA EN ESPAÑOL             |
+-------------------------- lacuerda.net ---------------------------+
| ARTISTA: Coalo Zamorano                                           |
| CANCION: POR QUIEN ERES TU                                        |
| AUTOR:   Coalo Zamorano                                           |
| ALBUM:   Cosas Poderosas                                          |
+------------------------------------------------------ACO-czam0045-+
| TRANS:   Jocelyn, Fernando                                        |
=====================================================================

VERSO:
G          Am              Bm     C2   D
Por quien eres Tu te doy la gloria

   G      D/F#  Em        Em/D           Am7    D
Por quien eres        Tu te doy       mi amor

CORO:
         Cmaj7                          G/B    Em7
///Jehova Jireh, eres quien provee

         Am7   C/D             Dm       Db     Cmaj7
Jehova Nissi,           Tu pele - - as por mi
Y te adorare por quien eres Tu///

FINAL:
      Am7       Dsus   D   Em  Em/Eb   Em/D
Y te adorare por quien eres Tu

Em/C#  Am7       Dsus   D    G
Y te adorare por quien eres Tu

=========================== lacuerda.net ============================
Este fichero es trabajo propio de su transcriptor y representa su    
interpretación personal de la canción. El material contenido en      
esta página es para exclusivo uso privado, por lo que se prohibe su  
reproducción o retransmisión, así como su uso para fines comerciales.
=========================== lacuerda.net ============================
''';

  group('LaCuerdaService', () {
    test('normalizeSongPath normalizes various URL and slug formats', () {
      expect(
        LaCuerdaService.normalizeSongPath(
          'https://acordes.lacuerda.net/coalo_zamorano/por_quien_eres_tu-5.shtml',
        ),
        equals('coalo_zamorano/por_quien_eres_tu-5'),
      );

      expect(
        LaCuerdaService.normalizeSongPath(
          'http://lacuerda.net/coalo_zamorano/por_quien_eres_tu-5.shtml',
        ),
        equals('coalo_zamorano/por_quien_eres_tu-5'),
      );

      expect(
        LaCuerdaService.normalizeSongPath(
          'https://acordes.lacuerda.net/TXT/coalo_zamorano/por_quien_eres_tu-5.txt',
        ),
        equals('coalo_zamorano/por_quien_eres_tu-5'),
      );

      expect(
        LaCuerdaService.normalizeSongPath(
          'acordes.lacuerda.net/coalo_zamorano/por_quien_eres_tu-5',
        ),
        equals('coalo_zamorano/por_quien_eres_tu-5'),
      );

      expect(
        LaCuerdaService.normalizeSongPath('coalo_zamorano/por_quien_eres_tu-5'),
        equals('coalo_zamorano/por_quien_eres_tu-5'),
      );

      expect(
        () => LaCuerdaService.normalizeSongPath('   '),
        throwsA(isA<FormatException>()),
      );
    });

    test('buildTxtUrl constructs direct plain text URL', () {
      expect(
        LaCuerdaService.buildTxtUrl(
          'https://acordes.lacuerda.net/coalo_zamorano/por_quien_eres_tu-5.shtml',
        ),
        equals(
          'https://acordes.lacuerda.net/TXT/coalo_zamorano/por_quien_eres_tu-5.txt',
        ),
      );

      expect(
        LaCuerdaService.buildTxtUrl('coalo_zamorano/por_quien_eres_tu-5'),
        equals(
          'https://acordes.lacuerda.net/TXT/coalo_zamorano/por_quien_eres_tu-5.txt',
        ),
      );
    });

    test('toTitleCase converts uppercase titles and preserves mixed case', () {
      expect(
        LaCuerdaService.toTitleCase('POR QUIEN ERES TU'),
        equals('Por Quien Eres Tu'),
      );
      expect(
        LaCuerdaService.toTitleCase('TU FIDELIDAD'),
        equals('Tu Fidelidad'),
      );
      expect(
        LaCuerdaService.toTitleCase('Cuan Grande es Dios'),
        equals('Cuan Grande es Dios'),
      );
    });

    test('convertSolfegeToAnglo translates Spanish solfege chords to standard notation', () {
      expect(LaCuerdaService.convertSolfegeToAnglo('DO'), equals('C'));
      expect(LaCuerdaService.convertSolfegeToAnglo('REm'), equals('Dm'));
      expect(LaCuerdaService.convertSolfegeToAnglo('MIm7'), equals('Em7'));
      expect(LaCuerdaService.convertSolfegeToAnglo('FA#m7'), equals('F#m7'));
      expect(LaCuerdaService.convertSolfegeToAnglo('SOLmaj7'), equals('Gmaj7'));
      expect(LaCuerdaService.convertSolfegeToAnglo('LAsus4'), equals('Asus4'));
      expect(LaCuerdaService.convertSolfegeToAnglo('SI7'), equals('B7'));
      expect(LaCuerdaService.convertSolfegeToAnglo('LA/DO#'), equals('A/C#'));
      expect(LaCuerdaService.convertSolfegeToAnglo('SOL/SI'), equals('G/B'));
      expect(LaCuerdaService.convertSolfegeToAnglo('SIb'), equals('Bb'));
      expect(LaCuerdaService.convertSolfegeToAnglo('DOm7/SIb'), equals('Cm7/Bb'));
    });

    test('parseTxt extracts metadata, chords, sections and converts to domain Song', () {
      final parsed = LaCuerdaService.parseTxt(sampleLaCuerdaTxt);

      expect(parsed.provider, equals(SupportedUrlProvider.laCuerda));
      expect(parsed.title, equals('Por Quien Eres Tu'));
      expect(parsed.artist, equals('Coalo Zamorano'));
      expect(parsed.author, equals('Coalo Zamorano'));
      expect(parsed.album, equals('Cosas Poderosas'));
      expect(parsed.transcriber, equals('Jocelyn, Fernando'));
      expect(parsed.key, equals('G'));
      expect(parsed.sections.length, equals(3));

      // Verse 1
      final verse = parsed.sections.firstWhere((s) => s.name.contains('Verse'));
      expect(verse.chords, containsAll(['G', 'Am', 'Bm', 'C2', 'D']));
      expect(verse.lyrics, contains('Por quien eres Tu te doy la gloria'));

      // Chorus
      final chorus = parsed.sections.firstWhere((s) => s.name.contains('Chorus'));
      expect(chorus.chords, containsAll(['Cmaj7', 'G/B', 'Em7', 'Am7']));
      expect(chorus.repeatCount, equals(3)); // Triple slash /// -> 3x

      // Domain Song conversion
      final domainSong = parsed.toSong();
      expect(domainSong.title, equals('Por Quien Eres Tu'));
      expect(domainSong.artist, equals('Coalo Zamorano'));
      expect(domainSong.key, equals('G'));
      expect(domainSong.sections.length, equals(3));
      expect(domainSong.tags, contains('Cosas Poderosas'));
      expect(domainSong.notes, contains('Coalo Zamorano'));
      // Verify chords are preserved within lyrics in ChordPro bracket format
      expect(domainSong.sections.first.lyrics, contains('[G]'));
      expect(domainSong.sections.first.chords.map((c) => c.displayLabel), containsAll(['G', 'Am', 'Bm']));
    });

    test('parseTxt handles solfege chord lines and converts to Anglo-Saxon chords', () {
      const solfegeTxt = '''
=====================================================================
| ARTISTA: Marcos Witt                                              |
| CANCION: TU FIDELIDAD                                             |
=====================================================================

VERSO:
SOL       MIm7
Tu fidelidad es grande

LAsus4  LA7  SOL        RE
Tu fidelidad incomparable es
''';

      final parsed = LaCuerdaService.parseTxt(solfegeTxt);
      expect(parsed.title, equals('Tu Fidelidad'));
      expect(parsed.artist, equals('Marcos Witt'));
      expect(parsed.key, equals('G'));

      final verse = parsed.sections.first;
      expect(verse.chords, containsAll(['G', 'Em7', 'Asus4', 'A7', 'D']));
    });

    test('parseTxt recognizes (Coro) and standalone VERSO section headers', () {
      const variedHeadersTxt = '''
=====================================================================
| ARTISTA: Miel San Marcos                                          |
| CANCION: NO HAY LUGAR MAS ALTO                                    |
=====================================================================

VERSO 1
G             D/F#
A tus pies arde mi corazon
Em            C
A tus pies entrego lo que soy

(CORO)
              G
No hay lugar más alto
            D/F#
Más grande que estar a tus pies
''';

      final parsed = LaCuerdaService.parseTxt(variedHeadersTxt);
      expect(parsed.sections.length, equals(2));
      expect(parsed.sections[0].name, equals('Verse 1'));
      expect(parsed.sections[0].chords, containsAll(['G', 'D/F#', 'Em', 'C']));

      expect(parsed.sections[1].name, equals('Chorus'));
      expect(parsed.sections[1].chords, containsAll(['G', 'D/F#']));

      final song = parsed.toSong();
      expect(song.sections[0].lyrics, contains('[G]'));
      expect(song.sections[1].lyrics, contains('[G]'));
    });
  });
}

