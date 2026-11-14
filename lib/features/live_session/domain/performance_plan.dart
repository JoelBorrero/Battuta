/// Battuta — what a performance plays: the songs of a setlist (or one song),
/// each in its key and in section order.
library;

import 'package:battuta/features/live_session/domain/performance_cue.dart';
import 'package:battuta/features/live_session/domain/scroll_pace.dart';
import 'package:battuta/features/repertoire/domain/entities/musical_key.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';

/// One song of the performance.
class PerformanceSong {
  const PerformanceSong({
    required this.itemId,
    required this.songId,
    required this.title,
    required this.key,
    required this.semitones,
    required this.tempo,
    required this.timeSignature,
    required this.cues,
    this.song,
  });

  /// The setlist item (stable while the setlist is edited); `song:<id>` for a
  /// one-song performance.
  final String itemId;

  /// The song version; empty for a tombstone.
  final String songId;

  final String title;

  /// The song itself; `null` when it is not on this device.
  final Song? song;

  /// The key it is played in (the setlist's override, else the song's own).
  final String key;

  /// Shift from the song's own key to [key], in semitones (-5 to 6).
  final int semitones;

  /// Tempo in BPM (the setlist's override, else the song's); 0 when unknown.
  final int tempo;

  final (int, int) timeSignature;

  /// The sections to play, repeats expanded. Empty when [isMissing].
  final List<PerformanceCue> cues;

  /// Whether the song is not on this device (deleted, unshared, tombstone).
  bool get isMissing => song == null;

  /// Tempo to scroll by: [tempo], or 72 when the song has none.
  int get bpm => ScrollPace.effectiveBpm(tempo);

  /// Number of steps through this song; a missing song counts as one.
  int get stepCount => cues.isEmpty ? 1 : cues.length;

  @override
  bool operator ==(Object other) =>
      other is PerformanceSong &&
      other.itemId == itemId &&
      other.songId == songId &&
      other.title == title &&
      other.song == song &&
      other.key == key &&
      other.semitones == semitones &&
      other.tempo == tempo &&
      other.timeSignature == timeSignature &&
      _sameCues(other.cues, cues);

  static bool _sameCues(List<PerformanceCue> a, List<PerformanceCue> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    itemId,
    songId,
    title,
    song,
    key,
    semitones,
    tempo,
    timeSignature,
    Object.hashAll(cues),
  );
}

/// The ordered songs of one performance.
class PerformancePlan {
  const PerformancePlan(this.songs);

  /// A performance of a single song (a one-song set).
  factory PerformancePlan.fromSong(Song song) => PerformancePlan([
    _playable(
      itemId: 'song:${song.id}',
      song: song,
      keyOverride: null,
      tempoOverride: null,
    ),
  ]);

  /// A performance of [setlist]. [songsById] holds the songs that exist on this
  /// device; items whose song is missing (or a tombstone) become "not on this
  /// device" entries that keep their place.
  factory PerformancePlan.fromSetlist(
    Setlist setlist,
    Map<String, Song> songsById,
  ) {
    final items = [...setlist.items]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return PerformancePlan([
      for (final item in items)
        switch (item.songId.isEmpty ? null : songsById[item.songId]) {
          final Song song => _playable(
            itemId: item.id,
            song: song,
            keyOverride: item.keyOverride,
            tempoOverride: item.tempoOverride,
          ),
          null => _missing(item),
        },
    ]);
  }

  final List<PerformanceSong> songs;

  bool get isEmpty => songs.isEmpty;

  int get length => songs.length;

  /// Index of the song with setlist item [itemId], or -1.
  int indexOfItem(String itemId) => songs.indexWhere((s) => s.itemId == itemId);

  /// Semitones from key [from] up or down (whichever is nearer) to key [to];
  /// 0 when either is not a known key.
  static int keyShift(String from, String? to) {
    final target = to?.trim();
    if (target == null || target.isEmpty) return 0;
    try {
      final diff =
          (MusicalKey.fromString(target).semitoneIndex -
              MusicalKey.fromString(from).semitoneIndex) %
          12;
      return diff > 6 ? diff - 12 : diff;
    } on ArgumentError {
      return 0;
    }
  }

  /// [song]'s sections by `orderIndex`, each repeated `repeatCount` times.
  static List<PerformanceCue> cuesOf(Song song) {
    final sections = [...song.sections]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    if (sections.isEmpty) return [PerformanceCue.wholeSong(song.id)];
    return [
      for (final SongSection section in sections)
        for (var pass = 1; pass <= _passes(section); pass++)
          PerformanceCue(
            section: section,
            repeat: pass,
            repeatCount: _passes(section),
          ),
    ];
  }

  static int _passes(SongSection s) => s.repeatCount < 1 ? 1 : s.repeatCount;

  static PerformanceSong _playable({
    required String itemId,
    required Song song,
    required String? keyOverride,
    required int? tempoOverride,
  }) {
    final override = keyOverride?.trim();
    final hasOverride = override != null && override.isNotEmpty;
    return PerformanceSong(
      itemId: itemId,
      songId: song.id,
      title: song.title,
      song: song,
      key: hasOverride ? override : song.key,
      semitones: hasOverride ? keyShift(song.key, override) : 0,
      tempo: tempoOverride ?? song.tempo,
      timeSignature: song.timeSignature,
      cues: cuesOf(song),
    );
  }

  static PerformanceSong _missing(SetlistItem item) => PerformanceSong(
    itemId: item.id,
    songId: item.songId,
    title: item.titleSnapshot ?? '',
    key: item.keyOverride ?? item.keySnapshot ?? '',
    semitones: 0,
    tempo: item.tempoOverride ?? 0,
    timeSignature: const (4, 4),
    cues: const [],
  );

  @override
  bool operator ==(Object other) {
    if (other is! PerformancePlan || other.songs.length != songs.length) {
      return false;
    }
    for (var i = 0; i < songs.length; i++) {
      if (songs[i] != other.songs[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(songs);
}
