/// Battuta — Chord-Over-Lyrics Domain Entity & ChordPro Parser.
///
/// Models lyric lines with word-aligned chord annotations and provides
/// robust bidirectional parsing between formatted ChordPro bracket notation
/// (e.g. `"[G]Amazing [C]grace how [G]sweet the sound"`) and tokenized
/// lines suitable for responsive stage rendering and karaoke alignment.
library;

import 'package:equatable/equatable.dart';

/// Represents a single word or syllable token in a lyric line, optionally
/// accompanied by an attached chord symbol positioned directly above it.
class ChordLyricToken extends Equatable {
  const ChordLyricToken({
    required this.word,
    this.chord,
    this.trailingSpace = true,
  });

  /// The musical chord symbol placed directly over this word (e.g. `"G"`, `"Am7"`, `"D/F#"`),
  /// or `null` if no chord changes at this specific word.
  final String? chord;

  /// The lyric word, syllable, or punctuation token (e.g. `"Amazing"`, `"grace"`).
  final String word;

  /// Whether a trailing space follows this token when rendered in a line.
  final bool trailingSpace;

  /// Whether this token carries an active chord symbol.
  bool get hasChord => chord != null && chord!.trim().isNotEmpty;

  /// Creates a copy of this token with the given fields replaced.
  ChordLyricToken copyWith({
    String? word,
    String? chord,
    bool? trailingSpace,
    bool clearChord = false,
  }) {
    return ChordLyricToken(
      word: word ?? this.word,
      chord: clearChord ? null : (chord ?? this.chord),
      trailingSpace: trailingSpace ?? this.trailingSpace,
    );
  }

  @override
  List<Object?> get props => [word, chord, trailingSpace];

  @override
  String toString() => hasChord ? '[$chord]$word' : word;
}

/// Represents an entire line of lyrics with its constituent [ChordLyricToken]s.
class ChordLyricLine extends Equatable {
  const ChordLyricLine({
    required this.tokens,
  });

  /// Ordered tokens forming this line.
  final List<ChordLyricToken> tokens;

  /// Whether any token in this line has a chord assigned.
  bool get hasChords => tokens.any((t) => t.hasChord);

  /// Pure text content of this line with chord tags stripped.
  String get rawLyrics {
    final buffer = StringBuffer();
    for (final token in tokens) {
      buffer.write(token.word);
      if (token.trailingSpace) buffer.write(' ');
    }
    return buffer.toString().trimRight();
  }

  /// Formatted ChordPro string for this line.
  String toChordPro() {
    final buffer = StringBuffer();
    for (final token in tokens) {
      if (token.hasChord) {
        buffer.write('[${token.chord!.trim()}]');
      }
      buffer.write(token.word);
      if (token.trailingSpace) buffer.write(' ');
    }
    return buffer.toString().trimRight();
  }

  @override
  List<Object?> get props => [tokens];
}

/// Parser and serializer for ChordPro formatted lyrics and karaoke alignments.
class ChordLyricsParser {
  const ChordLyricsParser._();

  static final RegExp _bracketChordRegex = RegExp(r'\[([^\]]+)\]');

  /// Determines whether [text] contains ChordPro-style bracketed chord annotations.
  static bool hasChordPro(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    return _bracketChordRegex.hasMatch(text);
  }

  /// Strips all `[Chord]` tags from [text], returning pure lyrics.
  static String stripChords(String text) {
    return text.replaceAll(_bracketChordRegex, '');
  }

  /// Extracts all chord symbols found in bracket notation (e.g. `"[G]...[C]"`) in order.
  static List<String> extractChords(String? text) {
    if (text == null || text.trim().isEmpty) return const [];
    return _bracketChordRegex
        .allMatches(text)
        .map((m) => m.group(1)?.trim() ?? '')
        .where((c) => c.isNotEmpty)
        .toList();
  }

