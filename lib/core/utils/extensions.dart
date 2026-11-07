/// Convenience extensions used throughout the Battuta app.
///
/// Adds expressive helpers to built-in types so business logic reads more
/// naturally and common transformations don't require standalone functions.
library;

import 'package:intl/intl.dart';

// ── String ──────────────────────────────────────────────────────────────────

/// Useful additions to [String] and [String?].
extension StringX on String {
  /// Returns a copy with the first character uppercased and the rest
  /// unchanged.
  ///
  /// ```dart
  /// 'hello'.capitalize; // 'Hello'
  /// 'HELLO'.capitalize; // 'HELLO'
  /// ```
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Returns a copy with the first character of every word uppercased.
  ///
  /// Words are delimited by whitespace.
  ///
  /// ```dart
  /// 'amazing grace'.titleCase; // 'Amazing Grace'
  /// ```
  String get titleCase => split(' ').map((w) => w.capitalize).join(' ');

  /// Whether this string is blank (empty or only whitespace).
  bool get isBlank => trimLeft().isEmpty;

  /// Truncates the string to [maxLength] characters, appending an
  /// [ellipsis] if truncation occurred.
  ///
  /// ```dart
  /// 'A very long title'.truncated(10); // 'A very lo…'
  /// ```
  String truncated(int maxLength, {String ellipsis = '…'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }
}

/// Nullable-string helpers.
extension NullableStringX on String? {
  /// `true` when the string is `null`, empty, or only whitespace.
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;

  /// Returns [this] if it is non-null and non-empty, otherwise [fallback].
  String orDefault(String fallback) => isNullOrEmpty ? fallback : this!;
}

// ── DateTime ────────────────────────────────────────────────────────────────

/// Formatting helpers for [DateTime].
extension DateTimeX on DateTime {
  /// Formats as `'Jan 5, 2025'`.
  String get formattedDate => DateFormat.yMMMd().format(this);

  /// Formats as `'3:45 PM'`.
  String get formattedTime => DateFormat.jm().format(this);

  /// Formats as `'Jan 5, 2025 · 3:45 PM'`.
  String get formattedDateTime => '$formattedDate · $formattedTime';

  /// Returns a human-friendly relative label like *"just now"*,
  /// *"5 min ago"*, *"yesterday"*, or falls back to [formattedDate].
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);

    return switch (diff) {
      Duration(inSeconds: < 60) => 'just now',
      Duration(inMinutes: < 60) => '${diff.inMinutes} min ago',
      Duration(inHours: < 24) => '${diff.inHours}h ago',
      Duration(inDays: 1) => 'yesterday',
      Duration(inDays: < 7) => '${diff.inDays}d ago',
      _ => formattedDate,
    };
  }

  /// Whether this [DateTime] falls on the same calendar day as [other].
  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

// ── Iterable ────────────────────────────────────────────────────────────────

/// Collection helpers that complement Dart 3's built-in `firstOrNull`.
extension IterableX<E> on Iterable<E> {
  /// Groups elements by a key derived from each element.
  ///
  /// ```dart
  /// final songs = [song1, song2, song3];
  /// final byKey = songs.groupBy((s) => s.key);
  /// // {Key.C: [song1, song3], Key.G: [song2]}
  /// ```
  Map<K, List<E>> groupBy<K>(K Function(E element) keyOf) {
    final map = <K, List<E>>{};
    for (final element in this) {
      (map[keyOf(element)] ??= []).add(element);
    }
    return map;
  }

  /// Like [map] but the callback also receives the element's index.
  Iterable<T> mapIndexed<T>(T Function(int index, E element) convert) sync* {
    var index = 0;
    for (final element in this) {
      yield convert(index++, element);
    }
  }

  /// Returns the element with the maximum value of [orderBy], or `null`
  /// if the iterable is empty.
  E? maxBy<T extends Comparable<T>>(T Function(E element) orderBy) {
    E? best;
    T? bestValue;
    for (final element in this) {
      final value = orderBy(element);
      if (bestValue == null || value.compareTo(bestValue) > 0) {
        best = element;
        bestValue = value;
      }
    }
    return best;
  }

  /// Returns the element with the minimum value of [orderBy], or `null`
  /// if the iterable is empty.
  E? minBy<T extends Comparable<T>>(T Function(E element) orderBy) {
    E? best;
    T? bestValue;
    for (final element in this) {
      final value = orderBy(element);
      if (bestValue == null || value.compareTo(bestValue) < 0) {
        best = element;
        bestValue = value;
      }
    }
    return best;
  }

  /// Separates elements with the given [separator].
  ///
  /// Useful for inserting dividers between widgets:
  /// ```dart
  /// Column(children: items.separatedBy(Divider()).toList());
  /// ```
  Iterable<E> separatedBy(E separator) sync* {
    var first = true;
    for (final element in this) {
      if (!first) yield separator;
      yield element;
      first = false;
    }
  }
}

// ── Map ─────────────────────────────────────────────────────────────────────

/// Convenience helpers on [Map].
extension MapX<K, V> on Map<K, V> {
  /// Returns the value for [key], or computes and stores it via [ifAbsent]
  /// if the key is not present.
  ///
  /// This is identical to [putIfAbsent] but reads more naturally when used
  /// as an expression.
  V getOrPut(K key, V Function() ifAbsent) => putIfAbsent(key, ifAbsent);
}
