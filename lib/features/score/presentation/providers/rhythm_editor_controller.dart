/// Battuta — Rhythm Editor Controller & State.
///
/// Orchestrates the 'Tap-First' rhythmic editing workflow, tracking active
/// measure capacity, advancing the note cursor, and enforcing time signature
/// tick constraints in real time.
library;

import 'package:battuta/features/score/domain/entities/measure.dart';
import 'package:battuta/features/score/domain/entities/note_event.dart';
import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/rhythmic_value.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:flutter/foundation.dart';

/// Position of the active rhythm editing cursor in the score tree.
class RhythmCursor {
  const RhythmCursor({
    required this.sectionId,
    required this.measureNumber,
    required this.eventIndex,
  });

  final String sectionId;
  final int measureNumber;
  final int eventIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RhythmCursor &&
          runtimeType == other.runtimeType &&
          sectionId == other.sectionId &&
          measureNumber == other.measureNumber &&
          eventIndex == other.eventIndex;

  @override
  int get hashCode => Object.hash(sectionId, measureNumber, eventIndex);

  @override
  String toString() =>
      'RhythmCursor(sec: $sectionId, m: $measureNumber, idx: $eventIndex)';
}

/// State of the active rhythm editing session.
class RhythmEditorState {
  const RhythmEditorState({
    required this.score,
    this.cursor,
  });

  final Score score;
  final RhythmCursor? cursor;

  /// Retrieves the currently active [Measure] under the cursor.
  Measure? get activeMeasure {
    if (cursor == null) return null;
    final section = score.findSectionById(cursor!.sectionId);
    if (section == null) return null;
    for (final m in section.measures) {
      if (m.number == cursor!.measureNumber) return m;
    }
    return null;
  }

  /// Retrieves the currently active [NoteEvent] under the cursor.
  NoteEvent? get activeEvent {
    final measure = activeMeasure;
    if (measure == null || cursor == null) return null;
    if (cursor!.eventIndex < 0 || cursor!.eventIndex >= measure.events.length) {
      return null;
    }
    return measure.events[cursor!.eventIndex];
  }

  /// Total ticks filled in the active measure.
  int get activeMeasureTotalTicks => activeMeasure?.totalTicks ?? 0;

  /// Maximum allowed ticks in the active measure based on its time signature.
  int get activeMeasureMaxTicks => activeMeasure?.maxTicks ?? 0;

  /// Remaining tick capacity in the active measure.
  int get activeMeasureRemainingTicks => activeMeasure?.remainingTicks ?? 0;

  /// Ratio of capacity filled (0.0 to 1.0).
  double get activeMeasureFillRatio => activeMeasure?.fillRatio ?? 0.0;

  /// Whether the active measure is completely filled.
  bool get isActiveMeasureComplete => activeMeasure?.isComplete ?? false;

  /// Whether the active measure exceeds capacity.
  bool get hasActiveMeasureOverflow => activeMeasure?.hasOverflow ?? false;

  /// Checks if [rhythm] fits into the active note event without overflowing the measure.
  bool canFitRhythm(RhythmicValue rhythm) {
    final measure = activeMeasure;
    if (measure == null || cursor == null) return false;
    return measure.canFitRhythmAt(cursor!.eventIndex, rhythm);
  }

  RhythmEditorState copyWith({
    Score? score,
    RhythmCursor? cursor,
    bool clearCursor = false,
  }) {
    return RhythmEditorState(
      score: score ?? this.score,
      cursor: clearCursor ? null : (cursor ?? this.cursor),
    );
  }
}

/// Controller managing rhythm input actions and cursor advancement.
class RhythmEditorController extends ChangeNotifier {
  RhythmEditorController({required Score initialScore})
      : _state = RhythmEditorState(score: initialScore) {
    _autoSelectFirstUnassignedNote();
  }

  RhythmEditorState _state;

  /// Active state of the rhythm editor.
  RhythmEditorState get state => _state;

  /// Sets the active score to edit.
  void setScore(Score score) {
    _state = _state.copyWith(score: score);
    notifyListeners();
  }

  /// Moves the cursor to the note event at [eventIndex] in measure [measureNumber] of section [sectionId].
  void setCursor({
    required String sectionId,
    required int measureNumber,
    required int eventIndex,
  }) {
    _state = _state.copyWith(
      cursor: RhythmCursor(
        sectionId: sectionId,
        measureNumber: measureNumber,
        eventIndex: eventIndex,
      ),
    );
    notifyListeners();
  }

  /// Assigns [rhythm] to the active note under the cursor and advances to the next unassigned note.
  ///
  /// Returns `true` if the rhythm was successfully assigned, or `false` if it exceeds capacity.
  bool assignDuration(RhythmicValue rhythm) {
    final measure = _state.activeMeasure;
    final cursor = _state.cursor;
    if (measure == null || cursor == null) return false;

    if (!measure.canFitRhythmAt(cursor.eventIndex, rhythm)) {
      return false;
    }

    // Update measure with assigned rhythm
    final updatedMeasure = measure.assignRhythmAt(cursor.eventIndex, rhythm);

    // Update score
    final updatedScore = _updateMeasureInScore(
      cursor.sectionId,
      updatedMeasure,
    );

    _state = _state.copyWith(score: updatedScore);

    // Advance cursor to next unassigned note
    _advanceToNextUnassignedNote();
    notifyListeners();
    return true;
  }

