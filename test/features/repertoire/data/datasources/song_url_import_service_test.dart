import 'package:battuta/features/repertoire/data/datasources/cifra_club_service.dart';
import 'package:battuta/features/repertoire/data/datasources/la_cuerda_service.dart';
import 'package:battuta/features/repertoire/data/datasources/song_url_import_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCifraClubService extends Mock implements CifraClubService {}
class MockLaCuerdaService extends Mock implements LaCuerdaService {}

void main() {
  group('SongUrlImportService', () {
    test('detectProvider recognizes Cifra Club URLs and slugs', () {
      expect(
        SongUrlImportService.detectProvider(
          'https://www.cifraclub.com/la-ibi/santo-por-siempre/',
        ),
        equals(SupportedUrlProvider.cifraClub),
      );
      expect(
        SongUrlImportService.detectProvider(
          'http://cifraclub.com/hillsong/oceanos/',
        ),
        equals(SupportedUrlProvider.cifraClub),
      );
      expect(
        SongUrlImportService.detectProvider('la-ibi/santo-por-siempre'),
        equals(SupportedUrlProvider.cifraClub),
      );
    });

    test('detectProvider recognizes LaCuerda URLs and slugs', () {
      expect(
        SongUrlImportService.detectProvider(
          'https://acordes.lacuerda.net/coalo_zamorano/por_quien_eres_tu-5.shtml',
        ),
        equals(SupportedUrlProvider.laCuerda),
      );
      expect(
        SongUrlImportService.detectProvider(
          'http://lacuerda.net/marcos_witt/tu_fidelidad.shtml',
        ),
        equals(SupportedUrlProvider.laCuerda),
      );
      expect(
        SongUrlImportService.detectProvider(
          'coalo_zamorano/por_quien_eres_tu-5',
        ),
        equals(SupportedUrlProvider.laCuerda),
      );
    });

    test('detectProvider categorizes unknown URLs', () {
      expect(
        SongUrlImportService.detectProvider('https://example.com/sheet-music'),
        equals(SupportedUrlProvider.unknown),
      );
    });

    test('importFromUrl delegates to LaCuerdaService for LaCuerda URLs', () async {
      final mockLaCuerda = MockLaCuerdaService();
      final mockCifraClub = MockCifraClubService();

      const sampleParsed = LaCuerdaParsedSong(
        title: 'Por Quien Eres Tu',
        artist: 'Coalo Zamorano',
        key: 'G',
        chordsUsed: ['G', 'C', 'D'],
        sections: [
          LaCuerdaSection(
            name: 'Verse 1',
            lyrics: 'Por quien eres Tu',
            chords: ['G', 'C', 'D'],
            rawContent: '[G]Por quien [C]eres [D]Tu',
          ),
        ],
        plainText: 'Por quien eres Tu',
        chordProText: '[G]Por quien [C]eres [D]Tu',
      );

      when(() => mockLaCuerda.fetchSong(any()))
          .thenAnswer((_) async => sampleParsed);

      final service = SongUrlImportService(
        cifraClubService: mockCifraClub,
        laCuerdaService: mockLaCuerda,
      );

      final song = await service.importFromUrl(
        'https://acordes.lacuerda.net/coalo_zamorano/por_quien_eres_tu-5.shtml',
      );

      expect(song.title, equals('Por Quien Eres Tu'));
      expect(song.artist, equals('Coalo Zamorano'));
      expect(song.key, equals('G'));
      verify(() => mockLaCuerda.fetchSong(any())).called(1);
      verifyNever(() => mockCifraClub.fetchSong(any()));
    });

    test('importFromUrl handles unknown provider FormatException', () async {
      final service = SongUrlImportService();
      expect(
        () => service.importFromUrl('https://unknown-tabs.com/song'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
