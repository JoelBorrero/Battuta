/// Battuta — Musical measure entity.
///
/// Encapsulates a single bar/measure of music, containing note events,
/// chord symbols, time signature constraints, and tick capacity validation.
library;

import 'package:battuta/core/errors/exceptions.dart';
import 'package:battuta/features/score/domain/entities/chord_symbol.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';

/// Immutable representation of a measure (bar) in a score.
class Measure {
  /// Creates a [Measure].
  const Measure({
    required this.number,
    this.timeSignature = TimeSignature.fourFour,
    this.events = const [],
    this.chords = const [],
  }) : assert(number >= 1, 'Measure number must be 1 or greater');

  /// 1-based measure index in the score.
  final int number;

  /// Time signature defining the meter and maximum tick capacity.
  final TimeSignature timeSignature;

  /// Ordered musical note events (pitches and rests) within this measure.
  final List<NoteEvent> events;

  /// Harmonic chord symbols positioned in this measure.
  final List<ChordSymbol> chords;

  /// Converts this [Measure] to a JSON map.
  Map<String, dynamic> toJson() => {
        'number': number,
        'timeSignature': timeSignature.toJson(),
        'events': events.map((e) => e.toJson()).toList(),
        'chords': chords.map((c) => c.toJson()).toList(),
      };

