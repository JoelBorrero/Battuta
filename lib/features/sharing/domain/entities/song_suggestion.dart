/// Matching songs while a version is being created, imported, scanned or moved.
///
/// A song is the work (title + artist); every version is linked to one. The
/// backend decides identity with a normalized key (see
/// `normalize_song_text` in the `song_linking` migration); [normalizeSongText]
/// is the same rule so the device can suggest songs from its cache offline.
library;

import 'dart:math' as math;

import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:equatable/equatable.dart';

/// A song offered to the user: where to attach the version being created.
class SongSuggestion extends Equatable {
  const SongSuggestion({
    required this.songWorkId,
    required this.title,
    this.artist = '',
    this.createdBy,
    this.versionCount = 1,
  });

  /// [json] is one row of the `search_songs` RPC.
  factory SongSuggestion.fromJson(Map<String, dynamic> json) => SongSuggestion(
    songWorkId: json['song_id'] as String,
    title: (json['title'] as String?) ?? '',
    artist: (json['artist'] as String?) ?? '',
    createdBy: json['created_by'] as String?,
    versionCount: (json['version_count'] as num?)?.toInt() ?? 0,
  );

  final String songWorkId;
  final String title;
  final String artist;

  /// Account that created the song (the only one who renames it).
  final String? createdBy;

  /// Versions of the song the account can see.
  final int versionCount;

  @override
  List<Object?> get props => [
    songWorkId,
    title,
    artist,
    createdBy,
    versionCount,
  ];
}

const _accents = <String, String>{
  'àáâãäåāăą': 'a',
  'çćĉċč': 'c',
  'ďđ': 'd',
  'èéêëēĕėęě': 'e',
  'ĝğġģ': 'g',
  'ìíîïĩīĭįı': 'i',
  'ñńņňŉ': 'n',
  'òóôõöøōŏő': 'o',
  'śŝşš': 's',
  'ţťŧ': 't',
  'ùúûüũūŭůűų': 'u',
  'ýÿŷ': 'y',
  'źżž': 'z',
};

final _accentMap = <int, String>{
  for (final entry in _accents.entries)
    for (final rune in entry.key.runes) rune: entry.value,
};

/// Lower case, accent-free; apostrophes dropped, other punctuation is a space;
/// spaces collapsed. "Tú Fidelidad" and "Tu fidelidad" match; "Way Maker
/// (Live)" stays different from "Way Maker".
String normalizeSongText(String text) {
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    buffer.write(_accentMap[rune] ?? String.fromCharCode(rune));
  }
  return buffer
      .toString()
      .replaceAll(RegExp("['’`]"), '')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();
}

/// The identity of a song: normalized title and artist.
String songKey(String title, String artist) =>
    '${normalizeSongText(title)}|${normalizeSongText(artist)}';

Set<String> _trigrams(String text) {
  final grams = <String>{};
  for (final word in text.split(' ')) {
    if (word.isEmpty) continue;
    final padded = '  $word ';
    for (var i = 0; i + 3 <= padded.length; i++) {
      grams.add(padded.substring(i, i + 3));
    }
  }
  return grams;
}

/// Trigram similarity in `[0, 1]` (the idea behind `pg_trgm`).
double textSimilarity(String a, String b) {
  final left = _trigrams(a);
  final right = _trigrams(b);
  if (left.isEmpty || right.isEmpty) return 0;
  final shared = left.intersection(right).length;
  return shared / (left.length + right.length - shared);
}

/// Shortest text worth searching for.
const minSuggestionQueryLength = 2;

/// Whether [query] is long enough to look for songs.
bool isSearchableSongQuery(String query) =>
    normalizeSongText(query).length >= minSuggestionQueryLength;

/// Songs known on this device (the cached versions) that match [query]: the
/// text is contained in title and artist, or is close to the title (typos).
/// Offline-first: this is all the suggestions have without a connection.
List<SongSuggestion> suggestionsFromCache(
  Iterable<Song> cached,
  String query, {
  int limit = 8,
}) {
  final needle = normalizeSongText(query);
  if (needle.length < minSuggestionQueryLength) return const [];
  final works = <String, List<Song>>{};
  for (final song in cached) {
    final id = song.songWorkId;
    if (id != null) works.putIfAbsent(id, () => []).add(song);
  }
  final scored = <(SongSuggestion, double, bool)>[];
  for (final MapEntry(key: id, value: versions) in works.entries) {
    final first = versions.first;
    final title = normalizeSongText(first.title);
    final flat = '$title ${normalizeSongText(first.artist)}'.trim();
    final contains = flat.contains(needle);
    final score = math.max(
      textSimilarity(flat, needle),
      textSimilarity(title, needle),
    );
    if (!contains && score <= 0.3) continue;
    scored.add((
      SongSuggestion(
        songWorkId: id,
        title: first.title,
        artist: first.artist,
        createdBy: first.songCreatorId,
        versionCount: versions.length,
      ),
      score,
      flat.startsWith(needle),
    ));
  }
  return _ranked(scored, limit);
}

List<SongSuggestion> _ranked(
  List<(SongSuggestion, double, bool)> scored,
  int limit,
) {
  scored.sort((a, b) {
    if (a.$3 != b.$3) return a.$3 ? -1 : 1;
    final byScore = b.$2.compareTo(a.$2);
    if (byScore != 0) return byScore;
    return a.$1.title.compareTo(b.$1.title);
  });
  return [for (final entry in scored.take(limit)) entry.$1];
}

/// Joins the device's suggestions with the backend's, one entry per song. The
/// backend's wins (it counts every visible version); order follows [query].
List<SongSuggestion> mergeSuggestions(
  List<SongSuggestion> cached,
  List<SongSuggestion> remote,
  String query, {
  int limit = 8,
}) {
  final byId = <String, SongSuggestion>{
    for (final s in cached) s.songWorkId: s,
    for (final s in remote) s.songWorkId: s,
  };
  final needle = normalizeSongText(query);
  final scored = [
    for (final s in byId.values)
      (
        s,
        math.max(
          textSimilarity(normalizeSongText('${s.title} ${s.artist}'), needle),
          textSimilarity(normalizeSongText(s.title), needle),
        ),
        normalizeSongText('${s.title} ${s.artist}').startsWith(needle),
      ),
  ];
  return _ranked(scored, limit);
}

/// Linking a version to a song picked from the suggestions.
extension SongLinking on Song {
  /// This version attached to [song]: it takes the song's identity, title and
  /// artist (they belong to the song, not to the version).
  Song linkedTo(SongSuggestion song) => copyWith(
    songWorkId: song.songWorkId,
    title: song.title,
    artist: song.artist,
    songCreatorId: song.createdBy,
  );
}
