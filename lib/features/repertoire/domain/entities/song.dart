/// Battuta — Song entity.
///
/// The core domain model for a song in the repertoire. Contains all
/// metadata (title, artist, key, tempo, time signature) and the ordered
/// list of [SongSection]s that make up the lead sheet.
///
/// Uses **freezed** for immutable value semantics and JSON serialization.
library;

import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'song.freezed.dart';
part 'song.g.dart';

/// The primary song entity used across the Battuta app.
///
/// ```dart
/// final song = Song(
///   id: 'song-1',
///   title: 'Amazing Grace',
///   artist: 'John Newton',
///   key: 'G',
///   tempo: 72,
///   timeSignature: (4, 4),
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
/// );
/// ```
@freezed
abstract class Song with _$Song {
  /// Creates an immutable [Song].
  const factory Song({
    /// Unique identifier for this song.
    required String id,

    /// The song title.
    required String title,

    /// The performing artist or original composer.
    required String artist,

    /// The musical key as a string (e.g., `"C"`, `"G#m"`, `"Bb"`).
    ///
    /// Use [MusicalKey.fromString] when you need transposition or
    /// music-theory operations.
    required String key,

    /// Tempo in beats per minute.
    required int tempo,

    /// Time signature expressed as a record of `(beats, beatValue)`.
    ///
    /// For example, 4/4 time is `(4, 4)` and 6/8 time is `(6, 8)`.
    @Default((4, 4)) (int beats, int beatValue) timeSignature,

    /// Ordered sections that compose this song's lead sheet.
    @Default([]) List<SongSection> sections,

    /// Free-form tags for categorization (e.g., `["worship", "hymn"]`).
    @Default([]) List<String> tags,

    /// Optional local path to a cover image.
    String? coverImagePath,

    /// Optional free-text notes about the song.
    String? notes,

    /// Timestamp when the song was first created.
    required DateTime createdAt,

    /// Timestamp of the last modification.
    required DateTime updatedAt,
  }) = _Song;

  const Song._();

  /// Deserializes a [Song] from a JSON map.
  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

  /// Formatted time-signature string for display (e.g., `"4/4"`).
  String get timeSignatureLabel {
    final (beats, beatValue) = timeSignature;
    return '$beats/$beatValue';
  }

  /// Formatted tempo string for display (e.g., `"120 BPM"`).
  String get tempoLabel => '$tempo BPM';
}
