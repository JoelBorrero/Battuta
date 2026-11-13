/// Battuta — Theme Mode provider.
///
/// Manages user-selected [ThemeMode] (Light, Dark, or System), provides
/// reactive updates across the entire widget tree and saves the choice on the
/// device.
library;

import 'package:battuta/core/services/api_key_storage.dart';
import 'package:battuta/core/services/device_preferences_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key used to persist the theme choice in local storage.
abstract final class ThemeStorageKeys {
  static const String themeMode = 'battuta_theme_mode';
}

/// Manages application-level [ThemeMode].
class ThemeModeNotifier extends Notifier<ThemeMode> {
  bool _userChose = false;

  @override
  ThemeMode build() {
    _userChose = false;
    _load(ref.watch(devicePreferencesStorageProvider));
    return ThemeMode.system;
  }

  Future<void> _load(ApiKeyStorage storage) async {
    try {
      final code = await storage.read(ThemeStorageKeys.themeMode);
      // A choice made while loading wins over the saved one.
      if (!ref.mounted || _userChose) return;
      state = switch (code) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      // Retain the system default on read error.
    }
  }

  /// Updates and saves the active [ThemeMode]. System deletes the saved key.
  Future<void> setThemeMode(ThemeMode mode) async {
    _userChose = true;
    state = mode;
    final storage = ref.read(devicePreferencesStorageProvider);
    try {
      if (mode == ThemeMode.system) {
        await storage.delete(ThemeStorageKeys.themeMode);
      } else {
        await storage.write(ThemeStorageKeys.themeMode, mode.name);
      }
    } catch (_) {
      // In-memory state remains updated even if saving fails.
    }
  }
}

/// Provides the active [ThemeMode] for the application.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
