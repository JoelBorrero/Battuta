import 'package:battuta/features/repertoire/data/datasources/cifra_club_service.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CifraClubService', () {
    test('normalizeSongPath normalizes various input formats correctly', () {
      expect(
        CifraClubService.normalizeSongPath('la-ibi/santo-por-siempre/'),
        equals('la-ibi/santo-por-siempre/'),
      );
      expect(
        CifraClubService.normalizeSongPath('la-ibi/santo-por-siempre'),
        equals('la-ibi/santo-por-siempre/'),
      );
      expect(
        CifraClubService.normalizeSongPath('/la-ibi/santo-por-siempre/'),
        equals('la-ibi/santo-por-siempre/'),
      );
      expect(
        CifraClubService.normalizeSongPath('https://www.cifraclub.com/la-ibi/santo-por-siempre/'),
        equals('la-ibi/santo-por-siempre/'),
      );
      expect(
        CifraClubService.normalizeSongPath('http://www.cifraclub.com/la-ibi/santo-por-siempre'),
        equals('la-ibi/santo-por-siempre/'),
      );
    });

    test('parseHtml correctly extracts metadata, chords, and sections from HTML', () {
      const mockHtml = '''
<!DOCTYPE html>
<html>
<head>
  <title>Santo Por Siempre (acordes) - Adoración La IBI - Cifra Club</title>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "MusicComposition",
    "name": "Santo Por Siempre",
    "byArtist": {
      "@type": "MusicGroup",
      "name": "Adoración La IBI"
    }
  }
  </script>
</head>
<body>
  <script>
    self.__next_f.push([1, "{\\"keyShape\\":\\"G\\",\\"bpm\\":70,\\"capo\\":0,\\"tuning\\":\\"E A D G B E\\"}"]);
  </script>
  <pre class="_crVx" data-chord-content="true">
[Intro] <b data-chord-name="C">C</b>  <b data-chord-name="Em">Em</b>  <b data-chord-name="D">D</b>  <b data-chord-name="Bm">Bm</b>

[Primera Parte]
 <b data-chord-name="G">G</b>
Mil generaciones
    <b data-chord-name="C">C</b>          <b data-chord-name="G">G</b>
Se postran adorarle
       <b data-chord-name="Em">Em</b>        <b data-chord-name="D">D</b>
Le cantan al cordero
         <b data-chord-name="C">C</b>
Que venció

[Estribillo 1]
            <b data-chord-name="C">C</b>
Claman ángeles
 <b data-chord-name="Em">Em</b>  <b data-chord-name="D">D</b>
Santo
               <b data-chord-name="Bm7">Bm7</b>
Clama la creación
    <b data-chord-name="Em">Em</b>
Santo
           <b data-chord-name="Am7">Am7</b>
Exaltado Dios
    <b data-chord-name="D">D</b>
Santo
            <b data-chord-name="G">G</b>
Santo por siempre
  </pre>
</body>
</html>
''';

      final song = CifraClubService.parseHtml(mockHtml);

      expect(song.title, equals('Santo Por Siempre'));
      expect(song.artist, equals('Adoración La IBI'));
      expect(song.key, equals('G'));
      expect(song.bpm, equals(70));
      expect(song.capo, equals(0));
      expect(song.tuning, equals('E A D G B E'));
      expect(song.chordsUsed, containsAll(['C', 'Em', 'D', 'Bm', 'G', 'Bm7', 'Am7']));

      expect(song.sections.length, equals(3));
      expect(song.sections[0].name, equals('Intro'));
      expect(song.sections[0].chords, containsAll(['C', 'Em', 'D', 'Bm']));

      expect(song.sections[1].name, equals('Primera Parte'));
      expect(song.sections[1].lyrics, contains('Mil generaciones'));

      expect(song.sections[2].name, equals('Estribillo 1'));
      expect(song.sections[2].lyrics, contains('Claman ángeles'));

      // Verify domain mapping to Battuta Song entity
      final domainSong = CifraClubService.toDomainSong(song, id: 'test_santo');
      expect(domainSong.id, equals('test_santo'));
      expect(domainSong.title, equals('Santo Por Siempre'));
      expect(domainSong.artist, equals('Adoración La IBI'));
      expect(domainSong.key, equals('G'));
      expect(domainSong.tempo, equals(70));
      expect(domainSong.timeSignature, equals((4, 4)));
      expect(domainSong.sections.length, equals(3));

      final introSection = domainSong.sections.first;
      expect(introSection.name, equals('Intro'));
      expect(introSection.chords.length, greaterThanOrEqualTo(4));
      expect(introSection.chords.first.root, equals('C'));
      expect(introSection.chords.first.quality, equals(ChordQuality.major));
    });

    test('browser headers include necessary sec-fetch and sec-ch-ua headers', () {
      const headers = CifraClubService.defaultBrowserHeaders;
      expect(headers.containsKey('user-agent'), isTrue);
      expect(headers.containsKey('sec-fetch-dest'), isTrue);
      expect(headers.containsKey('sec-fetch-mode'), isTrue);
      expect(headers.containsKey('sec-fetch-site'), isTrue);
      expect(headers['sec-fetch-dest'], equals('document'));
      expect(headers['sec-fetch-mode'], equals('navigate'));
    });
  });
}