  /// Constructs a [Measure] from a JSON map.
  factory Measure.fromJson(Map<String, dynamic> json) => Measure(
        number: json['number'] as int,
        timeSignature:
            TimeSignature.fromJson(json['timeSignature'] as Map<String, dynamic>),
        events: (json['events'] as List<dynamic>?)
                ?.map((e) => NoteEvent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        chords: (json['chords'] as List<dynamic>?)
                ?.map((c) => ChordSymbol.fromJson(c as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  // ---------------------------------------------------------------------------
  // Capacity & Duration Metrics
  // ---------------------------------------------------------------------------

  /// Total duration of all note events in this measure, in MIDI ticks.
  int get totalTicks =>
      events.fold(0, (sum, event) => sum + event.rhythmicValue.ticks);

  /// Maximum allowed duration in MIDI ticks as defined by [timeSignature].
  int get maxTicks => timeSignature.maxTicks;

  /// Remaining tick capacity in this measure before reaching [maxTicks].
  int get remainingTicks => maxTicks - totalTicks;

  /// Whether this measure is completely filled to its maximum capacity.
  bool get isComplete => totalTicks == maxTicks;

  /// Whether the events in this measure exceed the allowed [maxTicks].
  bool get hasOverflow => totalTicks > maxTicks;

  /// Whether this measure contains no note events.
  bool get isEmpty => events.isEmpty;

  /// Number of note events with [RhythmicValue.unassigned] (0 ticks).
  int get unassignedCount =>
      events.where((e) => e.rhythmicValue.isUnassigned).length;

  /// Whether any note event in this measure has unassigned rhythm.
  bool get hasUnassignedEvents =>
      events.any((e) => e.rhythmicValue.isUnassigned);

  /// Fraction of measure capacity filled (0.0 to 1.0).
  double get fillRatio =>
      maxTicks == 0 ? 0.0 : (totalTicks / maxTicks).clamp(0.0, 1.0);

  /// Checks if assigning [rhythm] to [eventIndex] would fit within [maxTicks].
  bool canFitRhythmAt(int eventIndex, RhythmicValue rhythm) {
    if (eventIndex < 0 || eventIndex >= events.length) return false;
    final currentTicks = events[eventIndex].rhythmicValue.ticks;
    return (totalTicks - currentTicks + rhythm.ticks) <= maxTicks;
  }

  /// Checks if adding an event of [durationTicks] would fit within [maxTicks].
  bool canFitDuration(int durationTicks) =>
      (totalTicks + durationTicks) <= maxTicks;

  /// Throws [MeasureOverflowException] if [hasOverflow] is `true`.
  void validateMeasureCapacity() {
    if (hasOverflow) {
      throw MeasureOverflowException(
        message: 'Measure #$number exceeds time signature capacity: '
            '$totalTicks ticks > $maxTicks ticks ($timeSignature).',
        maxTicks: maxTicks,
        attemptedTicks: totalTicks,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Factory Constructors
  // ---------------------------------------------------------------------------

  /// Constructs a [Measure] from a list of raw Gemini OMR pitch strings.
  ///
  /// Instantiates each [NoteEvent] with neutral [RhythmicValue.unassigned] (0 ticks),
  /// ready for subsequent tap-rhythm assignment.
  factory Measure.fromGeminiPitchList(
    List<String> pitches, {
    int number = 1,
    TimeSignature timeSignature = TimeSignature.fourFour,
    String Function(int index)? idGenerator,
  }) {
    final events = <NoteEvent>[];
    for (var i = 0; i < pitches.length; i++) {
      final id = idGenerator != null ? idGenerator(i) : 'm$number-e$i';
      final pitch = Pitch.parse(pitches[i]);
      events.add(
        NoteEvent.note(
          id: id,
          pitch: pitch,
          rhythmicValue: RhythmicValue.unassigned,
          tickOffset: 0,
        ),
      );
    }

    return Measure(
      number: number,
      timeSignature: timeSignature,
      events: List.unmodifiable(events),
    );
  }

  // ---------------------------------------------------------------------------
  // Rhythmic Editing & Capacity Validation
  // ---------------------------------------------------------------------------

  /// Assigns a new [rhythm] to the event at [eventIndex].
  ///
  /// Throws [RangeError] if [eventIndex] is out of bounds.
  /// Throws [MeasureOverflowException] if assigning [rhythm] causes [totalTicks]
  /// to exceed [maxTicks].
  ///
  /// Recalculates contiguous [NoteEvent.tickOffset] positions for all events.
  Measure assignRhythmAt(int eventIndex, RhythmicValue rhythm) {
    if (eventIndex < 0 || eventIndex >= events.length) {
      throw RangeError.index(eventIndex, events, 'eventIndex');
    }

    final currentEventTicks = events[eventIndex].rhythmicValue.ticks;
    final projectedTotalTicks = totalTicks - currentEventTicks + rhythm.ticks;

    if (projectedTotalTicks > maxTicks) {
      throw MeasureOverflowException(
        message: 'Assigning rhythm exceeds measure capacity: '
            'attempted $projectedTotalTicks ticks, max is $maxTicks ticks for $timeSignature.',
        maxTicks: maxTicks,
        attemptedTicks: projectedTotalTicks,
      );
    }

    final updatedEvents = <NoteEvent>[];
    var currentOffset = 0;

    for (var i = 0; i < events.length; i++) {
      final oldEvent = events[i];
      final duration = (i == eventIndex) ? rhythm : oldEvent.rhythmicValue;

      updatedEvents.add(
        oldEvent.copyWith(
          rhythmicValue: duration,
          tickOffset: currentOffset,
        ),
      );

      currentOffset += duration.ticks;
    }

    return copyWith(events: List.unmodifiable(updatedEvents));
  }

  /// Toggles rest state for the note event at [eventIndex].
  Measure toggleRestAt(int eventIndex, {Pitch defaultPitch = Pitch.middleC}) {
    if (eventIndex < 0 || eventIndex >= events.length) {
      throw RangeError.index(eventIndex, events, 'eventIndex');
    }

    final oldEvent = events[eventIndex];
    final updatedEvent = oldEvent.isRest
        ? oldEvent.copyWith(pitch: defaultPitch)
        : oldEvent.copyWith(clearPitch: true);

    final updatedList = List<NoteEvent>.from(events);
    updatedList[eventIndex] = updatedEvent;

    return copyWith(events: List.unmodifiable(updatedList));
  }

  /// Toggles tie state for the note event at [eventIndex].
  Measure toggleTieAt(int eventIndex) {
    if (eventIndex < 0 || eventIndex >= events.length) {
      throw RangeError.index(eventIndex, events, 'eventIndex');
    }

    final oldEvent = events[eventIndex];
    final updatedEvent = oldEvent.copyWith(isTied: !oldEvent.isTied);

    final updatedList = List<NoteEvent>.from(events);
    updatedList[eventIndex] = updatedEvent;

    return copyWith(events: List.unmodifiable(updatedList));
  }

  /// Updates the pitch of the note event at [eventIndex] during vertical drag-and-snap editing.
  ///
  /// Snaps noteheads to lines or spaces and updates the score tree in real time,
  /// preserving rhythmic value, lyrics, ties, and contiguous offsets.
  Measure dragPitchAt(int eventIndex, Pitch newPitch) {
    if (eventIndex < 0 || eventIndex >= events.length) {
      throw RangeError.index(eventIndex, events, 'eventIndex');
    }

    final oldEvent = events[eventIndex];
    final updatedEvent = oldEvent.copyWith(
      pitch: newPitch,
    );

    final updatedEvents = List<NoteEvent>.from(events);
    updatedEvents[eventIndex] = updatedEvent;

    return copyWith(events: List.unmodifiable(updatedEvents));
  }

  /// Appends a new [event] to this measure.
  ///
  /// When [validateCapacity] is `true`, throws [MeasureOverflowException] if the event
  /// would cause the measure to exceed [maxTicks].
  Measure addEvent(NoteEvent event, {bool validateCapacity = false}) {
    if (validateCapacity && (totalTicks + event.rhythmicValue.ticks > maxTicks)) {
      final projectedTicks = totalTicks + event.rhythmicValue.ticks;
      throw MeasureOverflowException(
        message: 'Adding event exceeds measure capacity: '
            'attempted $projectedTicks ticks, max is $maxTicks ticks.',
        maxTicks: maxTicks,
        attemptedTicks: projectedTicks,
      );
    }

    final newOffset = event.tickOffset > 0 || events.isEmpty
        ? event.tickOffset
        : totalTicks;

    final adjustedEvent = event.tickOffset == newOffset
        ? event
        : event.copyWith(tickOffset: newOffset);

    return copyWith(
      events: List.unmodifiable([...events, adjustedEvent]),
    );
  }

  /// Appends a [chord] symbol to this measure.
  Measure addChord(ChordSymbol chord) {
    return copyWith(
      chords: List.unmodifiable([...chords, chord]),
    );
  }

  /// Creates a copy of this [Measure] with optional updated fields.
  Measure copyWith({
    int? number,
    TimeSignature? timeSignature,
    List<NoteEvent>? events,
    List<ChordSymbol>? chords,
  }) {
    return Measure(
      number: number ?? this.number,
      timeSignature: timeSignature ?? this.timeSignature,
      events: events ?? this.events,
      chords: chords ?? this.chords,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Measure &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          timeSignature == other.timeSignature &&
          _listEquals(events, other.events) &&
          _listEquals(chords, other.chords);

  @override
  int get hashCode => Object.hash(
        number,
        timeSignature,
        Object.hashAll(events),
        Object.hashAll(chords),
      );

  @override
  String toString() =>
      'Measure #$number ($timeSignature, $totalTicks/${maxTicks}t, ${events.length} events, ${chords.length} chords)';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
