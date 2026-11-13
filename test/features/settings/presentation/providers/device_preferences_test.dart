import 'package:battuta/app/localization/locale_provider.dart';
import 'package:battuta/app/theme/theme_provider.dart';
import 'package:battuta/core/services/device_preferences_storage.dart';
import 'package:battuta/features/settings/domain/stage_preferences.dart';
import 'package:battuta/features/settings/presentation/providers/stage_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/device_prefs_fakes.dart';
import '../../../../support/memory_storage.dart';

ProviderContainer containerFor(MemoryStorage storage) {
  final c = ProviderContainer(
    overrides: [devicePreferencesStorageProvider.overrideWithValue(storage)],
  );
  addTearDown(c.dispose);
  return c;
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  group('StagePreferences provider', () {
    test('defaults when nothing is saved', () async {
      final c = containerFor(SlowMemoryStorage());
      expect(c.read(stagePreferencesProvider), const StagePreferences());
      await settle();
      final p = c.read(stagePreferencesProvider);
      expect(p.chartTextScale, 1.0);
      expect(p.preferFlats, isFalse);
      expect(p.keepScreenAwake, isTrue);
    });

    test(
      'saves each field under its own key and restores after a restart',
      () async {
        final storage = SlowMemoryStorage();
        final first = containerFor(storage);
        first.read(stagePreferencesProvider);
        await settle();
        final n = first.read(stagePreferencesProvider.notifier);
        await n.setChartTextScale(1.3);
        await n.setPreferFlats(true);
        await n.setKeepScreenAwake(false);

        expect(storage.values, {
          'battuta_chart_text_scale': '1.3',
          'battuta_prefer_flats': 'true',
          'battuta_keep_screen_awake': 'false',
        });

        final second = containerFor(storage);
        second.read(stagePreferencesProvider);
        await settle();
        final p = second.read(stagePreferencesProvider);
        expect(p.chartTextScale, 1.3);
        expect(p.preferFlats, isTrue);
        expect(p.keepScreenAwake, isFalse);
      },
    );

    test('bad stored values fall back to the defaults', () async {
      final c = containerFor(
        SlowMemoryStorage(
          initial: {
            'battuta_chart_text_scale': 'huge',
            'battuta_prefer_flats': 'maybe',
            'battuta_keep_screen_awake': '1',
          },
        ),
      );
      c.read(stagePreferencesProvider);
      await settle();
      expect(c.read(stagePreferencesProvider), const StagePreferences());
    });

    test('out of range scale is kept inside 0.8 to 1.6', () async {
      final c = containerFor(
        SlowMemoryStorage(initial: {'battuta_chart_text_scale': '9'}),
      );
      c.read(stagePreferencesProvider);
      await settle();
      expect(c.read(stagePreferencesProvider).chartTextScale, 1.6);
    });

    test('a failing storage keeps the defaults and does not throw', () async {
      final c = containerFor(SlowMemoryStorage(failReads: true));
      c.read(stagePreferencesProvider);
      await settle();
      expect(c.read(stagePreferencesProvider), const StagePreferences());
    });

    test('a late load never overwrites a choice made while loading', () async {
      final storage = SlowMemoryStorage(
        initial: {
          'battuta_chart_text_scale': '1.5',
          'battuta_prefer_flats': 'true',
          'battuta_keep_screen_awake': 'false',
        },
        readDelay: const Duration(milliseconds: 50),
      );
      final c = containerFor(storage);
      c.read(stagePreferencesProvider);
      await c.read(stagePreferencesProvider.notifier).setPreferFlats(false);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final p = c.read(stagePreferencesProvider);
      expect(p.preferFlats, isFalse, reason: 'user choice wins');
      expect(p.chartTextScale, 1.5, reason: 'untouched fields still load');
      expect(p.keepScreenAwake, isFalse);
    });
  });

  group('ThemeMode provider', () {
    test('saves and restores the choice; System deletes the key', () async {
      final storage = SlowMemoryStorage();
      final first = containerFor(storage);
      first.read(themeModeProvider);
      await settle();
      await first.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(storage.values['battuta_theme_mode'], 'dark');

      final second = containerFor(storage);
      second.read(themeModeProvider);
      await settle();
      expect(second.read(themeModeProvider), ThemeMode.dark);

      await second
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.system);
      expect(storage.values.containsKey('battuta_theme_mode'), isFalse);
      final third = containerFor(storage);
      third.read(themeModeProvider);
      await settle();
      expect(third.read(themeModeProvider), ThemeMode.system);
    });

    test('a late load never overwrites a choice made while loading', () async {
      final storage = SlowMemoryStorage(
        initial: {'battuta_theme_mode': 'dark'},
        readDelay: const Duration(milliseconds: 50),
      );
      final c = containerFor(storage);
      c.read(themeModeProvider);
      await c.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(c.read(themeModeProvider), ThemeMode.light);
    });
  });

  group('Language provider', () {
    test('keeps its storage key and is restored after a restart', () async {
      final storage = SlowMemoryStorage(
        initial: {'battuta_selected_language': 'es'},
      );
      final c = containerFor(storage);
      c.read(appLanguageOptionProvider);
      await settle();
      expect(c.read(appLanguageOptionProvider), AppLanguageOption.spanish);
    });

    test('a late load never overwrites a choice made while loading', () async {
      final storage = SlowMemoryStorage(
        initial: {'battuta_selected_language': 'es'},
        readDelay: const Duration(milliseconds: 50),
      );
      final c = containerFor(storage);
      c.read(appLanguageOptionProvider);
      await c
          .read(appLanguageOptionProvider.notifier)
          .setLanguage(AppLanguageOption.english);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(c.read(appLanguageOptionProvider), AppLanguageOption.english);
    });
  });
}
