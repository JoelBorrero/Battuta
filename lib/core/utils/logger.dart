/// Application-wide logging facade.
///
/// Wraps the [`logger`](https://pub.dev/packages/logger) package with a
/// convenient static API so that every call site can log without
/// constructing its own [Logger] instance.
///
/// ```dart
/// AppLogger.info('Song loaded', details: songId);
/// AppLogger.error('Failed to save', error: e, stackTrace: st);
/// ```
///
/// Log level is configured once via [AppLogger.init] — typically in
/// `main()` — and respects the current [EnvConfig].
library;

import 'package:logger/logger.dart';

/// Centralized logger with static convenience methods.
///
/// Call [AppLogger.init] once at app startup.  After that, use the
/// static methods ([debug], [info], [warning], [error]) from anywhere.
final class AppLogger {
  const AppLogger._();

  static late final Logger _logger;
  static bool _initialized = false;

  // ── Initialization ──────────────────────────────────────────────────

  /// Configures the global logger.
  ///
  /// [level] controls the minimum severity that is printed.
  /// Defaults to [Level.debug] (everything) in debug mode and
  /// [Level.warning] in release builds.
  ///
  /// Must be called exactly once before any log method is used.
  static void init({Level level = Level.debug}) {
    if (_initialized) return;

    _logger = Logger(
      level: level,
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 80,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      filter: ProductionFilter(),
    );

    _initialized = true;
  }

  /// Ensures the logger has been initialized, using defaults if not.
  static void _ensureInit() {
    if (!_initialized) init();
  }

  // ── Log methods ───────────────────────────────────────────────────────

  /// Logs a **trace**-level message (extremely verbose).
  static void trace(
    String message, {
    Object? details,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _ensureInit();
    _logger.t(message, error: error ?? details, stackTrace: stackTrace);
  }

  /// Logs a **debug**-level message.
  static void debug(
    String message, {
    Object? details,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _ensureInit();
    _logger.d(message, error: error ?? details, stackTrace: stackTrace);
  }

  /// Logs an **info**-level message.
  static void info(
    String message, {
    Object? details,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _ensureInit();
    _logger.i(message, error: error ?? details, stackTrace: stackTrace);
  }

  /// Logs a **warning**-level message.
  static void warning(
    String message, {
    Object? details,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _ensureInit();
    _logger.w(message, error: error ?? details, stackTrace: stackTrace);
  }

  /// Logs an **error**-level message.
  ///
  /// Always include [error] and [stackTrace] when available so that
  /// crash-reporting tools can pick them up.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _ensureInit();
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Logs a **fatal**-level message (the app is about to crash).
  static void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _ensureInit();
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
