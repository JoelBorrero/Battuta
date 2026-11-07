import 'package:battuta/app/localization/locale_provider.dart';
import 'package:battuta/core/services/api_key_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class InMemoryLocaleStorage extends ApiKeyStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);
}

void main() {
  group('AppLanguageOption Enum Tests', () {
    test('verifies display names and storage codes', () {
      expect(AppLanguageOption.system.displayName, equals('Auto'));
      expect(AppLanguageOption.system.storageCode, equals('system'));
      expect(AppLanguageOption.system.toLocale(), isNull);

      expect(AppLanguageOption.english.displayName, equals('English'));
      expect(AppLanguageOption.english.storageCode, equals('en'));
      expect(AppLanguageOption.english.toLocale(), equals(const Locale('en')));

      expect(AppLanguageOption.spanish.displayName, equals('Español'));
      expect(AppLanguageOption.spanish.storageCode, equals('es'));
      expect(AppLanguageOption.spanish.toLocale(), equals(const Locale('es')));
    });

    test('fromStorageCode handles valid and fallback codes', () {
      expect(AppLanguageOption.fromStorageCode('en'), equals(AppLanguageOption.english));
      expect(AppLanguageOption.fromStorageCode('es'), equals(AppLanguageOption.spanish));
      expect(AppLanguageOption.fromStorageCode('system'), equals(AppLanguageOption.system));
      expect(AppLanguageOption.fromStorageCode(null), equals(AppLanguageOption.system));
      expect(AppLanguageOption.fromStorageCode('unknown'), equals(AppLanguageOption.system));
    });
  });

  group('LocaleNotifier Provider Tests', () {
    test('initializes with system default and resolves to null locale', () {
      final storage = InMemoryLocaleStorage();
      final container = ProviderContainer(
        overrides: [
          localeStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(appLanguageOptionProvider), equals(AppLanguageOption.system));
      expect(container.read(appLocaleProvider), isNull);
    });

    test('switches language and persists to storage', () async {
      final storage = InMemoryLocaleStorage();
      final container = ProviderContainer(
        overrides: [
          localeStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      // Switch to Spanish
      await container.read(appLanguageOptionProvider.notifier).setLanguage(AppLanguageOption.spanish);
      expect(container.read(appLanguageOptionProvider), equals(AppLanguageOption.spanish));
      expect(container.read(appLocaleProvider), equals(const Locale('es')));
      expect(await storage.read(LocaleStorageKeys.selectedLanguage), equals('es'));

      // Switch to English
      await container.read(appLanguageOptionProvider.notifier).setLanguage(AppLanguageOption.english);
      expect(container.read(appLanguageOptionProvider), equals(AppLanguageOption.english));
      expect(container.read(appLocaleProvider), equals(const Locale('en')));
      expect(await storage.read(LocaleStorageKeys.selectedLanguage), equals('en'));

      // Revert to system default (auto)
      await container.read(appLanguageOptionProvider.notifier).setLanguage(AppLanguageOption.system);
      expect(container.read(appLanguageOptionProvider), equals(AppLanguageOption.system));
      expect(container.read(appLocaleProvider), isNull);
      expect(await storage.read(LocaleStorageKeys.selectedLanguage), isNull);
    });
  });
}
