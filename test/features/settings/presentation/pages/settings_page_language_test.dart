import 'package:battuta/app/localization/locale_provider.dart';
import 'package:battuta/core/services/api_key_storage.dart';
import 'package:battuta/features/settings/presentation/pages/settings_page.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLocaleStorage extends ApiKeyStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);
}

void main() {
  Widget buildSubject({_FakeLocaleStorage? storage}) {
    final fakeStorage = storage ?? _FakeLocaleStorage();
    return ProviderScope(
      overrides: [
        localeStorageProvider.overrideWithValue(fakeStorage),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final locale = ref.watch(appLocaleProvider);
          return MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsPage(),
          );
        },
      ),
    );
  }

  testWidgets('renders language selector and switches live between English and Spanish', (tester) async {
    tester.view.physicalSize = const Size(1024, 2048);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final storage = _FakeLocaleStorage();
    await tester.pumpWidget(buildSubject(storage: storage));
    await tester.pumpAndSettle();

    // Verify initial render (English by default when system is English)
    expect(find.byKey(const ValueKey('language_tile')), findsOneWidget);
    expect(find.byKey(const ValueKey('language_segmented_btn')), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);

    // Tap Español
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();

    // Verify live update to Spanish
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Idioma de la aplicación'), findsOneWidget);
    expect(find.text('Sincronizar'), findsOneWidget);

    // Tap English
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // Verify live update back to English
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Sync Now'), findsOneWidget);
  });
}
