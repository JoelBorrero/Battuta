/// Battuta — stage preferences provider, saved on the device.
library;

import 'package:battuta/core/services/api_key_storage.dart';
import 'package:battuta/core/services/device_preferences_storage.dart';
import 'package:battuta/features/settings/domain/stage_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Storage keys, one per field.
abstract final class StagePreferencesKeys {
  static const String chartTextScale = 'battuta_chart_text_scale';
  static const String preferFlats = 'battuta_prefer_flats';
  static const String keepScreenAwake = 'battuta_keep_screen_awake';
}

/// Loads and saves [StagePreferences]. Missing or bad stored values fall back
/// to the defaults; a failing storage never throws.
class StagePreferencesNotifier extends Notifier<StagePreferences> {
  // Fields the user changed before the first load finished; the late load
  // must not overwrite them.
  final Set<String> _touched = {};

  @override
  StagePreferences build() {
    _touched.clear();
    final storage = ref.watch(devicePreferencesStorageProvider);
    _load(storage);
    return const StagePreferences();
  }

  Future<void> _load(ApiKeyStorage storage) async {
    final scale = await _read(storage, StagePreferencesKeys.chartTextScale);
    final flats = await _read(storage, StagePreferencesKeys.preferFlats);
    final awake = await _read(storage, StagePreferencesKeys.keepScreenAwake);
    if (!ref.mounted) return;

    final parsedScale = double.tryParse(scale ?? '');
    state = state.copyWith(
      chartTextScale:
          _touched.contains(StagePreferencesKeys.chartTextScale) ||
              parsedScale == null
          ? null
          : parsedScale,
      preferFlats: _touched.contains(StagePreferencesKeys.preferFlats)
          ? null
          : _parseBool(flats),
      keepScreenAwake: _touched.contains(StagePreferencesKeys.keepScreenAwake)
          ? null
          : _parseBool(awake),
    );
  }

  static Future<String?> _read(ApiKeyStorage storage, String key) async {
    try {
      return await storage.read(key);
    } catch (_) {
      return null;
    }
  }

  static bool? _parseBool(String? value) => switch (value) {
    'true' => true,
    'false' => false,
    _ => null,
  };

  Future<void> _write(String key, String value) async {
    _touched.add(key);
    try {
      await ref.read(devicePreferencesStorageProvider).write(key, value);
    } catch (_) {
      // The in-memory choice stays even if saving fails.
    }
  }

  /// Sets the chart text scale (snapped to 0.1 inside 0.8 to 1.6).
  Future<void> setChartTextScale(double value) {
    final scale = StagePreferences.normalizeScale(value);
    _touched.add(StagePreferencesKeys.chartTextScale);
    state = state.copyWith(chartTextScale: scale);
    return _write(StagePreferencesKeys.chartTextScale, scale.toString());
  }

  Future<void> setPreferFlats(bool value) {
    _touched.add(StagePreferencesKeys.preferFlats);
    state = state.copyWith(preferFlats: value);
    return _write(StagePreferencesKeys.preferFlats, value.toString());
  }

  Future<void> setKeepScreenAwake(bool value) {
    _touched.add(StagePreferencesKeys.keepScreenAwake);
    state = state.copyWith(keepScreenAwake: value);
    return _write(StagePreferencesKeys.keepScreenAwake, value.toString());
  }
}

final stagePreferencesProvider =
    NotifierProvider<StagePreferencesNotifier, StagePreferences>(
      StagePreferencesNotifier.new,
    );
