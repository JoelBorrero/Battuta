import 'package:battuta/core/services/api_key_storage.dart';
import 'package:battuta/core/services/demo_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiKeyStorage extends ApiKeyStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);
}

void main() {
  group('DemoModeProvider Tests', () {
    test('initializes with false when unpersisted', () {
      final container = ProviderContainer(
        overrides: [
          demoModeStorageProvider.overrideWithValue(_FakeApiKeyStorage()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(demoModeProvider), isFalse);
    });

    test('persists enabled state when setDemoMode is called', () async {
      final storage = _FakeApiKeyStorage();
      final container = ProviderContainer(
        overrides: [
          demoModeStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      container.read(demoModeProvider.notifier).setDemoMode(true);
      expect(container.read(demoModeProvider), isTrue);

      final stored = await storage.read(DemoModeStorageKeys.demoModeEnabled);
      expect(stored, equals('true'));

      container.read(demoModeProvider.notifier).toggle();
      expect(container.read(demoModeProvider), isFalse);

      final updatedStored = await storage.read(DemoModeStorageKeys.demoModeEnabled);
      expect(updatedStored, equals('false'));
    });

    test('loads persisted true state from storage upon initialization', () async {
      final storage = _FakeApiKeyStorage();
      await storage.write(DemoModeStorageKeys.demoModeEnabled, 'true');

      final container = ProviderContainer(
        overrides: [
          demoModeStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      // Trigger build and allow microtasks
      container.read(demoModeProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(demoModeProvider), isTrue);
    });
  });
}
