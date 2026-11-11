/// In-app notifications created by the backend (triggers and RPCs).
library;

import 'package:battuta/features/organizations/domain/entities/json_helpers.dart';
import 'package:equatable/equatable.dart';

enum NotificationType {
  invitation('invitation'),
  roleChanged('role_changed'),
  removed('removed'),
  memberProfileEdited('member_profile_edited'),
  eventAssigned('event_assigned'),
  eventUnassigned('event_unassigned'),
  assignmentDeclined('assignment_declined'),
  archiveRequested('archive_requested'),
  archiveCancelled('archive_cancelled'),
  archiveCompleted('archive_completed'),
  songVersionForked('song_version_forked'),
  songMergeRequested('song_merge_requested'),
  songMergeAccepted('song_merge_accepted'),
  songMergeDeclined('song_merge_declined'),

  /// A type this app version does not know yet.
  unknown('unknown');

  const NotificationType(this.wire);

  final String wire;

  static NotificationType parse(Object? value) =>
      values.firstWhere((t) => t.wire == value, orElse: () => unknown);
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    this.rawType,
    this.organizationId,
    this.payload = const {},
    this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        recipientId: json['recipient_id'] as String,
        type: NotificationType.parse(json['type']),
        rawType: json['type'] as String?,
        organizationId: json['organization_id'] as String?,
        payload: parseJsonMap(json['payload']),
        createdAt: parseTimestamp(json['created_at']),
        readAt: parseTimestamp(json['read_at']),
      );

  final String id;
  final String recipientId;
  final NotificationType type;

  /// The type string as sent by the backend (useful for [NotificationType.unknown]).
  final String? rawType;
  final String? organizationId;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  AppNotification markRead(DateTime at) => AppNotification(
    id: id,
    recipientId: recipientId,
    type: type,
    rawType: rawType,
    organizationId: organizationId,
    payload: payload,
    createdAt: createdAt,
    readAt: readAt ?? at,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipient_id': recipientId,
    'type': rawType ?? type.wire,
    'organization_id': organizationId,
    'payload': payload,
    'created_at': formatTimestamp(createdAt),
    'read_at': formatTimestamp(readAt),
  };

  @override
  List<Object?> get props => [
    id,
    recipientId,
    type,
    rawType,
    organizationId,
    payload,
    createdAt,
    readAt,
  ];
}
