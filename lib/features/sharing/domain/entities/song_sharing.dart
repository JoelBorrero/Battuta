/// Entities of song sharing: the versions of a song seen by other people, the
/// song (work) itself and merge requests between two songs.
library;

import 'package:battuta/features/organizations/domain/entities/json_helpers.dart';
import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:equatable/equatable.dart';

/// A version of a song as listed to somebody who may not own it: enough to
/// show it in a list (label, owner, visibility, lineage) and to open it.
class SongVersionListing extends Equatable with VersionOwnerLabel {
  const SongVersionListing({
    required this.versionId,
    required this.songWorkId,
    required this.title,
    this.artist = '',
    this.label = 'Original',
    this.key = 'C',
    this.visibility = SongVisibility.private,
    this.ownerId,
    this.ownerUsername,
    this.ownerDisplayName,
    this.ownerDeactivated = false,
    this.forkedFromVersionId,
    this.updatedAt,
  });

  /// [json] is a `song_versions` row with `songs` and `owner` embedded.
  factory SongVersionListing.fromJson(Map<String, dynamic> json) {
    final song = parseJsonMap(json['songs']);
    final owner = parseJsonMap(json['owner']);
    return SongVersionListing(
      versionId: json['id'] as String,
      songWorkId: (json['song_id'] as String?) ?? '',
      title: (song['title'] as String?) ?? '',
      artist: (song['artist'] as String?) ?? '',
      label: (json['label'] as String?) ?? 'Original',
      key: (json['key'] as String?) ?? 'C',
      visibility: SongVisibility.parse(json['visibility'] as String?),
      ownerId: json['owner_id'] as String?,
      ownerUsername: owner['username'] as String?,
      ownerDisplayName: owner['display_name'] as String?,
      ownerDeactivated: owner['deactivated_at'] != null,
      forkedFromVersionId: json['forked_from_version_id'] as String?,
      updatedAt: parseTimestamp(json['updated_at']),
    );
  }

  final String versionId;
  final String songWorkId;
  final String title;
  final String artist;
  final String label;
  final String key;
  final SongVisibility visibility;
  final String? ownerId;
  @override
  final String? ownerUsername;
  @override
  final String? ownerDisplayName;
  @override
  final bool ownerDeactivated;
  final String? forkedFromVersionId;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    versionId,
    songWorkId,
    title,
    artist,
    label,
    key,
    visibility,
    ownerId,
    ownerUsername,
    ownerDisplayName,
    ownerDeactivated,
    forkedFromVersionId,
    updatedAt,
  ];
}

/// A song (the work that versions belong to): `songs` on the backend.
class SongWork extends Equatable {
  const SongWork({
    required this.id,
    required this.title,
    this.artist = '',
    this.createdBy,
    this.mergedIntoId,
  });

  factory SongWork.fromJson(Map<String, dynamic> json) => SongWork(
    id: json['id'] as String,
    title: (json['title'] as String?) ?? '',
    artist: (json['artist'] as String?) ?? '',
    createdBy: json['created_by'] as String?,
    mergedIntoId: json['merged_into_id'] as String?,
  );

  final String id;
  final String title;
  final String artist;
  final String? createdBy;

  /// Set when the song was merged away into another one.
  final String? mergedIntoId;

  @override
  List<Object?> get props => [id, title, artist, createdBy, mergedIntoId];
}

enum MergeRequestStatus {
  pending,
  accepted,
  declined,
  cancelled;

  static MergeRequestStatus parse(Object? value) => switch (value) {
    'accepted' => accepted,
    'declined' => declined,
    'cancelled' => cancelled,
    _ => pending,
  };
}

/// A request to merge song [sourceSongId] into [targetSongId]: every version
/// of the source moves under the target. The creator of the other song
/// ([approverId]) approves it.
class SongMergeRequest extends Equatable {
  const SongMergeRequest({
    required this.id,
    required this.sourceSongId,
    required this.targetSongId,
    required this.sourceTitle,
    required this.targetTitle,
    this.requestedBy,
    this.approverId,
    this.requesterName,
    this.status = MergeRequestStatus.pending,
    this.createdAt,
  });

  /// [json] is a `song_merge_requests` row, optionally with the requester's
  /// profile embedded as `requester`.
  factory SongMergeRequest.fromJson(Map<String, dynamic> json) {
    final requester = parseJsonMap(json['requester']);
    final display = (requester['display_name'] as String?)?.trim();
    final username = (requester['username'] as String?)?.trim();
    return SongMergeRequest(
      id: json['id'] as String,
      sourceSongId: json['source_song_id'] as String,
      targetSongId: json['target_song_id'] as String,
      sourceTitle: (json['source_title'] as String?) ?? '',
      targetTitle: (json['target_title'] as String?) ?? '',
      requestedBy: json['requested_by'] as String?,
      approverId: json['approver_id'] as String?,
      requesterName: display != null && display.isNotEmpty ? display : username,
      status: MergeRequestStatus.parse(json['status']),
      createdAt: parseTimestamp(json['created_at']),
    );
  }

  final String id;
  final String sourceSongId;
  final String targetSongId;
  final String sourceTitle;
  final String targetTitle;
  final String? requestedBy;
  final String? approverId;
  final String? requesterName;
  final MergeRequestStatus status;
  final DateTime? createdAt;

  bool get isPending => status == MergeRequestStatus.pending;

  /// Whether this request links the two songs, in either direction.
  bool connects(String songA, String songB) =>
      (sourceSongId == songA && targetSongId == songB) ||
      (sourceSongId == songB && targetSongId == songA);

  @override
  List<Object?> get props => [
    id,
    sourceSongId,
    targetSongId,
    sourceTitle,
    targetTitle,
    requestedBy,
    approverId,
    requesterName,
    status,
    createdAt,
  ];
}

/// The outcome of a fork: the new version, and whether it was made on this
/// device only (no connection), to be pushed by the next sync.
class ForkedVersion extends Equatable {
  const ForkedVersion(this.song, {this.madeOffline = false});

  final Song song;
  final bool madeOffline;

  @override
  List<Object?> get props => [song, madeOffline];
}
