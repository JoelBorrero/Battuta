import 'dart:io';

import 'package:battuta/features/sync/presentation/providers/live_sync_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/live_fakes.dart';

void main() {
  test('two concurrent startHosting calls share one server', () async {
    final discovery = FakeLiveSessionDiscovery();
    final container = ProviderContainer(
      overrides: [
        liveSessionDiscoveryProvider.overrideWithValue(discovery),
        lanAddressResolverProvider.overrideWithValue(FakeLanAddressResolver()),
        liveDeviceNameProvider.overrideWithValue('Test iPad'),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(liveSyncControllerProvider.notifier);

    final results = await Future.wait([
      notifier.startHosting(sessionName: 'Sunday'),
      notifier.startHosting(sessionName: 'Sunday'),
    ]);

    expect(results, [true, true]);
    final state = container.read(liveSyncControllerProvider);
    expect(state.isConnected, isTrue);
    // The advertised port is the one the single server is bound to.
    expect(discovery.advertised?.port, state.serverPort);
    expect(state.joinAddress?.port, state.serverPort);

    await notifier.disconnect();
    expect(discovery.advertised, isNull);
    final again = await ServerSocket.bind(
      InternetAddress.anyIPv4,
      state.serverPort!,
    );
    await again.close();
  });
}
