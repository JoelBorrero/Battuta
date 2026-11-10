/// Battuta — Cifra Club Scraper & Importer Service.
///
/// Fetches and parses chord charts, tabs, and lead sheets directly from Cifra Club
/// (e.g. `la-ibi/santo-por-siempre/`) into Battuta domain [Song] entities.
library;

import 'dart:convert';
import 'dart:io';

import 'package:battuta/features/repertoire/data/datasources/scraped_song_result.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';

/// Structured song data parsed from a Cifra Club HTML response.
class CifraClubParsedSong implements ScrapedSongResult {
  const CifraClubParsedSong({
    required this.title,
    required this.artist,
    required this.key,
    this.bpm,
    this.capo = 0,
    this.tuning = 'E A D G B E',
    required this.chordsUsed,
    required this.sections,
    required this.plainText,
    required this.chordProText,
  });

  @override
  SupportedUrlProvider get provider => SupportedUrlProvider.cifraClub;

  /// The song title (e.g. "Santo Por Siempre").
  @override
  final String title;

  /// The artist or worship ministry (e.g. "Adoración La IBI").
  @override
  final String artist;

  /// Root musical key / "Tom" (e.g. "G", "C#m").
  @override
  final String key;

  /// Tempo in beats per minute, if available.
  @override
  final int? bpm;

  /// Capotasto fret offset (0 if no capo).
  @override
  final int capo;

  /// Instrument tuning (e.g. "E A D G B E").
  @override
  final String tuning;

  /// All unique chord names identified in the chart.
  @override
  final List<String> chordsUsed;

  /// Parsed sections (Intro, Verse, Chorus, Bridge, etc.).
  @override
  final List<CifraClubSection> sections;

  /// Clean plain-text chord chart with chords positioned above lyrics.
  @override
  final String plainText;

  /// Standard ChordPro-formatted text with inline bracketed chords (e.g. "[G]Santo").
  @override
  final String chordProText;

  @override
  Song toSong({String? id}) => CifraClubService.toDomainSong(this, id: id);
}

/// A parsed section from Cifra Club.
class CifraClubSection implements ScrapedSongSection {
  const CifraClubSection({
    required this.name,
    required this.lyrics,
    required this.chords,
    required this.rawContent,
    this.repeatCount = 1,
  });

  /// Section heading (e.g. "Intro", "Primera Parte", "Estribillo 1", "Puente").
  @override
  final String name;

  /// Pure lyrics text for this section.
  @override
  final String lyrics;

  /// Ordered list of chord names appearing in this section.
  @override
  final List<String> chords;

  /// Raw text content of this section with bracketed chord annotations.
  @override
  final String rawContent;

  @override
  final int repeatCount;
}

/// Production-ready service that fetches and extracts Cifra Club songs.
class CifraClubService {
  CifraClubService({HttpClient? httpClient})
      : _client = httpClient ?? HttpClient();

  final HttpClient _client;

  /// Standard browser headers required to bypass Akamai/Cloudflare bot protection.
  static const Map<String, String> defaultBrowserHeaders = {
    'accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'accept-language': 'es-US,es;q=0.9,en-US;q=0.8,en;q=0.7',
    'sec-ch-ua':
        '"Not:A-Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"macOS"',
    'sec-fetch-dest': 'document',
    'sec-fetch-mode': 'navigate',
    'sec-fetch-site': 'none',
    'sec-fetch-user': '?1',
    'upgrade-insecure-requests': '1',
    'user-agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  /// Normalizes any input [songIdOrUrl] into a clean Cifra Club path.
  ///
  /// Examples:
  /// - `'la-ibi/santo-por-siempre/'` -> `'la-ibi/santo-por-siempre/'`
  /// - `'la-ibi/santo-por-siempre'` -> `'la-ibi/santo-por-siempre/'`
  /// - `'https://www.cifraclub.com/la-ibi/santo-por-siempre/'` -> `'la-ibi/santo-por-siempre/'`
  static String normalizeSongPath(String songIdOrUrl) {
    var cleaned = songIdOrUrl.trim();
    if (cleaned.startsWith('https://www.cifraclub.com/')) {
      cleaned = cleaned.substring('https://www.cifraclub.com/'.length);
    } else if (cleaned.startsWith('http://www.cifraclub.com/')) {
      cleaned = cleaned.substring('http://www.cifraclub.com/'.length);
    } else if (cleaned.startsWith('www.cifraclub.com/')) {
      cleaned = cleaned.substring('www.cifraclub.com/'.length);
    }

    // Strip leading slash
    while (cleaned.startsWith('/')) {
      cleaned = cleaned.substring(1);
    }

    // Ensure trailing slash
    if (!cleaned.endsWith('/')) {
      cleaned = '$cleaned/';
    }

    return cleaned;
  }

  /// Replays the request directly from the mobile device for the given [songIdOrUrl].
  Future<CifraClubParsedSong> fetchSong(String songIdOrUrl) async {
    final cleanPath = normalizeSongPath(songIdOrUrl);
    final targetUri = Uri.parse('https://www.cifraclub.com/$cleanPath');

    final request = await _client.getUrl(targetUri);
    for (final entry in defaultBrowserHeaders.entries) {
      request.headers.set(entry.key, entry.value);
    }

    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Failed to fetch from Cifra Club (${response.statusCode} ${response.reasonPhrase})',
        uri: targetUri,
      );
    }

