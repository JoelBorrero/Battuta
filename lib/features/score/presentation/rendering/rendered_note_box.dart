/// Battuta — Spatial Note Hit-Testing & Bounding Boxes.
///
/// Records physical canvas coordinates and bounding boxes of drawn noteheads
/// during the paint pass, enabling high-precision finger and Apple Pencil
/// hit-testing and vertical drag-and-snap gesture editing.
library;

import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:flutter/widgets.dart';

/// Bounding box and layout metadata for a rendered notehead on the canvas.
class RenderedNoteBox {
  const RenderedNoteBox({
    required this.noteId,
    required this.sectionId,
    required this.measureNumber,
    required this.eventIndex,
    required this.bounds,
    required this.center,
    required this.staffBottomY,
    required this.lineSpacing,
    required this.pitch,
  });

  /// Unique event ID.
  final String noteId;

  /// Containing section ID.
  final String sectionId;

  /// Containing measure number.
  final int measureNumber;

  /// Index of this note in the measure's events list.
  final int eventIndex;

  /// Physical bounding box of the notehead on the canvas.
  final Rect bounds;

  /// Center point of the notehead.
  final Offset center;

  /// Bottom line (E4) Y-coordinate of the note's staff system.
  final double staffBottomY;

  /// Staff line spacing in logical pixels.
  final double lineSpacing;

  /// Current musical pitch.
  final Pitch pitch;

  /// Expanded touch target (at least 44x44 pt per Apple Human Interface Guidelines).
  Rect get touchTarget => Rect.fromCenter(
        center: center,
        width: bounds.width < 44.0 ? 44.0 : bounds.width + 12.0,
        height: bounds.height < 44.0 ? 44.0 : bounds.height + 12.0,
      );
}

/// Spatial index of all noteheads rendered in the active score canvas.
class SpatialNoteIndex {
  final List<RenderedNoteBox> _notes = [];

  /// Registers a notehead bounding box during the paint pass.
  void register(RenderedNoteBox noteBox) {
    _notes.add(noteBox);
  }

  /// Finds the closest notehead hit by a tap/drag at [point].
  ///
  /// Evaluates Apple HIG touch targets first, resolving ties by shortest Euclidean distance.
  RenderedNoteBox? findNoteAt(Offset point, {double hitThreshold = 36.0}) {
    RenderedNoteBox? closest;
    var minDistance = double.infinity;

    for (final note in _notes) {
      if (note.touchTarget.contains(point)) {
        final distance = (note.center - point).distance;
        if (distance < minDistance) {
          minDistance = distance;
          closest = note;
        }
      }
    }

    if (closest != null) return closest;

    // Fallback: check euclidean distance within hitThreshold
    for (final note in _notes) {
      final distance = (note.center - point).distance;
      if (distance <= hitThreshold && distance < minDistance) {
        minDistance = distance;
        closest = note;
      }
    }

    return closest;
  }

  /// All registered note bounding boxes in the index.
  List<RenderedNoteBox> get allNotes => List.unmodifiable(_notes);

  /// Number of registered noteheads.
  int get count => _notes.length;

  /// Clears all entries from the index prior to a new paint pass.
  void clear() {
    _notes.clear();
  }
}
