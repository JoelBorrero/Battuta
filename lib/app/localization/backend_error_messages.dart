/// Localized messages for backend failures shown by the account and roster UI.
library;

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';

/// A user-facing message for [error] (a [Failure] or any thrown object).
String backendErrorMessage(AppLocalizations l10n, Object error) {
  if (error is! Failure) return l10n.backendErrorGeneric;
  return switch (error.errorCode) {
    BackendErrorCode.offline => l10n.backendErrorOffline,
    BackendErrorCode.notAdmin => l10n.backendErrorNotAdmin,
    BackendErrorCode.notMember ||
    BackendErrorCode.memberNotFound => l10n.backendErrorNotMember,
    BackendErrorCode.lastAdmin => l10n.backendErrorLastAdmin,
    BackendErrorCode.usernameTaken => l10n.usernameTakenError,
    BackendErrorCode.invalidUsername => l10n.usernameInvalidError,
    BackendErrorCode.invalidName => l10n.backendErrorInvalidName,
    BackendErrorCode.accountDeactivated => l10n.accountDeactivatedNotice,
    BackendErrorCode.memberDeactivated => l10n.backendErrorNotMember,
    BackendErrorCode.organizationArchived =>
      l10n.backendErrorOrganizationArchived,
    BackendErrorCode.inviteNotFound => l10n.backendErrorInviteNotFound,
    BackendErrorCode.inviteExpired => l10n.backendErrorInviteExpired,
    BackendErrorCode.inviteRevoked => l10n.backendErrorInviteRevoked,
    BackendErrorCode.inviteUsedUp => l10n.backendErrorInviteUsedUp,
    BackendErrorCode.alreadyMember => l10n.backendErrorAlreadyMember,
    BackendErrorCode.alreadyInvited => l10n.backendErrorAlreadyInvited,
    BackendErrorCode.userNotFound => l10n.backendErrorUserNotFound,
    BackendErrorCode.cannotInviteSelf => l10n.backendErrorCannotInviteSelf,
    BackendErrorCode.invitationNotPending =>
      l10n.backendErrorInvitationNotPending,
    BackendErrorCode.invitationNotFound => l10n.backendErrorInvitationNotFound,
    BackendErrorCode.bandNotInOrganization =>
      l10n.backendErrorBandNotInOrganization,
    BackendErrorCode.invalidExpiry => l10n.backendErrorInvalidExpiry,
    BackendErrorCode.invalidMaxUses => l10n.backendErrorInvalidMaxUses,
    BackendErrorCode.notSignedIn ||
    BackendErrorCode.notAuthenticated => l10n.backendErrorNotSignedIn,
    // Auth errors without a typed code (e.g. wrong password) carry GoTrue's
    // own readable message.
    null =>
      error is ServerFailure && error.message.isNotEmpty
          ? error.message
          : l10n.backendErrorGeneric,
    _ => l10n.backendErrorGeneric,
  };
}
