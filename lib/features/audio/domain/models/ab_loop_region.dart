/// Battuta — Key-Aware A/B Practice Loop Region Model.
///
/// Provides sub-millisecond boundary validation, minimum loop duration guards,
/// and zero-crossing crossfade window calculations to eliminate audible pops and clicks.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

@immutable
class AbLoopRegion {
  AbLoopRegion({
    required this.startMicros,
    required this.endMicros,
    this.fadeWindowMicros = 5000, // 5 milliseconds default
    this.label,
  }) {
    if (startMicros < 0) {
      throw ArgumentError.value(
        startMicros,
        'startMicros',
        'Loop start timestamp cannot be negative.',
      );
    }
    if (startMicros >= endMicros) {
      throw ArgumentError(
        'Loop start ($startMicros µs) must precede loop end ($endMicros µs).',
      );
    }
    if (durationMicros < minLoopDurationMicros) {
      throw ArgumentError(
        'Loop duration ($durationMicros µs) is below minimum allowed threshold ($minLoopDurationMicros µs).',
      );
    }
  }

  /// Minimum allowable loop segment: 100 milliseconds (100,000 µs)
  /// Prevents audio thread lockup and buffer thrashing.
  static const int minLoopDurationMicros = 100000;

  /// Start timestamp of loop in microseconds.
  final int startMicros;

  /// End timestamp of loop in microseconds.
  final int endMicros;

  /// Crossfade window length in microseconds applied at loop seams.
  final int fadeWindowMicros;

  /// Optional display label for this rehearsal segment.
  final String? label;

  /// Total duration of loop segment in microseconds.
  int get durationMicros => endMicros - startMicros;

  /// Start duration.
  Duration get startDuration => Duration(microseconds: startMicros);

  /// End duration.
  Duration get endDuration => Duration(microseconds: endMicros);

  /// Total duration as [Duration].
  Duration get duration => Duration(microseconds: durationMicros);

  /// Computes equal-power cosine crossfade multiplier for anti-click fade-in.
  ///
  /// [elapsedSinceStartMicros] should be between 0 and [fadeWindowMicros].
  double calculateFadeInMultiplier(int elapsedSinceStartMicros) {
    if (fadeWindowMicros <= 0) return 1.0;
    if (elapsedSinceStartMicros >= fadeWindowMicros) return 1.0;
    if (elapsedSinceStartMicros <= 0) return 0.0;

    final progress = elapsedSinceStartMicros / fadeWindowMicros;
    return math.sin(progress * (math.pi / 2));
  }

  /// Computes equal-power cosine crossfade multiplier for anti-click fade-out.
  ///
  /// [remainingUntilEndMicros] should be between 0 and [fadeWindowMicros].
  double calculateFadeOutMultiplier(int remainingUntilEndMicros) {
    if (fadeWindowMicros <= 0) return 1.0;
    if (remainingUntilEndMicros >= fadeWindowMicros) return 1.0;
    if (remainingUntilEndMicros <= 0) return 0.0;

    final progress = remainingUntilEndMicros / fadeWindowMicros;
    return math.sin(progress * (math.pi / 2));
  }

  /// Calculates sample window length for hardware zero-crossing alignment at [sampleRate] (e.g. 44100 or 48000 Hz).
  int calculateZeroCrossingSampleWindow(int sampleRate) {
    return (sampleRate * (fadeWindowMicros / 1000000.0)).round();
  }

  Map<String, dynamic> toJson() {
    return {
      'startMicros': startMicros,
      'endMicros': endMicros,
      'fadeWindowMicros': fadeWindowMicros,
      'label': label,
    };
  }

  factory AbLoopRegion.fromJson(Map<String, dynamic> json) {
    return AbLoopRegion(
      startMicros: (json['startMicros'] as num).toInt(),
      endMicros: (json['endMicros'] as num).toInt(),
      fadeWindowMicros: (json['fadeWindowMicros'] as num?)?.toInt() ?? 5000,
      label: json['label'] as String?,
    );
  }

  AbLoopRegion copyWith({
    int? startMicros,
    int? endMicros,
    int? fadeWindowMicros,
    String? label,
  }) {
    return AbLoopRegion(
      startMicros: startMicros ?? this.startMicros,
      endMicros: endMicros ?? this.endMicros,
      fadeWindowMicros: fadeWindowMicros ?? this.fadeWindowMicros,
      label: label ?? this.label,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AbLoopRegion &&
          runtimeType == other.runtimeType &&
          startMicros == other.startMicros &&
          endMicros == other.endMicros &&
          fadeWindowMicros == other.fadeWindowMicros &&
          label == other.label;

  @override
  int get hashCode =>
      Object.hash(startMicros, endMicros, fadeWindowMicros, label);

  @override
  String toString() =>
      'AbLoopRegion($startMicros µs -> $endMicros µs, duration: $durationMicros µs)';
}
