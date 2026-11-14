/// Battuta — the chart of the song on stage: its sections in performance
/// order, scrolling by itself at the song's tempo.
library;

import 'dart:math' as math;

import 'package:battuta/features/live_session/domain/performance_plan.dart';
import 'package:battuta/features/live_session/domain/scroll_pace.dart';
import 'package:battuta/features/live_session/presentation/providers/performance_controller.dart';
import 'package:battuta/features/live_session/presentation/widgets/auto_scroll_controller.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/services/song_transposer.dart';
import 'package:battuta/features/repertoire/presentation/widgets/chord_lyrics_view.dart';
import 'package:battuta/features/settings/presentation/providers/stage_preferences_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One song's chart. Give it a `ValueKey` of the song so each song starts at
/// the top with its own scroll position.
class PerformanceChart extends ConsumerStatefulWidget {
  const PerformanceChart({required this.song, super.key});

  /// The song to show; never a missing one.
  final PerformanceSong song;

  /// The section that crosses this fraction of the viewport (from the top) is
  /// the current one.
  static const double readingLine = 0.3;

  @override
  ConsumerState<PerformanceChart> createState() => _PerformanceChartState();
}

class _PerformanceChartState extends ConsumerState<PerformanceChart>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final AutoScrollController _auto;
  late List<GlobalKey> _keys;
  double? _viewport;
  int _navToken = 0;

  @override
  void initState() {
    super.initState();
    _keys = List.generate(widget.song.cues.length, (_) => GlobalKey());
    _auto = AutoScrollController(
      vsync: this,
      scroll: _scroll,
      pointsPerSecond: _pointsPerSecond,
      onTick: _sync,
      onEnd: () => ref.read(performanceControllerProvider.notifier).pause(),
    );
    ref.listenManual(
      performanceControllerProvider.select((s) => s.isScrolling),
      (_, playing) => playing ? _auto.start() : _auto.stop(),
      fireImmediately: true,
    );
    ref.listenManual(
      performanceControllerProvider.select((s) => s.navSerial),
      (_, _) => _goToCue(animate: true),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cue = ref.read(performanceControllerProvider).cueIndex;
      if (cue > 0) {
        _goToCue(animate: false);
      } else {
        _updateAtEnd();
      }
    });
  }

  @override
  void didUpdateWidget(PerformanceChart old) {
    super.didUpdateWidget(old);
    final count = widget.song.cues.length;
    if (_keys.length != count) {
      _keys = List.generate(count, (_) => GlobalKey());
    }
    // The setlist was edited under the chart: sections may have moved.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateAtEnd();
    });
  }

  @override
  void dispose() {
    _auto.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Geometry ──────────────────────────────────────────────────────────

  /// Scroll offset at which section [i] starts, or `null` before layout.
  double? _top(int i) {
    if (i < 0 || i >= _keys.length) return null;
    final box = _keys[i].currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    final viewport = RenderAbstractViewport.maybeOf(box);
    return viewport?.getOffsetToReveal(box, 0).offset;
  }

  double? _height(int i) {
    if (i < 0 || i >= _keys.length) return null;
    final box = _keys[i].currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size.height : null;
  }

  /// Where the reading line is at scroll offset [pixels]. It starts at the top
  /// of the first card and moves down twice as fast as the chart until it
  /// reaches its place, so a short first section stays current on Play.
  static double _lineAt(double pixels, double viewport) =>
      pixels +
      math.min(viewport * PerformanceChart.readingLine, pixels + _topPadding);

  static const double _topPadding = 8;

  /// Scroll offset at which the reading line sits just under [top].
  static double _offsetFor(double top, double viewport) {
    final settled = viewport * PerformanceChart.readingLine;
    final ramp = (top + 2 - _topPadding) / 2;
    return ramp + _topPadding <= settled ? ramp : top + 2 - settled;
  }

  /// Follows the chart: the section at the reading line becomes current.
  void _sync() {
    if (!_scroll.hasClients || widget.song.cues.isEmpty) return;
    final position = _scroll.position;
    final line = _lineAt(position.pixels, position.viewportDimension);
    var current = 0;
    for (var i = 0; i < _keys.length; i++) {
      final top = _top(i);
      if (top != null && top <= line + 0.5) current = i;
    }
    ref.read(performanceControllerProvider.notifier).followScroll(current);
    _updateAtEnd();
  }

  /// Whether the last section is fully on screen.
  void _updateAtEnd() {
    final notifier = ref.read(performanceControllerProvider.notifier);
    if (!_scroll.hasClients || _keys.isEmpty) {
      notifier.setAtEnd(true);
      return;
    }
    final last = _keys.length - 1;
    final top = _top(last);
    final height = _height(last);
    if (top == null || height == null) return;
    final position = _scroll.position;
    notifier.setAtEnd(
      top + height <= position.pixels + position.viewportDimension + 1,
    );
  }

  Future<void> _goToCue({required bool animate}) async {
    if (!_scroll.hasClients) return;
    final cue = ref.read(performanceControllerProvider).cueIndex;
    final top = _top(cue);
    if (top == null) return;
    final position = _scroll.position;
    // The cue's top sits just under the reading line, so following the scroll
    // agrees with where the player asked to be.
    final target = cue == 0
        ? 0.0
        : _offsetFor(
            top,
            position.viewportDimension,
          ).clamp(0.0, position.maxScrollExtent);
    final token = ++_navToken;
    final wasPlaying = _auto.isRunning;
    _auto.stop();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (animate && !reduce && (target - position.pixels).abs() > 1) {
      await _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scroll.jumpTo(target);
    }
    if (!mounted || token != _navToken) return;
    _updateAtEnd();
    if (wasPlaying || ref.read(performanceControllerProvider).isScrolling) {
      _auto.start();
    }
  }

  // ── Pace ──────────────────────────────────────────────────────────────

  /// Scroll speed at the current offset. It depends on the offset alone: the
  /// section whose span holds the reading line sets it, and the span (from
  /// its top to the next section's top, or its own height for the last) is
  /// covered in that section's duration. While the line is still ramping down
  /// it moves faster than the chart, so the chart is slowed to match.
  double _pointsPerSecond() {
    if (!_scroll.hasClients || widget.song.cues.isEmpty) return 0;
    final prefs = ref.read(stagePreferencesProvider);
    final speed = ref.read(performanceControllerProvider).speed;
    final song = widget.song;
    final position = _scroll.position;
    final line = _lineAt(position.pixels, position.viewportDimension);
    var index = 0;
    for (var i = 0; i < song.cues.length; i++) {
      final top = _top(i);
      if (top != null && top <= line + 0.5) index = i;
    }
    final top = _top(index);
    final next = index + 1 < song.cues.length ? _top(index + 1) : null;
    final height = _height(index);
    if (top == null || (next == null && height == null)) return 0;
    final span = next != null ? next - top : height!;
    final cue = song.cues[index];
    final seconds = ScrollPace.sectionSeconds(
      lyricLines: cue.isWholeSong
          ? 0
          : ScrollPace.lyricLineCount(cue.section.lyrics),
      chords: cue.isWholeSong ? const [] : cue.section.chords,
      bpm: song.tempo,
      timeSignature: song.timeSignature,
      barsPerLine: prefs.barsPerLine,
    );
    final lineSpeed = ScrollPace.pointsPerSecond(
      height: span,
      seconds: seconds,
      adjustment: speed,
    );
    final ramping =
        position.pixels + _topPadding <
        position.viewportDimension * PerformanceChart.readingLine;
    return ramping ? lineSpeed / 2 : lineSpeed;
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      // A hand on the chart takes over from the auto-scroll.
      ref.read(performanceControllerProvider.notifier).pause();
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      _sync();
    }
    return false;
  }

  // ── Build ─────────────────────────────────────────────────────────────

  Map<String, SongSection> _shownSections(bool preferFlats) {
    final PerformanceSong perf = widget.song;
    final Song? song = perf.song;
    if (song == null) return const {};
    final shown = perf.semitones == 0
        ? song
        : SongTransposer.transposeSong(
            song,
            perf.semitones,
            preferSharps: preferFlats ? false : null,
          );
    return {for (final s in shown.sections) s.id: s};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(stagePreferencesProvider);
    final sections = _shownSections(prefs.preferFlats);
    final cues = widget.song.cues;

    return LayoutBuilder(
      builder: (context, constraints) {
        final previous = _viewport;
        _viewport = constraints.maxHeight;
        if (previous != null && previous != _viewport) {
          // Rotated or resized: keep the current section on screen.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _goToCue(animate: false);
          });
        }
        return NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: SingleChildScrollView(
            key: const ValueKey('performance_chart_scroll'),
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cues.length; i++)
                  KeyedSubtree(
                    key: _keys[i],
                    child: ChordSectionCard(
                      section: (sections[cues[i].section.id] ?? cues[i].section)
                          .copyWith(
                            name: cues[i].isWholeSong
                                ? (l10n?.livePerfWholeSong ?? 'Whole song')
                                : cues[i].label,
                            repeatCount: 1,
                          ),
                      transpositionSemitones: 0,
                      viewMode: SongViewMode.both,
                      chartTextScale: prefs.chartTextScale,
                      preferSharps: !prefs.preferFlats,
                    ),
                  ),
                // Room for the last section to rise to the reading line.
                SizedBox(height: constraints.maxHeight * 0.7),
              ],
            ),
          ),
        );
      },
    );
  }
}
