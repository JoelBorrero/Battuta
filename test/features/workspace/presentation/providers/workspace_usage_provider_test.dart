import 'package:battuta/features/workspace/presentation/providers/workspace_usage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceUsageProvider Tests', () {
    test('initializes with authentic local offline metrics', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final usage = await container.read(workspaceUsageProvider.future);
      expect(usage.workspaceName, equals('Local Workspace'));
      expect(usage.tier, equals('Offline'));
      expect(usage.geminiCreditsLimit, equals(5000));
      expect(usage.geminiCreditsUsed, equals(0));
      expect(usage.geminiScansCount, equals(0));
      expect(usage.storageUsedBytes, equals(0));
      expect(usage.storageLimitBytes, equals(1024 * 1024 * 1024));
    });

    test(
      'recordGeminiScan increments credits and scan count locally',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final initial = await container.read(workspaceUsageProvider.future);
        final initialCredits = initial.geminiCreditsUsed;
        final initialScans = initial.geminiScansCount;

        // Record 1500 tokens -> 15 credits
        await container
            .read(workspaceUsageProvider.notifier)
            .recordGeminiScan(totalTokens: 1500);

        final updated = container.read(workspaceUsageProvider).value!;
        expect(updated.geminiCreditsUsed, equals(initialCredits + 15));
        expect(updated.geminiScansCount, equals(initialScans + 1));
      },
    );

    test(
      'recordStorageUpload increments storage bytes and file count',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final initial = await container.read(workspaceUsageProvider.future);
        final initialBytes = initial.storageUsedBytes;
        final initialFiles = initial.filesUploadedCount;

        await container
            .read(workspaceUsageProvider.notifier)
            .recordStorageUpload(fileSizeBytes: 2048576); // ~2MB

        final updated = container.read(workspaceUsageProvider).value!;
        expect(updated.storageUsedBytes, equals(initialBytes + 2048576));
        expect(updated.filesUploadedCount, equals(initialFiles + 1));
      },
    );
  });
}
