/// Battuta — Song entity.
///
/// The core domain model for a song in the repertoire. Contains all
/// metadata (title, artist, key, tempo, time signature) and the ordered
/// list of [SongSection]s that make up the lead sheet.
///
/// Uses **freezed** for immutable value semantics and JSON serialization.
library;

import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'song.freezed.dart';
part 'song.g.dart';

/// The primary song entity used across the Battuta app.
///
/// One [Song] is one **version** (arrangement) of a work: [id] is the version
/// id and [songWorkId] the id of the work it belongs to on the backend. The
/// version fields ([songWorkId], [ownerId], [label], [visibility],
/// [forkedFromVersionId], [sharedOrganizationIds]) are managed by the cloud
/// sync; a song created in local mode has no owner yet.
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

    /// Id of the work (`songs.id`) this version belongs to; null until synced.
    String? songWorkId,

    /// Account that owns this version; null for local-mode songs.
    String? ownerId,

    /// Name of this arrangement (e.g. `"Original"`, `"Acoustic"`).
    @Default('Original') String label,

    /// Who can see this version.
    @Default(SongVisibility.private) SongVisibility visibility,

    /// Version this one was forked from, if any.
    String? forkedFromVersionId,

    /// Organizations this version is shared with (visibility `organizations`).
    @Default([]) List<String> sharedOrganizationIds,

    /// Account that created the work this version belongs to (the only one
    /// who edits its title and artist); null when unknown (not synced yet).
    String? songCreatorId,
  }) = _Song;

  const Song._();

  /// Deserializes a [Song] from a JSON map.
  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

  /// Formatted time-signature string for display (e.g., `"4/4"`).
  String get timeSignatureLabel {
    final (beats, beatValue) = timeSignature;
    return '$beats/$beatValue';
  }

  /// Whether [accountId] may edit this version: local-mode songs (no owner)
  /// and the owner's own versions. Versions of other users (e.g. from an
  /// organization's repertoire) are read-only.
  bool isEditableBy(String? accountId) =>
      ownerId == null || ownerId == accountId;

  /// Whether [accountId] may change the title and artist of this version.
  ///
  /// They belong to the song (the work), shared by all its versions, and only
  /// its creator edits them. When the creator is not known yet (never synced)
  /// the version counts as created by its owner unless it is a fork of
  /// somebody else's version.
  bool canEditTitleBy(String? accountId) {
    if (ownerId == null) return true;
    if (songCreatorId != null) return songCreatorId == accountId;
    return ownerId == accountId && forkedFromVersionId == null;
  }

  /// Formatted tempo string for display (e.g., `"120 BPM"`).
  String get tempoLabel => '$tempo BPM';
}
