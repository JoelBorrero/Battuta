import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/core/services/api_key_storage.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/settings/presentation/pages/settings_page.dart';
import 'package:battuta/features/settings/presentation/providers/api_key_provider.dart';
import 'package:battuta/features/settings/presentation/widgets/api_key_dialog.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeApiKeyStorage extends ApiKeyStorage {
  FakeApiKeyStorage([this._initialKey]);
  String? _initialKey;

  @override
  Future<String?> read(String key) async => _initialKey;

  @override
  Future<void> write(String key, String value) async => _initialKey = value;

  @override
  Future<void> delete(String key) async => _initialKey = null;

  @override
  Future<bool> containsKey(String key) async => _initialKey != null;
}

void main() {
  testWidgets(
    'SettingsPage renders theme options and sections without overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeStorage = FakeApiKeyStorage();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiKeyStorageProvider.overrideWithValue(fakeStorage)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsPage(),
          ),
        ),
      );

      // Allow async providers to settle
      await tester.pumpAndSettle();

      // Verify sections and items
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);

      // Verify theme options
      expect(find.text('Stage'), findsOneWidget);
      expect(find.text('Rehearsal'), findsOneWidget);
      expect(find.text('System'), findsNWidgets(2)); // theme + language value

      // Verify Language section
      expect(find.byKey(const ValueKey('language_tile')), findsOneWidget);

      // Verify the admin rows
      await tester.scrollUntilVisible(find.text('Gemini API Key'), 100);
      expect(find.text('Gemini API Key'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Tapping Gemini API Key opens ApiKeyDialog', (
    WidgetTester tester,
  ) async {
    final fakeStorage = FakeApiKeyStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiKeyStorageProvider.overrideWithValue(fakeStorage)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap the Gemini API Key tile
    await tester.scrollUntilVisible(find.text('Gemini API Key'), 100);
    await tester.tap(find.text('Gemini API Key'));
    await tester.pumpAndSettle();

    // Verify dialog opened
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Enter new API Key'), findsOneWidget);
    expect(find.text('Save Key'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Tapping theme segmented button updates selection', (
    WidgetTester tester,
  ) async {
    final fakeStorage = FakeApiKeyStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiKeyStorageProvider.overrideWithValue(fakeStorage)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap 'Stage' (dark)
    await tester.tap(find.text('Stage'));
    await tester.pumpAndSettle();

    final control = tester.widget<StageSegmentedControl<ThemeMode>>(
      find.byType(StageSegmentedControl<ThemeMode>),
    );
    expect(control.selected, ThemeMode.dark);

    await tester.tap(find.text('Rehearsal'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<StageSegmentedControl<ThemeMode>>(
            find.byType(StageSegmentedControl<ThemeMode>),
          )
          .selected,
      ThemeMode.light,
    );
  });

  testWidgets('Non-admin user cannot see or access Gemini API Key section', (
    WidgetTester tester,
  ) async {
    final fakeStorage = FakeApiKeyStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiKeyStorageProvider.overrideWithValue(fakeStorage),
          isCurrentUserAdminProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Appearance and other non-admin sections exist
    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);

    // Verify API Configuration section and Gemini API Key tile are NOT rendered
    expect(find.byKey(const ValueKey('gemini_api_key_tile')), findsNothing);
    expect(find.byKey(const ValueKey('omr_debug_logs_tile')), findsNothing);
  });

  testWidgets(
    'ApiKeyDialog displays Access Restricted when accessed by non-admin',
    (WidgetTester tester) async {
      final fakeStorage = FakeApiKeyStorage();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiKeyStorageProvider.overrideWithValue(fakeStorage),
            isCurrentUserAdminProvider.overrideWithValue(false),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ApiKeyDialog.show(context),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap to open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify Access Restricted dialog
      expect(find.text('Access Restricted'), findsOneWidget);
      expect(
        find.text(
          'Gemini API key configuration is restricted to church administrators only.',
        ),
        findsOneWidget,
      );
      expect(find.text('Enter new API Key'), findsNothing);

      // Tap OK to close
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}
