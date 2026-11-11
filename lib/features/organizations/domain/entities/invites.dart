/// Invite links and invitations by username.
library;

import 'package:battuta/features/organizations/domain/entities/json_helpers.dart';
import 'package:equatable/equatable.dart';

class InviteLink extends Equatable {
  const InviteLink({
    required this.id,
    required this.organizationId,
    required this.token,
    required this.expiresAt,
    this.bandId,
    this.createdBy,
    this.createdAt,
    this.maxUses,
    this.useCount = 0,
    this.revokedAt,
  });

  factory InviteLink.fromJson(Map<String, dynamic> json) => InviteLink(
    id: json['id'] as String,
    organizationId: json['organization_id'] as String,
    token: json['token'] as String,
    expiresAt: parseTimestamp(json['expires_at'])!,
    bandId: json['band_id'] as String?,
    createdBy: json['created_by'] as String?,
    createdAt: parseTimestamp(json['created_at']),
    maxUses: (json['max_uses'] as num?)?.toInt(),
    useCount: (json['use_count'] as num?)?.toInt() ?? 0,
    revokedAt: parseTimestamp(json['revoked_at']),
  );

  final String id;
  final String organizationId;
  final String token;
  final DateTime expiresAt;
  final String? bandId;
  final String? createdBy;
  final DateTime? createdAt;
  final int? maxUses;
  final int useCount;
  final DateTime? revokedAt;

  bool get isRevoked => revokedAt != null;
  bool isExpired(DateTime now) => !expiresAt.isAfter(now);
  bool get isUsedUp => maxUses != null && useCount >= maxUses!;

  /// Whether the link can still be used at [now].
  bool isUsable(DateTime now) => !isRevoked && !isExpired(now) && !isUsedUp;

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'token': token,
    'expires_at': formatTimestamp(expiresAt),
    'band_id': bandId,
    'created_by': createdBy,
    'created_at': formatTimestamp(createdAt),
    'max_uses': maxUses,
    'use_count': useCount,
    'revoked_at': formatTimestamp(revokedAt),
  };

  @override
  List<Object?> get props => [
    id,
    organizationId,
    token,
    expiresAt,
    bandId,
    createdBy,
    createdAt,
    maxUses,
    useCount,
    revokedAt,
  ];
}

enum InvitationStatus {
  pending,
  accepted,
  declined,
  cancelled;

  static InvitationStatus parse(Object? value) =>
      values.firstWhere((s) => s.name == value, orElse: () => pending);
}

class Invitation extends Equatable {
  const Invitation({
    required this.id,
    required this.organizationId,
    required this.invitedUserId,
    this.bandId,
    this.invitedBy,
    this.status = InvitationStatus.pending,
    this.createdAt,
    this.respondedAt,
    this.organizationName,
  });

  /// [json] is a row of `invitations`; the organization name may be embedded
  /// as `organizations(name)`.
  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
    id: json['id'] as String,
    organizationId: json['organization_id'] as String,
    invitedUserId: json['invited_user_id'] as String,
    bandId: json['band_id'] as String?,
    invitedBy: json['invited_by'] as String?,
    status: InvitationStatus.parse(json['status']),
    createdAt: parseTimestamp(json['created_at']),
    respondedAt: parseTimestamp(json['responded_at']),
    organizationName: json['organizations'] is Map
        ? (json['organizations'] as Map)['name'] as String?
        : json['organization_name'] as String?,
  );

  final String id;
  final String organizationId;
  final String invitedUserId;
  final String? bandId;
  final String? invitedBy;
  final InvitationStatus status;
  final DateTime? createdAt;
  final DateTime? respondedAt;
  final String? organizationName;

  bool get isPending => status == InvitationStatus.pending;

  Invitation withOrganizationName(String? name) => Invitation(
    id: id,
    organizationId: organizationId,
    invitedUserId: invitedUserId,
    bandId: bandId,
    invitedBy: invitedBy,
    status: status,
    createdAt: createdAt,
    respondedAt: respondedAt,
    organizationName: organizationName ?? name,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'invited_user_id': invitedUserId,
    'band_id': bandId,
    'invited_by': invitedBy,
    'status': status.name,
    'created_at': formatTimestamp(createdAt),
    'responded_at': formatTimestamp(respondedAt),
    'organization_name': organizationName,
  };

  @override
  List<Object?> get props => [
    id,
    organizationId,
    invitedUserId,
    bandId,
    invitedBy,
    status,
    createdAt,
    respondedAt,
    organizationName,
  ];
}
