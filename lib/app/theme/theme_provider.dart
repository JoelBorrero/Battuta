/// Battuta — Theme Mode provider.
///
/// Manages user-selected [ThemeMode] (Light, Dark, or System) and provides
/// reactive updates across the entire widget tree.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages application-level [ThemeMode].
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Updates the active [ThemeMode].
  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

/// Provides the active [ThemeMode] for the application.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
