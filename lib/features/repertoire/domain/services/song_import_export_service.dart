/// Battuta — Song Import & Export Service.
///
/// Provides bidirectional serialization and parsing for songs:
/// - Single and multi-song JSON export and import with format resilience.
/// - Plain text and ChordPro export and import recognizing `//` comments as section headers.
/// - Clipboard-ready formatting for fast sharing between musicians.
library;

import 'dart:convert';

import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/services/song_text_parser.dart';
import 'package:uuid/uuid.dart';

class SongImportExportService {
  const SongImportExportService._();

  static const _uuid = Uuid();
  static const _jsonEncoder = JsonEncoder.withIndent('  ');

  /// Serializes a single [Song] to formatted JSON.
  static String exportSongToJson(Song song) {
    return _jsonEncoder.convert(song.toJson());
  }

  /// Serializes a list of [Song]s to a formatted JSON array (backup format).
  static String exportRepertoireToJson(List<Song> songs) {
    final list = songs.map((s) => s.toJson()).toList();
    return _jsonEncoder.convert(list);
  }

  /// Serializes a [Song] to plain text with `//` comment section delimiters
  /// and ChordPro chord brackets.
  static String exportSongToPlainText(Song song) {
    return SongTextParser.toPlainText(song);
  }

  /// Checks if [raw] is valid JSON.
  static bool isJson(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return false;
    try {
      jsonDecode(trimmed);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Parses a single song from either JSON or plain text.
  ///
  /// If [raw] is a JSON array of songs, the first song is returned.
  static Song parseSong(String raw, {String? fallbackTitle}) {
    final trimmed = raw.trim();

    if (isJson(trimmed)) {
      final decoded = jsonDecode(trimmed);
      if (decoded is List && decoded.isNotEmpty) {
        final firstMap = decoded.first;
        if (firstMap is Map<String, dynamic>) {
          return Song.fromJson(_sanitizeSongJson(firstMap));
        } else if (firstMap is Map) {
          return Song.fromJson(_sanitizeSongJson(Map<String, dynamic>.from(firstMap)));
        }
      } else if (decoded is Map<String, dynamic>) {
        return Song.fromJson(_sanitizeSongJson(decoded));
      } else if (decoded is Map) {
        return Song.fromJson(_sanitizeSongJson(Map<String, dynamic>.from(decoded)));
      }
    }

    // Default to plain text parsing
    return SongTextParser.parse(
      rawText: raw,
      fallbackTitle: fallbackTitle,
    );
  }

  /// Parses one or more songs from either JSON (single song or array) or plain text.
  static List<Song> parseMultipleSongs(String raw, {String? fallbackTitle}) {
    final trimmed = raw.trim();

    if (isJson(trimmed)) {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        final songs = <Song>[];
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            songs.add(Song.fromJson(_sanitizeSongJson(item)));
          } else if (item is Map) {
            songs.add(Song.fromJson(_sanitizeSongJson(Map<String, dynamic>.from(item))));
          }
        }
        return songs;
      } else if (decoded is Map<String, dynamic>) {
        return [Song.fromJson(_sanitizeSongJson(decoded))];
      } else if (decoded is Map) {
        return [Song.fromJson(_sanitizeSongJson(Map<String, dynamic>.from(decoded)))];
      }
    }

