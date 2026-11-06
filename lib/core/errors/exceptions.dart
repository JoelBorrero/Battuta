/// Exception classes that mirror the [Failure] hierarchy.
///
/// These are thrown at the data-layer boundary (repositories, data sources)
/// and caught by repository implementations to convert into the
/// corresponding [Failure] type.
///
/// ```
///  Data Source  ──throws──▶  ServerException
///       │
///  Repository   ──catches──▶  returns Left(ServerFailure(…))
/// ```
library;

/// Base exception carrying a diagnostic [message] and optional [stackTrace].
sealed class AppException implements Exception {
  const AppException({required this.message, this.stackTrace});

  /// A human-readable description of what went wrong.
  final String message;

  /// Optional stack trace captured at the throw site.
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a remote server or network call fails.
///
/// Typical causes: HTTP errors, timeouts, connection refused.
final class ServerException extends AppException {
  /// Creates a [ServerException].
  ///
  /// [statusCode] is the HTTP status code when available.
  const ServerException({
    required super.message,
    super.stackTrace,
    this.statusCode,
  });

  /// The HTTP status code, if applicable.
  final int? statusCode;
}

/// Thrown when a local cache / database operation fails.
final class CacheException extends AppException {
  /// Creates a [CacheException].
  const CacheException({required super.message, super.stackTrace});
}

/// Thrown when input validation or a business rule check fails.
final class ValidationException extends AppException {
  /// Creates a [ValidationException].
  ///
  /// [fieldErrors] holds per-field error messages.
  const ValidationException({
    required super.message,
    super.stackTrace,
    this.fieldErrors = const {},
  });

  /// Per-field validation errors (field name → error message).
  final Map<String, String> fieldErrors;
}

/// Thrown when the user lacks permission to perform an action.
final class PermissionException extends AppException {
  /// Creates a [PermissionException].
  const PermissionException({required super.message, super.stackTrace});
}

/// A catch-all for unexpected errors at the data layer.
final class UnexpectedException extends AppException {
  /// Creates an [UnexpectedException].
  ///
  /// [originalError] preserves the raw exception/error for logging.
  const UnexpectedException({
    required super.message,
    super.stackTrace,
    this.originalError,
  });

  /// The original error object.
  final Object? originalError;
}

/// Thrown when rhythmic operations in a measure exceed the measure's time signature capacity.
final class MeasureOverflowException extends AppException {
  /// Creates a [MeasureOverflowException].
  const MeasureOverflowException({
    required super.message,
    super.stackTrace,
    this.maxTicks,
    this.attemptedTicks,
  });

  /// Maximum allowed ticks for the measure according to its time signature.
  final int? maxTicks;

  /// Attempted total ticks that caused the overflow.
  final int? attemptedTicks;
}
