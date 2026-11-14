/// Battuta — which of this device's addresses to show to the band.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';

/// One network interface and its IPv4 addresses.
@immutable
class LanInterfaceInfo {
  const LanInterfaceInfo(this.name, this.ipv4);

  final String name;
  final List<String> ipv4;
}

/// Finds the address other devices on this network can reach.
abstract interface class LanAddressResolver {
  /// The private IPv4 to share, or `null` when there is no usable network.
  Future<String?> resolve();
}

/// Picks the address to share from [interfaces]: private IPv4 only (10/8,
/// 172.16/12, 192.168/16, which also covers phone hotspots), never loopback,
/// link-local (169.254) or cellular / VPN interfaces. Wi-Fi first, then
/// hotspot interfaces, then anything else (e.g. Ethernet).
String? pickLanAddress(List<LanInterfaceInfo> interfaces) {
  String? best;
  var bestRank = 99;
  for (final iface in interfaces) {
    final rank = _rank(iface.name.toLowerCase());
    if (rank == null) continue;
    for (final address in iface.ipv4) {
      if (!isPrivateLanIPv4(address)) continue;
      if (rank < bestRank) {
        best = address;
        bestRank = rank;
      }
    }
  }
  return best;
}

/// Whether [address] is a private, routable-on-LAN IPv4.
bool isPrivateLanIPv4(String address) {
  final parts = address.split('.');
  if (parts.length != 4) return false;
  final o = parts.map(int.tryParse).toList();
  if (o.any((v) => v == null || v < 0 || v > 255)) return false;
  final a = o[0]!;
  final b = o[1]!;
  if (a == 10) return true;
  if (a == 172 && b >= 16 && b <= 31) return true;
  if (a == 192 && b == 168) return true;
  return false;
}

/// Lower is better; `null` skips the interface.
int? _rank(String name) {
  const skipped = [
    'lo',
    'pdp_ip',
    'rmnet',
    'ccmni',
    'wwan',
    'utun',
    'tun',
    'tap',
    'ppp',
    'ipsec',
    'awdl',
    'llw',
    'dummy',
    'docker',
    'veth',
  ];
  for (final prefix in skipped) {
    if (name == prefix || name.startsWith(prefix)) return null;
  }
  if (name.startsWith('wlan') || name.startsWith('wlp') || name == 'en0') {
    return 0;
  }
  if (name.startsWith('ap') ||
      name.startsWith('swlan') ||
      name.startsWith('softap') ||
      name.startsWith('bridge')) {
    return 1;
  }
  return 2;
}

/// [LanAddressResolver] backed by `NetworkInterface.list`.
class SystemLanAddressResolver implements LanAddressResolver {
  const SystemLanAddressResolver();

  @override
  Future<String?> resolve() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      return pickLanAddress([
        for (final i in interfaces)
          LanInterfaceInfo(i.name, [for (final a in i.addresses) a.address]),
      ]);
    } catch (_) {
      return null;
    }
  }
}
