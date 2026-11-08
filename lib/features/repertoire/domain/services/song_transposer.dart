/// Battuta — Song Transposition and Chord Parsing Service.
///
/// Provides music-theory operations for transposing chord charts and songs,
/// and parsing user chord strings into [ChordCell] domain entities.
library;

import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:battuta/features/repertoire/domain/entities/musical_key.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';

/// Utilities for transposing notes, chords, and complete songs.
class SongTransposer {
  const SongTransposer._();

  static const List<String> _sharpNotes = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  static const List<String> _flatNotes = [
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'Gb',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];

  static const Map<String, int> _noteToSemitone = {
    'c': 0,
    'b#': 0,
    'c#': 1,
    'db': 1,
    'd': 2,
    'd#': 3,
    'eb': 3,
    'e': 4,
    'fb': 4,
    'f': 5,
    'e#': 5,
    'f#': 6,
    'gb': 6,
    'g': 7,
    'g#': 8,
    'ab': 8,
    'a': 9,
    'a#': 10,
    'bb': 10,
    'b': 11,
    'cb': 11,
  };

  /// Transposes an individual note string (e.g. "C", "F#", "Bb") by [semitones].
  static String transposeNote(
    String note,
    int semitones, {
    bool preferSharps = true,
  }) {
    final clean = note.trim().toLowerCase();
    final currentSemitone = _noteToSemitone[clean];
    if (currentSemitone == null) return note;

    final targetSemitone = (currentSemitone + semitones % 12 + 12) % 12;
    final scale = preferSharps ? _sharpNotes : _flatNotes;
    return scale[targetSemitone];
  }

  /// Transposes a single [ChordCell] by [semitones].
  static ChordCell transposeChord(
    ChordCell chord,
    int semitones, {
    required bool preferSharps,
  }) {
    if (semitones == 0) return chord;

    final newRoot = transposeNote(
      chord.root,
      semitones,
      preferSharps: preferSharps,
    );
    final newBass = chord.bass != null
        ? transposeNote(chord.bass!, semitones, preferSharps: preferSharps)
        : null;

    return chord.copyWith(root: newRoot, bass: newBass, customLabel: null);
  }

  /// Transposes an entire [Song] by [semitones].
  ///
  /// Adjusts the song's root key and every chord in all sections.
  static Song transposeSong(Song song, int semitones) {
    if (semitones == 0) return song;

    MusicalKey? currentKey;
    try {
      currentKey = MusicalKey.fromString(song.key);
    } catch (_) {
      // Fallback if song has an irregular key string
      currentKey = null;
    }

    final targetKey = currentKey?.transpose(semitones);
    final preferSharps = targetKey?.useSharps ?? !song.key.contains('b');
    final newKeyName =
        targetKey?.name ??
        transposeNote(song.key, semitones, preferSharps: preferSharps);

    final updatedSections = song.sections.map((section) {
      final updatedChords = section.chords
          .map((c) => transposeChord(c, semitones, preferSharps: preferSharps))
          .toList();
      final updatedLyrics = section.lyrics != null
          ? transposeChordProText(
              section.lyrics!,
              semitones,
              preferSharps: preferSharps,
            )
          : null;
      return section.copyWith(chords: updatedChords, lyrics: updatedLyrics);
    }).toList();

    return song.copyWith(
      key: newKeyName,
      sections: updatedSections,
      updatedAt: DateTime.now(),
    );
  }

  static final RegExp _bracketChordRegex = RegExp(r'\[([^\]]+)\]');

  /// Transposes all bracketed `[Chord]` tags in a ChordPro text string.
  static String transposeChordProText(
    String text,
    int semitones, {
    bool preferSharps = true,
  }) {
    if (semitones == 0 || text.isEmpty) return text;

    return text.replaceAllMapped(_bracketChordRegex, (match) {
      final chordStr = match.group(1)!.trim();
      final transposed = transposeChordString(
        chordStr,
        semitones,
        preferSharps: preferSharps,
      );
      return '[$transposed]';
    });
  }

