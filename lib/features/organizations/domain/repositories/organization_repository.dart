/// Organizations, members, bands, invites, archiving and notifications.
///
/// Reads come from the offline cache (`watch...` streams, which also trigger a
/// refresh when online). Writes need a connection: offline they return
/// `Left` with `BackendErrorCode.offline`. Nothing here throws.
library;

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/organizations/domain/entities/invites.dart';
import 'package:battuta/features/organizations/domain/entities/notification.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:fpdart/fpdart.dart' hide Band;

typedef Result<T> = Either<Failure, T>;

abstract interface class OrganizationRepository {
  // Organizations
  Stream<List<Organization>> watchOrganizations({bool includeArchived = false});
  Future<Result<Unit>> refreshOrganizations();
  Future<Result<Organization>> createOrganization(String name);
  Future<Result<Organization>> renameOrganization(
    String organizationId,
    String name,
  );
  Future<Result<Unit>> leaveOrganization(String organizationId);
  Future<Result<OrganizationQuota>> getQuota(String organizationId);

  // Members
  Stream<List<OrganizationMember>> watchMembers(String organizationId);
  Future<Result<Unit>> refreshMembers(String organizationId);
  Future<Result<OrganizationMember>> updateMusicianProfile(
    String organizationId,
    String memberId, {
    List<String>? instruments,
    String? minPitch,
    String? maxPitch,
    String? notes,
  });
  Future<Result<OrganizationMember>> setMemberRole(
    String organizationId,
    String memberId,
    OrganizationRole role,
  );
  Future<Result<Unit>> removeMember(String organizationId, String memberId);

  // Bands
  Stream<List<Band>> watchBands(String organizationId);
  Stream<List<BandMember>> watchBandMembers(String organizationId);
  Future<Result<Unit>> refreshBands(String organizationId);
  Future<Result<Band>> createBand(
    String organizationId,
    String name, {
    String? description,
    int colorValue = Band.defaultColorValue,
  });
  Future<Result<Band>> updateBand(Band band);
  Future<Result<Unit>> deleteBand(String organizationId, String bandId);
  Future<Result<BandMember>> addBandMember(
    String organizationId,
    String bandId,
    String memberId,
  );
  Future<Result<Unit>> removeBandMember(
    String organizationId,
    String bandMemberId,
  );

  // Invite links and invitations
  Stream<List<InviteLink>> watchInviteLinks(String organizationId);
  Future<Result<Unit>> refreshInviteLinks(String organizationId);
  Future<Result<InviteLink>> createInviteLink(
    String organizationId, {
    String? bandId,
    Duration expiresIn = const Duration(days: 7),
    int? maxUses,
  });
  Future<Result<InviteLink>> revokeInviteLink(
    String organizationId,
    String linkId,
  );
  Future<Result<OrganizationMember>> joinWithInviteLink(String token);

  /// Invitations of one organization (admins see all, members their own).
  Stream<List<Invitation>> watchInvitations(String organizationId);
  Future<Result<Unit>> refreshInvitations(String organizationId);

  /// Invitations addressed to the signed-in user.
  Stream<List<Invitation>> watchMyInvitations();
  Future<Result<Unit>> refreshMyInvitations();
  Future<Result<Invitation>> inviteUserByUsername(
    String organizationId,
    String username, {
    String? bandId,
  });
  Future<Result<Invitation>> respondToInvitation(
    Invitation invitation, {
    required bool accept,
  });
  Future<Result<Invitation>> cancelInvitation(
    String organizationId,
    String invitationId,
  );
  Future<Result<List<UserProfile>>> searchProfiles(String query);

  // Archiving (needs every admin; cannot be undone from the app)
  Stream<ArchiveRequest?> watchArchiveRequest(String organizationId);
  Future<Result<Unit>> refreshArchiveRequest(String organizationId);
  Future<Result<Organization>> requestArchive(String organizationId);
  Future<Result<Organization>> approveArchive(String organizationId);
  Future<Result<Organization>> cancelArchive(String organizationId);

  // Notifications
  Stream<List<AppNotification>> watchNotifications();
  Future<Result<Unit>> refreshNotifications();
  Future<Result<Unit>> markNotificationsRead([List<String>? ids]);

  /// Refreshes everything cached for the signed-in account.
  Future<Result<Unit>> refreshAll();
}
