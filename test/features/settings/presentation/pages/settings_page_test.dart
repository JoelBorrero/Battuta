import 'package:battuta/core/services/api_key_storage.dart';
import 'package:battuta/features/settings/presentation/pages/settings_page.dart';
import 'package:battuta/features/settings/presentation/providers/api_key_provider.dart';
import 'package:battuta/features/settings/presentation/widgets/api_key_dialog.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
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
          child: const MaterialApp(home: SettingsPage()),
        ),
      );

      // Allow async providers to settle
      await tester.pumpAndSettle();

      // Verify sections and items
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Choose light, dark, or system mode'), findsOneWidget);

      // Verify SegmentedButton options
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);

      // Verify Language section
      expect(find.byKey(const ValueKey('language_tile')), findsOneWidget);
      expect(find.byKey(const ValueKey('language_segmented_btn')), findsOneWidget);

      // Verify API Configuration section
      await tester.scrollUntilVisible(find.text('Gemini API Key'), 100);
      expect(find.text('API Configuration'), findsOneWidget);
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
        child: const MaterialApp(home: SettingsPage()),
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
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.pumpAndSettle();

    // Tap 'Dark'
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final segmentedBtn = tester.widget<SegmentedButton<ThemeMode>>(
      find.byType(SegmentedButton<ThemeMode>),
    );
    expect(segmentedBtn.selected, equals({ThemeMode.dark}));
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
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Appearance and other non-admin sections exist
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);

    // Verify API Configuration section and Gemini API Key tile are NOT rendered
    expect(find.text('API Configuration'), findsNothing);
    expect(find.byKey(const ValueKey('gemini_api_key_tile')), findsNothing);
    expect(find.byKey(const ValueKey('omr_debug_logs_tile')), findsNothing);
  });

  testWidgets('ApiKeyDialog displays Access Restricted when accessed by non-admin', (
    WidgetTester tester,
  ) async {
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
      find.text('Gemini API key configuration is restricted to church administrators only.'),
      findsOneWidget,
    );
    expect(find.text('Enter new API Key'), findsNothing);

    // Tap OK to close
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
