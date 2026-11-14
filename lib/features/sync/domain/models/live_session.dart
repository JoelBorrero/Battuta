/// Battuta — a Live session found on the local network.
library;

import 'package:flutter/foundation.dart';

/// Version of the Live wire protocol advertised over mDNS.
const int liveProtocolVersion = 1;

/// mDNS service type of a hosted Live session.
const String liveServiceType = '_battuta-live._tcp';

@immutable
class LiveSession {
  const LiveSession({
    required this.id,
    required this.name,
    required this.directorName,
    required this.host,
    required this.port,
    this.protocolVersion = liveProtocolVersion,
  });

  /// Stable identity while the session stays on the network.
  final String id;

  /// What the director called the session ("Sunday service").
  final String name;

  /// The director's device ("Joel's iPad").
  final String directorName;
  final String host;
  final int port;
  final int protocolVersion;

  /// Sessions from a newer, incompatible protocol are shown but not joinable.
  bool get isCompatible => protocolVersion <= liveProtocolVersion;

  @override
  bool operator ==(Object other) =>
      other is LiveSession &&
      other.id == id &&
      other.name == name &&
      other.directorName == directorName &&
      other.host == host &&
      other.port == port &&
      other.protocolVersion == protocolVersion;

  @override
  int get hashCode =>
      Object.hash(id, name, directorName, host, port, protocolVersion);
}
