/// Battuta — device preferences for the stage: chart text size, accidental
/// spelling and screen wake. Saved on the device, never synced.
library;

/// Immutable stage preferences.
class StagePreferences {
  const StagePreferences({
    this.chartTextScale = defaultChartTextScale,
    this.preferFlats = false,
    this.keepScreenAwake = true,
  });

  static const double minChartTextScale = 0.8;
  static const double maxChartTextScale = 1.6;
  static const double defaultChartTextScale = 1.0;

  /// Number of 0.1 steps between min and max.
  static const int chartTextScaleDivisions = 8;

  /// Multiplier for chord and lyric text in the chart (0.8 to 1.6).
  final double chartTextScale;

  /// Spell transposed notes with flats (Db) instead of sharps (C#).
  final bool preferFlats;

  /// Keep the screen on while the Live page is open.
  final bool keepScreenAwake;

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
  }) => StagePreferences(
    chartTextScale: chartTextScale == null
        ? this.chartTextScale
        : normalizeScale(chartTextScale),
    preferFlats: preferFlats ?? this.preferFlats,
    keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
  );

  @override
  bool operator ==(Object other) =>
      other is StagePreferences &&
      other.chartTextScale == chartTextScale &&
      other.preferFlats == preferFlats &&
      other.keepScreenAwake == keepScreenAwake;

  @override
  int get hashCode => Object.hash(chartTextScale, preferFlats, keepScreenAwake);

  @override
  String toString() =>
      'StagePreferences(scale: $chartTextScale, flats: $preferFlats, '
      'awake: $keepScreenAwake)';
}
