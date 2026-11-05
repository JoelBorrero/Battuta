import 'package:battuta/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BattutaApp smoke test - initializes and renders Repertoire', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: BattutaApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the Repertoire screen is rendered as the initial tab.
    expect(find.text('Repertoire'), findsWidgets);
  });
}
