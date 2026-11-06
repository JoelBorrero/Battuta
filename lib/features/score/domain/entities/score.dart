/// Battuta — Musical score entity.
///
/// Root entity of the score domain hierarchy containing song metadata,
/// time signature, key signature, tempo, and ordered musical sections.
library;

import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/section.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';

/// An immutable representation of a complete musical score.
class Score {
  /// Creates an immutable [Score].
  const Score({
    required this.id,
    required this.title,
    this.composer,
    this.artist,
    this.timeSignature = TimeSignature.fourFour,
    this.keySignature = 'C',
    this.tempo = 120,
    this.sections = const [],
    this.metadata = const {},
  })  : assert(tempo > 0 && tempo <= 400, 'tempo must be between 1 and 400 BPM');

  /// Unique identifier for this score.
  final String id;

  /// Song / piece title.
  final String title;

  /// Composer or arranger name.
  final String? composer;

  /// Performing artist or worship band name.
  final String? artist;

  /// Primary time signature for the score.
  final TimeSignature timeSignature;

  /// Key signature name (e.g. `"C"`, `"G"`, `"F#m"`).
  final String keySignature;

  /// Playback and rehearsal tempo in Beats Per Minute (BPM).
  final int tempo;

  /// Ordered sections making up the song arrangement.
  final List<Section> sections;

  /// Additional extensible metadata (e.g., CCLI license number, copyright, tags).
  final Map<String, dynamic> metadata;

  /// Converts this [Score] to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'composer': composer,
        'artist': artist,
        'timeSignature': timeSignature.toJson(),
        'keySignature': keySignature,
        'tempo': tempo,
        'sections': sections.map((s) => s.toJson()).toList(),
        'metadata': metadata,
      };

  /// Constructs a [Score] from a JSON map.
  factory Score.fromJson(Map<String, dynamic> json) => Score(
        id: json['id'] as String,
        title: json['title'] as String,
        composer: json['composer'] as String?,
        artist: json['artist'] as String?,
        timeSignature: json['timeSignature'] != null
            ? TimeSignature.fromJson(
                json['timeSignature'] as Map<String, dynamic>)
            : TimeSignature.fourFour,
        keySignature: json['keySignature'] as String? ?? 'C',
        tempo: json['tempo'] as int? ?? 120,
        sections: (json['sections'] as List<dynamic>?)
                ?.map((s) => Section.fromJson(s as Map<String, dynamic>))
                .toList() ??
            const [],
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      );

  // ---------------------------------------------------------------------------
  // Traversal & Metric Helpers
  // ---------------------------------------------------------------------------

  /// Flattened list of all measures across all sections in presentation order.
  List<Measure> get allMeasures =>
      sections.expand((section) => section.measures).toList();

  /// Total count of measures in the arrangement.
  int get totalMeasures => allMeasures.length;

  /// Total duration of the entire score arrangement in MIDI ticks,
  /// including section repeats.
  int get totalTicks =>
      sections.fold(0, (sum, section) => sum + section.totalPerformanceTicks);

  /// Estimated duration of the piece based on [tempo] and [totalTicks].
  Duration get estimatedDuration {
    if (tempo == 0 || totalTicks == 0) return Duration.zero;
    // 480 ticks = 1 quarter-note beat.
    // seconds = (ticks / 480) * (60 / tempo)
    final totalMilliseconds =
        ((totalTicks / 480.0) * (60000.0 / tempo)).round();
    return Duration(milliseconds: totalMilliseconds);
  }

  /// Finds a section by its unique [id]. Returns `null` if not found.
  Section? findSectionById(String sectionId) {
    for (final section in sections) {
      if (section.id == sectionId) return section;
    }
    return null;
  }

  /// Finds a section linked to an external presentation software UUID ([externalSyncId]).
  ///
  /// Used by v1.1 ProPresenter sync handlers.
  Section? findSectionByExternalSyncId(String syncId) {
    for (final section in sections) {
      if (section.externalSyncId == syncId) return section;
    }
    return null;
  }

  /// Immutably updates the pitch of a note in the score tree at the specified coordinates.
  Score updateNotePitch({
    required String sectionId,
    required int measureNumber,
    required int eventIndex,
    required Pitch newPitch,
  }) {
    final updatedSections = sections.map((sec) {
      if (sec.id != sectionId) return sec;
      final updatedMeasures = sec.measures.map((meas) {
        if (meas.number != measureNumber) return meas;
        return meas.dragPitchAt(eventIndex, newPitch);
      }).toList();
      return sec.copyWith(measures: List.unmodifiable(updatedMeasures));
    }).toList();

    return copyWith(sections: List.unmodifiable(updatedSections));
  }

  /// Creates a copy of this [Score] with optional updated fields.
  Score copyWith({
    String? id,
    String? title,
    String? composer,
    String? artist,
    TimeSignature? timeSignature,
    String? keySignature,
    int? tempo,
    List<Section>? sections,
    Map<String, dynamic>? metadata,
  }) {
    return Score(
      id: id ?? this.id,
      title: title ?? this.title,
      composer: composer ?? this.composer,
      artist: artist ?? this.artist,
      timeSignature: timeSignature ?? this.timeSignature,
      keySignature: keySignature ?? this.keySignature,
      tempo: tempo ?? this.tempo,
      sections: sections ?? this.sections,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Score &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          composer == other.composer &&
          artist == other.artist &&
          timeSignature == other.timeSignature &&
          keySignature == other.keySignature &&
          tempo == other.tempo &&
          _listEquals(sections, other.sections);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        composer,
        artist,
        timeSignature,
        keySignature,
        tempo,
        Object.hashAll(sections),
      );

  @override
  String toString() =>
      'Score($title by ${artist ?? composer ?? "Unknown"}, $keySignature, $tempo BPM, ${sections.length} sections)';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

