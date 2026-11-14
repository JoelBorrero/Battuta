/// Opens `battuta://join/<token>` invite links and `battuta-live://<host>:<port>`
/// Live session links while the app runs or starts.
library;

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:battuta/app/routes/app_router.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/organizations/domain/services/invite_link_parser.dart';
import 'package:battuta/features/sync/domain/models/live_join_address.dart';
import 'package:battuta/features/sync/presentation/providers/live_sync_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where deep links come from. Replaced in tests.
abstract interface class DeepLinkSource {
  /// Every link opened with the app, the one that started it included.
  Stream<Uri> get links;
}

class AppLinksSource implements DeepLinkSource {
  @override
  Stream<Uri> get links => AppLinks().uriLinkStream.handleError((Object _) {
    // Platforms without the plugin (tests, desktop) simply have no links.
  }, test: (e) => e is MissingPluginException || e is PlatformException);
}

final deepLinkSourceProvider = Provider<DeepLinkSource>(
  (ref) => AppLinksSource(),
);

/// Sends join links to the router and Live links to the Live tab. Anything
/// else (e.g. the Supabase auth callback) is ignored here.
final deepLinkHandlerProvider = Provider<void>((ref) {
  StreamSubscription<Uri>? subscription;
  try {
    subscription = ref.watch(deepLinkSourceProvider).links.listen((uri) {
      final live = LiveJoinAddress.fromUri(uri);
      if (live != null) {
        ref.read(appRouterProvider).go(AppRoutes.live);
        ref.read(liveSyncControllerProvider.notifier).handleLiveLink(live);
        return;
      }
      final token = inviteTokenFromUri(uri);
      if (token == null) return;
      ref.read(appRouterProvider).go(AppRoutes.join(token));
    }, onError: (_) {});
  } on MissingPluginException {
    // No deep link support on this platform.
  }
  ref.onDispose(() => subscription?.cancel());
});
