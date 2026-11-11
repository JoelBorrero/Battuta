import 'dart:async';

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/organizations/domain/entities/invites.dart';
import 'package:battuta/features/organizations/domain/entities/notification.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repository.dart';
import 'package:flutter_test/flutter_test.dart' show Fake;
import 'package:fpdart/fpdart.dart' hide Band;

/// In-memory [OrganizationRepository] for widget tests: the streams the UI
/// watches, the writes the roster makes, and failures that can be injected.
/// Anything else throws (`Fake`), so a test never silently depends on it.
class FakeOrganizationRepository extends Fake
    implements OrganizationRepository {
  FakeOrganizationRepository({
    List<Organization> organizations = const [],
    List<OrganizationMember> members = const [],
    List<Band> bands = const [],
    List<BandMember> bandMembers = const [],
  }) : _organizations = [...organizations],
       _members = [...members],
       _bands = [...bands],
       _bandMembers = [...bandMembers];

  final List<Organization> _organizations;
  final List<OrganizationMember> _members;
  final List<Band> _bands;
  final List<BandMember> _bandMembers;
  final _changes = StreamController<void>.broadcast(sync: true);

  /// When set, the next write returns this failure (then it is cleared).
  Failure? nextFailure;

  /// Names of the writes made, in order (e.g. `setMemberRole:m2:admin`).
  final List<String> calls = [];

  int _ids = 0;

  final List<InviteLink> _links = [];
  final List<Invitation> _invitations = [];
  final List<Invitation> _myInvitations = [];
  final List<AppNotification> _notifications = [];

  /// People `searchProfiles` can find.
  List<UserProfile> directory = const [];

  /// Queries received by `searchProfiles`.
  final List<String> searches = [];

  /// What `joinWithInviteLink` returns when it succeeds.
  String joinOrganizationId = 'org-1';

  /// Whether the next calls of `markNotificationsRead` etc. fail as offline.
  bool offline = false;

  Failure get _offlineFailure => backendFailure(BackendErrorCode.offline);

  void setInviteLinks(List<InviteLink> links) {
    _links
      ..clear()
      ..addAll(links);
    _notify();
  }

  void setInvitations(List<Invitation> invitations) {
    _invitations
      ..clear()
      ..addAll(invitations);
    _notify();
  }

  void setMyInvitations(List<Invitation> invitations) {
    _myInvitations
      ..clear()
      ..addAll(invitations);
    _notify();
  }

  void setNotifications(List<AppNotification> notifications) {
    _notifications
      ..clear()
      ..addAll(notifications);
    _notify();
  }

  @override
  Stream<List<InviteLink>> watchInviteLinks(String organizationId) => _watch(
    () => [
      for (final l in _links)
        if (l.organizationId == organizationId) l,
    ],
  );

  @override
  Stream<List<Invitation>> watchInvitations(String organizationId) => _watch(
    () => [
      for (final i in _invitations)
        if (i.organizationId == organizationId) i,
    ],
  );

  @override
  Stream<List<Invitation>> watchMyInvitations() =>
      _watch(() => [..._myInvitations]);

  @override
  Future<Either<Failure, Unit>> refreshInvitations(String organizationId) async =>
      right(unit);

  @override
  Stream<List<AppNotification>> watchNotifications() =>
      _watch(() => [..._notifications]);

  @override
  Future<Either<Failure, Unit>> markNotificationsRead([
    List<String>? ids,
  ]) async {
    calls.add('markNotificationsRead:${ids?.join(',') ?? 'all'}');
    if (offline) return left(_offlineFailure);
    if (_failed<Unit>() case final f?) return f;
    final at = DateTime(2026, 11, 11);
    for (var i = 0; i < _notifications.length; i++) {
      if (ids == null || ids.contains(_notifications[i].id)) {
        _notifications[i] = _notifications[i].markRead(at);
      }
    }
    _notify();
    return right(unit);
  }

  @override
  Future<Either<Failure, InviteLink>> createInviteLink(
    String organizationId, {
    String? bandId,
    Duration expiresIn = const Duration(days: 7),
    int? maxUses,
  }) async {
    calls.add(
      'createInviteLink:$organizationId:${bandId ?? '-'}:${expiresIn.inDays}:'
      '${maxUses ?? '-'}',
    );
    if (offline) return left(_offlineFailure);
    if (_failed<InviteLink>() case final f?) return f;
    final link = InviteLink(
      id: 'link-${_ids++}',
      organizationId: organizationId,
      token: 'a1b2c3d4e5f60718293a4b5c6d7e8f90${_ids.toString().padLeft(4, '0')}',
      expiresAt: DateTime.now().add(expiresIn),
      bandId: bandId,
      maxUses: maxUses,
    );
    _links.add(link);
    _notify();
    return right(link);
  }

  @override
  Future<Either<Failure, InviteLink>> revokeInviteLink(
    String organizationId,
    String linkId,
  ) async {
    calls.add('revokeInviteLink:$linkId');
    if (_failed<InviteLink>() case final f?) return f;
    final index = _links.indexWhere((l) => l.id == linkId);
    final old = _links[index];
    final revoked = InviteLink(
      id: old.id,
      organizationId: old.organizationId,
      token: old.token,
      expiresAt: old.expiresAt,
      bandId: old.bandId,
      maxUses: old.maxUses,
      useCount: old.useCount,
      revokedAt: DateTime.now(),
    );
    _links[index] = revoked;
    _notify();
    return right(revoked);
  }

  @override
  Future<Either<Failure, OrganizationMember>> joinWithInviteLink(
    String token,
  ) async {
    calls.add('joinWithInviteLink:$token');
    if (offline) return left(_offlineFailure);
    if (_failed<OrganizationMember>() case final f?) return f;
    return right(
      OrganizationMember(
        id: 'm-joined',
        organizationId: joinOrganizationId,
        userId: 'u-me',
      ),
    );
  }

  @override
  Future<Either<Failure, List<UserProfile>>> searchProfiles(
    String query,
  ) async {
    calls.add('searchProfiles:$query');
    searches.add(query);
    if (offline) return left(_offlineFailure);
    if (_failed<List<UserProfile>>() case final f?) return f;
    final q = query.toLowerCase();
    return right([
      for (final p in directory)
        if (p.username.toLowerCase().contains(q) ||
            p.displayName.toLowerCase().contains(q))
          p,
    ]);
  }

  @override
  Future<Either<Failure, Invitation>> inviteUserByUsername(
    String organizationId,
    String username, {
    String? bandId,
  }) async {
    calls.add('inviteUserByUsername:$username:${bandId ?? '-'}');
    if (offline) return left(_offlineFailure);
    if (_failed<Invitation>() case final f?) return f;
    final profile = directory.firstWhere((p) => p.username == username);
    final invitation = Invitation(
      id: 'inv-${_ids++}',
      organizationId: organizationId,
      invitedUserId: profile.id,
      bandId: bandId,
      inviteeUsername: profile.username,
      inviteeDisplayName: profile.displayName,
    );
    _invitations.add(invitation);
    _notify();
    return right(invitation);
  }

  @override
  Future<Either<Failure, Invitation>> cancelInvitation(
    String organizationId,
    String invitationId,
  ) async {
    calls.add('cancelInvitation:$invitationId');
    if (_failed<Invitation>() case final f?) return f;
    final index = _invitations.indexWhere((i) => i.id == invitationId);
    final old = _invitations[index];
    final cancelled = Invitation(
      id: old.id,
      organizationId: old.organizationId,
      invitedUserId: old.invitedUserId,
      status: InvitationStatus.cancelled,
      inviteeUsername: old.inviteeUsername,
      inviteeDisplayName: old.inviteeDisplayName,
    );
    _invitations[index] = cancelled;
    _notify();
    return right(cancelled);
  }

  @override
  Future<Either<Failure, Invitation>> respondToInvitation(
    Invitation invitation, {
    required bool accept,
  }) async {
    calls.add('respondToInvitation:${invitation.id}:$accept');
    if (_failed<Invitation>() case final f?) return f;
    final index = _myInvitations.indexWhere((i) => i.id == invitation.id);
    final updated = Invitation(
      id: invitation.id,
      organizationId: invitation.organizationId,
      invitedUserId: invitation.invitedUserId,
      status: accept ? InvitationStatus.accepted : InvitationStatus.declined,
      organizationName: invitation.organizationName,
    );
    _myInvitations[index] = updated;
    if (accept) {
      _organizations.add(
        Organization(
          id: invitation.organizationId,
          name: invitation.organizationName ?? 'Org',
          myRole: OrganizationRole.member,
        ),
      );
    }
    _notify();
    return right(updated);
  }

  void _notify() => _changes.add(null);

  Stream<List<T>> _watch<T>(List<T> Function() read) {
    late StreamController<List<T>> controller;
    StreamSubscription<void>? sub;
    controller = StreamController<List<T>>(
      onListen: () {
        controller.add(read());
        sub = _changes.stream.listen((_) => controller.add(read()));
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  /// Decides a failure per write, by its entry in [calls] (checked first).
  Failure? Function(String call)? failWhen;

  Either<Failure, T>? _failed<T>() {
    final byCall = failWhen?.call(calls.last);
    if (byCall != null) return left(byCall);
    final failure = nextFailure;
    if (failure == null) return null;
    nextFailure = null;
    return left(failure);
  }

  /// Replaces the organizations (as a realtime / refresh update would).
  void setOrganizations(List<Organization> organizations) {
    _organizations
      ..clear()
      ..addAll(organizations);
    _notify();
  }

  void setMembers(List<OrganizationMember> members) {
    _members
      ..clear()
      ..addAll(members);
    _notify();
  }

  @override
  Stream<List<Organization>> watchOrganizations({
    bool includeArchived = false,
  }) => _watch(
    () => [
      for (final o in _organizations)
        if (includeArchived || !o.isArchived) o,
    ],
  );

  @override
  Stream<List<OrganizationMember>> watchMembers(String organizationId) =>
      _watch(
        () => [
          for (final m in _members)
            if (m.organizationId == organizationId) m,
        ],
      );

  @override
  Stream<List<Band>> watchBands(String organizationId) => _watch(
    () => [
      for (final b in _bands)
        if (b.organizationId == organizationId) b,
    ],
  );

  @override
  Stream<List<BandMember>> watchBandMembers(String organizationId) => _watch(
    () => [
      for (final b in _bandMembers)
        if (b.organizationId == organizationId) b,
    ],
  );

  @override
  Future<Either<Failure, Organization>> createOrganization(String name) async {
    calls.add('createOrganization:$name');
    if (_failed<Organization>() case final f?) return f;
    final created = Organization(
      id: 'org-new-${_ids++}',
      name: name,
      myRole: OrganizationRole.admin,
    );
    _organizations.add(created);
    _notify();
    return right(created);
  }

  @override
  Future<Either<Failure, OrganizationMember>> updateMusicianProfile(
    String organizationId,
    String memberId, {
    List<String>? instruments,
    String? minPitch,
    String? maxPitch,
    String? notes,
  }) async {
    calls.add(
      'updateMusicianProfile:$memberId:${instruments?.join(',')}:'
      '$minPitch:$maxPitch:$notes',
    );
    if (_failed<OrganizationMember>() case final f?) return f;
    final index = _members.indexWhere((m) => m.id == memberId);
    final old = _members[index];
    final updated = OrganizationMember(
      id: old.id,
      organizationId: old.organizationId,
      userId: old.userId,
      role: old.role,
      instruments: instruments ?? old.instruments,
      minPitch: minPitch == null
          ? old.minPitch
          : (minPitch.isEmpty ? null : minPitch),
      maxPitch: maxPitch == null
          ? old.maxPitch
          : (maxPitch.isEmpty ? null : maxPitch),
      notes: notes == null ? old.notes : (notes.isEmpty ? null : notes),
      username: old.username,
      displayName: old.displayName,
    );
    _members[index] = updated;
    _notify();
    return right(updated);
  }

  @override
  Future<Either<Failure, OrganizationMember>> setMemberRole(
    String organizationId,
    String memberId,
    OrganizationRole role,
  ) async {
    calls.add('setMemberRole:$memberId:${role.name}');
    if (_failed<OrganizationMember>() case final f?) return f;
    final index = _members.indexWhere((m) => m.id == memberId);
    final old = _members[index];
    final updated = OrganizationMember(
      id: old.id,
      organizationId: old.organizationId,
      userId: old.userId,
      role: role,
      instruments: old.instruments,
      minPitch: old.minPitch,
      maxPitch: old.maxPitch,
      notes: old.notes,
      username: old.username,
      displayName: old.displayName,
    );
    _members[index] = updated;
    _notify();
    return right(updated);
  }

  @override
  Future<Either<Failure, Unit>> removeMember(
    String organizationId,
    String memberId,
  ) async {
    calls.add('removeMember:$memberId');
    if (_failed<Unit>() case final f?) return f;
    _members.removeWhere((m) => m.id == memberId);
    _notify();
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> leaveOrganization(String organizationId) async {
    calls.add('leaveOrganization:$organizationId');
    if (_failed<Unit>() case final f?) return f;
    _organizations.removeWhere((o) => o.id == organizationId);
    _notify();
    return right(unit);
  }

  @override
  Future<Either<Failure, Band>> createBand(
    String organizationId,
    String name, {
    String? description,
    int colorValue = Band.defaultColorValue,
  }) async {
    calls.add('createBand:$name');
    if (_failed<Band>() case final f?) return f;
    final band = Band(
      id: 'band-new-${_ids++}',
      organizationId: organizationId,
      name: name,
      description: description,
      colorValue: colorValue,
    );
    _bands.add(band);
    _notify();
    return right(band);
  }

  @override
  Future<Either<Failure, Band>> updateBand(Band band) async {
    calls.add('updateBand:${band.id}:${band.name}');
    if (_failed<Band>() case final f?) return f;
    final index = _bands.indexWhere((b) => b.id == band.id);
    _bands[index] = band;
    _notify();
    return right(band);
  }

  @override
  Future<Either<Failure, Unit>> deleteBand(
    String organizationId,
    String bandId,
  ) async {
    calls.add('deleteBand:$bandId');
    if (_failed<Unit>() case final f?) return f;
    _bands.removeWhere((b) => b.id == bandId);
    _bandMembers.removeWhere((b) => b.bandId == bandId);
    _notify();
    return right(unit);
  }

  @override
  Future<Either<Failure, BandMember>> addBandMember(
    String organizationId,
    String bandId,
    String memberId,
  ) async {
    calls.add('addBandMember:$bandId:$memberId');
    if (_failed<BandMember>() case final f?) return f;
    final link = BandMember(
      id: 'bm-${_ids++}',
      organizationId: organizationId,
      bandId: bandId,
      memberId: memberId,
    );
    _bandMembers.add(link);
    _notify();
    return right(link);
  }

  @override
  Future<Either<Failure, Unit>> removeBandMember(
    String organizationId,
    String bandMemberId,
  ) async {
    calls.add('removeBandMember:$bandMemberId');
    if (_failed<Unit>() case final f?) return f;
    _bandMembers.removeWhere((b) => b.id == bandMemberId);
    _notify();
    return right(unit);
  }

  // ---- Settings: rename, quota and archiving --------------------------------

  /// What `getQuota` returns.
  OrganizationQuota quota = const OrganizationQuota(
    tier: 'free',
    monthlyGeminiCreditsLimit: 100,
    maxStorageBytes: 52428800,
  );

  final Map<String, ArchiveRequest> _archiveRequests = {};

  /// The id of the signed-in user in archive approvals.
  String meId = 'u-me';

  void setArchiveRequest(String organizationId, ArchiveRequest? request) {
    if (request == null) {
      _archiveRequests.remove(organizationId);
    } else {
      _archiveRequests[organizationId] = request;
    }
    _notify();
  }

  @override
  Future<Either<Failure, OrganizationQuota>> getQuota(
    String organizationId,
  ) async {
    calls.add('getQuota:$organizationId');
    if (offline) return left(_offlineFailure);
    if (_failed<OrganizationQuota>() case final f?) return f;
    return right(quota);
  }

  @override
  Future<Either<Failure, Organization>> renameOrganization(
    String organizationId,
    String name,
  ) async {
    calls.add('renameOrganization:$organizationId:$name');
    if (_failed<Organization>() case final f?) return f;
    final index = _organizations.indexWhere((o) => o.id == organizationId);
    final renamed = _organizations[index].copyWith(name: name);
    _organizations[index] = renamed;
    _notify();
    return right(renamed);
  }

  @override
  Stream<ArchiveRequest?> watchArchiveRequest(String organizationId) =>
      _watch<ArchiveRequest?>(
        () => [_archiveRequests[organizationId]],
      ).map((rows) => rows.firstOrNull);

  @override
  Future<Either<Failure, Unit>> refreshArchiveRequest(
    String organizationId,
  ) async => right(unit);

  Organization _archiveIfEveryAdminApproved(String organizationId) {
    final index = _organizations.indexWhere((o) => o.id == organizationId);
    final request = _archiveRequests[organizationId]!;
    final admins = _members.where(
      (m) => m.organizationId == organizationId && m.isAdmin && m.isActive,
    );
    if (admins.every((m) => request.isApprovedBy(m.userId))) {
      _organizations[index] = _organizations[index].copyWith(
        archivedAt: DateTime(2026, 11, 11),
      );
      _archiveRequests.remove(organizationId);
    }
    _notify();
    return _organizations[index];
  }

  @override
  Future<Either<Failure, Organization>> requestArchive(
    String organizationId,
  ) async {
    calls.add('requestArchive:$organizationId');
    if (offline) return left(_offlineFailure);
    if (_failed<Organization>() case final f?) return f;
    _archiveRequests[organizationId] = ArchiveRequest(
      organizationId: organizationId,
      requestedBy: meId,
      approvals: [ArchiveApproval(userId: meId)],
    );
    return right(_archiveIfEveryAdminApproved(organizationId));
  }

  @override
  Future<Either<Failure, Organization>> approveArchive(
    String organizationId,
  ) async {
    calls.add('approveArchive:$organizationId');
    if (offline) return left(_offlineFailure);
    if (_failed<Organization>() case final f?) return f;
    final request = _archiveRequests[organizationId]!;
    _archiveRequests[organizationId] = ArchiveRequest(
      organizationId: organizationId,
      requestedBy: request.requestedBy,
      requestedAt: request.requestedAt,
      approvals: [...request.approvals, ArchiveApproval(userId: meId)],
    );
    return right(_archiveIfEveryAdminApproved(organizationId));
  }

  @override
  Future<Either<Failure, Organization>> cancelArchive(
    String organizationId,
  ) async {
    calls.add('cancelArchive:$organizationId');
    if (_failed<Organization>() case final f?) return f;
    _archiveRequests.remove(organizationId);
    _notify();
    return right(_organizations.firstWhere((o) => o.id == organizationId));
  }
}

/// A backend failure with its typed code, as the repositories return.
Failure backendFailure(BackendErrorCode code) =>
    code.failure(message: code.code);
