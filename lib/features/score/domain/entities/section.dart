/// Battuta — Song section score entity.
///
/// Groups measures into discrete rehearsal blocks (e.g., Intro, Verse, Chorus)
/// and provides synchronization hooks for external stage presentation software.
library;

import 'package:battuta/features/score/domain/entities/measure.dart';

/// An immutable representation of a score section containing sequential measures.
///
/// Includes an [externalSyncId] field reserved for v1.1 live stage synchronization
/// (e.g. ProPresenter 7+ Presentation Group UUIDs).
class Section {
  /// Creates an immutable [Section].
  const Section({
    required this.id,
    required this.name,
    this.externalSyncId,
    this.measures = const [],
    this.repeatCount = 1,
    this.orderIndex = 0,
  })  : assert(repeatCount >= 1, 'repeatCount must be at least 1'),
        assert(orderIndex >= 0, 'orderIndex cannot be negative');

  /// Unique identifier for this section within the score.
  final String id;

  /// Display name of the section (e.g., `"Intro"`, `"Verse 1"`, `"Chorus"`, `"Bridge"`).
  final String name;

  /// External synchronization ID reserved for v1.1 integrations
  /// (e.g., ProPresenter Group UUID).
  ///
  /// Null if not linked to an external presentation software group.
  final String? externalSyncId;

  /// Ordered list of measures contained in this section.
  final List<Measure> measures;

  /// Number of times this section is repeated in the song arrangement.
  final int repeatCount;

  /// Zero-based display order index within the parent score.
  final int orderIndex;

  /// Converts this [Section] to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'externalSyncId': externalSyncId,
        'measures': measures.map((m) => m.toJson()).toList(),
        'repeatCount': repeatCount,
        'orderIndex': orderIndex,
      };

  /// Constructs a [Section] from a JSON map.
  factory Section.fromJson(Map<String, dynamic> json) => Section(
        id: json['id'] as String,
        name: json['name'] as String,
        externalSyncId: json['externalSyncId'] as String?,
        measures: (json['measures'] as List<dynamic>?)
                ?.map((m) => Measure.fromJson(m as Map<String, dynamic>))
                .toList() ??
            const [],
        repeatCount: json['repeatCount'] as int? ?? 1,
        orderIndex: json['orderIndex'] as int? ?? 0,
      );

  // ---------------------------------------------------------------------------
  // Metrics & Helpers
  // ---------------------------------------------------------------------------

  /// Total count of measures in this section.
  int get totalMeasures => measures.length;

  /// Total duration of all measures in this section in MIDI ticks (single pass).
  int get totalTicks =>
      measures.fold(0, (sum, measure) => sum + measure.totalTicks);

  /// Total duration of this section accounting for [repeatCount].
  int get totalPerformanceTicks => totalTicks * repeatCount;

  /// Whether this section is linked to an external software sync ID.
  bool get isSynced => externalSyncId != null && externalSyncId!.isNotEmpty;

  /// Creates a copy of this [Section] with optional updated fields.
  Section copyWith({
    String? id,
    String? name,
    String? externalSyncId,
    bool clearExternalSyncId = false,
    List<Measure>? measures,
    int? repeatCount,
    int? orderIndex,
  }) {
    return Section(
      id: id ?? this.id,
      name: name ?? this.name,
      externalSyncId: clearExternalSyncId
          ? null
          : (externalSyncId ?? this.externalSyncId),
      measures: measures ?? this.measures,
      repeatCount: repeatCount ?? this.repeatCount,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Section &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          externalSyncId == other.externalSyncId &&
          repeatCount == other.repeatCount &&
          orderIndex == other.orderIndex &&
          _listEquals(measures, other.measures);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        externalSyncId,
        repeatCount,
        orderIndex,
        Object.hashAll(measures),
      );

  @override
  String toString() =>
      'Section($name, #$id, ${measures.length} measures${isSynced ? ', sync: $externalSyncId' : ''})';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

