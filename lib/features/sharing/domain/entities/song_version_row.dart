/// One line of a song's list of versions: a version cached on the device, one
/// the backend lists, or both.
library;

import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:equatable/equatable.dart';

class SongVersionRow extends Equatable with VersionOwnerLabel {
  const SongVersionRow({
    required this.versionId,
    required this.label,
    required this.key,
    required this.visibility,
    this.ownerId,
    this.ownerUsername,
    this.ownerDisplayName,
    this.ownerDeactivated = false,
    this.forkedFromVersionId,
    this.isCached = false,
  });

  factory SongVersionRow.fromSong(Song song) => SongVersionRow(
    versionId: song.id,
    label: song.label,
    key: song.key,
    visibility: song.visibility,
    ownerId: song.ownerId,
    forkedFromVersionId: song.forkedFromVersionId,
    isCached: true,
  );

  factory SongVersionRow.fromListing(
    SongVersionListing listing, {
    bool isCached = false,
  }) => SongVersionRow(
    versionId: listing.versionId,
    label: listing.label,
    key: listing.key,
    visibility: listing.visibility,
    ownerId: listing.ownerId,
    ownerUsername: listing.ownerUsername,
    ownerDisplayName: listing.ownerDisplayName,
    ownerDeactivated: listing.ownerDeactivated,
    forkedFromVersionId: listing.forkedFromVersionId,
    isCached: isCached,
  );

  final String versionId;
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

  /// Whether the version is on this device (so it opens without internet).
  final bool isCached;

  /// Whether [accountId] owns it (versions of local mode count as mine).
  bool isMine(String? accountId) => ownerId == null || ownerId == accountId;

  @override
  List<Object?> get props => [
    versionId,
    label,
    key,
    visibility,
    ownerId,
    ownerUsername,
    ownerDisplayName,
    ownerDeactivated,
    forkedFromVersionId,
    isCached,
  ];
}

/// The versions on this device plus the ones the backend lists, once each.
///
/// The backend's data wins (it names the owners); a cached version the
/// backend did not list is kept, because it still opens offline. Mine come
/// first, then the others by label.
List<SongVersionRow> mergeVersionRows({
  required List<Song> cached,
  required List<SongVersionListing> remote,
  required String? accountId,
}) {
  final cachedIds = {for (final song in cached) song.id};
  final byId = <String, SongVersionRow>{
    for (final song in cached) song.id: SongVersionRow.fromSong(song),
    for (final listing in remote)
      listing.versionId: SongVersionRow.fromListing(
        listing,
        isCached: cachedIds.contains(listing.versionId),
      ),
  };
  return byId.values.toList()..sort((a, b) {
    final mine = (b.isMine(accountId) ? 1 : 0) - (a.isMine(accountId) ? 1 : 0);
    if (mine != 0) return mine;
    return a.label.toLowerCase().compareTo(b.label.toLowerCase());
  });
}
