/// Battuta — Supabase Client Manager.
///
/// Encapsulates initialization and runtime access to the [SupabaseClient].
/// Guarantees that offline execution and unconfigured setups never crash
/// during application startup.
library;

import 'package:battuta/core/services/supabase_config_service.dart';
import 'package:battuta/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientManager {
  SupabaseClientManager({
    SupabaseConfigService? configService,
  }) : _configService = configService ?? SupabaseConfigService();

  final SupabaseConfigService _configService;
  bool _initialized = false;
  static bool _globalInitialized = false;

  /// Visible for testing: resets static initialization tracker.
  static void resetForTesting() {
    _globalInitialized = false;
  }

  /// Whether the Supabase SDK has been successfully initialized.
  bool get isInitialized {
    if (_initialized || _globalInitialized) return true;
    try {
      // In supabase_flutter, accessing Supabase.instance throws if uninitialized
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns the active [SupabaseClient] if initialized, or null.
  SupabaseClient? get client {
    if (!isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Initializes the Supabase SDK using configured credentials.
  ///
  /// Returns `true` if initialization succeeded, or `false` if credentials
  /// are absent or initialization was skipped. Never throws.
  Future<bool> initialize({String? customUrl, String? customAnonKey}) async {
    try {
      if (isInitialized && customUrl == null && customAnonKey == null) {
        return true;
      }

      final url = customUrl ?? await _configService.getActiveUrl();
      final anonKey = customAnonKey ?? await _configService.getActiveAnonKey();

      if (url == null || anonKey == null || url.isEmpty || anonKey.isEmpty) {
        AppLogger.info(
          'Supabase credentials not configured. Operating in local offline mode.',
        );
        _initialized = false;
        _globalInitialized = false;
        return false;
      }

      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: true,
        ),
      );

      _initialized = true;
      _globalInitialized = true;
      AppLogger.info('Supabase client initialized successfully.');
      return true;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to initialize Supabase client: $e',
        error: e,
        stackTrace: stack,
      );
      _initialized = false;
      _globalInitialized = false;
      return false;
    }
  }
}
