/// The invite token waiting for an account: a link opened (or pasted) while
/// signed out is kept here until sign-in, then the router joins with it.
library;

import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingInviteToken extends Notifier<String?> {
  @override
  String? build() {
    // A token waits for an account only: signing out or switching to another
    // account drops it (signing in from signed out keeps it).
    ref.listen(currentAccountIdProvider, (previous, next) {
      if (previous != null && previous != next) state = null;
    });
    return null;
  }

  void set(String token) => state = token;

  void clear() => state = null;
}

final pendingInviteTokenProvider =
    NotifierProvider<PendingInviteToken, String?>(PendingInviteToken.new);
