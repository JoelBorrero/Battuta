/// Battuta — Supabase Configuration Service.
///
/// Manages loading and persisting Supabase URL and Anon Key credentials
/// securely using [ApiKeyStorage] with fallback to environment variables.
library;

import 'package:battuta/app/config/app_constants.dart';
import 'package:battuta/core/services/api_key_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Keys used for secure storage of Supabase credentials.
abstract final class SupabaseConfigKeys {
  static const String customUrl = 'battuta_custom_supabase_url';
  static const String customAnonKey = 'battuta_custom_supabase_anon_key';
}

/// Which server a [SupabasePreset] points to.
enum SupabasePresetKind { remote, local }

/// A server the `.env` file names, offered as a one-tap choice in settings.
class SupabasePreset {
  const SupabasePreset({
    required this.kind,
    required this.url,
    required this.key,
  });

  final SupabasePresetKind kind;
  final String url;
  final String key;
}

/// Service managing Supabase connectivity credentials.
class SupabaseConfigService {
  SupabaseConfigService({
    ApiKeyStorage? storage,
    Map<String, String>? env,
    this._httpClient,
  }) : _storage = storage ?? SecureApiKeyStorage(),
       _envOverride = env;

  final ApiKeyStorage _storage;
  final Map<String, String>? _envOverride;
  final http.Client? _httpClient;

  Map<String, String> get _env =>
      _envOverride ?? (dotenv.isInitialized ? dotenv.env : const {});

  String? _envValue(List<String> names) {
    for (final name in names) {
      final value = _env[name]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  /// The servers named in `.env`: the remote project (`SUPABASE_URL` +
  /// `SUPABASE_PUBLISHABLE_KEY` / `SUPABASE_ANON_KEY`) and, for development,
  /// a local stack (`SUPABASE_LOCAL_URL` + `SUPABASE_LOCAL_PUBLISHABLE_KEY` /
  /// `SUPABASE_LOCAL_ANON_KEY`). Entries missing a URL or key are left out.
  List<SupabasePreset> presets() {
    SupabasePreset? preset(
      SupabasePresetKind kind,
      String urlName,
      List<String> keyNames,
    ) {
      final url = _envValue([urlName]);
      final key = _envValue(keyNames);
      if (url == null || key == null) return null;
      return SupabasePreset(kind: kind, url: url, key: key);
    }

    return [
      ?preset(SupabasePresetKind.remote, 'SUPABASE_URL', [
        'SUPABASE_PUBLISHABLE_KEY',
        'SUPABASE_ANON_KEY',
      ]),
      ?preset(SupabasePresetKind.local, 'SUPABASE_LOCAL_URL', [
        'SUPABASE_LOCAL_PUBLISHABLE_KEY',
        'SUPABASE_LOCAL_ANON_KEY',
      ]),
    ];
  }

  /// Whether the server at [url] answers its auth health check with [key].
  /// Never throws.
  Future<bool> checkReachable({
    required String url,
    required String key,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final client = _httpClient ?? http.Client();
    try {
      final base = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      final response = await client
          .get(Uri.parse('$base/auth/v1/health'), headers: {'apikey': key})
          .timeout(timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      if (_httpClient == null) client.close();
    }
  }

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
    return _envValue(['SUPABASE_URL']) ?? AppConstants.defaultSupabaseUrl;
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
    return _envValue(['SUPABASE_PUBLISHABLE_KEY', 'SUPABASE_ANON_KEY']) ??
        AppConstants.defaultSupabaseAnonKey;
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