  /// Toggles rest state for the active note event.
  void toggleRest() {
    final measure = _state.activeMeasure;
    final cursor = _state.cursor;
    if (measure == null || cursor == null) return;

    final updatedMeasure = measure.toggleRestAt(cursor.eventIndex);
    final updatedScore = _updateMeasureInScore(
      cursor.sectionId,
      updatedMeasure,
    );

    _state = _state.copyWith(score: updatedScore);
    notifyListeners();
  }

  /// Toggles tie on the active note event.
  void toggleTie() {
    final measure = _state.activeMeasure;
    final cursor = _state.cursor;
    if (measure == null || cursor == null) return;

    final updatedMeasure = measure.toggleTieAt(cursor.eventIndex);
    final updatedScore = _updateMeasureInScore(
      cursor.sectionId,
      updatedMeasure,
    );

    _state = _state.copyWith(score: updatedScore);
    notifyListeners();
  }

  /// Updates pitch at cursor (e.g. from vertical drag).
  void updatePitchAtCursor(Pitch newPitch) {
    final measure = _state.activeMeasure;
    final cursor = _state.cursor;
    if (measure == null || cursor == null) return;

    final updatedMeasure = measure.dragPitchAt(cursor.eventIndex, newPitch);
    final updatedScore = _updateMeasureInScore(
      cursor.sectionId,
      updatedMeasure,
    );

    _state = _state.copyWith(score: updatedScore);
    notifyListeners();
  }

  /// Moves cursor to previous note.
  void previousNote() {
    final cursor = _state.cursor;
    final measure = _state.activeMeasure;
    if (cursor == null || measure == null) return;

    if (cursor.eventIndex > 0) {
      setCursor(
        sectionId: cursor.sectionId,
        measureNumber: cursor.measureNumber,
        eventIndex: cursor.eventIndex - 1,
      );
    }
  }

  /// Moves cursor to next note.
  void nextNote() {
    final cursor = _state.cursor;
    final measure = _state.activeMeasure;
    if (cursor == null || measure == null) return;

    if (cursor.eventIndex < measure.events.length - 1) {
      setCursor(
        sectionId: cursor.sectionId,
        measureNumber: cursor.measureNumber,
        eventIndex: cursor.eventIndex + 1,
      );
    }
  }

  Score _updateMeasureInScore(String sectionId, Measure updatedMeasure) {
    final updatedSections = _state.score.sections.map((section) {
      if (section.id != sectionId) return section;
      final updatedMeasures = section.measures.map((m) {
        if (m.number != updatedMeasure.number) return m;
        return updatedMeasure;
      }).toList();
      return section.copyWith(measures: List.unmodifiable(updatedMeasures));
    }).toList();

    return _state.score.copyWith(sections: List.unmodifiable(updatedSections));
  }

  void _autoSelectFirstUnassignedNote() {
    for (final section in _state.score.sections) {
      for (final measure in section.measures) {
        final unassignedIdx =
            measure.events.indexWhere((e) => e.rhythmicValue.isUnassigned);
        if (unassignedIdx != -1) {
          _state = _state.copyWith(
            cursor: RhythmCursor(
              sectionId: section.id,
              measureNumber: measure.number,
              eventIndex: unassignedIdx,
            ),
          );
          return;
        }
      }
    }

    // Fallback: select first note in score
    if (_state.score.sections.isNotEmpty &&
        _state.score.sections.first.measures.isNotEmpty &&
        _state.score.sections.first.measures.first.events.isNotEmpty) {
      _state = _state.copyWith(
        cursor: RhythmCursor(
          sectionId: _state.score.sections.first.id,
          measureNumber: _state.score.sections.first.measures.first.number,
          eventIndex: 0,
        ),
      );
    }
  }

  void _advanceToNextUnassignedNote() {
    final cursor = _state.cursor;
    if (cursor == null) return;

    final section = _state.score.findSectionById(cursor.sectionId);
    if (section == null) return;

    // 1. Search remaining notes in current measure
    final currentMeasure = _state.activeMeasure;
    if (currentMeasure != null) {
      for (var i = cursor.eventIndex + 1;
          i < currentMeasure.events.length;
          i++) {
        if (currentMeasure.events[i].rhythmicValue.isUnassigned) {
          _state = _state.copyWith(
            cursor: RhythmCursor(
              sectionId: cursor.sectionId,
              measureNumber: cursor.measureNumber,
              eventIndex: i,
            ),
          );
          return;
        }
      }
    }

    // 2. Search remaining measures in score
    var passedCurrent = false;
    for (final sec in _state.score.sections) {
      for (final m in sec.measures) {
        if (!passedCurrent) {
          if (sec.id == cursor.sectionId && m.number == cursor.measureNumber) {
            passedCurrent = true;
          }
          continue;
        }

        final unassignedIdx =
            m.events.indexWhere((e) => e.rhythmicValue.isUnassigned);
        if (unassignedIdx != -1) {
          _state = _state.copyWith(
            cursor: RhythmCursor(
              sectionId: sec.id,
              measureNumber: m.number,
              eventIndex: unassignedIdx,
            ),
          );
          return;
        }
      }
    }

    // 3. If no more unassigned notes, advance to adjacent note if available
    if (currentMeasure != null &&
        cursor.eventIndex < currentMeasure.events.length - 1) {
      _state = _state.copyWith(
        cursor: RhythmCursor(
          sectionId: cursor.sectionId,
          measureNumber: cursor.measureNumber,
          eventIndex: cursor.eventIndex + 1,
        ),
      );
    }
  }
}
