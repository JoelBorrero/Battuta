/// Battuta — Workspace Resource & Quotas Domain Entity.
///
/// Encapsulates live usage metrics for Gemini AI credits and Supabase cloud
/// storage at the workspace/band level.
library;

class WorkspaceUsage {
  const WorkspaceUsage({
    required this.workspaceId,
    required this.workspaceName,
    required this.tier,
    required this.billingPeriod,
    required this.geminiCreditsUsed,
    required this.geminiCreditsLimit,
    required this.geminiScansCount,
    required this.storageUsedBytes,
    required this.storageLimitBytes,
    required this.filesUploadedCount,
  });

  final String workspaceId;
  final String workspaceName;
  final String tier;
  final String billingPeriod;
  final int geminiCreditsUsed;
  final int geminiCreditsLimit;
  final int geminiScansCount;
  final int storageUsedBytes;
  final int storageLimitBytes;
  final int filesUploadedCount;

  /// Clamped ratio (0.0 to 1.0) of AI credits consumed.
  double get creditsRatio =>
      geminiCreditsLimit > 0 ? (geminiCreditsUsed / geminiCreditsLimit).clamp(0.0, 1.0) : 0.0;

  /// Clamped ratio (0.0 to 1.0) of cloud storage bytes consumed.
  double get storageRatio =>
      storageLimitBytes > 0 ? (storageUsedBytes / storageLimitBytes).clamp(0.0, 1.0) : 0.0;

  /// Formatted storage string (e.g. "42.5 MB / 1024 MB").
  String get formattedStorage {
    final usedMb = (storageUsedBytes / (1024 * 1024)).toStringAsFixed(1);
    final limitMb = (storageLimitBytes / (1024 * 1024)).toStringAsFixed(0);
    return '$usedMb MB / $limitMb MB';
  }

  /// Formatted credits string (e.g. "1,450 / 5,000 Credits").
  String get formattedCredits =>
      '$geminiCreditsUsed / $geminiCreditsLimit Credits';

  WorkspaceUsage copyWith({
    String? workspaceId,
    String? workspaceName,
    String? tier,
    String? billingPeriod,
    int? geminiCreditsUsed,
    int? geminiCreditsLimit,
    int? geminiScansCount,
    int? storageUsedBytes,
    int? storageLimitBytes,
    int? filesUploadedCount,
  }) {
    return WorkspaceUsage(
      workspaceId: workspaceId ?? this.workspaceId,
      workspaceName: workspaceName ?? this.workspaceName,
      tier: tier ?? this.tier,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      geminiCreditsUsed: geminiCreditsUsed ?? this.geminiCreditsUsed,
      geminiCreditsLimit: geminiCreditsLimit ?? this.geminiCreditsLimit,
      geminiScansCount: geminiScansCount ?? this.geminiScansCount,
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      storageLimitBytes: storageLimitBytes ?? this.storageLimitBytes,
      filesUploadedCount: filesUploadedCount ?? this.filesUploadedCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceUsage &&
          runtimeType == other.runtimeType &&
          workspaceId == other.workspaceId &&
          workspaceName == other.workspaceName &&
          tier == other.tier &&
          billingPeriod == other.billingPeriod &&
          geminiCreditsUsed == other.geminiCreditsUsed &&
          geminiCreditsLimit == other.geminiCreditsLimit &&
          geminiScansCount == other.geminiScansCount &&
          storageUsedBytes == other.storageUsedBytes &&
          storageLimitBytes == other.storageLimitBytes &&
          filesUploadedCount == other.filesUploadedCount;

  @override
  int get hashCode => Object.hash(
        workspaceId,
        workspaceName,
        tier,
        billingPeriod,
        geminiCreditsUsed,
        geminiCreditsLimit,
        geminiScansCount,
        storageUsedBytes,
        storageLimitBytes,
        filesUploadedCount,
      );
}
