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

  testWidgets('SettingsPage renders the Workspace Resources & Quota card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 2048);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workspace_usage_card')), findsOneWidget);
    expect(find.text('ACTIVE WORKSPACE POOL'), findsOneWidget);
    expect(find.textContaining('Local Workspace'), findsOneWidget);
    expect(find.text('Gemini AI Credits'), findsOneWidget);
    expect(find.text('Cloud Storage'), findsOneWidget);

    // Developer options remain, and there is no demo mode toggle anymore.
    expect(find.text('API Configuration'), findsOneWidget);
    expect(find.byKey(const ValueKey('supabase_config_tile')), findsOneWidget);
    expect(find.byKey(const ValueKey('gemini_api_key_tile')), findsOneWidget);
    expect(find.byKey(const ValueKey('demo_mode_switch')), findsNothing);
  });
}
