/// Battuta — [LiveSessionDiscovery] over mDNS / Bonjour (package `bonsoir`).
library;

import 'dart:async';
import 'dart:math';

import 'package:battuta/features/sync/domain/models/live_session.dart';
import 'package:battuta/features/sync/domain/services/live_session_discovery.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';

class BonsoirSessionDiscovery implements LiveSessionDiscovery {
  BonsoirSessionDiscovery() : _ownId = _randomId();

  /// Sent in the TXT record so this device can hide its own session.
  final String _ownId;
  BonsoirBroadcast? _broadcast;
  int _advertiseGeneration = 0;

  static String _randomId() {
    final r = Random.secure();
    return List.generate(8, (_) => r.nextInt(16).toRadixString(16)).join();
  }

  @override
  Stream<List<LiveSession>> browse() {
    late final StreamController<List<LiveSession>> controller;
    BonsoirDiscovery? discovery;
    StreamSubscription<BonsoirDiscoveryEvent>? sub;
    // Set when the listener leaves; a start still in flight then undoes
    // itself instead of leaving browsing (and the multicast lock) running.
    var cancelled = false;
    Future<void>? starting;
    final found = <String, LiveSession>{};

    void emit() {
      if (!controller.isClosed) {
        controller.add(List.unmodifiable(found.values));
      }
    }

    Future<void> start() async {
      try {
        final d = BonsoirDiscovery(type: liveServiceType);
        discovery = d;
        await d.initialize();
        if (cancelled) return;
        sub = d.eventStream?.listen((event) {
          final service = event.service;
          switch (event) {
            case BonsoirDiscoveryServiceFoundEvent():
              // Addresses arrive with the resolved event.
              service?.resolve(d.serviceResolver);
            case BonsoirDiscoveryServiceResolvedEvent() ||
                BonsoirDiscoveryServiceUpdatedEvent():
              final session = service == null ? null : _toSession(service);
              if (session != null && service != null) {
                found[service.name] = session;
                emit();
              }
            case BonsoirDiscoveryServiceLostEvent():
              if (service != null && found.remove(service.name) != null) {
                emit();
              }
            default:
              break;
          }
        }, onError: (Object _) {});
        if (cancelled) return;
        await d.start();
      } catch (error) {
        debugPrint('Live discovery unavailable: $error');
      }
    }

    Future<void> stop() async {
      cancelled = true;
      // Let a pending start finish (it returns early once cancelled).
      try {
        await starting;
      } catch (_) {}
      await sub?.cancel();
      sub = null;
      try {
        await discovery?.stop();
      } catch (_) {}
      discovery = null;
      found.clear();
    }

    controller = StreamController<List<LiveSession>>(
      onListen: () {
        controller.add(const []);
        starting = start();
      },
      onCancel: stop,
    );
    return controller.stream;
  }

  LiveSession? _toSession(BonsoirService service) {
    final attrs = service.attributes;
    if (attrs['id'] == _ownId) return null;
    final host = service.hostAddresses.firstWhere(
      _isIPv4,
      orElse: () => service.hostname ?? '',
    );
    if (host.isEmpty || service.port <= 0) return null;
    return LiveSession(
      id: service.name,
      name: attrs['session'] ?? service.name,
      directorName: attrs['director'] ?? '',
      host: host,
      port: service.port,
      protocolVersion: int.tryParse(attrs['v'] ?? '') ?? liveProtocolVersion,
    );
  }

  static bool _isIPv4(String s) => RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(s);

  @override
  Future<void> advertise({
    required String sessionName,
    required String directorName,
    required int port,
  }) async {
    await stopAdvertising();
    final generation = ++_advertiseGeneration;
    try {
      final broadcast = BonsoirBroadcast(
        service: BonsoirService(
          name: buildLiveServiceName(sessionName, directorName),
          type: liveServiceType,
          port: port,
          attributes: {
            'session': sessionName,
            'director': directorName,
            'v': '$liveProtocolVersion',
            'id': _ownId,
          },
        ),
      );
      _broadcast = broadcast;
      await broadcast.initialize();
      // Stopped while initializing: do not start announcing a dead session.
      if (generation != _advertiseGeneration) return;
      await broadcast.start();
      if (generation != _advertiseGeneration) {
        await broadcast.stop();
      }
    } catch (error) {
      debugPrint('Live advertising unavailable: $error');
    }
  }

  @override
  Future<void> stopAdvertising() async {
    _advertiseGeneration++;
    final broadcast = _broadcast;
    _broadcast = null;
    if (broadcast == null) return;
    try {
      await broadcast.stop();
    } catch (_) {}
  }
}