  /// Parses a multi-line ChordPro or plain text string into structured [ChordLyricLine]s.
  ///
  /// Handles:
  /// - Standard ChordPro inline chords: `"[G]Amazing [C]grace"`
  /// - Chords mid-word: `"a[D]mazing"`
  /// - Standalone chord lines: `"[G]  [C]  [D]"`
  /// - Plain lyrics without chords: `"Amazing grace how sweet the sound"`
  static List<ChordLyricLine> parse(String? rawText) {
    if (rawText == null || rawText.trim().isEmpty) {
      return const [];
    }

    final rawLines = rawText.split(RegExp(r'\r?\n'));
    final result = <ChordLyricLine>[];

    for (final line in rawLines) {
      final trimmedLine = line.trimRight();
      if (trimmedLine.isEmpty) {
        result.add(const ChordLyricLine(tokens: []));
        continue;
      }

      result.add(_parseLine(trimmedLine));
    }

    return result;
  }

  static ChordLyricLine _parseLine(String line) {
    final tokens = <ChordLyricToken>[];

    // Regex to split line into segments of chord tags or word characters/whitespace
    // Matches either [Chord] or chunks of non-bracket characters
    final segmentRegex = RegExp(r'(\[[^\]]+\]|[^\[]+)');
    final matches = segmentRegex.allMatches(line);

    String? pendingChord;

    for (final match in matches) {
      final text = match.group(0)!;

      if (text.startsWith('[') && text.endsWith(']')) {
        // Chord tag
        final chordName = text.substring(1, text.length - 1).trim();
        if (chordName.isNotEmpty) {
          pendingChord = chordName;
        }
      } else {
        // Lyric text chunk
        // Break this text chunk into words while preserving spaces
        final words = text.split(' ');
        for (var i = 0; i < words.length; i++) {
          final word = words[i];
          final isLastWordInChunk = i == words.length - 1;
          final trailingSpace = !isLastWordInChunk;

          if (word.isNotEmpty) {
            tokens.add(
              ChordLyricToken(
                word: word,
                chord: pendingChord,
                trailingSpace: trailingSpace,
              ),
            );
            pendingChord = null;
          } else if (pendingChord != null && isLastWordInChunk) {
            // Chord stood alone with trailing space
            tokens.add(
              ChordLyricToken(
                word: '',
                chord: pendingChord,
                trailingSpace: true,
              ),
            );
            pendingChord = null;
          }
        }
      }
    }

    // Trailing chord at the very end of the line
    if (pendingChord != null) {
      tokens.add(
        ChordLyricToken(
          word: '',
          chord: pendingChord,
          trailingSpace: false,
        ),
      );
    }

    return ChordLyricLine(tokens: tokens);
  }

  /// Serializes a list of [ChordLyricLine]s back into standard ChordPro text.
  static String toChordPro(List<ChordLyricLine> lines) {
    return lines.map((line) => line.toChordPro()).join('\n');
  }

  /// Automatically distributes a list of [chords] evenly across the words in [plainLyrics],
  /// creating an intelligent starting point for karaoke alignment.
  static String autoDistribute({
    required String plainLyrics,
    required List<String> chords,
  }) {
    if (chords.isEmpty) return plainLyrics;

    final cleanText = stripChords(plainLyrics);
    final lines = cleanText.split(RegExp(r'\r?\n'));
    final totalWords = cleanText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;

    if (totalWords == 0) return plainLyrics;

    final chordInterval = (totalWords / chords.length).clamp(1.0, 999.0);
    var chordIndex = 0;
    var wordCounter = 0;

    final outputLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        outputLines.add('');
        continue;
      }

      final words = trimmed.split(RegExp(r'\s+'));
      final lineTokens = <String>[];

      for (var i = 0; i < words.length; i++) {
        final word = words[i];
        if (word.isEmpty) continue;

        // Check if next chord falls on this word
        final targetWordIndex = (chordIndex * chordInterval).floor();
        if (wordCounter >= targetWordIndex && chordIndex < chords.length) {
          lineTokens.add('[${chords[chordIndex]}]$word');
          chordIndex++;
        } else {
          lineTokens.add(word);
        }
        wordCounter++;
      }

      outputLines.add(lineTokens.join(' '));
    }

    return outputLines.join('\n');
  }
}
