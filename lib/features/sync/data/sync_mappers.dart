/// Battuta — Mapping between Drift rows and the Supabase song/setlist schema.
///
/// Pure functions (no I/O) so the field-by-field mapping is unit tested.
library;

import 'dart:convert';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/sync/domain/services/sync_policy.dart';
import 'package:drift/drift.dart';

/// Columns a client may send when creating a `song_versions` row.
Map<String, dynamic> versionInsertPayload(
  SongEntry song, {
  required String workId,
  required String ownerId,
}) => {
  'id': song.id,
  'song_id': workId,
  'owner_id': ownerId,
  'label': song.label,
  'visibility': song.visibility,
  'forked_from_version_id': song.forkedFromVersionId,
  ..._versionContent(song),
};

/// Columns a client may update on an existing version: its content and the
/// time of the edit. Label and visibility go along only when the sharing
/// changed locally ([withSharing]), so a stale copy never undoes a change made
/// on another device.
Map<String, dynamic> versionUpdatePayload(
  SongEntry song, {
  bool withSharing = false,
}) => {
  if (withSharing) ...versionSharingPayload(song),
  ..._versionContent(song),
};

/// The label and visibility of a version.
Map<String, dynamic> versionSharingPayload(SongEntry song) => {
  'label': song.label,
  'visibility': song.visibility,
};

Map<String, dynamic> _versionContent(SongEntry song) => {
  'key': song.key,
  'tempo': song.tempo,
  'time_signature_beats': song.timeSignatureBeats,
  'time_signature_beat_value': song.timeSignatureBeatValue,
  'sections_json': song.sectionsJson,
  'tags_json': song.tagsJson,
  'cover_image_path': song.coverImagePath,
  'notes': song.notes,
  'edited_at': SyncPolicy.editedAtText(song.editedAtMs),
};

/// A local row for a backend `song_versions` row.
///
/// [row] is the version joined with its work (`songs`) and, for the owner,
/// its `version_shares`.
SongsCompanion songCompanionFromRemote(
  Map<String, dynamic> row, {
  required String accountId,
}) {
  final work = (row['songs'] as Map?)?.cast<String, dynamic>() ?? const {};
  final ownerId = row['owner_id'] as String;
  final shares = ownerId == accountId
      ? [
          for (final s in (row['version_shares'] as List?) ?? const [])
            (s as Map)['organization_id'] as String,
        ]
      : const <String>[];
  final updatedAt = SyncPolicy.normalizeTimestamp(row['updated_at']);
  return SongsCompanion(
    id: Value(row['id'] as String),
    title: Value(work['title'] as String? ?? 'Untitled'),
    artist: Value(work['artist'] as String? ?? ''),
    key: Value(row['key'] as String? ?? 'C'),
    tempo: Value((row['tempo'] as num?)?.toInt() ?? 120),
    timeSignatureBeats: Value(
      (row['time_signature_beats'] as num?)?.toInt() ?? 4,
    ),
    timeSignatureBeatValue: Value(
      (row['time_signature_beat_value'] as num?)?.toInt() ?? 4,
    ),
    sectionsJson: Value(row['sections_json'] as String? ?? '[]'),
    tagsJson: Value(row['tags_json'] as String? ?? '[]'),
    coverImagePath: Value(row['cover_image_path'] as String?),
    notes: Value(row['notes'] as String?),
    createdAt: Value(
      DateTime.tryParse('${row['created_at']}') ?? DateTime.now(),
    ),
    updatedAt: Value(DateTime.parse(updatedAt)),
    songWorkId: Value(row['song_id'] as String?),
    ownerId: Value(ownerId),
    label: Value(row['label'] as String? ?? 'Original'),
    visibility: Value(row['visibility'] as String? ?? 'private'),
    forkedFromVersionId: Value(row['forked_from_version_id'] as String?),
    sharedOrganizationIdsJson: Value(jsonEncode(shares)),
    isDirty: const Value(false),
    deletedAt: const Value(null),
    remoteUpdatedAt: Value(updatedAt),
    accountId: Value(accountId),
    editedAtMs: Value(_editedAtMs(row)),
    sharingDirty: const Value(false),
  );
}

/// The edit time of a backend row; rows from before `edited_at` existed fall
/// back to their last update.
int _editedAtMs(Map<String, dynamic> row) =>
    SyncPolicy.timestampMs(row['edited_at'] ?? row['updated_at']);

