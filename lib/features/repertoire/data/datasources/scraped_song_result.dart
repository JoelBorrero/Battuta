/// Battuta — Scraped Song Result Interface.
///
/// Common abstraction for songs scraped from external chord/tab providers
/// (Cifra Club, LaCuerda, etc.) before saving into Battuta's repertoire.
library;

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

/// A parsed section from a scraped chord/tab web page.
abstract class ScrapedSongSection {
  /// Section name (e.g. "Intro", "Verse 1", "Chorus", "Bridge", "Outro").
  String get name;

  /// Pure lyrics text for this section.
  String get lyrics;

  /// Ordered list of chord names appearing in this section.
  List<String> get chords;

  /// Raw text content of this section with bracketed chord annotations.
  String get rawContent;

  /// Number of times this section is repeated (defaults to 1).
  int get repeatCount;
}

/// Unified parsed song result from an external web provider.
abstract class ScrapedSongResult {
  /// The provider source.
  SupportedUrlProvider get provider;

  /// The song title (e.g. "Santo Por Siempre", "Por Quien Eres Tu").
  String get title;

  /// The artist or worship ministry (e.g. "Coalo Zamorano").
  String get artist;

  /// Root musical key (e.g. "G", "C#m").
  String get key;

  /// Tempo in BPM, if available.
  int? get bpm;

  /// Capotasto fret offset (0 if none).
  int get capo;

  /// Instrument tuning (e.g. "E A D G B E").
  String get tuning;

  /// All unique chord names identified in the chart.
  List<String> get chordsUsed;

  /// Parsed sections (Verse, Chorus, Bridge, etc.).
  List<ScrapedSongSection> get sections;

  /// Clean plain-text chord chart with chords positioned above lyrics.
  String get plainText;

  /// Standard ChordPro-formatted text with inline bracketed chords.
  String get chordProText;

  /// Converts this scraped result into a Battuta domain [Song] entity.
  Song toSong({String? id});
}

