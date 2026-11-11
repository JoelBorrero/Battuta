/// Organizations, members, bands and archiving.
library;

import 'package:battuta/features/organizations/domain/entities/json_helpers.dart';
import 'package:equatable/equatable.dart';

enum OrganizationRole {
  admin,
  member;

  static OrganizationRole parse(Object? value) =>
      value == 'admin' ? admin : member;
}

class Organization extends Equatable {
  const Organization({
    required this.id,
    required this.name,
    this.createdBy,
    this.archivedAt,
    this.createdAt,
    this.myRole,
  });

  /// [json] is a row of `organizations`; `my_role` is added by the
  /// repository (and persisted in the cache).
  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
    id: json['id'] as String,
    name: json['name'] as String,
    createdBy: json['created_by'] as String?,
    archivedAt: parseTimestamp(json['archived_at']),
    createdAt: parseTimestamp(json['created_at']),
    myRole: json['my_role'] == null
        ? null
        : OrganizationRole.parse(json['my_role']),
  );

  final String id;
  final String name;
  final String? createdBy;
  final DateTime? archivedAt;
  final DateTime? createdAt;

  /// The signed-in user's role in this organization, when known.
  final OrganizationRole? myRole;

  bool get isArchived => archivedAt != null;
  bool get isAdmin => myRole == OrganizationRole.admin;

  Organization copyWith({
    String? name,
    DateTime? archivedAt,
    OrganizationRole? myRole,
  }) => Organization(
    id: id,
    name: name ?? this.name,
    createdBy: createdBy,
    archivedAt: archivedAt ?? this.archivedAt,
    createdAt: createdAt,
    myRole: myRole ?? this.myRole,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created_by': createdBy,
    'archived_at': formatTimestamp(archivedAt),
    'created_at': formatTimestamp(createdAt),
    'my_role': myRole?.name,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    createdBy,
    archivedAt,
    createdAt,
    myRole,
  ];
}

/// Free default or stored override returned by `organization_quota`.
class OrganizationQuota extends Equatable {
  const OrganizationQuota({
    required this.tier,
    required this.monthlyGeminiCreditsLimit,
    required this.maxStorageBytes,
  });

  factory OrganizationQuota.fromJson(Map<String, dynamic> json) =>
      OrganizationQuota(
        tier: json['tier'] as String,
        monthlyGeminiCreditsLimit: (json['monthly_gemini_credits_limit'] as num)
            .toInt(),
        maxStorageBytes: (json['max_storage_bytes'] as num).toInt(),
      );

  final String tier;
  final int monthlyGeminiCreditsLimit;
  final int maxStorageBytes;

  @override
  List<Object?> get props => [tier, monthlyGeminiCreditsLimit, maxStorageBytes];
}

