/// Battuta — Team Group Entity.
///
/// Models sub-teams, rotating worship groups, and arrangement clusters
/// (e.g. Band Alpha, Band Beta, Acoustic Team) where members frequently
/// perform together.
library;

import 'package:equatable/equatable.dart';

class TeamGroup extends Equatable {
  const TeamGroup({
    required this.id,
    required this.name,
    this.description,
    this.colorValue = 0xFFE5A93C,
  });

  /// Unique identifier for this group.
  final String id;

  /// Display name (e.g. "Alpha Team", "Acoustic Band").
  final String name;

  /// Optional description or notes for the group.
  final String? description;

  /// Color representation for UI tags and badges.
  final int colorValue;

  TeamGroup copyWith({
    String? id,
    String? name,
    String? description,
    int? colorValue,
  }) {
    return TeamGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  @override
  List<Object?> get props => [id, name, description, colorValue];
}
