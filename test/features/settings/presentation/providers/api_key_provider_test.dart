import 'package:battuta/core/services/api_key_service.dart';
import 'package:battuta/core/services/api_key_storage.dart';
import 'package:battuta/features/settings/presentation/providers/api_key_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeApiKeyStorage extends ApiKeyStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);
}

void main() {
  const testKey = 'AIzaSyA1234567890abcdefghijklmnopqrstuv';

  test('ApiKeyNotifier manages key state changes reactively', () async {
    final fakeStorage = FakeApiKeyStorage();
    final container = ProviderContainer(
      overrides: [
        apiKeyStorageProvider.overrideWithValue(fakeStorage),
      ],
    );
    addTearDown(container.dispose);

    // Initial state without key
    final initialState = await container.read(apiKeyNotifierProvider.future);
    expect(initialState.isConfigured, isFalse);
    expect(initialState.source, equals(ApiKeySource.none));

    // Set custom key
    await container.read(apiKeyNotifierProvider.notifier).setCustomKey(testKey);

    final updatedState = container.read(apiKeyNotifierProvider).value!;
    expect(updatedState.isConfigured, isTrue);
    expect(updatedState.isUserCustom, isTrue);
    expect(updatedState.activeKey, equals(testKey));
    expect(updatedState.maskedKey, contains('••••'));

    // Clear custom key
    await container.read(apiKeyNotifierProvider.notifier).clearCustomKey();

    final clearedState = container.read(apiKeyNotifierProvider).value!;
    expect(clearedState.isConfigured, isFalse);
    expect(clearedState.source, equals(ApiKeySource.none));
  });
}