/// `scores` payload for a local score of version [versionId].
Map<String, dynamic> scorePayload(ScoreEntry score, String versionId) => {
  'id': score.id,
  'version_id': versionId,
  'title': score.title,
  'composer': score.composer,
  'artist': score.artist,
  'time_signature': _decodeJson(score.timeSignatureJson, {
    'numerator': 4,
    'denominator': 4,
  }),
  'key_signature': score.keySignature,
  'tempo': score.tempo,
  'sections': _decodeJson(score.sectionsJson, const <Object>[]),
  'metadata': _decodeJson(score.metadataJson, const <String, Object>{}),
  'deleted_at': null,
  'edited_at': SyncPolicy.editedAtText(score.editedAtMs),
};

Object _decodeJson(String text, Object fallback) {
  try {
    return jsonDecode(text) as Object;
  } catch (_) {
    return fallback;
  }
}

/// A local row for a backend `scores` row.
ScoresCompanion scoreCompanionFromRemote(Map<String, dynamic> row) {
  final updatedAt = SyncPolicy.normalizeTimestamp(row['updated_at']);
  return ScoresCompanion(
    id: Value(row['id'] as String),
    songId: Value(row['version_id'] as String),
    title: Value(row['title'] as String? ?? 'Untitled Score'),
    composer: Value(row['composer'] as String?),
    artist: Value(row['artist'] as String?),
    timeSignatureJson: Value(
      jsonEncode(
        row['time_signature'] is Map
            ? row['time_signature']
            : {'numerator': 4, 'denominator': 4},
      ),
    ),
    keySignature: Value(row['key_signature'] as String? ?? 'C'),
    tempo: Value((row['tempo'] as num?)?.toInt() ?? 120),
    sectionsJson: Value(
      jsonEncode(row['sections'] is List ? row['sections'] : const []),
    ),
    metadataJson: Value(
      jsonEncode(row['metadata'] is Map ? row['metadata'] : const {}),
    ),
    updatedAt: Value(DateTime.parse(updatedAt)),
    isDirty: const Value(false),
    deletedAt: const Value(null),
    remoteUpdatedAt: Value(updatedAt),
    editedAtMs: Value(_editedAtMs(row)),
  );
}

/// What a setlist entry knows about the song it points to.
class ItemSongInfo {
  const ItemSongInfo({
    required this.title,
    required this.artist,
    required this.label,
    required this.key,
  });

  final String title;
  final String artist;
  final String label;
  final String key;
}

/// `setlist_items` payload.
///
/// [versionId] is null for tombstones and for songs that only exist on this
/// device; [info] then supplies the snapshot the backend keeps for the entry.
Map<String, dynamic> setlistItemPayload(
  SetlistItem item, {
  required String setlistId,
  required String? organizationId,
  required String? versionId,
  ItemSongInfo? info,
}) => {
  'id': item.id,
  'setlist_id': setlistId,
  'organization_id': organizationId,
  'position': item.orderIndex,
  'version_id': versionId,
  'title_snapshot': info?.title ?? item.titleSnapshot ?? 'Untitled',
  'artist_snapshot': info?.artist ?? item.artistSnapshot,
  'label_snapshot': info?.label ?? item.labelSnapshot,
  'key_snapshot': info?.key ?? item.keySnapshot,
  'key_override': item.keyOverride,
  'tempo_override': item.tempoOverride,
  'notes': item.notes,
};

/// A local [SetlistItem] for a backend `setlist_items` row.
///
/// * [visibleVersionIds]: versions this device can read. An entry whose version
///   is not among them (deleted, unshared, made private) becomes a read-only
///   tombstone (`songId` empty) that keeps the backend's snapshot.
/// * [local]: the entry with the same id on this device. If it points to a song
///   that never reached the backend ([localOnlySongIds], e.g. a bundled
///   sample), the link is kept because the backend could not store it.
SetlistItem setlistItemFromRemote(
  Map<String, dynamic> row, {
  required Set<String> visibleVersionIds,
  required Set<String> localOnlySongIds,
  SetlistItem? local,
}) {
  final versionId = row['version_id'] as String?;
  var songId = versionId != null && visibleVersionIds.contains(versionId)
      ? versionId
      : '';
  if (songId.isEmpty &&
      versionId == null &&
      local != null &&
      local.songId.isNotEmpty &&
      localOnlySongIds.contains(local.songId)) {
    songId = local.songId;
  }
  return SetlistItem(
    id: row['id'] as String,
    songId: songId,
    orderIndex: (row['position'] as num?)?.toInt() ?? 0,
    keyOverride: row['key_override'] as String?,
    tempoOverride: (row['tempo_override'] as num?)?.toInt(),
    notes: row['notes'] as String?,
    titleSnapshot: row['title_snapshot'] as String?,
    artistSnapshot: row['artist_snapshot'] as String?,
    labelSnapshot: row['label_snapshot'] as String?,
    keySnapshot: row['key_snapshot'] as String?,
  );
}
