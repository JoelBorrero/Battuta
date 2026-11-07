/// Battuta — Persistent File System OMR Debug Logger.
///
/// Records detailed diagnostic logs for Gemini OMR recognition pipelines
/// directly to the device file system, enabling in-app inspection on mobile
/// and offline troubleshooting.
library;

import 'dart:async';
import 'dart:io';

import 'package:battuta/core/utils/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Service responsible for managing, appending, and reading OMR diagnostic logs
/// on the device's persistent file system.
class OmrLogService {
  /// Creates an [OmrLogService].
  ///
  /// Optionally accepts [logDirectory] or [logFile] for hermetic testing.
  OmrLogService({
    Directory? logDirectory,
    File? logFile,
  })  : _customLogDirectory = logDirectory,
        _customLogFile = logFile;

  final Directory? _customLogDirectory;
  final File? _customLogFile;
  final StreamController<String> _logStreamController =
      StreamController<String>.broadcast();

  /// Stream of log messages added during the current application runtime.
  Stream<String> get logUpdates => _logStreamController.stream;

  /// Resolves the dedicated [File] used for OMR debug logs.
  Future<File> getLogFile() async {
    final customFile = _customLogFile;
    if (customFile != null) return customFile;

    Directory baseDir;
    final customDir = _customLogDirectory;
    if (customDir != null) {
      baseDir = customDir;
    } else {
      try {
        baseDir = await getApplicationDocumentsDirectory();
      } catch (_) {
        baseDir = Directory.systemTemp;
      }
    }

    final logsDir = Directory('${baseDir.path}/logs');
    if (!logsDir.existsSync()) {
      await logsDir.create(recursive: true);
    }

    return File('${logsDir.path}/omr_debug.log');
  }

  /// Returns the absolute path string of the log file.
  Future<String> getLogFilePath() async {
    final file = await getLogFile();
    return file.path;
  }

  /// Appends a structured log entry to the log file on disk.
  Future<void> log(
    String tag,
    String message, {
    Map<String, dynamic>? details,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer();
    buffer.writeln('[$timestamp] [$tag] $message');

    if (details != null && details.isNotEmpty) {
      details.forEach((key, value) {
        buffer.writeln('    • $key: $value');
      });
    }

    if (error != null) {
      buffer.writeln('    ⚠️ ERROR: $error');
    }

    if (stackTrace != null) {
      buffer.writeln('    STACK TRACE:');
      final lines = stackTrace.toString().split('\n').take(12);
      for (final line in lines) {
        buffer.writeln('      $line');
      }
    }

    buffer.writeln('─' * 60);

    final entry = buffer.toString();
    try {
      final file = await getLogFile();
      await file.writeAsString(entry, mode: FileMode.append, flush: true);
    } catch (e) {
      AppLogger.warning('Failed to write to OMR log file: $e');
    }

    _logStreamController.add(entry);
    AppLogger.debug('OMR_DEBUG [$tag] $message');
  }

  /// Helper: Logs session initialization with image details.
  Future<void> logSessionStart({
    required String mode,
    required int imageSizeBytes,
    required String mimeType,
  }) async {
    final kb = (imageSizeBytes / 1024).toStringAsFixed(1);
    final mb = (imageSizeBytes / (1024 * 1024)).toStringAsFixed(2);
    await log('OMR_SESSION_START', 'Initiated OMR scan session', details: {
      'Scan Mode': mode,
      'Image Size': '$imageSizeBytes bytes ($kb KB / $mb MB)',
      'MIME Type': mimeType,
    });
  }

  /// Helper: Logs API key status without exposing credentials.
  Future<void> logApiKeyResolved({
    required String? key,
    required String source,
  }) async {
    final String masked;
    if (key == null || key.trim().isEmpty) {
      masked = 'MISSING / NULL';
    } else if (key.length <= 8) {
      masked = '*** (length: ${key.length})';
    } else {
      final prefix = key.substring(0, 6);
      final suffix = key.substring(key.length - 4);
      masked = '$prefix...$suffix (length: ${key.length})';
    }

    await log('API_KEY_CHECK', 'Resolved Gemini API key', details: {
      'Source': source,
      'Key Status': masked,
      'Configured': key != null && key.trim().isNotEmpty,
    });
  }

  /// Helper: Logs request dispatch to Gemini.
  Future<void> logRequestDispatched({
    required String model,
    required String prompt,
    required int systemInstructionLength,
  }) async {
    await log('REQUEST_DISPATCHED', 'Sending payload to Gemini model', details: {
      'Model': model,
      'System Instruction Length': '$systemInstructionLength chars',
      'Prompt': prompt,
    });
  }

  /// Helper: Logs Gemini response payload and round-trip latency.
  Future<void> logResponseReceived({
    required int durationMs,
    required String? rawResponseText,
    int? totalTokens,
  }) async {
    final length = rawResponseText?.length ?? 0;
    final snippet = (rawResponseText != null && rawResponseText.isNotEmpty)
        ? (rawResponseText.length > 300
            ? '${rawResponseText.substring(0, 300)}... [truncated ${rawResponseText.length - 300} chars]'
            : rawResponseText)
        : '(empty response)';

    await log('RESPONSE_RECEIVED', 'Received response from Gemini', details: {
      'Duration': '${durationMs}ms',
      'Response Length': '$length characters',
      'Tokens Consumed': ?totalTokens,
      'Response Preview': snippet,
    });
  }

  /// Helper: Logs JSON parsing and domain mapping result.
  Future<void> logResult({
    required bool success,
    required String summary,
    Map<String, dynamic>? metrics,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    await log(
      success ? 'OMR_SUCCESS' : 'OMR_ERROR',
      summary,
      details: metrics,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Reads the entire contents of the log file.
  Future<String> readLogs() async {
    try {
      final file = await getLogFile();
      if (file.existsSync()) {
        final content = await file.readAsString();
        if (content.trim().isEmpty) {
          return 'No logs recorded yet in ${file.path}';
        }
        return content;
      }
      return 'Log file not found at ${file.path}';
    } catch (e) {
      return 'Failed to read logs: $e';
    }
  }

  /// Returns the current size of the log file in bytes.
  Future<int> getLogSizeBytes() async {
    try {
      final file = await getLogFile();
      if (file.existsSync()) {
        return file.lengthSync();
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Truncates / clears the log file.
  Future<void> clearLogs() async {
    try {
      final file = await getLogFile();
      if (file.existsSync()) {
        await file.writeAsString('');
      }
      _logStreamController.add('[LOGS CLEARED]');
      AppLogger.info('OMR debug log file cleared');
    } catch (e) {
      AppLogger.warning('Failed to clear OMR log file: $e');
    }
  }

  /// Releases resources.
  void dispose() {
    _logStreamController.close();
  }
}
