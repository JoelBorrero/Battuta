/// The router redirect rules, kept pure so they can be unit tested.
library;

import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/auth/presentation/providers/app_entry_provider.dart';

/// Returns where [location] must redirect to, or `null` to stay.
///
/// * loading (`entry == null`): stay.
/// * [AppEntry.firstLaunch]: only the account entry pages are reachable.
/// * [AppEntry.offline]: the app, plus the sign-in pages (opened from
///   Settings or the Team tab); the welcome page again when [hasNotice]
///   (e.g. the account was deactivated); the account pages stay reachable.
///   The profile page needs an account: it leads to the sign-in page.
/// * [AppEntry.signedIn]: the app; entry pages lead back into it.
///
/// Invite links: a join location (`/join/<token>`) needs an account, so
/// signed-out users are sent to the sign-in flow (the caller keeps the token
/// as [pendingInviteToken]); once signed in, a pending token leads to its
/// join page, whichever page the user was on.
String? resolveAppRedirect({
  required AppEntry? entry,
  required bool hasNotice,
  required String location,
  String? pendingInviteToken,
}) {
  if (entry == null) return null;
  final inEntryFlow = AppRoutes.isAccountEntry(location);
  final isJoin = AppRoutes.joinTokenOf(location) != null;
  switch (entry) {
    case AppEntry.firstLaunch:
      return inEntryFlow ? null : AppRoutes.welcome;
    case AppEntry.offline:
      if (hasNotice) return inEntryFlow ? null : AppRoutes.welcome;
      if (isJoin || location == AppRoutes.profile) return AppRoutes.signIn;
      return location == AppRoutes.welcome ? AppRoutes.initial : null;
    case AppEntry.signedIn:
      if (pendingInviteToken != null && !isJoin) {
        return AppRoutes.join(pendingInviteToken);
      }
      return inEntryFlow ? AppRoutes.initial : null;
  }
}
