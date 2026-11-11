import 'package:battuta/features/auth/presentation/providers/app_entry_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/memory_storage.dart';

void main() {
  testWidgets('BattutaApp smoke test - initializes and renders Repertoire', (
    WidgetTester tester,
  ) async {
    // The user chose "Continue offline" on a previous run.
    final harness = AppHarness(
      entryStorage: MemoryStorage({
        AppEntryStorageKeys.continueOffline: 'true',
      }),
    );
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.build());
    await tester.pumpAndSettle();

    // Verify that the Repertoire screen is rendered as the initial tab.
    expect(find.text('Repertoire'), findsWidgets);
  });
}
