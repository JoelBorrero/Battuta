import 'package:battuta/core/services/api_key_storage.dart';
import 'package:battuta/core/services/supabase_client_manager.dart';
import 'package:battuta/core/services/supabase_config_service.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/settings/presentation/widgets/supabase_config_dialog.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _MemoryStorage extends ApiKeyStorage {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);
}

class _FakeClientManager extends SupabaseClientManager {
  _FakeClientManager(SupabaseConfigService config)
    : super(configService: config);

  @override
  Future<bool> initialize({String? customUrl, String? customAnonKey}) async =>
      true;
}

const _remoteUrl = 'https://abc.supabase.co';
const _localUrl = 'http://192.168.1.20:54321';
const _env = {
  'SUPABASE_URL': _remoteUrl,
  'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_remote',
  'SUPABASE_LOCAL_URL': _localUrl,
  'SUPABASE_LOCAL_PUBLISHABLE_KEY': 'sb_publishable_local',
};

void main() {
  late _MemoryStorage storage;
  late List<Uri> requested;
  late bool serverUp;

  setUp(() {
    storage = _MemoryStorage();
    requested = [];
    serverUp = true;
    SupabaseClientManager.resetForTesting();
  });

  tearDown(SupabaseClientManager.resetForTesting);

  Widget buildApp({Map<String, String> env = _env}) {
    final config = SupabaseConfigService(
      storage: storage,
      env: env,
      httpClient: MockClient((request) async {
        requested.add(request.url);
        return http.Response('{}', serverUp ? 200 : 503);
      }),
    );
    return ProviderScope(
      overrides: [
        supabaseConfigServiceProvider.overrideWithValue(config),
        supabaseClientManagerProvider.overrideWithValue(
          _FakeClientManager(config),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => SupabaseConfigDialog.show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  String fieldText(WidgetTester tester, String key) =>
      tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;

  testWidgets('fields have leading icons', (tester) async {
    await tester.pumpWidget(buildApp());
    await open(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('supabase_config_url_field')),
        matching: find.byIcon(Icons.link),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('supabase_config_key_field')),
        matching: find.byIcon(Icons.key_outlined),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Remote and Local presets fill the fields', (tester) async {
    await tester.pumpWidget(buildApp());
    await open(tester);

    final remote = find.byKey(const ValueKey('supabase_preset_remote'));
    final local = find.byKey(const ValueKey('supabase_preset_local'));
    expect(tester.widget<ChoiceChip>(remote).selected, isTrue);

    await tester.tap(local);
    await tester.pump();
    expect(fieldText(tester, 'supabase_config_url_field'), _localUrl);
    expect(
      fieldText(tester, 'supabase_config_key_field'),
      'sb_publishable_local',
    );
    expect(tester.widget<ChoiceChip>(local).selected, isTrue);
    expect(tester.widget<ChoiceChip>(remote).selected, isFalse);
  });

  testWidgets('presets are hidden when .env names only one server', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        env: const {'SUPABASE_URL': _remoteUrl, 'SUPABASE_ANON_KEY': 'anon'},
      ),
    );
    await open(tester);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('an unreachable server shows an error and is not saved', (
    tester,
  ) async {
    serverUp = false;
    await tester.pumpWidget(buildApp());
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('supabase_preset_local')));
    await tester.tap(find.byKey(const ValueKey('supabase_config_save_btn')));
    await tester.pumpAndSettle();

    expect(requested.single.toString(), '$_localUrl/auth/v1/health');
    final error = tester.widget<Text>(
      find.byKey(const ValueKey('supabase_config_error')),
    );
    expect(error.data, contains('192.168.1.20:54321'));
    expect(storage.values, isEmpty);
    expect(find.byType(SupabaseConfigDialog), findsOneWidget);
  });

  testWidgets('switching servers saves and asks for a restart', (tester) async {
    SupabaseClientManager.setActiveUrlForTesting(_remoteUrl);
    await tester.pumpWidget(buildApp());
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('supabase_preset_local')));
    await tester.tap(find.byKey(const ValueKey('supabase_config_save_btn')));
    await tester.pumpAndSettle();

    expect(find.byType(SupabaseConfigDialog), findsNothing);
    expect(storage.values[SupabaseConfigKeys.customUrl], _localUrl);
    expect(
      find.byKey(const ValueKey('supabase_restart_snack')),
      findsOneWidget,
    );
  });

  testWidgets('saving the running server says it is connected', (tester) async {
    SupabaseClientManager.setActiveUrlForTesting(_remoteUrl);
    await tester.pumpWidget(buildApp());
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('supabase_config_save_btn')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('supabase_connected_snack')),
      findsOneWidget,
    );
    expect(find.text('Connected to abc.supabase.co'), findsOneWidget);
  });

  testWidgets('no overflow at 320 px with the presets', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(buildApp());
    await open(tester);
    expect(tester.takeException(), isNull);
  });
}
