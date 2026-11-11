/// Seams the invite UI uses for platform features, so tests can replace them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the system share sheet with [text]. [origin] anchors the popover on
/// iPad.
typedef InviteSharer = Future<void> Function(String text, {Rect? origin});

final inviteSharerProvider = Provider<InviteSharer>(
  (ref) => (text, {origin}) async {
    await SharePlus.instance.share(
      ShareParams(text: text, sharePositionOrigin: origin),
    );
  },
);
