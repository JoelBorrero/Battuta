/// Battuta — Cloud Sync Result Model.
///
/// Encapsulates the outcome of a two-way synchronization run between
/// the local Drift SQLite database and Supabase.
library;

import 'package:equatable/equatable.dart';

class CloudSyncResult extends Equatable {
  const CloudSyncResult({
    required this.isSuccess,
    required this.isOffline,
    required this.pushedCount,
    required this.pulledCount,
    this.errorMessage,
    required this.timestamp,
  });

  /// Successful sync run with counts of affected entities.
  factory CloudSyncResult.success({
    int pushedCount = 0,
    int pulledCount = 0,
    DateTime? timestamp,
  }) {
    return CloudSyncResult(
      isSuccess: true,
      isOffline: false,
      pushedCount: pushedCount,
      pulledCount: pulledCount,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// App is in Airplane Mode or offline without network connectivity.
  factory CloudSyncResult.offline({String? reason, DateTime? timestamp}) {
    return CloudSyncResult(
      isSuccess: false,
      isOffline: true,
      pushedCount: 0,
      pulledCount: 0,
      errorMessage: reason ?? 'Device is offline. Local changes remain cached.',
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Sync operation failed due to a server or validation error.
  factory CloudSyncResult.failure({
    required String error,
    DateTime? timestamp,
  }) {
    return CloudSyncResult(
      isSuccess: false,
      isOffline: false,
      pushedCount: 0,
      pulledCount: 0,
      errorMessage: error,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  final bool isSuccess;
  final bool isOffline;
  final int pushedCount;
  final int pulledCount;
  final String? errorMessage;
  final DateTime timestamp;

  int get totalAffected => pushedCount + pulledCount;

  @override
  List<Object?> get props => [
    isSuccess,
    isOffline,
    pushedCount,
    pulledCount,
    errorMessage,
    timestamp,
  ];
}
