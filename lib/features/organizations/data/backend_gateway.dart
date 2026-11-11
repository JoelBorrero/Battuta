/// Shared plumbing for the Supabase data sources: client access and the
/// translation of every error into a typed [Failure].
library;

import 'dart:async';
import 'dart:io';

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Returns the active client, or `null` when Supabase is not configured.
typedef SupabaseClientProvider = supa.SupabaseClient? Function();

/// Converts any exception thrown by the Supabase SDK into a [Failure].
Failure mapBackendError(Object error, [StackTrace? stackTrace]) {
  if (error is Failure) return error;
  if (error is supa.PostgrestException) {
    final code = BackendErrorCode.fromMessage(
      error.message,
      sqlState: error.code,
    );
    return code.failure(message: error.message, stackTrace: stackTrace);
  }
  if (error is supa.AuthException) {
    final code = BackendErrorCode.fromMessage(error.message);
    if (code != BackendErrorCode.unknown) {
      return code.failure(message: error.message, stackTrace: stackTrace);
    }
    final lower = error.message.toLowerCase();
    if (lower.contains('retryable') || lower.contains('failed host lookup')) {
      return BackendErrorCode.offline.failure(
        message: 'No connection to the server.',
        stackTrace: stackTrace,
      );
    }
    return ServerFailure(
      message: error.message,
      statusCode: int.tryParse(error.statusCode ?? ''),
      stackTrace: stackTrace,
    );
  }
  if (_isConnectivityError(error)) {
    return BackendErrorCode.offline.failure(
      message: 'No connection to the server.',
      stackTrace: stackTrace,
    );
  }
  return UnexpectedFailure(
    message: 'Unexpected backend error: $error',
    stackTrace: stackTrace,
    originalError: error,
  );
}

bool _isConnectivityError(Object error) =>
    error is SocketException ||
    error is TimeoutException ||
    error is http.ClientException ||
    error is WebSocketException ||
    error is HandshakeException ||
    error is supa.AuthRetryableFetchException;

/// Base class of the Supabase data sources.
abstract class SupabaseGateway {
  SupabaseGateway(this.clientProvider);

  final SupabaseClientProvider clientProvider;

  /// The id of the signed-in user, or `null`.
  String? get currentUserId => clientProvider()?.auth.currentUser?.id;

  /// Runs [action] for calls anyone may make (no session needed). Still needs
  /// a client; maps errors like [run].
  Future<T> runPublic<T>(
    Future<T> Function(supa.SupabaseClient client) action,
  ) async {
    final client = clientProvider();
    if (client == null) {
      throw BackendErrorCode.offline.failure(
        message: 'Cloud services are not available.',
      );
    }
    try {
      return await action(client);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  /// Runs [action] with the client. Throws a typed [Failure] when there is no
  /// client ([BackendErrorCode.offline]), no session
  /// ([BackendErrorCode.notSignedIn]) or the call fails.
  Future<T> run<T>(
    Future<T> Function(supa.SupabaseClient client, String userId) action,
  ) async {
    final client = clientProvider();
    if (client == null) {
      throw BackendErrorCode.offline.failure(
        message: 'Cloud services are not available.',
      );
    }
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw BackendErrorCode.notSignedIn.failure(message: 'Sign in first.');
    }
    try {
      return await action(client, userId);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }
}
