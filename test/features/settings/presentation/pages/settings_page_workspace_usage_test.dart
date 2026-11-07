import 'package:battuta/features/settings/presentation/pages/settings_page.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject() {
    return const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(),
      ),
    );
  }

  testWidgets('SettingsPage renders Workspace Resources & Quota card with gauges', (tester) async {
    tester.view.physicalSize = const Size(1024, 2048);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Verify Workspace Resources section
    expect(find.byKey(const ValueKey('workspace_usage_card')), findsOneWidget);
    expect(find.text('ACTIVE WORKSPACE POOL'), findsOneWidget);
    expect(find.textContaining('Grace Church Worship'), findsOneWidget);

    // Verify Gauges
    expect(find.text('Gemini AI Credits'), findsOneWidget);
    expect(find.textContaining('Credits'), findsWidgets);
    expect(find.text('Cloud Storage'), findsOneWidget);
    expect(find.textContaining('MB'), findsWidgets);

    // Verify developer options / API configuration
    expect(find.text('API Configuration'), findsOneWidget);
    expect(find.byKey(const ValueKey('supabase_config_tile')), findsOneWidget);
    expect(find.byKey(const ValueKey('gemini_api_key_tile')), findsOneWidget);
  });
}
