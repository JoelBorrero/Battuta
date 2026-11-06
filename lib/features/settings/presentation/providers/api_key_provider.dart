/// Riverpod providers for API key management and settings.
library;

import 'package:battuta/core/services/api_key_service.dart';
import 'package:battuta/core/services/api_key_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the low-level secure storage abstraction.
final apiKeyStorageProvider = Provider<ApiKeyStorage>((ref) {
  return SecureApiKeyStorage();
});

/// Provides the high-level [ApiKeyService].
final apiKeyServiceProvider = Provider<ApiKeyService>((ref) {
  final storage = ref.watch(apiKeyStorageProvider);
  return ApiKeyService(storage: storage);
});

/// Represents the UI state of the Gemini API key.
class ApiKeyState {
  const ApiKeyState({
    required this.activeKey,
    required this.source,
  });

  final String? activeKey;
  final ApiKeySource source;

  bool get isConfigured => activeKey != null && activeKey!.isNotEmpty;
  bool get isUserCustom => source == ApiKeySource.userSecureStorage;
  bool get isFromEnv => source == ApiKeySource.envFile;
  String get maskedKey => ApiKeyService.maskKey(activeKey);
}

/// Manages reactive updates to the Gemini API key.
class ApiKeyNotifier extends AsyncNotifier<ApiKeyState> {
  @override
  Future<ApiKeyState> build() async {
    final service = ref.watch(apiKeyServiceProvider);
    final key = await service.getActiveGeminiKey();
    final source = await service.getGeminiKeySource();
    return ApiKeyState(activeKey: key, source: source);
  }

  /// Sets a user-entered Gemini API key in secure storage.
  Future<void> setCustomKey(String newKey) async {
    final service = ref.read(apiKeyServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await service.setCustomGeminiKey(newKey);
      final key = await service.getActiveGeminiKey();
      final source = await service.getGeminiKeySource();
      return ApiKeyState(activeKey: key, source: source);
    });
  }

  /// Clears the user's custom key, reverting to `.env` if available.
  Future<void> clearCustomKey() async {
    final service = ref.read(apiKeyServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await service.clearCustomGeminiKey();
      final key = await service.getActiveGeminiKey();
      final source = await service.getGeminiKeySource();
      return ApiKeyState(activeKey: key, source: source);
    });
  }
}

/// Provides the reactive [ApiKeyState].
final apiKeyNotifierProvider =
    AsyncNotifierProvider<ApiKeyNotifier, ApiKeyState>(
  ApiKeyNotifier.new,
);
