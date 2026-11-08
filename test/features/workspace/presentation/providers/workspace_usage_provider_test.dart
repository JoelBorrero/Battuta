import 'package:battuta/core/services/demo_mode_provider.dart';
import 'package:battuta/features/workspace/presentation/providers/workspace_usage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDemoModeNotifier extends DemoModeNotifier {
  _FakeDemoModeNotifier([this._initial = false]);
  final bool _initial;
  @override
  bool build() => _initial;
}

void main() {
  group('WorkspaceUsageProvider Tests', () {
    test('initializes with authentic local offline metrics when demo mode is off', () async {
      final container = ProviderContainer(
        overrides: [
          demoModeProvider.overrideWith(() => _FakeDemoModeNotifier(false)),
        ],
      );
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

    test('initializes with sample showcase metrics when demo mode is on', () async {
      final container = ProviderContainer(
        overrides: [
          demoModeProvider.overrideWith(() => _FakeDemoModeNotifier(true)),
        ],
      );
      addTearDown(container.dispose);

      final usage = await container.read(workspaceUsageProvider.future);
      expect(usage.workspaceName, equals('Grace Church Worship'));
      expect(usage.tier, equals('Pro'));
      expect(usage.geminiCreditsLimit, equals(5000));
      expect(usage.geminiCreditsUsed, equals(1450));
      expect(usage.geminiScansCount, equals(14));
      expect(usage.storageUsedBytes, equals(42 * 1024 * 1024));
      expect(usage.storageLimitBytes, equals(1024 * 1024 * 1024));
    });

    test('recordGeminiScan increments credits and scan count locally', () async {
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
    });

    test('recordStorageUpload increments storage bytes and file count', () async {
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
    });
  });
}
