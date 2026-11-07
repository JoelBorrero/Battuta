/// Battuta — Note event entity.
///
/// Models a single musical event (pitched note or musical rest) with duration,
/// measure tick placement, tie flags, and lyric syllables.
library;

import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';

/// An immutable representation of a single note or rest within a measure.
class NoteEvent {
  /// Creates a [NoteEvent].
  const NoteEvent({
    required this.id,
    this.pitch,
    required this.rhythmicValue,
    this.tickOffset = 0,
    this.isTied = false,
    this.lyric,
    this.velocity = 80,
  }) : assert(tickOffset >= 0, 'tickOffset cannot be negative'),
       assert(
         velocity >= 0 && velocity <= 127,
         'velocity must be within MIDI range [0, 127]',
       );

  /// Creates a pitched note event.
  const NoteEvent.note({
    required this.id,
    required Pitch this.pitch,
    required this.rhythmicValue,
    this.tickOffset = 0,
    this.isTied = false,
    this.lyric,
    this.velocity = 80,
  }) : assert(tickOffset >= 0, 'tickOffset cannot be negative'),
       assert(
         velocity >= 0 && velocity <= 127,
         'velocity must be within MIDI range [0, 127]',
       );

  /// Creates a musical rest event (pitch is null, velocity is 0).
  const NoteEvent.rest({
    required this.id,
    required this.rhythmicValue,
    this.tickOffset = 0,
  }) : pitch = null,
       isTied = false,
       lyric = null,
       velocity = 0,
       assert(tickOffset >= 0, 'tickOffset cannot be negative');

  /// Unique identifier for this note event.
  final String id;

  /// Pitch of the note, or `null` if this event is a musical rest.
  final Pitch? pitch;

  /// Duration of this event in musical ticks.
  final RhythmicValue rhythmicValue;

  /// Start offset within the measure in MIDI ticks.
  final int tickOffset;

  /// Whether this note is tied to the subsequent note event.
  final bool isTied;

  /// Optional vocal lyric syllable attached to this note.
  final String? lyric;

  /// MIDI playback velocity (0 to 127).
  final int velocity;

  /// Whether this event is a musical rest (`pitch == null`).
  bool get isRest => pitch == null;

  /// Whether this event is a sounding note (`pitch != null`).
  bool get isNote => pitch != null;

  /// List of sounding pitches in this event (single pitch or empty if rest).
  List<Pitch> get pitches => pitch != null ? [pitch!] : const [];

  /// Whether this note event contains multiple simultaneous pitches.
  bool get isChord => false;

  /// Duration of this note event in MIDI ticks.
  int get ticks => rhythmicValue.ticks;

  /// Converts this [NoteEvent] to a JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'pitch': pitch?.toJson(),
    'rhythmicValue': rhythmicValue.toJson(),
    'tickOffset': tickOffset,
    'isTied': isTied,
    'lyric': lyric,
    'velocity': velocity,
  };

  /// Constructs a [NoteEvent] from a JSON map.
  factory NoteEvent.fromJson(Map<String, dynamic> json) => NoteEvent(
    id: json['id'] as String,
    pitch: json['pitch'] != null
        ? Pitch.fromJson(json['pitch'] as Map<String, dynamic>)
        : null,
    rhythmicValue: RhythmicValue.fromJson(
      json['rhythmicValue'] as Map<String, dynamic>,
    ),
    tickOffset: json['tickOffset'] as int? ?? 0,
    isTied: json['isTied'] as bool? ?? false,
    lyric: json['lyric'] as String?,
    velocity: json['velocity'] as int? ?? 80,
  );

  /// Creates a copy of this [NoteEvent] with optional updated fields.
  NoteEvent copyWith({
    String? id,
    Pitch? pitch,
    bool clearPitch = false,
    RhythmicValue? rhythmicValue,
    int? tickOffset,
    bool? isTied,
    String? lyric,
    bool clearLyric = false,
    int? velocity,
  }) {
    return NoteEvent(
      id: id ?? this.id,
      pitch: clearPitch ? null : (pitch ?? this.pitch),
      rhythmicValue: rhythmicValue ?? this.rhythmicValue,
      tickOffset: tickOffset ?? this.tickOffset,
      isTied: isTied ?? this.isTied,
      lyric: clearLyric ? null : (lyric ?? this.lyric),
      velocity: velocity ?? this.velocity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          pitch == other.pitch &&
          rhythmicValue == other.rhythmicValue &&
          tickOffset == other.tickOffset &&
          isTied == other.isTied &&
          lyric == other.lyric &&
          velocity == other.velocity;

  @override
  int get hashCode => Object.hash(
    id,
    pitch,
    rhythmicValue,
    tickOffset,
    isTied,
    lyric,
    velocity,
  );

  @override
  String toString() {
    if (isRest) {
      return 'NoteEvent.rest($rhythmicValue, @${tickOffset}t)';
    }
    return 'NoteEvent($pitch, $rhythmicValue, @${tickOffset}t${isTied ? ', tied' : ''})';
  }
}
