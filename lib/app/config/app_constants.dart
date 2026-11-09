/// App-wide constants for the Battuta music rehearsal & lead-sheet companion.
///
/// Centralizes magic strings, version info, database names, and other
/// compile-time constants so they can be changed in one place.
library;

/// Immutable application-level constants.
///
/// This class cannot be instantiated — all members are static.
final class AppConstants {
  const AppConstants._();

  // ── Identity ──────────────────────────────────────────────────────────

  /// Human-readable application name shown in the UI and about screens.
  static const String appName = 'Battuta';

  /// Semantic version string following SemVer 2.0.
  static const String appVersion = '0.1.0';

  /// Integer build number, typically bumped by CI.
  static const int buildNumber = 1;

  /// Bundle / application identifier used across platforms.
  static const String bundleId = 'com.battuta.app';

  // ── Persistence ───────────────────────────────────────────────────────

  /// SQLite / Drift database file name stored in the app-support directory.
  static const String databaseName = 'battuta.db';

  /// Current schema version for database migrations.
  static const int databaseVersion = 1;

  /// Prefix for shared-preferences keys to avoid collisions.
  static const String prefsPrefix = 'battuta_';

  // ── Networking ────────────────────────────────────────────────────────

  /// Default HTTP timeout for API calls.
  static const Duration httpTimeout = Duration(seconds: 30);

  /// Maximum number of automatic retry attempts for transient failures.
  static const int maxRetries = 3;

  // ── Cloud / Supabase Defaults ─────────────────────────────────────────

  /// Default production Supabase endpoint for automated zero-config connectivity.
  static const String defaultSupabaseUrl =
      'https://gyiofbbzxgrwvxpssirh.supabase.co';

  /// Default anonymous public key for automated zero-config connectivity.
  static const String defaultSupabaseAnonKey =
      'sb_publishable_z8m5oJOFzQfV8YPNrO9acQ_CfNSLGp-';

  // ── Music Domain ──────────────────────────────────────────────────────

  /// Default BPM when no tempo is specified for a song.
  static const int defaultBpm = 120;

  /// Standard tuning reference frequency (A4) in Hz.
  static const double referencePitch = 440.0;

  /// Maximum number of songs allowed in a single setlist.
  static const int maxSetlistSize = 50;

  /// Supported time signatures presented in the editor UI.
  static const List<(int, int)> supportedTimeSignatures = [
    (2, 4),
    (3, 4),
    (4, 4),
    (5, 4),
    (6, 8),
    (7, 8),
    (12, 8),
  ];

  // ── UI ────────────────────────────────────────────────────────────────

  /// Standard animation duration used across page transitions.
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// Fast animation duration for micro-interactions.
  static const Duration animationDurationFast = Duration(milliseconds: 150);

  /// Default border radius value for cards and containers.
  static const double defaultBorderRadius = 12.0;

  /// Minimum horizontal padding for screen-level layouts.
  static const double screenPadding = 16.0;
}
