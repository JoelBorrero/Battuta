/// An organization's repertoire: the song versions it plays.
library;

import 'package:battuta/features/organizations/domain/entities/json_helpers.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:equatable/equatable.dart';

/// Who owns a version, as shown next to it ("Owned by ...").
mixin VersionOwnerLabel {
  String? get ownerUsername;
  String? get ownerDisplayName;
  bool get ownerDeactivated;

  /// Display name, falling back to the username; `null` when unknown.
  String? get ownerName {
    final display = ownerDisplayName?.trim();
    if (display != null && display.isNotEmpty) return display;
    final username = ownerUsername?.trim();
    return username == null || username.isEmpty ? null : username;
  }
}

/// One version in the repertoire of an organization, with the snapshot the
/// list needs (title, artist, key, label and owner) so it works offline even
/// before the version itself has been synced to the device.
class RepertoireEntry extends Equatable with VersionOwnerLabel {
  const RepertoireEntry({
    required this.organizationId,
    required this.versionId,
    required this.title,
    this.artist = '',
    this.label = 'Original',
    this.key = 'C',
    this.ownerId,
    this.ownerUsername,
    this.ownerDisplayName,
    this.ownerDeactivated = false,
    this.addedBy,
    this.addedAt,
  });

  /// [json] is a row of `organization_repertoire` with its `song_versions`
  /// embedded (title and artist through `songs`, the owner as `owner`), or a
  /// cached [toJson].
  factory RepertoireEntry.fromJson(Map<String, dynamic> json) {
    final version = json['song_versions'] is Map
        ? parseJsonMap(json['song_versions'])
        : json;
    final song = version['songs'] is Map
        ? parseJsonMap(version['songs'])
        : version;
    final owner = version['owner'] is Map
        ? parseJsonMap(version['owner'])
        : version;
    return RepertoireEntry(
      organizationId: json['organization_id'] as String,
      versionId: json['version_id'] as String,
      title: (song['title'] as String?) ?? '',
      artist: (song['artist'] as String?) ?? '',
      label: (version['label'] as String?) ?? 'Original',
      key: (version['key'] as String?) ?? 'C',
      ownerId: version['owner_id'] as String?,
      ownerUsername: owner['username'] as String?,
      ownerDisplayName: owner['display_name'] as String?,
      ownerDeactivated:
          owner['owner_deactivated'] == true || owner['deactivated_at'] != null,
      addedBy: json['added_by'] as String?,
      addedAt: parseTimestamp(json['created_at']),
    );
  }

  final String organizationId;
  final String versionId;
  final String title;
  final String artist;
  final String label;
  final String key;
  final String? ownerId;
  @override
  final String? ownerUsername;
  @override
  final String? ownerDisplayName;
  @override
  final bool ownerDeactivated;
  final String? addedBy;
  final DateTime? addedAt;

  Map<String, dynamic> toJson() => {
    'organization_id': organizationId,
    'version_id': versionId,
    'title': title,
    'artist': artist,
    'label': label,
    'key': key,
    'owner_id': ownerId,
    'username': ownerUsername,
    'display_name': ownerDisplayName,
    'owner_deactivated': ownerDeactivated,
    'added_by': addedBy,
    'created_at': formatTimestamp(addedAt),
  };

  @override
  List<Object?> get props => [
    organizationId,
    versionId,
    title,
    artist,
    label,
    key,
    ownerId,
    ownerUsername,
    ownerDisplayName,
    ownerDeactivated,
    addedBy,
    addedAt,
  ];
}

/// A version an admin can add to the repertoire (visible to the organization:
/// shared with it, or public).
class RepertoireCandidate extends Equatable with VersionOwnerLabel {
  const RepertoireCandidate({
    required this.versionId,
    required this.title,
    this.artist = '',
    this.label = 'Original',
    this.key = 'C',
    this.ownerId,
    this.ownerUsername,
    this.ownerDisplayName,
    this.ownerDeactivated = false,
    this.visibility = SongVisibility.public,
    this.sharedOrganizationIds = const [],
  });

  /// [json] is a `song_versions` row with `songs`, `owner` and
  /// `version_shares` embedded.
  factory RepertoireCandidate.fromJson(Map<String, dynamic> json) {
    final song = parseJsonMap(json['songs']);
    final owner = parseJsonMap(json['owner']);
    final shares = json['version_shares'];
    return RepertoireCandidate(
      versionId: json['id'] as String,
      title: (song['title'] as String?) ?? '',
      artist: (song['artist'] as String?) ?? '',
      label: (json['label'] as String?) ?? 'Original',
      key: (json['key'] as String?) ?? 'C',
      ownerId: json['owner_id'] as String?,
      ownerUsername: owner['username'] as String?,
      ownerDisplayName: owner['display_name'] as String?,
      ownerDeactivated: owner['deactivated_at'] != null,
      visibility: SongVisibility.parse(json['visibility'] as String?),
      sharedOrganizationIds: shares is List
          ? [
              for (final share in shares)
                if (share is Map && share['organization_id'] is String)
                  share['organization_id'] as String,
            ]
          : const [],
    );
  }

  final String versionId;
  final String title;
  final String artist;
  final String label;
  final String key;
  final String? ownerId;
  @override
  final String? ownerUsername;
  @override
  final String? ownerDisplayName;
  @override
  final bool ownerDeactivated;
  final SongVisibility visibility;
  final List<String> sharedOrganizationIds;

  /// Whether the organization [organizationId] may add this version.
  bool isVisibleTo(String organizationId) =>
      visibility == SongVisibility.public ||
      (visibility == SongVisibility.organizations &&
          sharedOrganizationIds.contains(organizationId));

  RepertoireEntry toEntry(String organizationId, {String? addedBy}) =>
      RepertoireEntry(
        organizationId: organizationId,
        versionId: versionId,
        title: title,
        artist: artist,
        label: label,
        key: key,
        ownerId: ownerId,
        ownerUsername: ownerUsername,
        ownerDisplayName: ownerDisplayName,
        ownerDeactivated: ownerDeactivated,
        addedBy: addedBy,
        addedAt: DateTime.now().toUtc(),
      );

  @override
  List<Object?> get props => [
    versionId,
    title,
    artist,
    label,
    key,
    ownerId,
    ownerUsername,
    ownerDisplayName,
    ownerDeactivated,
    visibility,
    sharedOrganizationIds,
  ];
}