    final htmlContent = await response.transform(utf8.decoder).join();
    return parseHtml(htmlContent);
  }

  /// Parses raw Cifra Club HTML content into a [CifraClubParsedSong].
  static CifraClubParsedSong parseHtml(String htmlContent) {
    // 1. Extract Title and Artist (prefer JSON-LD schema, fallback to <title>)
    String title = 'Unknown Title';
    String artist = 'Unknown Artist';

    final jsonLdMatches = RegExp(
      r'<script type="application/ld\+json">(.*?)</script>',
      dotAll: true,
    ).allMatches(htmlContent);

    for (final match in jsonLdMatches) {
      try {
        final data = jsonDecode(match.group(1)!);
        if (data is Map<String, dynamic>) {
          if (data['@type'] == 'MusicComposition' && data['name'] != null) {
            title = data['name'].toString().trim();
          }
          if (data['byArtist'] is Map && data['byArtist']['name'] != null) {
            artist = data['byArtist']['name'].toString().trim();
          }
        }
      } catch (_) {}
    }

    if (title == 'Unknown Title') {
      final titleTag = RegExp(
        r'<title>(.*?)(?:\s*\(acordes\))?\s*-\s*(.*?)\s*-\s*Cifra Club</title>',
        caseSensitive: false,
      ).firstMatch(htmlContent);

      if (titleTag != null) {
        title = titleTag.group(1)?.trim() ?? title;
        artist = titleTag.group(2)?.trim() ?? artist;
      }
    }

    // 2. Extract Musical Key (Tom)
    String key = 'C';
    final keyMatch = RegExp(r'keyShape[^\w]+([A-G][b#]?[m]?)').firstMatch(htmlContent);
    if (keyMatch != null) {
      key = keyMatch.group(1)!;
    }

    // 3. Extract BPM / Tempo
    int? bpm;
    final bpmMatch = RegExp(r'bpm[^\d]+(\d+)').firstMatch(htmlContent);
    if (bpmMatch != null) {
      bpm = int.tryParse(bpmMatch.group(1)!);
    }

    // 4. Extract Capo
    int capo = 0;
    final capoMatch = RegExp(r'capo[^\d]+(\d+)').firstMatch(htmlContent);
    if (capoMatch != null) {
      capo = int.tryParse(capoMatch.group(1)!) ?? 0;
    }

    // 5. Extract Tuning
    String tuning = 'E A D G B E';
    final tuningMatch = RegExp(r'tuning[^A-Za-z0-9]+([A-G](?:\s+[A-G])+)')
        .firstMatch(htmlContent);
    if (tuningMatch != null) {
      tuning = tuningMatch.group(1)!.trim();
    }

    // 6. Extract Pre Content (Chords & Lyrics)
    final preMatch = RegExp(
      r'<pre[^>]*data-chord-content="true"[^>]*>(.*?)</pre>',
      dotAll: true,
    ).firstMatch(htmlContent);

    final rawPre = preMatch?.group(1) ?? '';

    // Extract all unique chords used
    final chordRegex = RegExp(r'<b[^>]*data-chord-name="([^"]+)"[^>]*>');
    final chordsFound = <String>{};
    for (final m in chordRegex.allMatches(rawPre)) {
      final chord = m.group(1);
      if (chord != null && chord.isNotEmpty) {
        chordsFound.add(chord);
      }
    }

    // Unescape HTML entities & strip zero-width spaces
    final cleanPre = rawPre
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll('\u200b', '');

    // Format plain visual chord sheet: <b ...>CHORD</b> -> CHORD
    final plainText = cleanPre
        .replaceAllMapped(RegExp(r'<b[^>]*>(.*?)</b>'), (m) => m.group(1) ?? '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .trim();

    // Format bracketed ChordPro text: <b ...>CHORD</b> -> [CHORD]
    final bracketedText = cleanPre
        .replaceAllMapped(RegExp(r'<b[^>]*>(.*?)</b>'), (m) => '[${m.group(1)}]')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .trim();

    final sections = _parseSections(bracketedText);

    return CifraClubParsedSong(
      title: title,
      artist: artist,
      key: key,
      bpm: bpm,
      capo: capo,
      tuning: tuning,
      chordsUsed: chordsFound.toList(),
      sections: sections,
      plainText: plainText,
      chordProText: bracketedText,
    );
  }

  /// Parses bracketed text into logical sections.
  static List<CifraClubSection> _parseSections(String text) {
    final lines = text.split('\n');
    final sections = <CifraClubSection>[];

    String currentName = 'Intro';
    final currentLines = <String>[];

    // Matches standalone section headers e.g. "[Primera Parte]" or inline headers "[Intro] [C] [Em]"
    final headerPrefixRegex = RegExp(
      r'^\s*\[([a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s\-_]+)\](?:\s*(.*))?$',
    );
    // Matches musical chords starting with A-G
    final chordExtractRegex = RegExp(r'\[([A-G][b#]?[^\]]*)\]');

    void commitSection() {
      if (currentLines.isEmpty) return;
      final content = currentLines.join('\n').trim();

      // Extract chords appearing in this section
      final chords = <String>[];
      for (final match in chordExtractRegex.allMatches(content)) {
        final c = match.group(1)?.trim();
        if (c != null && c.isNotEmpty && !chords.contains(c)) {
          chords.add(c);
        }
      }

      // Extract pure lyrics (strip [Chords])
      final lyrics = content.replaceAll(chordExtractRegex, '').trim();

      sections.add(CifraClubSection(
        name: currentName,
        lyrics: lyrics,
        chords: chords,
        rawContent: content,
      ));
      currentLines.clear();
    }

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      final headerMatch = headerPrefixRegex.firstMatch(line);

      // Distinguish section header from standalone chord like "[G]"
      final potentialHeader = headerMatch?.group(1)?.trim();
      final isSectionName = potentialHeader != null &&
          (potentialHeader.length > 3 ||
              !RegExp(r'^[A-G][b#]?(?:m|maj|dim|aug|sus|add|\d|\/)*$')
                  .hasMatch(potentialHeader));

      if (headerMatch != null && isSectionName) {
        commitSection();
        currentName = potentialHeader;
        final remainder = headerMatch.group(2)?.trim();
        if (remainder != null && remainder.isNotEmpty) {
          currentLines.add(remainder);
        }
      } else {
        currentLines.add(line);
      }
    }

    commitSection();
    return sections;
  }

  /// Converts a [CifraClubParsedSong] into Battuta's domain [Song] entity.
  static Song toDomainSong(
    CifraClubParsedSong parsed, {
    String? id,
    List<String> tags = const ['cifraclub', 'worship'],
  }) {
    final now = DateTime.now();
    final songId = id ?? 'cifra_${now.millisecondsSinceEpoch}';

    final songSections = <SongSection>[];
    for (var i = 0; i < parsed.sections.length; i++) {
      final s = parsed.sections[i];

      final chordCells = s.chords.map((chordName) {
        return _parseChordCell(chordName);
      }).toList();

      songSections.add(SongSection(
        id: '${songId}_sec_$i',
        name: s.name,
        chords: chordCells,
        lyrics: s.lyrics.isEmpty ? null : s.lyrics,
        rehearsalNotes: s.rawContent,
        orderIndex: i,
      ));
    }

    final notes = StringBuffer();
    if (parsed.capo > 0) {
      notes.writeln('Capo: Traste ${parsed.capo}');
    }
    if (parsed.tuning != 'E A D G B E') {
      notes.writeln('Afinación: ${parsed.tuning}');
    }

    return Song(
      id: songId,
      title: parsed.title,
      artist: parsed.artist,
      key: parsed.key,
      tempo: parsed.bpm ?? 70,
      timeSignature: const (4, 4),
      sections: songSections,
      tags: tags,
      notes: notes.isEmpty ? null : notes.toString().trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  static ChordCell _parseChordCell(String chordName) {
    var trimmed = chordName.trim();
    String? bass;

    if (trimmed.contains('/')) {
      final parts = trimmed.split('/');
      trimmed = parts[0];
      bass = parts.length > 1 ? parts[1] : null;
    }

    // Match root: e.g. C, C#, Bb
    final rootMatch = RegExp(r'^([A-G][b#]?)').firstMatch(trimmed);
    if (rootMatch == null) {
      return ChordCell(
        root: 'C',
        quality: ChordQuality.custom,
        customLabel: chordName,
      );
    }

    final root = rootMatch.group(1)!;
    final suffix = trimmed.substring(root.length);

    ChordQuality quality = ChordQuality.major;
    if (suffix == 'm') {
      quality = ChordQuality.minor;
    } else if (suffix == '7') {
      quality = ChordQuality.dominant7;
    } else if (suffix == 'm7') {
      quality = ChordQuality.minor7;
    } else if (suffix == 'maj7' || suffix == 'M7') {
      quality = ChordQuality.major7;
    } else if (suffix == 'dim' || suffix == '°') {
      quality = ChordQuality.diminished;
    } else if (suffix == 'aug' || suffix == '+') {
      quality = ChordQuality.augmented;
    } else if (suffix == 'sus2') {
      quality = ChordQuality.sus2;
    } else if (suffix == 'sus4' || suffix == 'sus') {
      quality = ChordQuality.sus4;
    } else if (suffix.isNotEmpty) {
      quality = ChordQuality.custom;
    }

    return ChordCell(
      root: root,
      quality: quality,
      bass: bass,
      customLabel: quality == ChordQuality.custom ? chordName : null,
    );
  }
}
