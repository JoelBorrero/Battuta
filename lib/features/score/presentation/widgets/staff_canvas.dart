/// Battuta — StaffCanvas widget with Vertical Drag-and-Snap GestureDetector.
///
/// Wraps [StaffPainter] in a scrollable container with spatial hit-testing,
/// allowing musicians to drag noteheads vertically with a finger or Apple Pencil,
/// mathematically snapping them to half-staff-space increments in real time.
library;

import 'package:battuta/features/score/domain/entities/pitch.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/presentation/providers/rhythm_editor_controller.dart';
import 'package:battuta/features/score/presentation/rendering/rendered_note_box.dart';
import 'package:battuta/features/score/presentation/rendering/section_layout_index.dart';
import 'package:battuta/features/score/presentation/rendering/staff_metrics.dart';
import 'package:battuta/features/score/presentation/rendering/staff_painter.dart';
import 'package:battuta/features/score/presentation/rendering/staff_pitch_mapper.dart';
import 'package:flutter/material.dart';

/// Interactive score canvas rendering staves, barlines, chords, notes, and drag-and-snap gesture editing.
class StaffCanvas extends StatefulWidget {
  /// Creates a [StaffCanvas].
  const StaffCanvas({
    required this.score,
    super.key,
    this.metrics = const StaffMetrics(),
    this.scrollController,
    this.layoutIndex,
    this.spatialIndex,
    this.measureWarnings,
    this.selectedCursor,
    this.selectedSectionId,
    this.selectedMeasureNumber,
    this.selectedEventIndex,
    this.onLayoutReady,
    this.onNotePitchChanged,
    this.onNoteTapped,
    this.onDragCompleted,
  });

  /// The active score to render.
  final Score score;

  /// Layout and typography metrics.
  final StaffMetrics metrics;

  /// Optional external [ScrollController] to control canvas scrolling.
  final ScrollController? scrollController;

  /// Layout index registering section vertical coordinates.
  final SectionLayoutIndex? layoutIndex;

  /// Spatial index registering note bounding boxes for hit-testing.
  final SpatialNoteIndex? spatialIndex;

  /// Optional map of measure numbers to Gemini advertencia warnings.
  final Map<int, String>? measureWarnings;

  /// Optional rhythm cursor identifying the selected note.
  final RhythmCursor? selectedCursor;

  /// Optional section ID of the selected note event.
  final String? selectedSectionId;

  /// Optional measure number of the selected note event.
  final int? selectedMeasureNumber;

  /// Optional event index of the selected note within its measure.
  final int? selectedEventIndex;

  /// Callback invoked after layout offsets are registered.
  final void Function(SectionLayoutIndex index)? onLayoutReady;

  /// Callback invoked in real time when a notehead is dragged to a new pitch.
  final void Function(
    String sectionId,
    int measureNumber,
    int eventIndex,
    Pitch newPitch,
  )?
  onNotePitchChanged;

  /// Callback invoked when a notehead is tapped.
  final void Function(RenderedNoteBox note)? onNoteTapped;

  /// Callback invoked when a drag gesture finishes.
  final VoidCallback? onDragCompleted;

  @override
  State<StaffCanvas> createState() => StaffCanvasState();
}

class StaffCanvasState extends State<StaffCanvas> {
  late final ScrollController _scrollController;
  late final SectionLayoutIndex _layoutIndex;
  late final SpatialNoteIndex _spatialIndex;
  bool _ownsController = false;

  /// The currently active note being dragged vertically.
  RenderedNoteBox? _draggedNote;

  /// The currently selected note (fallback when external cursor is not provided).
  RenderedNoteBox? _selectedNote;

  String? get _activeSectionId =>
      _draggedNote?.sectionId ??
      widget.selectedCursor?.sectionId ??
      widget.selectedSectionId ??
      _selectedNote?.sectionId;

