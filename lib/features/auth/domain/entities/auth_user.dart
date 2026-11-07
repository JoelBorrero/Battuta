/// Battuta — Authenticated User Entity.
///
/// Immutable domain model representing a Musical Director or team member
/// authenticated with the cloud backend.
library;

import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.createdAt,
    this.metadata = const {},
  });

  /// Unique Supabase user UUID.
  final String id;

  /// User account email.
  final String email;

  /// Optional display name.
  final String? displayName;

  /// Timestamp when the account was registered.
  final DateTime? createdAt;

  /// Additional raw user metadata from the auth provider.
  final Map<String, dynamic> metadata;

  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [id, email, displayName, createdAt, metadata];
}
