/// Battuta — Vocal Lyric Syllable Tokenizer & Note Alignment Service.
///
/// Implements vocal prosody hyphenation, Spanish/Italian synalepha (sinalefa)
/// vowel elision across word boundaries, and 1:1 notehead-to-syllable mapping.
library;

import '../entities/measure.dart';
import '../entities/note_event.dart';

abstract final class LyricSyllableTokenizer {
  static const _vowels = {
    'a',
    'e',
    'i',
    'o',
    'u',
    'á',
    'é',
    'í',
    'ó',
    'ú',
    'ü',
    'y',
    'A',
    'E',
    'I',
    'O',
    'U',
    'Á',
    'É',
    'Í',
    'Ó',
    'Ú',
    'Ü',
    'Y',
  };

  /// Returns true if [char] is a vowel (including accented vowels and vocalic 'y').
  static bool isVowel(String char) => _vowels.contains(char);

  /// Splits [rawLyrics] into syllable tokens with trailing hyphens for intra-word
  /// syllables and automatic synalepha (sinalefa) vowel merger between adjacent words.
  ///
  /// Example:
  /// `"Glo-ria al Se-ñor"` -> `["Glo-", "ria al", "Se-", "ñor"]`
  /// `"A-la-ba-ré a mi Dios"` -> `["A-", "la-", "ba-", "ré a", "mi", "Dios"]`
  static List<String> tokenize(String rawLyrics, {bool handleSinalefa = true}) {
    final text = rawLyrics.trim();
    if (text.isEmpty) return const [];

    // 1. Split into words by whitespace
    final words = text.split(RegExp(r'\s+'));
    final rawSyllables = <_WordSyllable>[];

    for (final word in words) {
      // Check for explicit elision using ~ or _ between words within word token
      if (word.contains('~') || (word.contains('_') && !word.startsWith('_'))) {
        final merged = word.replaceAll(RegExp(r'[~_]'), ' ');
        rawSyllables.add(
          _WordSyllable(
            text: merged,
            isEndOfWord: true,
            isExplicitElision: true,
          ),
        );
      } else {
        _addWordSyllables(word, rawSyllables, isEndOfWord: true);
      }
    }

    if (!handleSinalefa || rawSyllables.length <= 1) {
      return rawSyllables.map((s) => s.text).toList();
    }

    // 2. Perform Sinalefa / Synalepha vowel elision across word boundaries
    final result = <String>[];
    var i = 0;

    while (i < rawSyllables.length) {
      final current = rawSyllables[i];

      if (i + 1 < rawSyllables.length &&
          current.isEndOfWord &&
          !current.isExplicitElision &&
          !current.text.endsWith('-')) {
        final next = rawSyllables[i + 1];

        // Check if current ends with vowel and next starts with vowel or 'h' + vowel
        if (!next.isExplicitElision && _canElide(current.text, next.text)) {
          // Merge syllables into a single vocal event (e.g. "ria" + "al" -> "ria al")
          result.add('${current.text} ${next.text}');
          i += 2;
          continue;
        }
      }

      result.add(current.text);
      i++;
    }

    return result;
  }

  static void _addWordSyllables(
    String word,
    List<_WordSyllable> list, {
    required bool isEndOfWord,
  }) {
    if (word.isEmpty) return;

    if (word.contains('-')) {
      final parts = word.split('-');
      for (var p = 0; p < parts.length; p++) {
        final part = parts[p];
        if (part.isEmpty) continue;
        final isLastInWord = p == parts.length - 1;
        final formatted = isLastInWord ? part : '$part-';
        list.add(
          _WordSyllable(
            text: formatted,
            isEndOfWord: isLastInWord && isEndOfWord,
          ),
        );
      }
    } else {
      list.add(_WordSyllable(text: word, isEndOfWord: isEndOfWord));
    }
  }

  static bool _canElide(String wordEnding, String wordBeginning) {
    if (wordEnding.isEmpty || wordBeginning.isEmpty) return false;

    // Strip punctuation at boundary
    final endClean = wordEnding.replaceAll(
      RegExp(r'[^a-zA-ZáéíóúüÁÉÍÓÚÜ]'),
      '',
    );
    final startClean = wordBeginning.replaceAll(
      RegExp(r'[^a-zA-ZáéíóúüÁÉÍÓÚÜ]'),
      '',
    );

    if (endClean.isEmpty || startClean.isEmpty) return false;

    final lastChar = endClean[endClean.length - 1];
    var firstChar = startClean[0];

    // In Spanish, silent 'h' allows sinalefa (e.g. "de hoy" -> "de hoy")
    if ((firstChar == 'h' || firstChar == 'H') && startClean.length > 1) {
      firstChar = startClean[1];
    }

    return isVowel(lastChar) && isVowel(firstChar);
  }

  /// Maps lyric syllables 1:1 against sounding (non-rest) notes in [events].
  /// Musical rests are preserved without syllables.
  static List<NoteEvent> alignLyricsToNotes(
    List<NoteEvent> events,
    String rawLyrics, {
    bool handleSinalefa = true,
  }) {
    final syllables = tokenize(rawLyrics, handleSinalefa: handleSinalefa);
    var sylIndex = 0;
    final updated = <NoteEvent>[];

    for (final event in events) {
      if (event.isRest) {
        updated.add(event);
      } else {
        if (sylIndex < syllables.length) {
          updated.add(event.copyWith(lyric: syllables[sylIndex]));
          sylIndex++;
        } else {
          updated.add(event.copyWith(clearLyric: true));
        }
      }
    }

    return updated;
  }

  /// Aligns lyric syllables to all sounding notes across a [measure].
  static Measure alignLyricsToMeasure(
    Measure measure,
    String rawLyrics, {
    bool handleSinalefa = true,
  }) {
    final alignedEvents = alignLyricsToNotes(
      measure.events,
      rawLyrics,
      handleSinalefa: handleSinalefa,
    );
    return measure.copyWith(events: List.unmodifiable(alignedEvents));
  }
}

class _WordSyllable {
  const _WordSyllable({
    required this.text,
    required this.isEndOfWord,
    this.isExplicitElision = false,
  });

  final String text;
  final bool isEndOfWord;
  final bool isExplicitElision;
}
