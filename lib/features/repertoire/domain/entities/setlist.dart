/// Battuta — Setlist entity.
///
/// Models an ordered set of songs for a rehearsal or worship service,
/// with support for key overrides, set notes, and offline persistence.
library;

import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';

/// An immutable collection of songs prepared for a specific service or rehearsal.
class Setlist {
  /// Creates a [Setlist].
  const Setlist({
    required this.id,
    required this.title,
    this.description,
    this.eventDate,
    this.items = const [],
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for this setlist.
  final String id;

  /// Display title (e.g. `"Sunday Morning - Easter 2026"`).
  final String title;

  /// Optional description or notes for the set.
  final String? description;

  /// Date and time when the service or event occurs.
  final DateTime? eventDate;

  /// Ordered songs included in this setlist.
  final List<SetlistItem> items;

  /// Tags for filtering (e.g. `["Sunday", "Acoustic", "Youth"]`).
  final List<String> tags;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last modification timestamp.
  final DateTime updatedAt;

  /// Count of songs in the setlist.
  int get songCount => items.length;

  /// Converts this [Setlist] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'eventDate': eventDate?.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Constructs a [Setlist] from a JSON map.
  factory Setlist.fromJson(Map<String, dynamic> json) => Setlist(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        eventDate: json['eventDate'] != null
            ? DateTime.parse(json['eventDate'] as String)
            : null,
        items: (json['items'] as List<dynamic>?)
                ?.map((i) => SetlistItem.fromJson(i as Map<String, dynamic>))
                .toList() ??
            const [],
        tags: (json['tags'] as List<dynamic>?)
                ?.map((t) => t as String)
                .toList() ??
            const [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  /// Creates a copy of this [Setlist] with optional updated fields.
  Setlist copyWith({
    String? id,
    String? title,
    String? description,
    bool clearDescription = false,
    DateTime? eventDate,
    bool clearEventDate = false,
    List<SetlistItem>? items,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Setlist(
      id: id ?? this.id,
      title: title ?? this.title,
      description:
          clearDescription ? null : (description ?? this.description),
      eventDate: clearEventDate ? null : (eventDate ?? this.eventDate),
      items: items ?? this.items,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Setlist &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          eventDate == other.eventDate &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          _listEquals(items, other.items) &&
          _listEquals(tags, other.tags);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        eventDate,
        createdAt,
        updatedAt,
        Object.hashAll(items),
        Object.hashAll(tags),
      );

  @override
  String toString() =>
      'Setlist($title, ${items.length} songs${eventDate != null ? ', date: $eventDate' : ''})';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
