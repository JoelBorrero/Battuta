/// Battuta — OMR Debug Log Provider.
///
/// Exposes the persistent [OmrLogService] and reactive [OmrLogState]
/// for in-app mobile log inspection and real-time updates.
library;

import 'package:battuta/features/scanner/data/services/omr_log_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the app-wide [OmrLogService] instance.
final omrLogServiceProvider = Provider<OmrLogService>((ref) {
  final service = OmrLogService();
  ref.onDispose(service.dispose);
  return service;
});

/// State model for the in-app OMR log viewer.
class OmrLogState {
  const OmrLogState({
    this.filePath = '',
    this.fileSizeBytes = 0,
    this.content = '',
  });

  final String filePath;
  final int fileSizeBytes;
  final String content;

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  OmrLogState copyWith({
    String? filePath,
    int? fileSizeBytes,
    String? content,
  }) {
    return OmrLogState(
      filePath: filePath ?? this.filePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      content: content ?? this.content,
    );
  }
}

/// Notifier driving the in-app log viewer modal.
class OmrLogNotifier extends AsyncNotifier<OmrLogState> {
  OmrLogService get _service => ref.read(omrLogServiceProvider);

  @override
  Future<OmrLogState> build() async {
    final service = ref.watch(omrLogServiceProvider);
    final path = await service.getLogFilePath();
    final size = await service.getLogSizeBytes();
    final content = await service.readLogs();
    return OmrLogState(
      filePath: path,
      fileSizeBytes: size,
      content: content,
    );
  }

  /// Reloads logs from the persistent file system.
  Future<void> loadLogs() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final path = await _service.getLogFilePath();
      final size = await _service.getLogSizeBytes();
      final content = await _service.readLogs();
      return OmrLogState(
        filePath: path,
        fileSizeBytes: size,
        content: content,
      );
    });
  }

  /// Clears the log file on disk and resets state.
  Future<void> clearLogs() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _service.clearLogs();
      final path = await _service.getLogFilePath();
      final size = await _service.getLogSizeBytes();
      final content = await _service.readLogs();
      return OmrLogState(
        filePath: path,
        fileSizeBytes: size,
        content: content,
      );
    });
  }

  /// Copies the current log text to clipboard.
  Future<void> copyToClipboard() async {
    final current = state.asData?.value;
    if (current != null && current.content.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: current.content));
    }
  }
}

/// Provider for reactive OMR log inspection.
final omrLogNotifierProvider =
    AsyncNotifierProvider<OmrLogNotifier, OmrLogState>(OmrLogNotifier.new);
