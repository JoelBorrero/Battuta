import 'dart:async';

import 'package:battuta/features/sync/data/lan_address_resolver.dart';
import 'package:battuta/features/sync/domain/models/live_session.dart';
import 'package:battuta/features/sync/domain/services/live_session_discovery.dart';

/// [LiveSessionDiscovery] without mDNS: tests push the sessions they want.
class FakeLiveSessionDiscovery implements LiveSessionDiscovery {
  final _controller = StreamController<List<LiveSession>>.broadcast();

  /// Whether someone is listening to [browse].
  bool get browsing => _controller.hasListener;

  /// What the last [advertise] call announced; `null` when not advertising.
  ({String sessionName, String directorName, int port})? advertised;

  void emit(List<LiveSession> sessions) => _controller.add(sessions);

  @override
  Stream<List<LiveSession>> browse() => _controller.stream;

  @override
  Future<void> advertise({
    required String sessionName,
    required String directorName,
    required int port,
  }) async {
    advertised = (
      sessionName: sessionName,
      directorName: directorName,
      port: port,
    );
  }

  @override
  Future<void> stopAdvertising() async {
    advertised = null;
  }
}

/// [LanAddressResolver] returning a fixed address (or none).
class FakeLanAddressResolver implements LanAddressResolver {
  FakeLanAddressResolver([this.address = '192.168.1.20']);

  String? address;

  @override
  Future<String?> resolve() async => address;
}
