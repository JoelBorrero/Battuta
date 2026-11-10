/// Battuta — LaCuerda Service.
///
/// Fetches, parses, and converts plain-text chord charts from LaCuerda
/// (`acordes.lacuerda.net` / `lacuerda.net`) into Battuta [Song] domain entities.
///
/// Workflow:
/// Given a song URL like `https://acordes.lacuerda.net/coalo_zamorano/por_quien_eres_tu-5.shtml`,
/// this service fetches the raw plain-text tab from:
/// `https://acordes.lacuerda.net/TXT/coalo_zamorano/por_quien_eres_tu-5.txt`,
/// extracts metadata, converts Spanish/Solfège chords if present to Anglo-Saxon,
/// aligns chords over lyrics into ChordPro format, and produces a structured [Song].
library;

import 'dart:convert';
import 'dart:io';

import 'package:battuta/features/repertoire/data/datasources/scraped_song_result.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/services/song_text_parser.dart';
import 'package:battuta/features/repertoire/domain/services/song_transposer.dart';
import 'package:uuid/uuid.dart';

/// A parsed section from LaCuerda.
class LaCuerdaSection implements ScrapedSongSection {
  const LaCuerdaSection({
    required this.name,
    required this.lyrics,
    required this.chords,
    required this.rawContent,
    this.repeatCount = 1,
  });

  @override
  final String name;

  @override
  final String lyrics;

  @override
  final List<String> chords;

  @override
  final String rawContent;

  @override
  final int repeatCount;
}

/// Structured song data parsed from a LaCuerda TXT response.
class LaCuerdaParsedSong implements ScrapedSongResult {
  const LaCuerdaParsedSong({
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
    this.author,
    this.album,
    this.transcriber,
  });

  @override
  SupportedUrlProvider get provider => SupportedUrlProvider.laCuerda;

  @override
  final String title;

  @override
  final String artist;

  @override
  final String key;

  @override
  final int? bpm;

  @override
  final int capo;

  @override
  final String tuning;

  @override
  final List<String> chordsUsed;

  @override
  final List<LaCuerdaSection> sections;

  @override
  final String plainText;

  @override
  final String chordProText;

  /// Original author credited on LaCuerda.
  final String? author;

  /// Album name if provided in header.
  final String? album;

  /// Transcriber name credited on LaCuerda.
  final String? transcriber;

  @override
  Song toSong({String? id}) => LaCuerdaService.toDomainSong(this, id: id);
}

/// Production-ready service that fetches and extracts songs from LaCuerda.
class LaCuerdaService {
  LaCuerdaService({HttpClient? httpClient})
      : _client = httpClient ?? HttpClient();

  final HttpClient _client;
  static const _uuid = Uuid();

