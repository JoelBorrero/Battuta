import 'package:battuta/core/services/device_preferences_storage.dart';
import 'package:battuta/features/settings/domain/stage_preferences.dart';
import 'package:battuta/features/settings/presentation/providers/stage_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/device_prefs_fakes.dart';
import '../../../../support/memory_storage.dart';

void main() {
  ProviderContainer make(MemoryStorage storage) {
    final c = ProviderContainer(
      overrides: [devicePreferencesStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(c.dispose);
    // Starts the notifier (and its load) and keeps it alive.
    c.listen(stagePreferencesProvider, (_, _) {});
    return c;
  }

  Future<void> loaded() =>
      Future<void>.delayed(const Duration(milliseconds: 5));

  test('defaults: 2 bars per line and no saved speeds', () {
    const prefs = StagePreferences();
    expect(prefs.barsPerLine, 2);
    expect(prefs.songSpeeds, isEmpty);
  });

  test('bars per line is saved and read back', () async {
    final storage = MemoryStorage();
    final first = make(storage);
    await first.read(stagePreferencesProvider.notifier).setBarsPerLine(4);
    expect(storage.values['battuta_bars_per_line'], '4');

    final second = make(storage);
    await loaded();
    expect(second.read(stagePreferencesProvider).barsPerLine, 4);
  });

  test('bars per line outside 1, 2 and 4 is not kept', () async {
    final storage = MemoryStorage();
    final c = make(storage);
    await c.read(stagePreferencesProvider.notifier).setBarsPerLine(3);
    expect(c.read(stagePreferencesProvider).barsPerLine, 2);

    final bad = make(MemoryStorage({'battuta_bars_per_line': '7'}));
    await loaded();
    expect(bad.read(stagePreferencesProvider).barsPerLine, 2);
  });

  test('song speeds are saved per song and read back', () async {
    final storage = MemoryStorage();
    final first = make(storage);
    final notifier = first.read(stagePreferencesProvider.notifier);
    await notifier.setSongSpeed('a', 1.4);
    await notifier.setSongSpeed('b', 0.7);

    final second = make(storage);
    await loaded();
    expect(second.read(stagePreferencesProvider).songSpeeds, {
      'a': 1.4,
      'b': 0.7,
    });
  });

  test('a speed is snapped, and the default is not stored', () async {
    final storage = MemoryStorage();
    final c = make(storage);
    final notifier = c.read(stagePreferencesProvider.notifier);
    await notifier.setSongSpeed('a', 9);
    expect(c.read(stagePreferencesProvider).songSpeeds['a'], 2.0);
    await notifier.setSongSpeed('a', 1.0);
    expect(c.read(stagePreferencesProvider).songSpeeds, isEmpty);
  });

  test('unreadable stored speeds are ignored', () async {
    for (final bad in ['not json', '[1,2]', '{"a":"fast"}']) {
      final c = make(MemoryStorage({'battuta_song_speeds': bad}));
      await loaded();
      expect(c.read(stagePreferencesProvider).songSpeeds, isEmpty, reason: bad);
    }
  });

  test('a storage that fails to read leaves the defaults', () async {
    final c = make(SlowMemoryStorage(failReads: true));
    await loaded();
    final prefs = c.read(stagePreferencesProvider);
    expect(prefs.barsPerLine, 2);
    expect(prefs.songSpeeds, isEmpty);
  });

  test('preferences with the same speeds are equal', () {
    expect(
      const StagePreferences(songSpeeds: {'a': 1.2}),
      const StagePreferences(songSpeeds: {'a': 1.2}),
    );
    expect(
      const StagePreferences(songSpeeds: {'a': 1.2}),
      isNot(const StagePreferences(songSpeeds: {'a': 1.3})),
    );
    expect(
      const StagePreferences(barsPerLine: 4),
      isNot(const StagePreferences()),
    );
  });
}
