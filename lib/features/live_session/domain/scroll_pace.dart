/// Battuta — how fast the chart scrolls while performing.
///
/// Pure arithmetic, no Flutter: the page asks it for points per second.
library;

import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';

/// Tempo-driven scroll speed of the performance chart.
///
/// One lyric line lasts [defaultBarsPerLine] bars by default; a bar lasts
/// `beatsPerBar * 60 / bpm` seconds. A section scrolls its measured height over
/// its duration, scaled by the player's adjustment (50 % to 200 %).
abstract final class ScrollPace {
  /// Tempo used for songs that have none.
  static const int defaultBpm = 72;

  /// Bars a chart line lasts when nothing else is chosen.
  static const int defaultBarsPerLine = 2;

  /// Allowed values of the "bars per line" setting.
  static const List<int> barsPerLineChoices = [1, 2, 4];

  /// Lowest and highest player adjustment, and its step.
  static const double minAdjustment = 0.5;
  static const double maxAdjustment = 2.0;
  static const double adjustmentStep = 0.1;
  static const double defaultAdjustment = 1.0;

  /// The tempo to count with: [bpm] when it is positive, else [defaultBpm].
  static int effectiveBpm(int bpm) => bpm > 0 ? bpm : defaultBpm;

  /// Beats in a bar of [beats]/[beatValue]. Compound meters (6/8, 9/8, 12/8)
  /// count dotted-quarter beats, so 6/8 has 2.
  static double beatsPerBar(int beats, int beatValue) {
    if (beats <= 0) return 4;
    if (beatValue == 8 && beats % 3 == 0) return beats / 3;
    return beats.toDouble();
  }

  /// Seconds one bar lasts.
  static double barSeconds({
    required int bpm,
    required (int, int) timeSignature,
  }) {
    final (beats, beatValue) = timeSignature;
    return beatsPerBar(beats, beatValue) * 60 / effectiveBpm(bpm);
  }

  /// Seconds one chart line lasts.
  static double lineSeconds({
    required int bpm,
    required (int, int) timeSignature,
    int barsPerLine = defaultBarsPerLine,
  }) =>
      (barsPerLine < 1 ? defaultBarsPerLine : barsPerLine) *
      barSeconds(bpm: bpm, timeSignature: timeSignature);

  /// Seconds the chord beats of a section add up to (0 without chords).
  static double chordSeconds(List<ChordCell> chords, int bpm) {
    final beats = chords.fold<int>(
      0,
      (sum, c) => sum + (c.beats > 0 ? c.beats : 0),
    );
    return beats * 60 / effectiveBpm(bpm);
  }

  /// How long a section lasts on stage.
  ///
  /// With lyrics: each lyric line lasts [barsPerLine] bars. The chord beats
  /// are one progression for the section, not its length, so they only set a
  /// lower bound. Chords only: the chord beats, or one line's worth of bars
  /// when there are none.
  static double sectionSeconds({
    required int lyricLines,
    required List<ChordCell> chords,
    required int bpm,
    required (int, int) timeSignature,
    int barsPerLine = defaultBarsPerLine,
  }) {
    final line = lineSeconds(
      bpm: bpm,
      timeSignature: timeSignature,
      barsPerLine: barsPerLine,
    );
    final chordTime = chordSeconds(chords, bpm);
    if (lyricLines > 0) {
      final lyricTime = lyricLines * line;
      return lyricTime > chordTime ? lyricTime : chordTime;
    }
    return chordTime > 0 ? chordTime : line;
  }

  /// Scroll speed in points per second to cover [height] in [seconds],
  /// scaled by the player's [adjustment]. 0 when either is not positive.
  static double pointsPerSecond({
    required double height,
    required double seconds,
    double adjustment = defaultAdjustment,
  }) {
    if (!height.isFinite || !seconds.isFinite || height <= 0 || seconds <= 0) {
      return 0;
    }
    return height / seconds * normalizeAdjustment(adjustment);
  }

  /// Lyric lines of a section: the lines that are not blank.
  static int lyricLineCount(String? lyrics) => lyrics == null
      ? 0
      : lyrics.split('\n').where((l) => l.trim().isNotEmpty).length;

  /// Snaps [value] to the 0.1 grid inside 0.5 to 2.0. Not-a-number and
  /// infinite values give 1.0.
  static double normalizeAdjustment(double value) {
    if (!value.isFinite) return defaultAdjustment;
    final clamped = value.clamp(minAdjustment, maxAdjustment);
    return (clamped * 10).round() / 10;
  }

  /// A "bars per line" value that is one of the allowed choices.
  static int normalizeBarsPerLine(int value) =>
      barsPerLineChoices.contains(value) ? value : defaultBarsPerLine;
}
