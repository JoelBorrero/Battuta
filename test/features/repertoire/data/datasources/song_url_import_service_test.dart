import 'dart:io';

import 'package:battuta/features/repertoire/data/datasources/song_url_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

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

    test('detectProvider recognizes LaCuerda URLs', () {
      expect(
        SongUrlImportService.detectProvider(
          'https://acordes.lacuerda.net/marcos_witt/tu_fidelidad.shtml',
        ),
        equals(SupportedUrlProvider.laCuerda),
      );
      expect(
        SongUrlImportService.detectProvider(
          'https://lacuerda.net/acordes/artista/cancion',
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

    test('importFromUrl handles LaCuerda coming soon exception', () async {
      final service = SongUrlImportService();
      expect(
        () => service.importFromUrl('https://lacuerda.net/artista/cancion'),
        throwsA(isA<HttpException>()),
      );
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
