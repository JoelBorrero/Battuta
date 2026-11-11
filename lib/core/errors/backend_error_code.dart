/// Typed error codes raised by the Supabase backend.
///
/// The names mirror the machine readable messages documented in
/// `supabase/README.md` ("Error codes"). [BackendErrorCode.failure] turns a
/// code into the matching [Failure] subclass:
///
/// * permission problems (`42501`, `28000`) -> [PermissionFailure]
/// * invalid input (`22023`) -> [ValidationFailure]
/// * everything else (including [offline]) -> [ServerFailure]
library;

import 'package:battuta/core/errors/failures.dart';

/// The family a [BackendErrorCode] belongs to.
enum BackendErrorKind { permission, input, other }

enum BackendErrorCode {
  // 28000
  notAuthenticated('not_authenticated', BackendErrorKind.permission),

  // 42501
  notAdmin('not_admin', BackendErrorKind.permission),
  notMember('not_member', BackendErrorKind.permission),
  notAssignee('not_assignee', BackendErrorKind.permission),
  notVersionOwner('not_version_owner', BackendErrorKind.permission),
  permissionDenied('permission_denied', BackendErrorKind.permission),

  // 22023
  invalidName('invalid_name', BackendErrorKind.input),
  invalidUsername('invalid_username', BackendErrorKind.input),
  invalidRole('invalid_role', BackendErrorKind.input),
  invalidExpiry('invalid_expiry', BackendErrorKind.input),
  invalidMaxUses('invalid_max_uses', BackendErrorKind.input),
  invalidAmount('invalid_amount', BackendErrorKind.input),

  // P0002
  inviteNotFound('invite_not_found', BackendErrorKind.other),
  userNotFound('user_not_found', BackendErrorKind.other),
  invitationNotFound('invitation_not_found', BackendErrorKind.other),
  memberNotFound('member_not_found', BackendErrorKind.other),
  versionNotFound('version_not_found', BackendErrorKind.other),
  songNotFound('song_not_found', BackendErrorKind.other),

  // P0001
  inviteRevoked('invite_revoked', BackendErrorKind.other),
  inviteExpired('invite_expired', BackendErrorKind.other),
  inviteUsedUp('invite_used_up', BackendErrorKind.other),
  alreadyMember('already_member', BackendErrorKind.other),
  alreadyInvited('already_invited', BackendErrorKind.other),
  cannotInviteSelf('cannot_invite_self', BackendErrorKind.other),
  invitationNotPending('invitation_not_pending', BackendErrorKind.other),
  lastAdmin('last_admin', BackendErrorKind.other),
  bandNotInOrganization('band_not_in_organization', BackendErrorKind.other),
  organizationArchived('organization_archived', BackendErrorKind.other),
  archiveAlreadyRequested('archive_already_requested', BackendErrorKind.other),
  archiveNotRequested('archive_not_requested', BackendErrorKind.other),
  accountDeactivated('account_deactivated', BackendErrorKind.other),
  memberDeactivated('member_deactivated', BackendErrorKind.other),
  songExists('song_exists', BackendErrorKind.other),

  // 23505
  usernameTaken('username_taken', BackendErrorKind.other),

  // Client side conditions.
  /// A unique constraint was violated (`23505` without a documented code),
  /// e.g. two admins materializing the same schedule occurrence.
  conflict('conflict', BackendErrorKind.other),
  offline('offline', BackendErrorKind.other),
  notOwner('not_owner', BackendErrorKind.permission),
  notSignedIn('not_signed_in', BackendErrorKind.permission),
  unknown('unknown', BackendErrorKind.other);

  const BackendErrorCode(this.code, this.kind);

  /// The machine readable message sent by the backend.
  final String code;

  final BackendErrorKind kind;

  /// Codes the backend can raise (excludes the client side ones).
  static List<BackendErrorCode> get documented => values
      .where(
        (c) =>
            c != offline &&
            c != conflict &&
            c != notOwner &&
            c != notSignedIn &&
            c != unknown,
      )
      .toList(growable: false);

  /// Maps a backend message to a code. Never throws: unknown text becomes
  /// [unknown], and RLS / grant violations become [permissionDenied].
  static BackendErrorCode fromMessage(String? message, {String? sqlState}) {
    final text = (message ?? '').trim();
    for (final value in values) {
      if (value.code == text) return value;
    }
    final lower = text.toLowerCase();
    // A machine readable code may be wrapped (e.g. "ERROR: invite_expired").
    for (final value in documented) {
      if (RegExp('\\b${value.code}\\b').hasMatch(lower)) return value;
    }
    if (lower.contains('row-level security') ||
        lower.contains('permission denied')) {
      return permissionDenied;
    }
    if (sqlState == '42501') return permissionDenied;
    if (sqlState == '28000') return notAuthenticated;
    if (sqlState == '23505') return conflict;
    return unknown;
  }

  /// Builds the [Failure] subclass matching this code's [kind].
  Failure failure({String? message, StackTrace? stackTrace}) {
    final text = message ?? code;
    return switch (kind) {
      BackendErrorKind.permission => PermissionFailure(
        message: text,
        stackTrace: stackTrace,
        errorCode: this,
      ),
      BackendErrorKind.input => ValidationFailure(
        message: text,
        stackTrace: stackTrace,
        errorCode: this,
      ),
      BackendErrorKind.other => ServerFailure(
        message: text,
        stackTrace: stackTrace,
        errorCode: this,
      ),
    };
  }
}