  int? get _activeMeasureNumber =>
      _draggedNote?.measureNumber ??
      widget.selectedCursor?.measureNumber ??
      widget.selectedMeasureNumber ??
      _selectedNote?.measureNumber;

  int? get _activeEventIndex =>
      _draggedNote?.eventIndex ??
      widget.selectedCursor?.eventIndex ??
      widget.selectedEventIndex ??
      _selectedNote?.eventIndex;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _ownsController = true;
    }
    _layoutIndex = widget.layoutIndex ?? SectionLayoutIndex();
    _spatialIndex = widget.spatialIndex ?? SpatialNoteIndex();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  /// Instantly or smoothly scrolls the canvas to the specified section header.
  Future<void> scrollToSection(
    String identifier, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    final yOffset = _layoutIndex.getYOffset(identifier);
    if (yOffset != null && _scrollController.hasClients) {
      if (duration == Duration.zero) {
        _scrollController.jumpTo(
          yOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        );
      } else {
        await _scrollController.animateTo(
          yOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: duration,
          curve: curve,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final totalHeight = StaffPainter.calculateTotalHeight(
          widget.score,
          availableWidth,
          metrics: widget.metrics,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onLayoutReady?.call(_layoutIndex);
          }
        });

        final theme = Theme.of(context);
        final effectiveMetrics = widget.metrics != const StaffMetrics()
            ? widget.metrics
            : StaffMetrics.fromTheme(theme);

        return SingleChildScrollView(
          controller: _scrollController,
          // When actively dragging a notehead, lock canvas scroll to ensure buttery dragging
          physics: _draggedNote != null
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              final hitNote = _spatialIndex.findNoteAt(event.localPosition);
              if (hitNote != null) {
                setState(() {
                  _draggedNote = hitNote;
                  _selectedNote = hitNote;
                });
                widget.onNoteTapped?.call(hitNote);
              }
            },
            onPointerMove: (event) {
              if (_draggedNote != null) {
                final note = _draggedNote!;
                // Mathematically snap Y coordinate to closest half-staff-space increment
                final snappedPitch = StaffPitchMapper.pitchForYCoordinate(
                  event.localPosition.dy,
                  staffBottomY: note.staffBottomY,
                  lineSpacing: note.lineSpacing,
                  accidental: note.pitch.accidental,
                );

                if (snappedPitch != note.pitch) {
                  widget.onNotePitchChanged?.call(
                    note.sectionId,
                    note.measureNumber,
                    note.eventIndex,
                    snappedPitch,
                  );

                  setState(() {
                    _draggedNote = RenderedNoteBox(
                      noteId: note.noteId,
                      sectionId: note.sectionId,
                      measureNumber: note.measureNumber,
                      eventIndex: note.eventIndex,
                      bounds: note.bounds,
                      center: note.center,
                      staffBottomY: note.staffBottomY,
                      lineSpacing: note.lineSpacing,
                      pitch: snappedPitch,
                    );
                    _selectedNote = _draggedNote;
                  });
                }
              }
            },
            onPointerUp: (event) {
              if (_draggedNote != null) {
                final wasDragged = _draggedNote!;
                setState(() {
                  _draggedNote = null;
                  _selectedNote = wasDragged;
                });
                widget.onDragCompleted?.call();
                widget.onNoteTapped?.call(wasDragged);
              }
            },
            onPointerCancel: (_) {
              if (_draggedNote != null) {
                setState(() {
                  _draggedNote = null;
                });
              }
            },
            child: CustomPaint(
              size: Size(availableWidth, totalHeight),
              painter: StaffPainter(
                score: widget.score,
                metrics: effectiveMetrics,
                layoutIndex: _layoutIndex,
                spatialIndex: _spatialIndex,
                measureWarnings: widget.measureWarnings,
                selectedSectionId: _activeSectionId,
                selectedMeasureNumber: _activeMeasureNumber,
                selectedEventIndex: _activeEventIndex,
                isDragging: _draggedNote != null,
              ),
            ),
          ),
        );
      },
    );
  }
}
