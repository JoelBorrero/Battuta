/// Battuta — OMR Log Viewer Modal.
///
/// Stage-ready in-app log viewer modal allowing musicians and developers
/// to inspect Gemini OMR requests, payloads, API key states, roundtrip latencies,
/// and errors directly on mobile devices without desktop tethering.
library;

import 'package:battuta/features/scanner/presentation/providers/omr_log_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modal dialog / bottom sheet for live inspection of OMR logs stored on the file system.
class OmrLogViewerModal extends ConsumerWidget {
  const OmrLogViewerModal({super.key});

  /// Presents the OMR log viewer modally based on screen form factor.
  static Future<void> show(BuildContext context) {
    final isTabletOrDesktop = MediaQuery.sizeOf(context).width >= 600;
    if (isTabletOrDesktop) {
      return showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: const Color(0xFF16181D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2E323B)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
            child: const OmrLogViewerModal(),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF16181D),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: Color(0xFF2E323B)),
        ),
        builder: (_) => const FractionallySizedBox(
          heightFactor: 0.90,
          child: OmrLogViewerModal(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(omrLogNotifierProvider);
    final notifier = ref.read(omrLogNotifierProvider.notifier);
    final state = stateAsync.asData?.value ?? const OmrLogState();
    final isLoading = stateAsync.isLoading;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF16181D),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.omrDiagnosticLogs ?? 'OMR Diagnostic Logs',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              l10n?.persistentFileSystemLogs ?? 'Persistent File System Logs',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8A8F98)),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            key: const ValueKey('omr_logs_refresh_btn'),
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: l10n?.refreshLogs ?? 'Refresh Logs',
            onPressed: isLoading ? null : () => notifier.loadLogs(),
          ),
          IconButton(
            key: const ValueKey('omr_logs_clear_btn'),
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            tooltip: l10n?.clearLogs ?? 'Clear Logs',
            onPressed: isLoading
                ? null
                : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E2024),
                        title: Text(
                          l10n?.clearOmrLogsTitle ?? 'Clear OMR Logs?',
                          style: const TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          l10n?.clearOmrLogsConfirm ??
                              'This will empty the omr_debug.log file on the device.',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(l10n?.cancel ?? 'Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text(l10n?.clearAction ?? 'Clear'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await notifier.clearLogs();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n?.omrLogsCleared ?? 'OMR logs cleared from file system.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // File path and metadata banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1E2024),
            child: Row(
              children: [
                const Icon(Icons.folder_open, size: 16, color: Color(0xFFE5A93C)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.filePath.isEmpty
                        ? (l10n?.locatingLogFile ?? 'Locating log file...')
                        : state.filePath,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF8A8F98),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E323B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    state.formattedSize,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE5A93C),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Log Content Area
          Expanded(
            child: isLoading && state.content.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n?.loadingDiagnosticLogs ?? 'Loading diagnostic logs...',
                        style: const TextStyle(color: Color(0xFF8A8F98), fontSize: 13),
                      ),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101114),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2E323B)),
                    ),
                    child: SingleChildScrollView(
                      key: const ValueKey('omr_logs_scroll_view'),
                      child: Text(
                        state.content.isEmpty
                            ? (l10n?.noLogsRecordedYet ??
                                'No logs recorded yet.\nRun an OMR scan to capture diagnostic logs.')
                            : state.content,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.45,
                          color: Color(0xFFE1E4E8),
                        ),
                      ),
                    ),
                  ),
          ),

          // Bottom Action Bar: Copy All
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF16181D),
              border: Border(top: BorderSide(color: Color(0xFF2E323B))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('omr_logs_copy_btn'),
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text(l10n?.copyAllLogs ?? 'Copy All Logs'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE5A93C),
                      side: const BorderSide(color: Color(0xFFE5A93C)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: state.content.isEmpty
                        ? null
                        : () async {
                            await notifier.copyToClipboard();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n?.omrLogsCopied ?? 'OMR logs copied to clipboard.',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
