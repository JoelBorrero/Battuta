/// Battuta — public profile of an account (`profiles` table).
library;

import 'package:battuta/features/organizations/domain/entities/json_helpers.dart';
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.deactivatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    username: json['username'] as String,
    displayName: json['display_name'] as String,
    avatarUrl: json['avatar_url'] as String?,
    deactivatedAt: parseTimestamp(json['deactivated_at']),
  );

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final DateTime? deactivatedAt;

  /// Whether the account was deactivated (it can no longer use the backend).
  bool get isDeactivated => deactivatedAt != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'deactivated_at': formatTimestamp(deactivatedAt),
  };

  @override
  List<Object?> get props => [id, username, displayName, avatarUrl, deactivatedAt];
}
