/// Battuta — finding and announcing Live sessions on the local network.
library;

import 'dart:convert';

import 'package:battuta/features/sync/domain/models/live_session.dart';

/// Announces a hosted session and lists the ones nearby (mDNS / Bonjour in
/// production, a fake in widget tests). Implementations never throw: a
/// platform without support simply finds nothing.
abstract interface class LiveSessionDiscovery {
  /// Sessions currently on the network; emits a new list whenever one
  /// appears or vanishes. Browsing runs while the stream is listened to.
  /// A session this device advertises itself is not included.
  Stream<List<LiveSession>> browse();

  /// Starts announcing a session on [port]. Replaces a previous announcement.
  Future<void> advertise({
    required String sessionName,
    required String directorName,
    required int port,
  });

  /// Stops announcing.
  Future<void> stopAdvertising();
}

/// Longest session name the host field accepts.
const int liveSessionNameMaxLength = 40;

/// mDNS service names are limited to 63 UTF-8 bytes.
const int liveServiceNameMaxBytes = 63;

/// Builds the advertised service name `session · device` within
/// [maxBytes] UTF-8 bytes. The session name is cut first (with an ellipsis)
/// so it stays readable; a very long device name is cut too, and when no
/// room is left for it the session name stands alone.
String buildLiveServiceName(
  String sessionName,
  String deviceName, {
  int maxBytes = liveServiceNameMaxBytes,
}) {
  const separator = ' · ';
  final sepBytes = utf8.encode(separator).length;
  final device = _truncateUtf8(deviceName.trim(), 24);
  final session = sessionName.trim();
  final deviceBytes = utf8.encode(device).length;

  if (device.isNotEmpty) {
    final room = maxBytes - sepBytes - deviceBytes;
    // Keep at least a short readable session name next to the device.
    if (room >= 8) {
      return '${_truncateUtf8(session, room, ellipsis: true)}$separator$device';
    }
  }
  return _truncateUtf8(session, maxBytes, ellipsis: true);
}

/// Cuts [text] to at most [maxBytes] UTF-8 bytes on a character boundary.
String _truncateUtf8(String text, int maxBytes, {bool ellipsis = false}) {
  if (utf8.encode(text).length <= maxBytes) return text;
  const dots = '…';
  final budget = ellipsis ? maxBytes - utf8.encode(dots).length : maxBytes;
  final out = StringBuffer();
  var used = 0;
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    final size = utf8.encode(char).length;
    if (used + size > budget) break;
    out.write(char);
    used += size;
  }
  final cut = out.toString().trimRight();
  return ellipsis ? '$cut$dots' : cut;
}
