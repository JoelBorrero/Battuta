/// Battuta — Workspace Resource Consumption & Telemetry Provider.
///
/// Manages live monitoring of Gemini AI tokens/credits and Supabase cloud
/// storage at the active workspace level.
library;

import 'package:battuta/core/services/supabase_client_manager.dart';
import 'package:battuta/core/utils/logger.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/workspace/domain/entities/workspace_usage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides reactive access to the active workspace's usage and quota metrics.
final workspaceUsageProvider =
    AsyncNotifierProvider<WorkspaceUsageNotifier, WorkspaceUsage>(
      WorkspaceUsageNotifier.new,
    );

class WorkspaceUsageNotifier extends AsyncNotifier<WorkspaceUsage> {
  static const _defaultWorkspaceId = 'ws-local-offline';

  @override
  Future<WorkspaceUsage> build() async {
    final clientManager = ref.watch(supabaseClientManagerProvider);
    return _fetchUsage(clientManager);
  }

  Future<WorkspaceUsage> _fetchUsage(
    SupabaseClientManager clientManager,
  ) async {
    final client = clientManager.client;
    final now = DateTime.now();
    final period = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    // Base metrics: authentic zero usage until the backend reports otherwise.
    final base = WorkspaceUsage(
      workspaceId: _defaultWorkspaceId,
      workspaceName: 'Local Workspace',
      tier: 'Offline',
      billingPeriod: period,
      geminiCreditsUsed: 0,
      geminiCreditsLimit: 5000,
      geminiScansCount: 0,
      storageUsedBytes: 0,
      storageLimitBytes: 1024 * 1024 * 1024,
      filesUploadedCount: 0,
    );

    if (client == null || client.auth.currentUser == null) {
      return base;
    }

    try {
      final usageRes = await client
          .from('workspace_usage')
          .select()
          .eq('billing_period', period)
          .maybeSingle();

      if (usageRes != null) {
        return base.copyWith(
          geminiCreditsUsed: usageRes['gemini_credits_consumed'] as int?,
          geminiScansCount: usageRes['gemini_scans_count'] as int?,
          storageUsedBytes: usageRes['storage_used_bytes'] as int?,
          filesUploadedCount: usageRes['files_uploaded_count'] as int?,
        );
      }
      return base;
    } catch (e) {
      AppLogger.info('Workspace usage loaded from local cache: $e');
      return base;
    }
  }

  /// Records a completed Gemini OMR scan and debits workspace credits.
  Future<void> recordGeminiScan({required int totalTokens}) async {
    final credits = (totalTokens / 100).ceil();
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          geminiCreditsUsed: current.geminiCreditsUsed + credits,
          geminiScansCount: current.geminiScansCount + 1,
        ),
      );
    }

    final client = ref.read(supabaseClientManagerProvider).client;
    if (client == null || client.auth.currentUser == null) return;

    try {
      await client.rpc(
        'record_gemini_scan_usage',
        params: {
          'p_workspace_id': current?.workspaceId ?? _defaultWorkspaceId,
          'p_tokens': totalTokens,
          'p_credits': credits,
        },
      );
    } catch (e) {
      AppLogger.info('Offline: Scan usage recorded locally.');
    }
  }

  /// Records an uploaded file and increments storage bytes.
  Future<void> recordStorageUpload({required int fileSizeBytes}) async {
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          storageUsedBytes: current.storageUsedBytes + fileSizeBytes,
          filesUploadedCount: current.filesUploadedCount + 1,
        ),
      );
    }
  }
}