class OrganizationMember extends Equatable {
  const OrganizationMember({
    required this.id,
    required this.organizationId,
    required this.userId,
    this.role = OrganizationRole.member,
    this.instruments = const [],
    this.minPitch,
    this.maxPitch,
    this.notes,
    this.deactivatedAt,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  /// [json] is a row of `organization_members`, optionally with the joined
  /// profile either embedded (`profiles`) or flattened (`username`, ...).
  factory OrganizationMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] is Map
        ? parseJsonMap(json['profiles'])
        : json;
    return OrganizationMember(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      userId: json['user_id'] as String,
      role: OrganizationRole.parse(json['role']),
      instruments: parseStringList(json['instruments']),
      minPitch: json['min_pitch'] as String?,
      maxPitch: json['max_pitch'] as String?,
      notes: json['notes'] as String?,
      deactivatedAt: parseTimestamp(json['deactivated_at']),
      username: profile['username'] as String?,
      displayName: profile['display_name'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
    );
  }

  final String id;
  final String organizationId;
  final String userId;
  final OrganizationRole role;
  final List<String> instruments;
  final String? minPitch;
  final String? maxPitch;
  final String? notes;
  final DateTime? deactivatedAt;

  // Joined profile (not part of the member row itself).
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  bool get isActive => deactivatedAt == null;
  bool get isAdmin => role == OrganizationRole.admin;

  OrganizationMember withProfileOf(OrganizationMember? other) {
    if (other == null || username != null) return this;
    return OrganizationMember(
      id: id,
      organizationId: organizationId,
      userId: userId,
      role: role,
      instruments: instruments,
      minPitch: minPitch,
      maxPitch: maxPitch,
      notes: notes,
      deactivatedAt: deactivatedAt,
      username: other.username,
      displayName: other.displayName,
      avatarUrl: other.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'user_id': userId,
    'role': role.name,
    'instruments': instruments,
    'min_pitch': minPitch,
    'max_pitch': maxPitch,
    'notes': notes,
    'deactivated_at': formatTimestamp(deactivatedAt),
    'username': username,
    'display_name': displayName,
    'avatar_url': avatarUrl,
  };

  @override
  List<Object?> get props => [
    id,
    organizationId,
    userId,
    role,
    instruments,
    minPitch,
    maxPitch,
    notes,
    deactivatedAt,
    username,
    displayName,
    avatarUrl,
  ];
}

class Band extends Equatable {
  const Band({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    this.colorValue = defaultColorValue,
  });

  factory Band.fromJson(Map<String, dynamic> json) => Band(
    id: json['id'] as String,
    organizationId: json['organization_id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    colorValue: (json['color_value'] as num?)?.toInt() ?? defaultColorValue,
  );

  /// Stage amber, `0xFFE5A93C`.
  static const int defaultColorValue = 0xFFE5A93C;

  final String id;
  final String organizationId;
  final String name;
  final String? description;
  final int colorValue;

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'name': name,
    'description': description,
    'color_value': colorValue,
  };

  @override
  List<Object?> get props => [
    id,
    organizationId,
    name,
    description,
    colorValue,
  ];
}

class BandMember extends Equatable {
  const BandMember({
    required this.id,
    required this.organizationId,
    required this.bandId,
    required this.memberId,
  });

  factory BandMember.fromJson(Map<String, dynamic> json) => BandMember(
    id: json['id'] as String,
    organizationId: json['organization_id'] as String,
    bandId: json['band_id'] as String,
    memberId: json['member_id'] as String,
  );

  final String id;
  final String organizationId;
  final String bandId;
  final String memberId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'band_id': bandId,
    'member_id': memberId,
  };

  @override
  List<Object?> get props => [id, organizationId, bandId, memberId];
}

class ArchiveApproval extends Equatable {
  const ArchiveApproval({required this.userId, this.approvedAt});

  factory ArchiveApproval.fromJson(Map<String, dynamic> json) =>
      ArchiveApproval(
        userId: json['user_id'] as String,
        approvedAt: parseTimestamp(json['approved_at']),
      );

  final String userId;
  final DateTime? approvedAt;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'approved_at': formatTimestamp(approvedAt),
  };

  @override
  List<Object?> get props => [userId, approvedAt];
}

/// The open request to archive an organization, with who approved it.
class ArchiveRequest extends Equatable {
  const ArchiveRequest({
    required this.organizationId,
    this.requestedBy,
    this.requestedAt,
    this.approvals = const [],
  });

  /// [json] is a row of `organization_archive_requests`, with approvals
  /// embedded as `organization_archive_approvals` (or `approvals`).
  factory ArchiveRequest.fromJson(Map<String, dynamic> json) {
    final raw = json['organization_archive_approvals'] ?? json['approvals'];
    return ArchiveRequest(
      organizationId: json['organization_id'] as String,
      requestedBy: json['requested_by'] as String?,
      requestedAt: parseTimestamp(json['requested_at']),
      approvals: raw is List
          ? raw.map((e) => ArchiveApproval.fromJson(parseJsonMap(e))).toList()
          : const [],
    );
  }

  final String organizationId;
  final String? requestedBy;
  final DateTime? requestedAt;
  final List<ArchiveApproval> approvals;

  bool isApprovedBy(String userId) => approvals.any((a) => a.userId == userId);

  Map<String, dynamic> toJson() => {
    'organization_id': organizationId,
    'requested_by': requestedBy,
    'requested_at': formatTimestamp(requestedAt),
    'approvals': approvals.map((a) => a.toJson()).toList(),
  };

  @override
  List<Object?> get props => [
    organizationId,
    requestedBy,
    requestedAt,
    approvals,
  ];
}
