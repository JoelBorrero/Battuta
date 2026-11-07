/// High-level API key management service.
///
/// Resolves active API keys by checking user-entered secure storage first,
/// falling back to development `.env` variables if configured.
library;

import 'package:battuta/core/services/api_key_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Storage key identifier for the Gemini API key.
const String geminiStorageKey = 'gemini_api_key';

/// Environment variable name for the Gemini API key.
const String geminiEnvKey = 'GEMINI_API_KEY';

/// Represents the origin of the active API key.
enum ApiKeySource {
  /// The key was entered manually by the user and stored in secure storage.
  userSecureStorage,

  /// The key was loaded from the `.env` development file.
  envFile,

  /// No key is currently configured.
  none,
}

/// Service managing the lifecycle, resolution, and validation of API keys.
class ApiKeyService {
  ApiKeyService({required this.storage, this.envOverrides});

  /// The underlying secure storage mechanism.
  final ApiKeyStorage storage;

  /// Optional in-memory environment variable overrides for testing.
  final Map<String, String>? envOverrides;

  Map<String, String> get _env {
    if (envOverrides != null) {
      return envOverrides!;
    }
    if (dotenv.isInitialized) {
      return dotenv.env;
    }
    return const {};
  }

  /// Retrieves the active Gemini API key.
  ///
  /// Checks user-entered secure storage first. If absent or empty, falls
  /// back to the `.env` variable `GEMINI_API_KEY`. Returns `null` if neither is set.
  Future<String?> getActiveGeminiKey() async {
    final customKey = await storage.read(geminiStorageKey);
    if (customKey != null && customKey.trim().isNotEmpty) {
      return customKey.trim();
    }

    final envKey = _env[geminiEnvKey]?.trim();
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }

    return null;
  }

  /// Determines the source of the currently active Gemini API key.
  Future<ApiKeySource> getGeminiKeySource() async {
    final customKey = await storage.read(geminiStorageKey);
    if (customKey != null && customKey.trim().isNotEmpty) {
      return ApiKeySource.userSecureStorage;
    }

    final envKey = _env[geminiEnvKey]?.trim();
    if (envKey != null && envKey.isNotEmpty) {
      return ApiKeySource.envFile;
    }

    return ApiKeySource.none;
  }

  /// Checks whether any valid Gemini API key is currently available.
  Future<bool> hasGeminiKey() async {
    final key = await getActiveGeminiKey();
    return key != null && key.isNotEmpty;
  }

  /// Saves a user-entered Gemini API key into secure storage.
  ///
  /// Throws [ArgumentError] if the key is invalid.
  Future<void> setCustomGeminiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (!isValidKey(trimmed)) {
      throw ArgumentError.value(
        apiKey,
        'apiKey',
        'Invalid API key format. Gemini API keys must be non-empty and at least 20 characters.',
      );
    }
    await storage.write(geminiStorageKey, trimmed);
  }

  /// Clears any user-entered Gemini API key from secure storage.
  ///
  /// Subsequent calls to [getActiveGeminiKey] will fall back to `.env` if available.
  Future<void> clearCustomGeminiKey() async {
    await storage.delete(geminiStorageKey);
  }

  /// Validates basic structural requirements of a Gemini API key.
  ///
  /// Google Gemini API keys are typically ~39 characters long, alphanumeric with
  /// occasional dashes/underscores (e.g. `AIzaSy...`).
  static bool isValidKey(String? key) {
    if (key == null) return false;
    final trimmed = key.trim();
    if (trimmed.length < 20 || trimmed.length > 120) return false;
    // Disallow whitespace
    if (trimmed.contains(RegExp(r'\s'))) return false;
    return true;
  }

  /// Masks an API key for safe display in the UI.
  ///
  /// Example: `AIzaSyD-1234567890abcdef` -> `AIza••••cdef`
  static String maskKey(String? key) {
    if (key == null || key.trim().isEmpty) {
      return 'Not configured';
    }
    final trimmed = key.trim();
    if (trimmed.length <= 8) {
      return '••••••••';
    }
    final prefix = trimmed.substring(0, 4);
    final suffix = trimmed.substring(trimmed.length - 4);
    return '$prefix••••••••$suffix';
  }
}
