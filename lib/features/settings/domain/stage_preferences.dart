/// Battuta — device preferences for the stage: chart text size, accidental
/// spelling, screen wake and auto-scroll. Saved on the device, never synced.
library;

/// Immutable stage preferences.
class StagePreferences {
  const StagePreferences({
    this.chartTextScale = defaultChartTextScale,
    this.preferFlats = false,
    this.keepScreenAwake = true,
    this.barsPerLine = defaultBarsPerLine,
    this.songSpeeds = const {},
  });

  static const double minChartTextScale = 0.8;
  static const double maxChartTextScale = 1.6;
  static const double defaultChartTextScale = 1.0;

  /// Number of 0.1 steps between min and max.
  static const int chartTextScaleDivisions = 8;

  /// Bars one chart line lasts when auto-scrolling (1, 2 or 4).
  static const int defaultBarsPerLine = 2;

  /// Multiplier for chord and lyric text in the chart (0.8 to 1.6).
  final double chartTextScale;

  /// Spell transposed notes with flats (Db) instead of sharps (C#).
  final bool preferFlats;

  /// Keep the screen on while the Live page is open.
  final bool keepScreenAwake;

  /// Bars one chart line lasts when auto-scrolling (1, 2 or 4).
  final int barsPerLine;

  /// Auto-scroll speed adjustment (0.5 to 2.0) the player chose, by song id.
  /// Songs not listed use 1.0.
  final Map<String, double> songSpeeds;

  /// Snaps [value] to the nearest 0.1 inside the allowed range. Not-a-number
  /// and infinite values give the default.
  static double normalizeScale(double value) {
    if (!value.isFinite) return defaultChartTextScale;
    final clamped = value.clamp(minChartTextScale, maxChartTextScale);
    return (clamped * 10).round() / 10;
  }

  StagePreferences copyWith({
    double? chartTextScale,
    bool? preferFlats,
    bool? keepScreenAwake,
    int? barsPerLine,
    Map<String, double>? songSpeeds,
  }) => StagePreferences(
    chartTextScale: chartTextScale == null
        ? this.chartTextScale
        : normalizeScale(chartTextScale),
    preferFlats: preferFlats ?? this.preferFlats,
    keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
    barsPerLine: barsPerLine ?? this.barsPerLine,
    songSpeeds: songSpeeds ?? this.songSpeeds,
  );

  @override
  bool operator ==(Object other) =>
      other is StagePreferences &&
      other.chartTextScale == chartTextScale &&
      other.preferFlats == preferFlats &&
      other.keepScreenAwake == keepScreenAwake &&
      other.barsPerLine == barsPerLine &&
      _sameSpeeds(other.songSpeeds, songSpeeds);

  static bool _sameSpeeds(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    chartTextScale,
    preferFlats,
    keepScreenAwake,
    barsPerLine,
    Object.hashAllUnordered([
      for (final e in songSpeeds.entries) Object.hash(e.key, e.value),
    ]),
  );

  @override
  String toString() =>
      'StagePreferences(scale: $chartTextScale, flats: $preferFlats, '
      'awake: $keepScreenAwake, barsPerLine: $barsPerLine)';
}
