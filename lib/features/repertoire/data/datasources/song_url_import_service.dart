/// Battuta — URL Song Import Service.
///
/// Coordinates fetching, parsing, and converting web lead sheets from supported
/// chord sites (Cifra Club and LaCuerda) into Battuta [Song] domain entities.
library;

import 'package:battuta/features/repertoire/data/datasources/cifra_club_service.dart';
import 'package:battuta/features/repertoire/data/datasources/la_cuerda_service.dart';
import 'package:battuta/features/repertoire/data/datasources/scraped_song_result.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';

export 'package:battuta/features/repertoire/data/datasources/scraped_song_result.dart';

/// Service that ingests full URLs and returns parsed [Song] entities.
class SongUrlImportService {
  SongUrlImportService({
    CifraClubService? cifraClubService,
    LaCuerdaService? laCuerdaService,
  })  : _cifraClubService = cifraClubService ?? CifraClubService(),
        _laCuerdaService = laCuerdaService ?? LaCuerdaService();

  final CifraClubService _cifraClubService;
  final LaCuerdaService _laCuerdaService;

  /// Detects the target provider from a raw [urlOrPath].
  static SupportedUrlProvider detectProvider(String urlOrPath) {
    final lower = urlOrPath.toLowerCase().trim();
    if (lower.contains('cifraclub.com')) {
      return SupportedUrlProvider.cifraClub;
    }
    if (lower.contains('lacuerda.net')) {
      return SupportedUrlProvider.laCuerda;
    }

    // Check if it matches LaCuerda artist/song-version pattern (e.g. 'coalo_zamorano/por_quien_eres_tu-5')
    if (lower.contains('_') || RegExp(r'-\d+(\.(shtml|txt))?$').hasMatch(lower)) {
      return SupportedUrlProvider.laCuerda;
    }

    // Default to CifraClub if it looks like standard slug (e.g. 'la-ibi/santo-por-siempre')
    if (RegExp(r'^[a-z0-9\-]+/[a-z0-9\-]+/?$').hasMatch(lower)) {
      return SupportedUrlProvider.cifraClub;
    }

    return SupportedUrlProvider.unknown;
  }

  /// Imports a song from a full [url].
  Future<Song> importFromUrl(String url, {String? customId}) async {
    final provider = detectProvider(url);

    switch (provider) {
      case SupportedUrlProvider.cifraClub:
        final parsed = await _cifraClubService.fetchSong(url);
        return parsed.toSong(id: customId);

      case SupportedUrlProvider.laCuerda:
        final parsed = await _laCuerdaService.fetchSong(url);
        return parsed.toSong(id: customId);

      case SupportedUrlProvider.unknown:
        throw const FormatException(
          'Unsupported URL. Supported providers: Cifra Club (cifraclub.com) and LaCuerda (lacuerda.net).',
        );
    }
  }

  /// Fetches raw parsed data from [url] without full domain conversion (for live preview).
  Future<ScrapedSongResult> fetchPreview(String url) async {
    final provider = detectProvider(url);
    switch (provider) {
      case SupportedUrlProvider.cifraClub:
        return _cifraClubService.fetchSong(url);
      case SupportedUrlProvider.laCuerda:
        return _laCuerdaService.fetchSong(url);
      case SupportedUrlProvider.unknown:
        throw const FormatException(
          'Unsupported URL. Supported providers: Cifra Club (cifraclub.com) and LaCuerda (lacuerda.net).',
        );
    }
  }
}
