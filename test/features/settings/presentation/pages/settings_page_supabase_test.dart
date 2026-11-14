import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/database/database_providers.dart';
import 'package:battuta/core/services/api_key_storage.dart';
import 'package:battuta/core/services/supabase_config_service.dart';
import 'package:battuta/features/auth/presentation/pages/create_account_page.dart';
import 'package:battuta/features/auth/presentation/pages/sign_in_page.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/settings/presentation/pages/settings_page.dart';
import 'package:battuta/features/settings/presentation/providers/api_key_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeApiKeyStorage extends ApiKeyStorage {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}

  @override
  Future<bool> containsKey(String key) async => false;
}

class _FakeSupabaseConfigService extends SupabaseConfigService {
  _FakeSupabaseConfigService() : super(storage: _FakeApiKeyStorage());
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        apiKeyStorageProvider.overrideWithValue(_FakeApiKeyStorage()),
        supabaseConfigServiceProvider.overrideWithValue(
          _FakeSupabaseConfigService(),
        ),
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(),
      ),
    );
  }

  testWidgets(
    'SettingsPage renders Cloud Synchronization section and handles Sync Now tap',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Cloud Synchronization section
      expect(find.text('ACCOUNT AND SYNC'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(
        find.text('Not signed in — Offline SQLite active'),
        findsOneWidget,
      );
      expect(find.text('Server'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('supabase_sync_status_tile')),
        findsOneWidget,
      );
      expect(find.text('Ready to sync'), findsOneWidget);
      expect(find.byKey(const ValueKey('sync_now_btn')), findsOneWidget);

      // Tap Sync Now
      await tester.tap(find.byKey(const ValueKey('sync_now_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should handle offline state gracefully without exceptions
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Tapping the signed-out account row opens the sign-in page', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SettingsPage()),
        GoRoute(path: AppRoutes.signIn, builder: (_, _) => const SignInPage()),
        GoRoute(
          path: AppRoutes.createAccount,
          builder: (_, _) => const CreateAccountPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiKeyStorageProvider.overrideWithValue(_FakeApiKeyStorage()),
          supabaseConfigServiceProvider.overrideWithValue(
            _FakeSupabaseConfigService(),
          ),
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('supabase_account_tile')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth_email_field')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth_password_field')), findsOneWidget);
  });

  testWidgets('Tapping Supabase Connection opens SupabaseConfigDialog', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Scroll to make sure tile is visible
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pump();

    // Tap Supabase Connection tile
    await tester.tap(find.byKey(const ValueKey('supabase_config_tile')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // SupabaseConfigDialog should be open
    expect(find.text('Supabase Project Setup'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('supabase_config_url_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('supabase_config_key_field')),
      findsOneWidget,
    );

    // Dismiss dialog
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Supabase Project Setup'), findsNothing);
  });
}
