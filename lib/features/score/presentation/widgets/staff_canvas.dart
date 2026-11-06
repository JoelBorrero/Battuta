/// Battuta — StaffCanvas widget.
///
/// Wraps [StaffPainter] in a scrollable container with automatic layout index
/// registration, enabling instant scrolling to rehearsal marks and section headers
/// for live performance and remote v1.1 presentation synchronization.
library;

import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/presentation/rendering/section_layout_index.dart';
import 'package:battuta/features/score/presentation/rendering/staff_metrics.dart';
import 'package:battuta/features/score/presentation/rendering/staff_painter.dart';
import 'package:flutter/material.dart';

/// Interactive score canvas rendering staves, barlines, chords, and navigation boxes.
class StaffCanvas extends StatefulWidget {
  /// Creates a [StaffCanvas].
  const StaffCanvas({
    required this.score,
    super.key,
    this.metrics = const StaffMetrics(),
    this.scrollController,
    this.layoutIndex,
    this.onLayoutReady,
  });

  /// The active score to render.
  final Score score;

  /// Layout and typography metrics.
  final StaffMetrics metrics;

  /// Optional external [ScrollController] to control canvas scrolling.
  final ScrollController? scrollController;

  /// Layout index registering section vertical coordinates.
  final SectionLayoutIndex? layoutIndex;

  /// Callback invoked after layout offsets are registered.
  final void Function(SectionLayoutIndex index)? onLayoutReady;

  @override
  State<StaffCanvas> createState() => StaffCanvasState();
}

class StaffCanvasState extends State<StaffCanvas> {
  late final ScrollController _scrollController;
  late final SectionLayoutIndex _layoutIndex;
  bool _ownsController = false;

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
  }

  @override
  void dispose() {
    if (_ownsController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  /// Instantly or smoothly scrolls the canvas to the specified section header.
  ///
  /// [identifier] can be a section ID, external sync ID (e.g. ProPresenter UUID),
  /// or section display name (e.g. "Verse 1", "Chorus").
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

        return SingleChildScrollView(
          controller: _scrollController,
          child: CustomPaint(
            size: Size(availableWidth, totalHeight),
            painter: StaffPainter(
              score: widget.score,
              metrics: widget.metrics,
              layoutIndex: _layoutIndex,
            ),
          ),
        );
      },
    );
  }
}
