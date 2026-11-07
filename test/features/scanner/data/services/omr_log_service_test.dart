import 'dart:io';

import 'package:battuta/features/scanner/data/services/omr_log_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late OmrLogService logService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('omr_log_test_');
    logService = OmrLogService(logDirectory: tempDir);
  });

  tearDown(() async {
    logService.dispose();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('OmrLogService File System Logging Tests', () {
    test('creates log file in dedicated directory and appends entries', () async {
      final filePath = await logService.getLogFilePath();
      expect(filePath, contains('omr_debug.log'));

      await logService.log('TEST_TAG', 'This is a test log message');

      final content = await logService.readLogs();
      expect(content, contains('[TEST_TAG] This is a test log message'));

      final size = await logService.getLogSizeBytes();
      expect(size, greaterThan(0));
    });

    test('logApiKeyResolved masks sensitive keys properly', () async {
      // Long key
      await logService.logApiKeyResolved(
        key: 'AIzaSyD-1234567890abcdefghijklmnopqrstuv',
        source: 'userSecureStorage',
      );

      final content = await logService.readLogs();
      expect(content, contains('AIzaSy...stuv'));
      expect(content, isNot(contains('1234567890abcdef')));
      expect(content, contains('Source: userSecureStorage'));
    });

    test('logSessionStart logs mode and formatted sizes', () async {
      await logService.logSessionStart(
        mode: 'Full Lead Sheet (Schema A)',
        imageSizeBytes: 2048576,
        mimeType: 'image/jpeg',
      );

      final content = await logService.readLogs();
      expect(content, contains('Full Lead Sheet (Schema A)'));
      expect(content, contains('image/jpeg'));
      expect(content, contains('1.95 MB'));
    });

    test('logResponseReceived logs duration and snippet', () async {
      await logService.logResponseReceived(
        durationMs: 1450,
        rawResponseText: '{"metadatos": {"titulo": "Test Song"}}',
        totalTokens: 1500,
      );

      final content = await logService.readLogs();
      expect(content, contains('1450ms'));
      expect(content, contains('Test Song'));
      expect(content, contains('Tokens Consumed: 1500'));
    });

    test('clearLogs empties the log file on disk', () async {
      await logService.log('ENTRY_1', 'First log');
      var size = await logService.getLogSizeBytes();
      expect(size, greaterThan(0));

      await logService.clearLogs();
      size = await logService.getLogSizeBytes();
      expect(size, equals(0));

      final content = await logService.readLogs();
      expect(content, contains('No logs recorded yet'));
    });
  });
}
