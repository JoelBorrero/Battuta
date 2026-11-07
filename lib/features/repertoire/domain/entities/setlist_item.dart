/// Battuta — Setlist item entity.
///
/// Models a reference to a song in a performance setlist with ordering
/// and setlist-specific key/tempo/note overrides.
library;

/// An immutable item within a [Setlist].
class SetlistItem {
  /// Creates a [SetlistItem].
  const SetlistItem({
    required this.id,
    required this.songId,
    required this.orderIndex,
    this.keyOverride,
    this.tempoOverride,
    this.notes,
  }) : assert(orderIndex >= 0, 'orderIndex cannot be negative');

  /// Unique identifier for this setlist entry.
  final String id;

  /// Identifier of the referenced [Song].
  final String songId;

  /// Position of the song in the setlist (0-indexed).
  final int orderIndex;

  /// Optional performance key override for this setlist (e.g. `"Bb"` instead of original `"C"`).
  final String? keyOverride;

  /// Optional performance tempo override in BPM.
  final int? tempoOverride;

  /// Performance-specific rehearsal or cue notes.
  final String? notes;

  /// Converts this [SetlistItem] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'songId': songId,
    'orderIndex': orderIndex,
    'keyOverride': keyOverride,
    'tempoOverride': tempoOverride,
    'notes': notes,
  };

  /// Constructs a [SetlistItem] from a JSON map.
  factory SetlistItem.fromJson(Map<String, dynamic> json) => SetlistItem(
    id: json['id'] as String,
    songId: json['songId'] as String,
    orderIndex: json['orderIndex'] as int,
    keyOverride: json['keyOverride'] as String?,
    tempoOverride: json['tempoOverride'] as int?,
    notes: json['notes'] as String?,
  );

  /// Creates a copy of this [SetlistItem] with optional updated fields.
  SetlistItem copyWith({
    String? id,
    String? songId,
    int? orderIndex,
    String? keyOverride,
    bool clearKeyOverride = false,
    int? tempoOverride,
    bool clearTempoOverride = false,
    String? notes,
    bool clearNotes = false,
  }) {
    return SetlistItem(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      orderIndex: orderIndex ?? this.orderIndex,
      keyOverride: clearKeyOverride ? null : (keyOverride ?? this.keyOverride),
      tempoOverride: clearTempoOverride
          ? null
          : (tempoOverride ?? this.tempoOverride),
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetlistItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          songId == other.songId &&
          orderIndex == other.orderIndex &&
          keyOverride == other.keyOverride &&
          tempoOverride == other.tempoOverride &&
          notes == other.notes;

  @override
  int get hashCode =>
      Object.hash(id, songId, orderIndex, keyOverride, tempoOverride, notes);

  @override
  String toString() =>
      'SetlistItem(#$orderIndex: song $songId${keyOverride != null ? ' in $keyOverride' : ''})';
}
