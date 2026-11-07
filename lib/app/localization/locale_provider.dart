/// Battuta — Application Language & Locale Provider.
///
/// Supports English and Spanish with System Default (Auto) as default.
/// Persists language preference securely across app sessions.
library;

import 'package:battuta/core/services/api_key_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available language choices in Battuta.
enum AppLanguageOption {
  system,
  english,
  spanish;

  /// Human-readable label for UI selection.
  String get displayName => switch (this) {
    AppLanguageOption.system => 'Auto',
    AppLanguageOption.english => 'English',
    AppLanguageOption.spanish => 'Español',
  };

  /// Detailed label including native name.
  String get fullDisplayName => switch (this) {
    AppLanguageOption.system => 'System Default (Auto)',
    AppLanguageOption.english => 'English (US)',
    AppLanguageOption.spanish => 'Español (ES/LA)',
  };

  /// Converts this option to an active [Locale] or `null` for system default.
  Locale? toLocale() => switch (this) {
    AppLanguageOption.system => null,
    AppLanguageOption.english => const Locale('en'),
    AppLanguageOption.spanish => const Locale('es'),
  };

  /// Serialized key for storage.
  String get storageCode => switch (this) {
    AppLanguageOption.system => 'system',
    AppLanguageOption.english => 'en',
    AppLanguageOption.spanish => 'es',
  };

  /// Deserializes a storage string to an [AppLanguageOption].
  static AppLanguageOption fromStorageCode(String? code) => switch (code) {
    'en' => AppLanguageOption.english,
    'es' => AppLanguageOption.spanish,
    _ => AppLanguageOption.system,
  };
}

/// Key used to persist user language selection in local storage.
abstract final class LocaleStorageKeys {
  static const String selectedLanguage = 'battuta_selected_language';
}

/// Provider for local storage used by the locale notifier.
final localeStorageProvider = Provider<ApiKeyStorage>((ref) {
  return SecureApiKeyStorage();
});

/// Notifier managing active language selection.
class LocaleNotifier extends Notifier<AppLanguageOption> {
  @override
  AppLanguageOption build() {
    final storage = ref.watch(localeStorageProvider);
    _loadPersistedLanguage(storage);
    return AppLanguageOption.system;
  }

  Future<void> _loadPersistedLanguage(ApiKeyStorage storage) async {
    try {
      final code = await storage.read(LocaleStorageKeys.selectedLanguage);
      if (code != null) {
        state = AppLanguageOption.fromStorageCode(code);
      }
    } catch (_) {
      // Retain system default on read error
    }
  }

  /// Updates and persists the user language preference.
  Future<void> setLanguage(AppLanguageOption option) async {
    state = option;
    final storage = ref.read(localeStorageProvider);
    try {
      if (option == AppLanguageOption.system) {
        await storage.delete(LocaleStorageKeys.selectedLanguage);
      } else {
        await storage.write(LocaleStorageKeys.selectedLanguage, option.storageCode);
      }
    } catch (_) {
      // In-memory state remains updated even if persistence fails
    }
  }
}

/// Exposes the user's selected language option.
final appLanguageOptionProvider =
    NotifierProvider<LocaleNotifier, AppLanguageOption>(LocaleNotifier.new);

/// Exposes the resolved [Locale] for [MaterialApp.locale].
/// Emits `null` when [AppLanguageOption.system] is active.
final appLocaleProvider = Provider<Locale?>((ref) {
  final option = ref.watch(appLanguageOptionProvider);
  return option.toLocale();
});
