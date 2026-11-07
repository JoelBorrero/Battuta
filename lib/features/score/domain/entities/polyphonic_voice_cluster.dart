/// Battuta — Polyphonic Voice Cluster Entity.
///
/// Models multiple simultaneous [Pitch] instances on the same beat sharing
/// a single stem and [RhythmicValue] for keyboard, vocal, and polyphonic engraving.
library;

import 'package:flutter/foundation.dart';

import 'note_event.dart';
import 'pitch.dart';
import 'rhythmic_value.dart';

@immutable
class PolyphonicVoiceCluster {
  PolyphonicVoiceCluster({
    required this.id,
    required List<Pitch> pitches,
    required this.rhythmicValue,
    this.tickOffset = 0,
    this.isTied = false,
    this.lyric,
    this.velocity = 80,
  }) : assert(tickOffset >= 0, 'tickOffset cannot be negative'),
       assert(
         velocity >= 0 && velocity <= 127,
         'velocity must be within MIDI range [0, 127]',
       ),
       pitches = List<Pitch>.unmodifiable(
         List<Pitch>.from(pitches)..sort((a, b) => a.compareTo(b)),
       );

  /// Unique identifier for this cluster event.
  final String id;

  /// Ordered pitches sounding simultaneously, from lowest to highest.
  final List<Pitch> pitches;

  /// Duration of this cluster event.
  final RhythmicValue rhythmicValue;

  /// Start offset within the measure in MIDI ticks.
  final int tickOffset;

  /// Whether this cluster is tied to the subsequent event.
  final bool isTied;

  /// Optional lyric syllable aligned to this cluster.
  final String? lyric;

  /// Playback velocity (0 to 127).
  final int velocity;

  /// Whether this cluster represents a musical rest (no pitches).
  bool get isRest => pitches.isEmpty;

  /// Whether this event contains more than one sounding pitch (a polyphonic chord).
  bool get isChord => pitches.length > 1;

  /// Lowest sounding pitch in the chord stack, or null if rest.
  Pitch? get lowestPitch => pitches.isEmpty ? null : pitches.first;

  /// Highest sounding pitch in the chord stack, or null if rest.
  Pitch? get highestPitch => pitches.isEmpty ? null : pitches.last;

  /// Duration in MIDI ticks.
  int get ticks => rhythmicValue.ticks;

  /// Constructs a [PolyphonicVoiceCluster] from a single [NoteEvent].
  factory PolyphonicVoiceCluster.fromNoteEvent(NoteEvent note) {
    return PolyphonicVoiceCluster(
      id: note.id,
      pitches: note.pitch != null ? [note.pitch!] : const [],
      rhythmicValue: note.rhythmicValue,
      tickOffset: note.tickOffset,
      isTied: note.isTied,
      lyric: note.lyric,
      velocity: note.velocity,
    );
  }

  /// Converts this cluster into individual [NoteEvent] instances.
  List<NoteEvent> toNoteEvents() {
    if (pitches.isEmpty) {
      return [
        NoteEvent.rest(
          id: id,
          rhythmicValue: rhythmicValue,
          tickOffset: tickOffset,
        ),
      ];
    }
    return pitches
        .map(
          (p) => NoteEvent.note(
            id: '${id}_${p.scientificNotation}',
            pitch: p,
            rhythmicValue: rhythmicValue,
            tickOffset: tickOffset,
            isTied: isTied,
            lyric: lyric,
            velocity: velocity,
          ),
        )
        .toList();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pitches': pitches.map((p) => p.toJson()).toList(),
    'rhythmicValue': rhythmicValue.toJson(),
    'tickOffset': tickOffset,
    'isTied': isTied,
    'lyric': lyric,
    'velocity': velocity,
  };

  factory PolyphonicVoiceCluster.fromJson(Map<String, dynamic> json) {
    final pitchesList =
        (json['pitches'] as List<dynamic>?)
            ?.map((p) => Pitch.fromJson(p as Map<String, dynamic>))
            .toList() ??
        const [];

    return PolyphonicVoiceCluster(
      id: json['id'] as String,
      pitches: pitchesList,
      rhythmicValue: RhythmicValue.fromJson(
        json['rhythmicValue'] as Map<String, dynamic>,
      ),
      tickOffset: (json['tickOffset'] as num?)?.toInt() ?? 0,
      isTied: (json['isTied'] as bool?) ?? false,
      lyric: json['lyric'] as String?,
      velocity: (json['velocity'] as num?)?.toInt() ?? 80,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolyphonicVoiceCluster &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          listEquals(pitches, other.pitches) &&
          rhythmicValue == other.rhythmicValue &&
          tickOffset == other.tickOffset &&
          isTied == other.isTied &&
          lyric == other.lyric &&
          velocity == other.velocity;

  @override
  int get hashCode => Object.hash(
    id,
    Object.hashAll(pitches),
    rhythmicValue,
    tickOffset,
    isTied,
    lyric,
    velocity,
  );

  @override
  String toString() =>
      'PolyphonicVoiceCluster(id: $id, pitches: ${pitches.map((p) => p.scientificNotation).toList()}, ticks: $ticks)';
}
