/// Typed failure hierarchy for domain-level error handling.
///
/// [Failure] is a **sealed class** so the compiler enforces exhaustive
/// pattern matching whenever you handle errors:
///
/// ```dart
/// final message = switch (failure) {
///   ServerFailure(:final message)     => 'Server: $message',
///   CacheFailure(:final message)      => 'Cache: $message',
///   ValidationFailure(:final message) => 'Validation: $message',
///   PermissionFailure(:final message) => 'Permission: $message',
///   UnexpectedFailure(:final message) => 'Unexpected: $message',
/// };
/// ```
///
/// Each variant carries a human-readable [message] and an optional
/// [stackTrace] for diagnostics.
library;

import 'package:battuta/core/errors/backend_error_code.dart';

/// Base failure type.
///
/// Sealed so that all subtypes are known at compile time, enabling
/// exhaustive `switch` expressions.
sealed class Failure {
  const Failure({
    required this.message,
    this.stackTrace,
    this.errorCode,
  });

  /// A human-readable description of what went wrong.
  final String message;

  /// The typed backend error behind this failure, when one is known.
  ///
  /// Set by the Supabase data layer (see [BackendErrorCode]); `null` for
  /// failures that did not come from the backend.
  final BackendErrorCode? errorCode;

  /// Optional stack trace captured at the point of failure.
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          errorCode == other.errorCode;

  @override
  int get hashCode => Object.hash(runtimeType, message, errorCode);
}

/// A failure originating from a remote server or network call.
///
/// Typical causes: HTTP 5xx, timeout, DNS resolution failure.
final class ServerFailure extends Failure {
  /// Creates a [ServerFailure] with the given [message].
  ///
  /// Optionally accepts an HTTP [statusCode] for richer diagnostics.
  const ServerFailure({
    required super.message,
    super.stackTrace,
    super.errorCode,
    this.statusCode,
  });

  /// The HTTP status code, if available.
  final int? statusCode;
}

/// A failure reading from or writing to a local cache / database.
final class CacheFailure extends Failure {
  /// Creates a [CacheFailure] with the given [message].
  const CacheFailure({
    required super.message,
    super.stackTrace,
    super.errorCode,
  });
}

/// A failure caused by invalid user input or business-rule violation.
final class ValidationFailure extends Failure {
  /// Creates a [ValidationFailure] with the given [message].
  ///
  /// [fieldErrors] may contain per-field error messages for form UIs.
  const ValidationFailure({
    required super.message,
    super.stackTrace,
    super.errorCode,
    this.fieldErrors = const {},
  });

  /// Map of field names to their individual validation error messages.
  final Map<String, String> fieldErrors;
}

/// A failure caused by insufficient permissions or authentication issues.
final class PermissionFailure extends Failure {
  /// Creates a [PermissionFailure] with the given [message].
  const PermissionFailure({
    required super.message,
    super.stackTrace,
    super.errorCode,
  });
}

/// A catch-all failure for truly unexpected errors (e.g. uncaught exceptions).
final class UnexpectedFailure extends Failure {
  /// Creates an [UnexpectedFailure] with the given [message].
  ///
  /// [originalError] preserves the raw exception/error for logging.
  const UnexpectedFailure({
    required super.message,
    super.stackTrace,
    this.originalError,
  });

  /// The original exception or error object, if available.
  final Object? originalError;
}

/// A failure representing a measure capacity overflow.
final class MeasureOverflowFailure extends Failure {
  /// Creates a [MeasureOverflowFailure].
  const MeasureOverflowFailure({
    required super.message,
    super.stackTrace,
    this.maxTicks,
    this.attemptedTicks,
  });

  /// The maximum allowed ticks for the measure.
  final int? maxTicks;

  /// The attempted ticks that caused the overflow.
  final int? attemptedTicks;
}
