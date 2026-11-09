/// Battuta — Song Text Parser.
///
/// Parses plain text, clipboard lead sheets, and ChordPro notations into
/// structured [Song] entities. Recognizes `//` comments as section delimiters
/// (e.g. `// Verse 1`, `// Chorus`, `// Puente`), metadata annotations, and
/// handles both bracketed ChordPro tags and two-line chords-over-lyrics.
library;

import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_lyric_line.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/services/song_transposer.dart';
import 'package:uuid/uuid.dart';

class SongTextParser {
  const SongTextParser._();

  static const _uuid = Uuid();

  /// Known section keywords in English and Spanish.
  static final RegExp _sectionKeywordRegex = RegExp(
    r'\b(intro|verse|verso|estrofa|chorus|coro|estribillo|bridge|puente|pre-chorus|prechorus|pre-coro|precoro|interlude|interludio|instrumental|solo|outro|ending|final|tag|coda|vamp|hook|refrain|section|parte|part)\b',
    caseSensitive: false,
  );

  /// Metadata key-value pattern: `// Key: Value` or `Key: Value`.
  static final RegExp _metaLineRegex = RegExp(
    r'^(?://\s*)?(title|título|artist|artista|author|autor|key|tono|clave|tempo|bpm|time|compás|compas|tags|etiquetas)\s*[:=]\s*(.+)$',
    caseSensitive: false,
  );

