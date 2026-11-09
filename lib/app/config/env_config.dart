/// Environment configuration for the Battuta app.
///
/// Uses a sealed-class hierarchy so exhaustiveness checking guarantees every
/// environment is handled wherever the config is consumed. The active
/// environment is selected at startup via [EnvConfig.init] and exposed
/// through the top-level [envConfig] getter.
library;

import 'package:battuta/app/config/app_constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// The three deployment environments the app can target.
enum Environment {
  /// Local development — verbose logging, mock services allowed.
  dev,

  /// Pre-production staging — real services, extra diagnostics.
  staging,

  /// Production release — minimal logging, all guards enabled.
  prod,
}

/// Sealed configuration root.
///
/// Each leaf class carries the concrete values for its environment.
/// Use pattern matching to branch on the active config:
///
/// ```dart
/// final label = switch (envConfig) {
///   DevConfig()     => 'DEV',
///   StagingConfig() => 'STG',
///   ProdConfig()    => 'PROD',
/// };
/// ```
sealed class EnvConfig {
  const EnvConfig();

  /// Base URL for the Gemini-powered backend API.
  String get apiBaseUrl;

  /// Human-readable environment label (useful in debug banners).
  String get environmentName;

  /// Whether the app is running in a debug-capable environment.
  bool get isDebug;

  /// Whether verbose network/database logging should be emitted.
  bool get enableVerboseLogging;

  /// Supabase project URL for cloud synchronization (optional).
  String get supabaseUrl;

  /// Supabase anon public key (optional).
  String get supabaseAnonKey;

  /// The [Environment] enum value this config represents.
  Environment get environment;

  // ── Factory / singleton access ──────────────────────────────────────

  static EnvConfig? _instance;

  /// Returns the active [EnvConfig], which must have been set via [init].
  ///
  /// Throws [StateError] if called before [init].
  static EnvConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError(
        'EnvConfig.init() must be called before accessing the instance.',
      );
    }
    return config;
  }

  /// Initializes the global environment configuration.
  ///
  /// Call this once in `main()` before `runApp`.
  static void init(Environment env) {
    _instance = switch (env) {
      Environment.dev => const DevConfig(),
      Environment.staging => const StagingConfig(),
      Environment.prod => const ProdConfig(),
    };
  }
}

/// Convenience top-level getter for the active config.
EnvConfig get envConfig => EnvConfig.instance;

// ── Concrete environment configs ──────────────────────────────────────────

/// Development environment configuration.
final class DevConfig extends EnvConfig {
  const DevConfig();

  @override
  String get apiBaseUrl => 'http://localhost:8080/api/v1';

  @override
  String get environmentName => 'Development';

  @override
  bool get isDebug => true;

  @override
  bool get enableVerboseLogging => true;

  @override
  String get supabaseUrl => dotenv.isInitialized
      ? (dotenv.env['SUPABASE_URL'] ?? AppConstants.defaultSupabaseUrl)
      : AppConstants.defaultSupabaseUrl;

  @override
  String get supabaseAnonKey => dotenv.isInitialized
      ? ((dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
              dotenv.env['SUPABASE_ANON_KEY']) ??
          AppConstants.defaultSupabaseAnonKey)
      : AppConstants.defaultSupabaseAnonKey;

  @override
  Environment get environment => Environment.dev;
}

/// Staging environment configuration.
final class StagingConfig extends EnvConfig {
  const StagingConfig();

  @override
  String get apiBaseUrl => 'https://staging-api.battuta.app/api/v1';

  @override
  String get environmentName => 'Staging';

  @override
  bool get isDebug => true;

  @override
  bool get enableVerboseLogging => false;

  @override
  String get supabaseUrl => dotenv.isInitialized
      ? (dotenv.env['SUPABASE_URL'] ?? AppConstants.defaultSupabaseUrl)
      : AppConstants.defaultSupabaseUrl;

  @override
  String get supabaseAnonKey => dotenv.isInitialized
      ? ((dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
              dotenv.env['SUPABASE_ANON_KEY']) ??
          AppConstants.defaultSupabaseAnonKey)
      : AppConstants.defaultSupabaseAnonKey;

  @override
  Environment get environment => Environment.staging;
}

/// Production environment configuration.
final class ProdConfig extends EnvConfig {
  const ProdConfig();

  @override
  String get apiBaseUrl => 'https://api.battuta.app/api/v1';

  @override
  String get environmentName => 'Production';

  @override
  bool get isDebug => false;

  @override
  bool get enableVerboseLogging => false;

  @override
  String get supabaseUrl => dotenv.isInitialized
      ? (dotenv.env['SUPABASE_URL'] ?? AppConstants.defaultSupabaseUrl)
      : AppConstants.defaultSupabaseUrl;

  @override
  String get supabaseAnonKey => dotenv.isInitialized
      ? ((dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
              dotenv.env['SUPABASE_ANON_KEY']) ??
          AppConstants.defaultSupabaseAnonKey)
      : AppConstants.defaultSupabaseAnonKey;

  @override
  Environment get environment => Environment.prod;
}
