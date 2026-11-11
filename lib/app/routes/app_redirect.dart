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
/// * [AppEntry.signedIn]: the app; entry pages lead back into it.
String? resolveAppRedirect({
  required AppEntry? entry,
  required bool hasNotice,
  required String location,
}) {
  if (entry == null) return null;
  final inEntryFlow = AppRoutes.isAccountEntry(location);
  switch (entry) {
    case AppEntry.firstLaunch:
      return inEntryFlow ? null : AppRoutes.welcome;
    case AppEntry.offline:
      if (hasNotice) return inEntryFlow ? null : AppRoutes.welcome;
      return location == AppRoutes.welcome ? AppRoutes.initial : null;
    case AppEntry.signedIn:
      return inEntryFlow ? AppRoutes.initial : null;
  }
}