    // Plain text input yields a single song
    return [
      SongTextParser.parse(
        rawText: raw,
        fallbackTitle: fallbackTitle,
      ),
    ];
  }

  /// Sanitizes loose or external JSON to guarantee compatibility with [Song.fromJson].
  static Map<String, dynamic> _sanitizeSongJson(Map<String, dynamic> map) {
    final sanitized = Map<String, dynamic>.from(map);

    // An imported file is always a new local-mode song: it must not carry the
    // ownership or sharing of the account that exported it.
    for (final key in const [
      'songWorkId',
      'ownerId',
      'forkedFromVersionId',
      'sharedOrganizationIds',
      'visibility',
      'label',
    ]) {
      sanitized.remove(key);
    }

    // ID
    if (sanitized['id'] == null || (sanitized['id'] as String).trim().isEmpty) {
      sanitized['id'] = _uuid.v4();
    }

    // Title
    if (sanitized['title'] == null || (sanitized['title'] as String).trim().isEmpty) {
      sanitized['title'] = 'Untitled Song';
    }

    // Artist
    if (sanitized['artist'] == null || (sanitized['artist'] as String).trim().isEmpty) {
      sanitized['artist'] = 'Unknown Artist';
    }

    // Key
    if (sanitized['key'] == null || (sanitized['key'] as String).trim().isEmpty) {
      sanitized['key'] = 'C';
    }

    // Tempo
    final tempoVal = sanitized['tempo'];
    if (tempoVal == null || tempoVal is! num || tempoVal <= 0) {
      sanitized['tempo'] = 120;
    } else {
      sanitized['tempo'] = tempoVal.toInt();
    }

    // Time signature: can be {r'$1': 4, r'$2': 4}, or [4, 4], or "4/4"
    final timeSigVal = sanitized['timeSignature'];
    if (timeSigVal is Map) {
      final b1 = timeSigVal[r'$1'] ?? timeSigVal['beats'] ?? 4;
      final b2 = timeSigVal[r'$2'] ?? timeSigVal['beatValue'] ?? 4;
      sanitized['timeSignature'] = {
        r'$1': (b1 is num) ? b1.toInt() : 4,
        r'$2': (b2 is num) ? b2.toInt() : 4,
      };
    } else if (timeSigVal is List && timeSigVal.length >= 2) {
      sanitized['timeSignature'] = {
        r'$1': (timeSigVal[0] is num) ? (timeSigVal[0] as num).toInt() : 4,
        r'$2': (timeSigVal[1] is num) ? (timeSigVal[1] as num).toInt() : 4,
      };
    } else if (timeSigVal is String) {
      final match = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(timeSigVal);
      if (match != null) {
        sanitized['timeSignature'] = {
          r'$1': int.tryParse(match.group(1)!) ?? 4,
          r'$2': int.tryParse(match.group(2)!) ?? 4,
        };
      } else {
        sanitized['timeSignature'] = {r'$1': 4, r'$2': 4};
      }
    } else {
      sanitized['timeSignature'] = {r'$1': 4, r'$2': 4};
    }

    // Timestamps
    final nowStr = DateTime.now().toIso8601String();
    if (sanitized['createdAt'] == null) {
      sanitized['createdAt'] = nowStr;
    } else {
      try {
        DateTime.parse(sanitized['createdAt'] as String);
      } catch (_) {
        sanitized['createdAt'] = nowStr;
      }
    }
    if (sanitized['updatedAt'] == null) {
      sanitized['updatedAt'] = nowStr;
    } else {
      try {
        DateTime.parse(sanitized['updatedAt'] as String);
      } catch (_) {
        sanitized['updatedAt'] = nowStr;
      }
    }

    // Tags
    if (sanitized['tags'] is! List) {
      sanitized['tags'] = <String>[];
    } else {
      sanitized['tags'] = (sanitized['tags'] as List).map((e) => e.toString()).toList();
    }

    // Sections
    final rawSections = sanitized['sections'];
    if (rawSections is! List) {
      sanitized['sections'] = <Map<String, dynamic>>[];
    } else {
      final sanitizedSections = <Map<String, dynamic>>[];
      for (var idx = 0; idx < rawSections.length; idx++) {
        final sec = rawSections[idx];
        if (sec is Map) {
          final secMap = Map<String, dynamic>.from(sec);
          if (secMap['id'] == null || (secMap['id'] as String).trim().isEmpty) {
            secMap['id'] = _uuid.v4();
          }
          if (secMap['name'] == null || (secMap['name'] as String).trim().isEmpty) {
            secMap['name'] = 'Section ${idx + 1}';
          }
          if (secMap['orderIndex'] == null || secMap['orderIndex'] is! num) {
            secMap['orderIndex'] = idx;
          } else {
            secMap['orderIndex'] = (secMap['orderIndex'] as num).toInt();
          }
          if (secMap['repeatCount'] == null || secMap['repeatCount'] is! num || (secMap['repeatCount'] as num) < 1) {
            secMap['repeatCount'] = 1;
          } else {
            secMap['repeatCount'] = (secMap['repeatCount'] as num).toInt();
          }
          if (secMap['chords'] is! List) {
            secMap['chords'] = <dynamic>[];
          }
          sanitizedSections.add(secMap);
        }
      }
      sanitized['sections'] = sanitizedSections;
    }

    return sanitized;
  }
}
