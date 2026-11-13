import 'package:battuta/core/platform/screen_wake_lock.dart';
import 'package:battuta/core/services/device_preferences_storage.dart';
import 'package:battuta/features/live_session/presentation/pages/live_session_page.dart';
import 'package:battuta/features/settings/presentation/providers/stage_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/device_prefs_fakes.dart';
import '../../../../support/memory_storage.dart';

void main() {
  late FakeScreenWakeLock lock;
  late ProviderContainer container;

  Widget host({required bool showLive}) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: showLive ? const LiveSessionPage() : const SizedBox(),
    ),
  );

  ProviderContainer makeContainer(MemoryStorage storage) {
    final c = ProviderContainer(
      overrides: [
        screenWakeLockProvider.overrideWithValue(lock),
        devicePreferencesStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    lock = FakeScreenWakeLock();
    container = makeContainer(MemoryStorage());
  });

  testWidgets('holds the wake lock while open and releases it on leave', (
    tester,
  ) async {
    await tester.pumpWidget(host(showLive: true));
    await tester.pumpAndSettle();
    expect(lock.held, isTrue);

    await tester.pumpWidget(host(showLive: false));
    await tester.pumpAndSettle();
    expect(lock.held, isFalse);
  });

  testWidgets('turning the preference off while open releases the lock', (
    tester,
  ) async {
    await tester.pumpWidget(host(showLive: true));
    await tester.pumpAndSettle();
    expect(lock.held, isTrue);

    await container
        .read(stagePreferencesProvider.notifier)
        .setKeepScreenAwake(false);
    await tester.pumpAndSettle();
    expect(lock.held, isFalse);

    await container
        .read(stagePreferencesProvider.notifier)
        .setKeepScreenAwake(true);
    await tester.pumpAndSettle();
    expect(lock.held, isTrue);
  });

  testWidgets('never takes the lock when the preference is off', (
    tester,
  ) async {
    container = makeContainer(
      MemoryStorage({'battuta_keep_screen_awake': 'false'}),
    );
    container.read(stagePreferencesProvider);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );

    await tester.pumpWidget(host(showLive: true));
    await tester.pumpAndSettle();
    expect(lock.held, isFalse);
    expect(lock.calls, isNot(contains('enable')));
  });
}