  /// Parses plain text or clipboard content into a structured [Song].
  static Song parse({
    required String rawText,
    String? fallbackTitle,
    String? defaultKey,
  }) {
    final lines = rawText.split(RegExp(r'\r?\n'));

    String title = fallbackTitle ?? 'Untitled Song';
    String artist = 'Unknown Artist';
    String key = defaultKey ?? 'C';
    int tempo = 120;
    (int, int) timeSignature = (4, 4);
    final List<String> tags = [];
    String? songNotes;

    // Intermediate representation of sections
    final List<_RawSection> rawSections = [];
    _RawSection? currentSection;

    for (var i = 0; i < lines.length; i++) {
      final rawLine = lines[i];
      final trimmed = rawLine.trim();

      if (trimmed.isEmpty) {
        if (currentSection != null && currentSection.lines.isNotEmpty) {
          // Preserve empty line in current section
          currentSection.lines.add('');
        }
        continue;
      }

      // 1. Check for Metadata line (e.g. "// Title: ...", "Key: G")
      final metaMatch = _metaLineRegex.firstMatch(trimmed);
      if (metaMatch != null) {
        final field = metaMatch.group(1)!.toLowerCase();
        final value = metaMatch.group(2)!.trim();

        switch (field) {
          case 'title':
          case 'título':
            if (value.isNotEmpty) title = value;
          case 'artist':
          case 'artista':
          case 'author':
          case 'autor':
            if (value.isNotEmpty) artist = value;
          case 'key':
          case 'tono':
          case 'clave':
            if (value.isNotEmpty) key = value;
          case 'tempo':
          case 'bpm':
            final parsedTempo = int.tryParse(RegExp(r'\d+').firstMatch(value)?.group(0) ?? '');
            if (parsedTempo != null && parsedTempo > 0) tempo = parsedTempo;
          case 'time':
          case 'compás':
          case 'compas':
            final timeMatch = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(value);
            if (timeMatch != null) {
              final beats = int.tryParse(timeMatch.group(1)!) ?? 4;
              final beatVal = int.tryParse(timeMatch.group(2)!) ?? 4;
              timeSignature = (beats, beatVal);
            }
          case 'tags':
          case 'etiquetas':
            tags.addAll(value.split(RegExp(r'[,;]')).map((t) => t.trim()).where((t) => t.isNotEmpty));
        }
        continue;
      }

      // 2. Check for Section Header comment (// Verse 1, // Chorus, [Verse 1], Chorus:)
      final isDoubleSlashComment = trimmed.startsWith('//');
      final isBracketHeader = trimmed.startsWith('[') &&
          trimmed.endsWith(']') &&
          _sectionKeywordRegex.hasMatch(trimmed);
      final isColonHeader = trimmed.endsWith(':') && _sectionKeywordRegex.hasMatch(trimmed);

      if (isDoubleSlashComment || isBracketHeader || isColonHeader) {
        String headerContent;
        if (isDoubleSlashComment) {
          headerContent = trimmed.substring(2).trim();
        } else if (isBracketHeader) {
          headerContent = trimmed.substring(1, trimmed.length - 1).trim();
        } else {
          headerContent = trimmed.substring(0, trimmed.length - 1).trim();
        }

        // If it's a double slash comment but does NOT contain any section keywords,
        // treat it as a rehearsal note or comment for the current section!
        final hasSectionKeyword = _sectionKeywordRegex.hasMatch(headerContent);
        if (isDoubleSlashComment && !hasSectionKeyword && rawSections.isNotEmpty) {
          final noteText = headerContent.replaceFirst(RegExp(r'^(?:note|nota)\s*[:=]\s*', caseSensitive: false), '').trim();
          if (noteText.isNotEmpty) {
            final existingNotes = currentSection?.rehearsalNotes;
            currentSection?.rehearsalNotes = (existingNotes != null && existingNotes.isNotEmpty)
                ? '$existingNotes\n$noteText'
                : noteText;
          }
          continue;
        }

        // Check repeat count inside comment e.g. "// Chorus (2x)" or "// Coro x2"
        int repeatCount = 1;
        final repeatMatch = RegExp(r'\(?(?:repeat|repite|x)?\s*(\d+)\s*(?:x|times|veces)?\)?', caseSensitive: false)
            .firstMatch(headerContent);
        if (repeatMatch != null) {
          final countVal = int.tryParse(repeatMatch.group(1)!);
          if (countVal != null && countVal > 0) {
            repeatCount = countVal;
          }
        }

        // Clean section name (e.g. "Verse 1", "Chorus", "Puente")
        String sectionName = headerContent
            .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
            .replaceAll(RegExp(r'x\s*\d+', caseSensitive: false), '')
            .trim();

        if (sectionName.isEmpty) {
          sectionName = 'Section ${rawSections.length + 1}';
        }

        currentSection = _RawSection(
          name: _standardizeSectionName(sectionName),
          repeatCount: repeatCount,
        );
        rawSections.add(currentSection);
        continue;
      }

      // Normal line within section
      currentSection ??= _RawSection(name: 'Verse 1');
      if (!rawSections.contains(currentSection)) {
        rawSections.add(currentSection);
      }
      currentSection.lines.add(rawLine);
    }

    // Fallback if no sections were parsed
    if (rawSections.isEmpty) {
      rawSections.add(_RawSection(name: 'Verse 1', lines: lines));
    }

    // Process raw lines of each section into ChordCells and lyrics
    final List<SongSection> parsedSections = [];
    for (var sIdx = 0; sIdx < rawSections.length; sIdx++) {
      final rawSec = rawSections[sIdx];
      final processed = _processSectionLines(rawSec.lines);

      parsedSections.add(
        SongSection(
          id: _uuid.v4(),
          name: rawSec.name,
          chords: processed.chords,
          lyrics: processed.lyricsChordPro.isNotEmpty ? processed.lyricsChordPro : null,
          rehearsalNotes: rawSec.rehearsalNotes,
          repeatCount: rawSec.repeatCount,
          orderIndex: sIdx,
        ),
      );
    }

    final now = DateTime.now();
    return Song(
      id: _uuid.v4(),
      title: title,
      artist: artist,
      key: key,
      tempo: tempo,
      timeSignature: timeSignature,
      sections: parsedSections,
      tags: tags,
      notes: songNotes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Capitalizes and normalizes recognized section names.
  static String _standardizeSectionName(String raw) {
    final lower = raw.toLowerCase().trim();

    // Check for Pre-Chorus first to avoid false positive on Chorus
    if (lower.contains('pre-chorus') || lower.contains('prechorus') || lower.contains('pre-coro') || lower.contains('precoro')) {
      return 'Pre-Chorus';
    }

    if (lower.contains('verse') || lower.contains('verso') || lower.contains('estrofa')) {
      final num = RegExp(r'\d+').firstMatch(lower)?.group(0) ?? '';
      return num.isNotEmpty ? 'Verse $num' : 'Verse 1';
    }

    if (lower.contains('chorus') || lower.contains('coro') || lower.contains('estribillo')) {
      final num = RegExp(r'\d+').firstMatch(lower)?.group(0) ?? '';
      return num.isNotEmpty ? 'Chorus $num' : 'Chorus';
    }

    if (lower.contains('bridge') || lower.contains('puente')) {
      final num = RegExp(r'\d+').firstMatch(lower)?.group(0) ?? '';
      return num.isNotEmpty ? 'Bridge $num' : 'Bridge';
    }

    if (lower.contains('intro')) return 'Intro';
    if (lower.contains('outro') || lower.contains('final') || lower.contains('ending')) return 'Outro';
    if (lower.contains('instrumental') || lower.contains('solo') || lower.contains('interlude') || lower.contains('interludio')) return 'Instrumental';
    if (lower.contains('tag') || lower.contains('coda') || lower.contains('vamp')) return 'Tag';

    // Capitalize first letter of each word
    final cleaned = raw.replaceAll(RegExp(r'[^\w\s\d]'), ' ').trim();
    if (cleaned.isEmpty) return 'Section';
    return cleaned.split(RegExp(r'\s+')).map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  /// Evaluates lines in a section:
  /// - Identifies ChordPro bracket notation (`[G]Amazing [C]grace`)
  /// - Identifies two-line Chords-Over-Lyrics and aligns them
  /// - Identifies pure chord progression lines (`G | C | Em | D`)
  static _SectionProcessingResult _processSectionLines(List<String> rawLines) {
    final List<ChordCell> sectionChords = [];
    final List<String> resultChordProLines = [];

    var i = 0;
    while (i < rawLines.length) {
      final currentLine = rawLines[i];
      final trimmed = currentLine.trim();

      if (trimmed.isEmpty) {
        resultChordProLines.add('');
        i++;
        continue;
      }

      // Check if line is already ChordPro format (e.g. "[G]Amazing [C]grace")
      if (ChordLyricsParser.hasChordPro(currentLine)) {
        resultChordProLines.add(trimmed);
        final chordsInLine = ChordLyricsParser.extractChords(trimmed);
        for (final chordStr in chordsInLine) {
          final cell = ChordParser.parseChord(chordStr);
          if (cell != null) sectionChords.add(cell);
        }
        i++;
        continue;
      }

      // Check if currentLine is a chord line
      final isCurrentChordLine = _isChordLine(currentLine);

      if (isCurrentChordLine) {
        // Parse chords from this line
        final chordsInLine = ChordParser.parseProgression(currentLine);
        sectionChords.addAll(chordsInLine);

        // Check if next line is a lyric line to merge into ChordPro
        if (i + 1 < rawLines.length) {
          final nextLine = rawLines[i + 1];
          final nextTrimmed = nextLine.trim();

          if (nextTrimmed.isNotEmpty && !_isChordLine(nextLine)) {
            // Merge two-line chords-over-lyrics into ChordPro
            final merged = _mergeChordsOverLyrics(currentLine, nextLine);
            resultChordProLines.add(merged);
            i += 2;
            continue;
          }
        }

        // Pure chord progression line (e.g. Intro "G | C | Em | D")
        resultChordProLines.add(trimmed);
        i++;
        continue;
      }

      // Plain lyric line without chords
      resultChordProLines.add(trimmed);
      i++;
    }

    return _SectionProcessingResult(
      chords: sectionChords,
      lyricsChordPro: resultChordProLines.join('\n').trim(),
    );
  }

  /// Determines if a line consists predominantly of chord symbols and separators.
  static bool _isChordLine(String line) {
    final tokens = line.trim().split(RegExp(r'[\s|,]+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return false;

    var chordCount = 0;
    for (final token in tokens) {
      if (token == '|' || token == '/' || token == '-' || token == '%') {
        chordCount++;
        continue;
      }
      final parsed = ChordParser.parseChord(token);
      if (parsed != null) {
        chordCount++;
      }
    }

    // If 75% or more tokens are valid chords or barlines, it's a chord line
    return (chordCount / tokens.length) >= 0.75;
  }

  /// Merges a chord line and an underlying lyric line into ChordPro format:
  /// `ChordLine: "G       C        Em"`
  /// `LyricLine: "Amazing grace how sweet"`
  /// `Result:    "[G]Amazing [C]grace how [Em]sweet"`
  static String _mergeChordsOverLyrics(String chordLine, String lyricLine) {
    // Collect chords and their start column indices
    final List<({int col, String chord})> chords = [];
    final chordRegex = RegExp(r'([A-Ga-g][#b]?(?:[^\s|,]*)?(?:/[A-Ga-g][#b]?)?)');
    for (final match in chordRegex.allMatches(chordLine)) {
      final chordStr = match.group(1)?.trim();
      if (chordStr != null && chordStr.isNotEmpty) {
        if (ChordParser.parseChord(chordStr) != null) {
          chords.add((col: match.start, chord: chordStr));
        }
      }
    }

    if (chords.isEmpty) return lyricLine.trim();

    final buffer = StringBuffer();
    var chordIdx = 0;

    for (var col = 0; col < lyricLine.length; col++) {
      while (chordIdx < chords.length && chords[chordIdx].col <= col) {
        buffer.write('[${chords[chordIdx].chord}]');
        chordIdx++;
      }
      buffer.write(lyricLine[col]);
    }

    // Append any chords that occurred after the end of the lyric text
    while (chordIdx < chords.length) {
      buffer.write(' [${chords[chordIdx].chord}]');
      chordIdx++;
    }

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Formats a [Song] into standard plain text with `//` section comments and ChordPro tags.
  static String toPlainText(Song song) {
    final buffer = StringBuffer();

    // Metadata lines
    buffer.writeln('// Title: ${song.title}');
    buffer.writeln('// Artist: ${song.artist}');
    buffer.writeln('// Key: ${song.key}');
    buffer.writeln('// Tempo: ${song.tempo}');
    final (beats, beatValue) = song.timeSignature;
    buffer.writeln('// Time: $beats/$beatValue');
    if (song.tags.isNotEmpty) {
      buffer.writeln('// Tags: ${song.tags.join(', ')}');
    }
    if (song.notes != null && song.notes!.trim().isNotEmpty) {
      buffer.writeln('// Notes: ${song.notes!.trim()}');
    }

    buffer.writeln();

    // Sections
    for (var i = 0; i < song.sections.length; i++) {
      final section = song.sections[i];
      final repeatSuffix = section.repeatCount > 1 ? ' (${section.repeatCount}x)' : '';
      buffer.writeln('// ${section.name}$repeatSuffix');

      if (section.rehearsalNotes != null && section.rehearsalNotes!.trim().isNotEmpty) {
        buffer.writeln('// Note: ${section.rehearsalNotes!.trim()}');
      }

      if (section.lyrics != null && section.lyrics!.trim().isNotEmpty) {
        buffer.writeln(section.lyrics!.trim());
      } else if (section.chords.isNotEmpty) {
        // Output chord progression if no lyrics
        buffer.writeln(section.chords.map((c) => c.displayLabel).join(' | '));
      }

      if (i < song.sections.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString().trim();
  }
}

class _RawSection {
  _RawSection({
    required this.name,
    this.repeatCount = 1,
    List<String>? lines,
  }) : lines = lines ?? [];

  final String name;
  final int repeatCount;
  String? rehearsalNotes;
  final List<String> lines;
}

class _SectionProcessingResult {
  const _SectionProcessingResult({
    required this.chords,
    required this.lyricsChordPro,
  });

  final List<ChordCell> chords;
  final String lyricsChordPro;
}