  /// Transposes an individual chord string (e.g. `"G"`, `"Am7"`, `"D/F#"`) by [semitones].
  static String transposeChordString(
    String chord,
    int semitones, {
    bool preferSharps = true,
  }) {
    if (semitones == 0 || chord.trim().isEmpty) return chord;

    final cell = ChordParser.parseChord(chord);
    if (cell == null) {
      // If it's a section header or non-chord tag like [Intro], [Chorus], return untouched
      return chord;
    }

    final transposed = transposeChord(
      cell,
      semitones,
      preferSharps: preferSharps,
    );
    return transposed.displayLabel;
  }
}

/// Parser for transforming chord strings (e.g. "C G/B Am Fmaj7") into [ChordCell]s.
class ChordParser {
  const ChordParser._();

  static final RegExp _chordPattern = RegExp(
    r'^([A-Ga-g][#b]?)([^/]*)(?:/(.*))?$',
  );

  /// Parses a space, bar, comma, or newline-separated chord progression.
  ///
  /// For example:
  /// `"C | G/B | Am | Fmaj7"` -> 4 [ChordCell]s.
  static List<ChordCell> parseProgression(
    String input, {
    int defaultBeats = 4,
  }) {
    final tokens = input
        .split(RegExp(r'[\s|,]+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty && t != '|' && t != '-' && t != '/')
        .toList();

    return tokens
        .map((t) => parseChord(t, beats: defaultBeats))
        .whereType<ChordCell>()
        .toList();
  }

  /// Parses an individual chord token into a [ChordCell].
  static ChordCell? parseChord(String token, {int beats = 4}) {
    final match = _chordPattern.firstMatch(token.trim());
    if (match == null) return null;

    final rawRoot = match.group(1)!;
    final root =
        rawRoot.substring(0, 1).toUpperCase() +
        (rawRoot.length > 1 ? rawRoot.substring(1) : '');

    final rawQuality = (match.group(2) ?? '').trim();
    final rawBass = match.group(3)?.trim();
    final bass = (rawBass != null && rawBass.isNotEmpty)
        ? rawBass.substring(0, 1).toUpperCase() +
              (rawBass.length > 1 ? rawBass.substring(1) : '')
        : null;

    final (quality, extensions) = _matchQualityAndExtensions(rawQuality);

    return ChordCell(
      root: root,
      quality: quality,
      bass: bass,
      extensions: extensions,
      beats: beats,
      customLabel: quality == ChordQuality.custom ? token : null,
    );
  }

  static (ChordQuality, List<String>) _matchQualityAndExtensions(
    String suffix,
  ) {
    final s = suffix.toLowerCase();

    if (s.isEmpty) return (ChordQuality.major, const []);
    if (s == 'm' || s == 'min' || s == '-') {
      return (ChordQuality.minor, const []);
    }
    if (s == 'm7' || s == 'min7' || s == '-7') {
      return (ChordQuality.minor7, const []);
    }
    if (s == 'maj7' || s == 'm7+' || s == 'delta') {
      return (ChordQuality.major7, const []);
    }
    if (s == '7' || s == 'dom7') return (ChordQuality.dominant7, const []);
    if (s == 'dim' || s == 'o') return (ChordQuality.diminished, const []);
    if (s == 'aug' || s == '+') return (ChordQuality.augmented, const []);
    if (s == 'sus2') return (ChordQuality.sus2, const []);
    if (s == 'sus4' || s == 'sus') return (ChordQuality.sus4, const []);
    if (s == 'add9') return (ChordQuality.add9, const []);

    // Other extensions or compound
    if (s.startsWith('m7b5')) {
      return (ChordQuality.minor7, ['b5']);
    }
    if (s == '9') return (ChordQuality.dominant7, ['9']);
    if (s == 'maj9') return (ChordQuality.major7, ['9']);
    if (s == 'm9') return (ChordQuality.minor7, ['9']);
    if (s == '11') return (ChordQuality.dominant7, ['11']);
    if (s == '13') return (ChordQuality.dominant7, ['13']);
    if (s == '6') return (ChordQuality.major, ['6']);
    if (s == 'm6') return (ChordQuality.minor, ['6']);

    return (ChordQuality.custom, const []);
  }
}
