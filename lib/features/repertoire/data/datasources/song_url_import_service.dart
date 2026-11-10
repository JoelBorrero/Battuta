/// Battuta — URL Song Import Service.
///
/// Coordinates fetching, parsing, and converting web lead sheets from supported
/// chord sites (Cifra Club, and LaCuerda soon) into Battuta [Song] domain entities.
library;

import 'dart:io';

import 'package:battuta/features/repertoire/data/datasources/cifra_club_service.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';

/// Supported external chord/tab website providers.
enum SupportedUrlProvider {
  cifraClub('Cifra Club', 'cifraclub.com'),
  laCuerda('LaCuerda', 'lacuerda.net'),
  unknown('Web Link', '');

  const SupportedUrlProvider(this.displayName, this.domain);
  final String displayName;
  final String domain;
}

/// Service that ingests full URLs and returns parsed [Song] entities.
class SongUrlImportService {
  SongUrlImportService({
    CifraClubService? cifraClubService,
  }) : _cifraClubService = cifraClubService ?? CifraClubService();

  final CifraClubService _cifraClubService;

  /// Detects the target provider from a raw [urlOrPath].
  static SupportedUrlProvider detectProvider(String urlOrPath) {
    final lower = urlOrPath.toLowerCase().trim();
    if (lower.contains('cifraclub.com')) {
      return SupportedUrlProvider.cifraClub;
    }
    if (lower.contains('lacuerda.net')) {
      return SupportedUrlProvider.laCuerda;
    }

    // Default to CifraClub if it looks like an artist/song slug (e.g. 'la-ibi/santo-por-siempre')
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
        return CifraClubService.toDomainSong(parsed, id: customId);

      case SupportedUrlProvider.laCuerda:
        throw const HttpException(
          'LaCuerda scraper is coming soon! Cifra Club URLs are currently supported.',
        );

      case SupportedUrlProvider.unknown:
        throw const FormatException(
          'Unsupported URL. Supported providers: Cifra Club (cifraclub.com) and LaCuerda (coming soon).',
        );
    }
  }

  /// Fetches raw parsed data from [url] without full domain conversion (for live preview).
  Future<CifraClubParsedSong> fetchPreview(String url) async {
    final provider = detectProvider(url);
    if (provider == SupportedUrlProvider.cifraClub) {
      return _cifraClubService.fetchSong(url);
    } else if (provider == SupportedUrlProvider.laCuerda) {
      throw const HttpException(
        'LaCuerda scraper is coming soon! Cifra Club URLs are currently supported.',
      );
    } else {
      throw const FormatException(
        'Unsupported URL. Supported providers: Cifra Club (cifraclub.com).',
      );
    }
  }
}