  /// Standard browser headers for LaCuerda plain-text requests.
  static const Map<String, String> _browserHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'text/plain,text/html,*/*',
    'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
  };

  /// Normalizes an input URL or slug into an artist/song path.
  ///
  /// Examples:
  /// - `https://acordes.lacuerda.net/coalo_zamorano/por_quien_eres_tu-5.shtml` -> `coalo_zamorano/por_quien_eres_tu-5`
  /// - `http://lacuerda.net/coalo_zamorano/por_quien_eres_tu-5.shtml` -> `coalo_zamorano/por_quien_eres_tu-5`
  /// - `https://acordes.lacuerda.net/TXT/coalo_zamorano/por_quien_eres_tu-5.txt` -> `coalo_zamorano/por_quien_eres_tu-5`
  /// - `coalo_zamorano/por_quien_eres_tu-5` -> `coalo_zamorano/por_quien_eres_tu-5`
  static String normalizeSongPath(String input) {
    var raw = input.trim();
    if (raw.isEmpty) {
      throw const FormatException('Empty URL provided');
    }

    // Scheme present
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final uri = Uri.tryParse(raw);
      if (uri != null) {
        var p = uri.path;
        if (p.toUpperCase().startsWith('/TXT/')) {
          p = p.substring(5);
        }
        p = p.replaceAll(
          RegExp(r'\.(shtml|html|txt)$', caseSensitive: false),
          '',
        );
        p = p.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+$'), '');
        if (p.isNotEmpty) return p;
      }
    }

    // Strip domain prefix without scheme: acordes.lacuerda.net/ or lacuerda.net/
    raw = raw.replaceFirst(
      RegExp(
        r'^(?:https?://)?(?:acordes\.)?lacuerda\.net/+',
        caseSensitive: false,
      ),
      '',
    );

    // Strip TXT/ prefix if provided
    if (raw.toUpperCase().startsWith('TXT/')) {
      raw = raw.substring(4);
    }

    // Strip file extensions
    raw = raw.replaceAll(
      RegExp(r'\.(shtml|html|txt)$', caseSensitive: false),
      '',
    );
    raw = raw.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+$'), '');

    if (raw.isEmpty) {
      throw const FormatException('Invalid LaCuerda URL or song path');
    }

    return raw;
  }

  /// Builds the direct plain-text URL for fetching from LaCuerda.
  ///
  /// `https://acordes.lacuerda.net/TXT/<artist>/<song>.txt`
  static String buildTxtUrl(String input) {
    final path = normalizeSongPath(input);
    return 'https://acordes.lacuerda.net/TXT/$path.txt';
  }

  /// Fetches raw plain-text file from LaCuerda.
  Future<String> fetchRawTab(String urlOrSlug) async {
    final txtUrl = buildTxtUrl(urlOrSlug);
    final uri = Uri.parse(txtUrl);

    try {
      final request = await _client.getUrl(uri);
      _browserHeaders.forEach(request.headers.set);

      final response = await request.close();

      if (response.statusCode == 404) {
        throw const HttpException(
          'Song not found on LaCuerda (404). Please verify the song URL or ID.',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'LaCuerda server returned error HTTP ${response.statusCode}',
        );
      }

      final bytes = await response.fold<List<int>>(
        <int>[],
        (buffer, data) => buffer..addAll(data),
      );

      // Attempt UTF-8 first, fallback to Latin-1 if malformed
      try {
        return utf8.decode(bytes);
      } catch (_) {
        return latin1.decode(bytes);
      }
    } on SocketException catch (e) {
      throw HttpException('Network error connecting to LaCuerda: ${e.message}');
    }
  }

  /// Parses raw LaCuerda plain-text file into a structured [LaCuerdaParsedSong].
  static LaCuerdaParsedSong parseTxt(String rawTxt, {String? sourceUrl}) {
    if (rawTxt.trim().isEmpty) {
      throw const FormatException('LaCuerda text content is empty');
    }

    // 1. Extract metadata from header box
    final artistMatch = RegExp(
      r'\|\s*ARTISTA\s*:\s*([^|\r\n]+)',
      caseSensitive: false,
    ).firstMatch(rawTxt);
    final songMatch = RegExp(
      r'\|\s*CANCION\s*:\s*([^|\r\n]+)',
      caseSensitive: false,
    ).firstMatch(rawTxt);
    final authorMatch = RegExp(
      r'\|\s*AUTOR\s*:\s*([^|\r\n]+)',
      caseSensitive: false,
    ).firstMatch(rawTxt);
    final albumMatch = RegExp(
      r'\|\s*ALBUM\s*:\s*([^|\r\n]+)',
      caseSensitive: false,
    ).firstMatch(rawTxt);
    final transMatch = RegExp(
      r'\|\s*TRANS\s*:\s*([^|\r\n]+)',
      caseSensitive: false,
    ).firstMatch(rawTxt);

    final artist = artistMatch?.group(1)?.trim() ?? 'Unknown Artist';
    final rawTitle = songMatch?.group(1)?.trim() ?? 'Untitled Song';
    final title = toTitleCase(rawTitle);

    final author = _cleanHeaderField(authorMatch?.group(1));
    final album = _cleanHeaderField(albumMatch?.group(1));
    final transcriber = _cleanHeaderField(transMatch?.group(1));

    // 2. Strip header box (everything up to closing ========)
    var body = rawTxt.replaceFirst(RegExp(r'={10,}[\s\S]*?={10,}\r?\n*'), '');

    // 3. Strip footer disclaimer (lacuerda.net box at end)
    final footerIdx = body.indexOf(
      RegExp(r'={10,}\s*lacuerda\.net', caseSensitive: false),
    );
    if (footerIdx != -1) {
      body = body.substring(0, footerIdx);
    }

    // 4. Detect explicit key (Tono / Tonalidad)
    String? explicitKey;
    final keyMatch = RegExp(
      r'(?:tono|tonalidad|key)\s*[:=]\s*([A-Ga-g][#b]?m?|(?:DO|RE|MI|FA|SOL|LA|SI)[#b]?m?)',
      caseSensitive: false,
    ).firstMatch(body);
    if (keyMatch != null) {
      explicitKey = convertSolfegeToAnglo(keyMatch.group(1)!.trim());
    }

    // 5. Pre-process chord lines: convert Solfège chords to Anglo-Saxon
    final lines = body.split(RegExp(r'\r?\n'));
    final processedLines = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isSolfegeChordLine(line)) {
        processedLines.add(convertSolfegeLine(line));
      } else {
        processedLines.add(line);
      }
    }

    // 6. Clean repeat markings like /// or // from within lyrics (e.g. "///Jehova Jireh" or "eres Tu///")
    // while preserving standard comment markers (// Metadata or // Section)
    final cleanedLines = <String>[];
    for (final line in processedLines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('//') &&
          (trimmed.contains(':') ||
              RegExp(
                r'//\s*(?:intro|verse|verso|estrofa|chorus|coro|estribillo|bridge|puente|pre|inter|solo|outro|final|coda)',
                caseSensitive: false,
              ).hasMatch(trimmed))) {
        cleanedLines.add(line);
      } else {
        cleanedLines.add(line.replaceAll(RegExp(r'/{2,}'), ''));
      }
    }
    final cleanedBody = cleanedLines.join('\n');

    // 7. Parse with SongTextParser
    final cleanInput = '// Title: $title\n// Artist: $artist\n${cleanedBody.trim()}';
    final baseSong = SongTextParser.parse(
      rawText: cleanInput,
      defaultKey: explicitKey ?? 'C',
    );

    // 8. Determine Key if not explicit
    var finalKey = explicitKey ?? baseSong.key;
    if (explicitKey == null) {
      for (final sec in baseSong.sections) {
        if (sec.chords.isNotEmpty) {
          final firstRoot = sec.chords.first.root;
          if (firstRoot.isNotEmpty) {
            finalKey = firstRoot;
            break;
          }
        }
      }
    }

    // 9. Map sections and detect repeat counts (from /// in raw text)
    final allChords = <String>{};
    final sections = <LaCuerdaSection>[];

    for (final s in baseSong.sections) {
      final chordNames = s.chords.map((c) => c.displayLabel).toList();
      allChords.addAll(chordNames);

      // Check if original section had repeat markings (/// -> 3x, // -> 2x)
      var repeatCount = s.repeatCount;
      if (repeatCount == 1 && body.contains(RegExp(r'/{3,}'))) {
        if (s.name.toLowerCase().contains('chorus') ||
            s.name.toLowerCase().contains('coro')) {
          repeatCount = 3;
        }
      }

      final cleanLyrics = s.lyrics != null
          ? s.lyrics!
              .replaceAll(RegExp(r'\[[^\]]+\]'), '')
              .split('\n')
              .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
              .join('\n')
              .trim()
          : '';

      sections.add(
        LaCuerdaSection(
          name: s.name,
          lyrics: cleanLyrics,
          chords: chordNames,
          rawContent: s.lyrics ?? '',
          repeatCount: repeatCount,
        ),
      );
    }

    return LaCuerdaParsedSong(
      title: title,
      artist: artist,
      key: finalKey,
      bpm: baseSong.tempo != 120 ? baseSong.tempo : null,
      capo: 0,
      tuning: 'E A D G B E',
      chordsUsed: allChords.toList(),
      sections: sections,
      plainText: body.trim(),
      chordProText: sections
          .map((s) => s.rawContent)
          .where((l) => l.isNotEmpty)
          .join('\n\n'),
      author: author,
      album: album,
      transcriber: transcriber,
    );
  }

  /// Fetches from LaCuerda and returns a parsed [LaCuerdaParsedSong].
  Future<LaCuerdaParsedSong> fetchSong(String urlOrSlug) async {
    final rawTxt = await fetchRawTab(urlOrSlug);
    return parseTxt(rawTxt, sourceUrl: urlOrSlug);
  }

  /// Converts a [LaCuerdaParsedSong] into a Battuta domain [Song] entity.
  static Song toDomainSong(LaCuerdaParsedSong parsed, {String? id}) {
    final now = DateTime.now();

    final sections = parsed.sections.asMap().entries.map((entry) {
      final index = entry.key;
      final sec = entry.value;

      final chords = sec.chords.map((name) {
        final parsedCell = ChordParser.parseChord(name);
        return parsedCell ??
            ChordCell(root: name, quality: ChordQuality.custom, beats: 4);
      }).toList();

      return SongSection(
        id: _uuid.v4(),
        name: sec.name,
        chords: chords,
        lyrics: sec.rawContent.isNotEmpty
            ? sec.rawContent
            : (sec.lyrics.isNotEmpty ? sec.lyrics : null),
        repeatCount: sec.repeatCount,
        orderIndex: index,
      );
    }).toList();

    final tags = <String>[];
    if (parsed.album != null && parsed.album!.isNotEmpty) {
      tags.add(parsed.album!);
    }

    final notes = <String>[];
    if (parsed.author != null && parsed.author!.isNotEmpty) {
      notes.add('Author: ${parsed.author}');
    }
    if (parsed.transcriber != null && parsed.transcriber!.isNotEmpty) {
      notes.add('Transcribed by: ${parsed.transcriber}');
    }

    return Song(
      id: id ?? _uuid.v4(),
      title: parsed.title,
      artist: parsed.artist,
      key: parsed.key,
      tempo: parsed.bpm ?? 120,
      timeSignature: (4, 4),
      sections: sections,
      tags: tags,
      notes: notes.isNotEmpty ? notes.join('\n') : null,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS: Solfège Translation & Formatting
  // ═══════════════════════════════════════════════════════════════════════════

  static const Map<String, String> _solfegeMap = {
    'DO': 'C',
    'RE': 'D',
    'MI': 'E',
    'FA': 'F',
    'SOL': 'G',
    'LA': 'A',
    'SI': 'B',
  };

  static final RegExp _solfegeChordRegex = RegExp(
    r'^(DO|RE|MI|FA|SOL|LA|SI)(#|b)?(m|min|maj|maj7|M|M7|7|9|11|13|sus|sus2|sus4|dim|aug|\+|2|4|5|6|\(add\d+\)|add\d+)?(?:/(DO|RE|MI|FA|SOL|LA|SI)(#|b)?)?$',
    caseSensitive: false,
  );

  /// Converts a single Solfège chord token (e.g. "SOLmaj7", "LA/DO#", "SIm7") to Anglo-Saxon.
  static String convertSolfegeToAnglo(String chord) {
    final solfegeRegex = RegExp(
      r'(?<=\b|/)(DO|RE|MI|FA|SOL|LA|SI)(?=[#b]?m?[0-9a-zA-Z]*)',
      caseSensitive: false,
    );

    return chord.replaceAllMapped(solfegeRegex, (match) {
      final root = match.group(1)!.toUpperCase();
      return _solfegeMap[root] ?? match.group(0)!;
    });
  }

  /// Determines whether a line is a chord line written in Solfège notation.
  static bool _isSolfegeChordLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;

    // Check if line contains parentheses comments like (ACORDES ORIGINALES DE LA GRABACION)
    if (trimmed.startsWith('(') && trimmed.endsWith(')')) return false;

    final tokens = trimmed.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return false;

    var chordCount = 0;
    for (final token in tokens) {
      final clean = token.replaceAll(RegExp(r'[(),]'), '');
      if (clean == '/' || clean == '-' || clean == '|') {
        chordCount++;
        continue;
      }
      if (_solfegeChordRegex.hasMatch(clean)) {
        chordCount++;
      }
    }

    return (chordCount / tokens.length) >= 0.6;
  }

  /// Replaces Solfège chords in a chord line with standard Anglo-Saxon chords.
  static String convertSolfegeLine(String line) {
    return line.replaceAllMapped(
      RegExp(
        r'(?<=\b|/)(DO|RE|MI|FA|SOL|LA|SI)(?=[#b]?(?:m|min|maj|sus|dim|aug|\d|\(add|\+|$|\s|/))',
        caseSensitive: false,
      ),
      (match) {
        final root = match.group(1)!.toUpperCase();
        return _solfegeMap[root] ?? match.group(0)!;
      },
    );
  }

  /// Converts ALL CAPS titles to Title Case.
  static String toTitleCase(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed != trimmed.toUpperCase()) return trimmed; // Already mixed case

    final words = trimmed.toLowerCase().split(RegExp(r'\s+'));
    final titleWords = words.map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).toList();
    return titleWords.join(' ');
  }

  static String? _cleanHeaderField(String? val) {
    if (val == null) return null;
    final t = val.trim();
    if (t.isEmpty || t == '-?-') return null;
    return t;
  }
}

