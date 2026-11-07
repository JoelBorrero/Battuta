import 'package:battuta/features/workspace/domain/entities/workspace_usage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceUsage Entity Tests', () {
    test('instantiates with expected values and computed getters', () {
      const usage = WorkspaceUsage(
        workspaceId: 'ws-grace',
        workspaceName: 'Grace Church Worship',
        tier: 'Pro',
        billingPeriod: '2026-11',
        geminiCreditsUsed: 2500,
        geminiCreditsLimit: 5000,
        geminiScansCount: 25,
        storageUsedBytes: 524288000, // 500 MB
        storageLimitBytes: 1073741824, // 1024 MB
        filesUploadedCount: 40,
      );

      expect(usage.workspaceId, equals('ws-grace'));
      expect(usage.workspaceName, equals('Grace Church Worship'));
      expect(usage.tier, equals('Pro'));
      expect(usage.billingPeriod, equals('2026-11'));
      expect(usage.geminiCreditsUsed, equals(2500));
      expect(usage.geminiCreditsLimit, equals(5000));
      expect(usage.geminiScansCount, equals(25));
      expect(usage.storageUsedBytes, equals(524288000));
      expect(usage.storageLimitBytes, equals(1073741824));
      expect(usage.filesUploadedCount, equals(40));

      // Ratios
      expect(usage.creditsRatio, closeTo(0.5, 0.001));
      expect(usage.storageRatio, closeTo(0.488, 0.005));

      // Formatting
      expect(usage.formattedCredits, equals('2500 / 5000 Credits'));
      expect(usage.formattedStorage, contains('500.0 MB / 1024 MB'));
    });

    test('supports copyWith and value equality', () {
      const usage1 = WorkspaceUsage(
        workspaceId: 'ws-grace',
        workspaceName: 'Grace Church Worship',
        tier: 'Pro',
        billingPeriod: '2026-11',
        geminiCreditsUsed: 1000,
        geminiCreditsLimit: 5000,
        geminiScansCount: 10,
        storageUsedBytes: 104857600,
        storageLimitBytes: 1073741824,
        filesUploadedCount: 15,
      );

      const usage2 = WorkspaceUsage(
        workspaceId: 'ws-grace',
        workspaceName: 'Grace Church Worship',
        tier: 'Pro',
        billingPeriod: '2026-11',
        geminiCreditsUsed: 1000,
        geminiCreditsLimit: 5000,
        geminiScansCount: 10,
        storageUsedBytes: 104857600,
        storageLimitBytes: 1073741824,
        filesUploadedCount: 15,
      );

      expect(usage1, equals(usage2));

      final updated = usage1.copyWith(geminiCreditsUsed: 1200);
      expect(updated.geminiCreditsUsed, equals(1200));
      expect(updated, isNot(equals(usage1)));
    });
  });
}
