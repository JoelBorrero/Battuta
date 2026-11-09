/// Battuta — Supabase Configuration Service.
///
/// Manages loading and persisting Supabase URL and Anon Key credentials
/// securely using [ApiKeyStorage] with fallback to environment variables.
library;

import 'package:battuta/app/config/app_constants.dart';
import 'package:battuta/core/services/api_key_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Keys used for secure storage of Supabase credentials.
abstract final class SupabaseConfigKeys {
  static const String customUrl = 'battuta_custom_supabase_url';
  static const String customAnonKey = 'battuta_custom_supabase_anon_key';
}

/// Service managing Supabase connectivity credentials.
class SupabaseConfigService {
  SupabaseConfigService({ApiKeyStorage? storage})
    : _storage = storage ?? SecureApiKeyStorage();

  final ApiKeyStorage _storage;

  /// Retrieves the active Supabase Project URL.
  ///
  /// Checks custom secure storage first; falls back to `.env` if available,
  /// and finally falls back to [AppConstants.defaultSupabaseUrl] for automated
  /// zero-config cloud connectivity.
  Future<String?> getActiveUrl() async {
    final customUrl = await _storage.read(SupabaseConfigKeys.customUrl);
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      return customUrl.trim();
    }
    if (dotenv.isInitialized) {
      final envUrl = dotenv.env['SUPABASE_URL']?.trim();
      if (envUrl != null && envUrl.isNotEmpty) {
        return envUrl;
      }
    }
    return AppConstants.defaultSupabaseUrl;
  }

  /// Retrieves the active Supabase Anon Public Key.
  ///
  /// Checks custom secure storage first; falls back to `.env` if available,
  /// and finally falls back to [AppConstants.defaultSupabaseAnonKey] for
  /// automated zero-config cloud connectivity.
  Future<String?> getActiveAnonKey() async {
    final customKey = await _storage.read(SupabaseConfigKeys.customAnonKey);
    if (customKey != null && customKey.trim().isNotEmpty) {
      return customKey.trim();
    }
    if (dotenv.isInitialized) {
      final envKey = (dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
              dotenv.env['SUPABASE_ANON_KEY'])
          ?.trim();
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }
    }
    return AppConstants.defaultSupabaseAnonKey;
  }

  /// Saves a user-provided custom Supabase URL and Anon Key.
  Future<void> setCustomConfig({
    required String url,
    required String anonKey,
  }) async {
    final trimmedUrl = url.trim();
    final trimmedKey = anonKey.trim();

    if (!trimmedUrl.startsWith('http://') &&
        !trimmedUrl.startsWith('https://')) {
      throw ArgumentError('Supabase URL must start with http:// or https://');
    }
    if (trimmedKey.isEmpty) {
      throw ArgumentError('Supabase Anon Key cannot be empty');
    }

    await _storage.write(SupabaseConfigKeys.customUrl, trimmedUrl);
    await _storage.write(SupabaseConfigKeys.customAnonKey, trimmedKey);
  }

  /// Clears any user-stored custom Supabase credentials.
  Future<void> clearCustomConfig() async {
    await _storage.delete(SupabaseConfigKeys.customUrl);
    await _storage.delete(SupabaseConfigKeys.customAnonKey);
  }

  /// Whether custom credentials are currently stored.
  Future<bool> hasCustomConfig() async {
    final customUrl = await _storage.read(SupabaseConfigKeys.customUrl);
    return customUrl != null && customUrl.trim().isNotEmpty;
  }

  /// Checks if valid Supabase configuration is present from any source.
  Future<bool> isConfigured() async {
    final url = await getActiveUrl();
    final key = await getActiveAnonKey();
    return url != null &&
        url.isNotEmpty &&
        key != null &&
        key.isNotEmpty &&
        (url.startsWith('https://') || url.startsWith('http://'));
  }
}
