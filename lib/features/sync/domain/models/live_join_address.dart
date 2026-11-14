/// Battuta — where a follower connects to join a Live session.
library;

import 'package:flutter/foundation.dart';

/// The URL scheme of Live join links (`battuta-live://192.168.1.20:47320`).
const String liveJoinLinkScheme = 'battuta-live';

/// The port a director tries first, so "just the IP" works.
const int liveDefaultPort = 47320;

/// Why a typed or scanned address was rejected.
enum LiveJoinAddressError { empty, invalidHost, invalidPort, invalidLink }

/// Thrown by [LiveJoinAddress.parse]. [message] is an English description for
/// logs; the UI maps [reason] to a localized string.
class LiveJoinAddressException implements FormatException {
  const LiveJoinAddressException(this.reason, this.message);

  final LiveJoinAddressError reason;

  @override
  final String message;

  @override
  int? get offset => null;

  @override
  dynamic get source => null;

  @override
  String toString() => 'LiveJoinAddressException: $message';
}

/// A director's host and port.
@immutable
class LiveJoinAddress {
  const LiveJoinAddress({required this.host, this.port = liveDefaultPort});

  final String host;
  final int port;

  static final RegExp _ipv4 = RegExp(
    r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
  );
  static final RegExp _hostname = RegExp(
    r'^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$',
  );

  /// Parses `192.168.1.20:47320`, `192.168.1.20` (default port),
  /// `ipad.local` or a `battuta-live://` link. Throws
  /// [LiveJoinAddressException] for anything else.
  factory LiveJoinAddress.parse(String? input) {
    final text = (input ?? '').trim();
    if (text.isEmpty) {
      throw const LiveJoinAddressException(
        LiveJoinAddressError.empty,
        'Enter the address shown on the host device.',
      );
    }

    String hostPart;
    String? portPart;
    if (text.contains('://')) {
      final uri = Uri.tryParse(text);
      if (uri == null || uri.scheme.toLowerCase() != liveJoinLinkScheme) {
        throw const LiveJoinAddressException(
          LiveJoinAddressError.invalidLink,
          'This is not a Battuta Live link.',
        );
      }
      hostPart = uri.host;
      portPart = uri.hasPort ? uri.port.toString() : null;
    } else {
      final colon = text.lastIndexOf(':');
      if (colon == -1) {
        hostPart = text;
      } else {
        hostPart = text.substring(0, colon);
        portPart = text.substring(colon + 1);
      }
    }

    if (!_validHost(hostPart)) {
      throw const LiveJoinAddressException(
        LiveJoinAddressError.invalidHost,
        'The address is not valid. Use something like 192.168.1.20.',
      );
    }

    var port = liveDefaultPort;
    if (portPart != null) {
      final parsed = int.tryParse(portPart);
      if (parsed == null || parsed < 1 || parsed > 65535) {
        throw const LiveJoinAddressException(
          LiveJoinAddressError.invalidPort,
          'The port must be a number between 1 and 65535.',
        );
      }
      port = parsed;
    }
    return LiveJoinAddress(host: hostPart, port: port);
  }

  /// Like [parse] but returns `null` instead of throwing.
  static LiveJoinAddress? tryParse(String? input) {
    try {
      return LiveJoinAddress.parse(input);
    } on LiveJoinAddressException {
      return null;
    }
  }

  /// The address inside a `battuta-live://` [uri], or `null` if [uri] is not
  /// a valid Live link.
  static LiveJoinAddress? fromUri(Uri uri) {
    if (uri.scheme.toLowerCase() != liveJoinLinkScheme) return null;
    return tryParse(uri.toString());
  }

  static bool _validHost(String host) {
    final m = _ipv4.firstMatch(host);
    if (m != null) {
      return [for (var i = 1; i <= 4; i++) int.parse(m.group(i)!)]
          .every((o) => o <= 255);
    }
    // A name needs a dot (`joels-ipad.local`); bare words are typos.
    return host.contains('.') &&
        _hostname.hasMatch(host) &&
        !RegExp(r'^[\d.]+$').hasMatch(host);
  }

  /// `192.168.1.20:47320`.
  String get display => '$host:$port';

  /// `battuta-live://192.168.1.20:47320`, what the QR code carries.
  String get link => '$liveJoinLinkScheme://$host:$port';

  @override
  bool operator ==(Object other) =>
      other is LiveJoinAddress && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);

  @override
  String toString() => display;
}
