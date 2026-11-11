/// Cache-first implementation of [OrganizationRepository].
library;

import 'dart:async';

import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/organizations/data/cached_repository_support.dart';
import 'package:battuta/features/organizations/data/organizations_local_cache.dart';
import 'package:battuta/features/organizations/data/organizations_remote_data_source.dart';
import 'package:battuta/features/organizations/domain/entities/invites.dart';
import 'package:battuta/features/organizations/domain/entities/notification.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/organizations/domain/repositories/account_session.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repository.dart';
import 'package:fpdart/fpdart.dart' hide Band;

class OrganizationRepositoryImpl
    with CachedRepositorySupport
    implements OrganizationRepository {
  OrganizationRepositoryImpl({
    required this.remote,
    required this.cache,
    required this.session,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final OrganizationsRemoteDataSource remote;
  @override
  final OrganizationsLocalCache cache;
  @override
  final AccountSession session;
  final DateTime Function() _clock;

  // ---- Helpers -------------------------------------------------------------

  Future<void> _upsert(
    String accountId,
    String kind,
    String id,
    Map<String, dynamic> json, {
    String scopeId = '',
  }) => cache.upsert(accountId, kind, id, json, scopeId: scopeId);

  Future<void> _upsertOrganization(String accountId, Organization org) =>
      _upsert(accountId, CacheKind.organization, org.id, org.toJson());

  /// An organization returned by an RPC has no role: keep the cached one.
  Future<Organization> _withCachedRole(
    String accountId,
    Organization org,
  ) async {
    final cached = await cache.readOne(
      accountId,
      CacheKind.organization,
      org.id,
      Organization.fromJson,
    );
    return org.copyWith(myRole: org.myRole ?? cached?.myRole);
  }

  Future<OrganizationMember> _withCachedProfile(
    String accountId,
    OrganizationMember member,
  ) async {
    final cached = await cache.readOne(
      accountId,
      CacheKind.member,
      member.id,
      OrganizationMember.fromJson,
    );
    return member.withProfileOf(cached);
  }

  Future<void> _cacheMember(String accountId, OrganizationMember member) =>
      _upsert(
        accountId,
        CacheKind.member,
        member.id,
        member.toJson(),
        scopeId: member.organizationId,
      );

  Future<void> _ignoreFailure(Future<Object?> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Best effort: the cache stays as it was.
    }
  }

  // ---- Organizations -------------------------------------------------------

  @override
  Stream<List<Organization>> watchOrganizations({
    bool includeArchived = false,
  }) =>
      watchCached<Organization>(
        CacheKind.organization,
        Organization.fromJson,
        refresh: () async {
          await refreshOrganizations();
        },
        sort: (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      ).map(
        (all) => includeArchived
            ? all
            : all.where((o) => !o.isArchived).toList(growable: false),
      );

  @override
  Future<Result<Unit>> refreshOrganizations() => guard((accountId) async {
    final orgs = await remote.myOrganizations(includeArchived: true);
    final memberships = await remote.fetchMyMemberships();
    final roles = {
      for (final m in memberships.where((m) => m.isActive))
        m.organizationId: m.role,
    };
    final fresh = [for (final org in orgs) org.copyWith(myRole: roles[org.id])];
    final previous = await cache.read(
      accountId,
      CacheKind.organization,
      Organization.fromJson,
    );
    await cache.replaceAll(
      accountId,
      CacheKind.organization,
      fresh.map((o) => (id: o.id, json: o.toJson())),
    );
    // Removed from (or left) an organization: drop all of its cached data.
    final freshIds = fresh.map((o) => o.id).toSet();
    for (final old in previous.where((o) => !freshIds.contains(o.id))) {
      await cache.removeScope(accountId, old.id);
    }
    return unit;
  });

  @override
  Future<Result<Organization>> createOrganization(String name) =>
      guard((accountId) async {
        final created = await remote.createOrganization(name);
        final org = created.copyWith(myRole: OrganizationRole.admin);
        await _upsertOrganization(accountId, org);
        return org;
      });

  @override
  Future<Result<Organization>> renameOrganization(
    String organizationId,
    String name,
  ) => guardWrite(organizationId, (accountId) async {
    final renamed = await remote.renameOrganization(organizationId, name);
    final org = await _withCachedRole(accountId, renamed);
    await _upsertOrganization(accountId, org);
    return org;
  });

  @override
  Future<Result<Unit>> leaveOrganization(String organizationId) =>
      guard((accountId) async {
        await remote.leaveOrganization(organizationId);
        await cache.remove(accountId, CacheKind.organization, organizationId);
        await cache.removeScope(accountId, organizationId);
        return unit;
      });

  @override
  Future<Result<OrganizationQuota>> getQuota(String organizationId) =>
      guard((_) => remote.organizationQuota(organizationId));

  // ---- Members -------------------------------------------------------------

  @override
  Stream<List<OrganizationMember>> watchMembers(String organizationId) =>
      watchCached<OrganizationMember>(
        CacheKind.member,
        OrganizationMember.fromJson,
        scopeId: organizationId,
        refresh: () async {
          await refreshMembers(organizationId);
        },
        sort: (a, b) => (a.displayName ?? a.username ?? '')
            .toLowerCase()
            .compareTo((b.displayName ?? b.username ?? '').toLowerCase()),
      );

  @override
  Future<Result<Unit>> refreshMembers(String organizationId) =>
      guard((accountId) async {
        final members = await remote.fetchMembers(organizationId);
        await cache.replaceAll(
          accountId,
          CacheKind.member,
          members.map((m) => (id: m.id, json: m.toJson())),
          scopeId: organizationId,
        );
        return unit;
      });

  @override
  Future<Result<OrganizationMember>> updateMusicianProfile(
    String organizationId,
    String memberId, {
    List<String>? instruments,
    String? minPitch,
    String? maxPitch,
    String? notes,
  }) => guardWrite(organizationId, (accountId) async {
    final member = await remote.updateMusicianProfile(
      memberId,
      instruments: instruments,
      minPitch: minPitch,
      maxPitch: maxPitch,
      notes: notes,
    );
    await _cacheMember(accountId, member);
    return member;
  });

  @override
  Future<Result<OrganizationMember>> setMemberRole(
    String organizationId,
    String memberId,
    OrganizationRole role,
  ) => guardWrite(organizationId, (accountId) async {
    final updated = await remote.setMemberRole(memberId, role);
    final member = await _withCachedProfile(accountId, updated);
    await _cacheMember(accountId, member);
    if (member.userId == accountId) {
      await _ignoreFailure(refreshOrganizations);
    }
    return member;
  });

  @override
  Future<Result<Unit>> removeMember(String organizationId, String memberId) =>
      guardWrite(organizationId, (accountId) async {
        await remote.removeMember(memberId);
        await _dropMember(accountId, organizationId, memberId);
        return unit;
      });

  /// Removing a member also removes their band memberships (server side).
  Future<void> _dropMember(
    String accountId,
    String organizationId,
    String memberId,
  ) async {
    await cache.remove(accountId, CacheKind.member, memberId);
    final links = await cache.read(
      accountId,
      CacheKind.bandMember,
      BandMember.fromJson,
      scopeId: organizationId,
    );
    for (final link in links.where((l) => l.memberId == memberId)) {
      await cache.remove(accountId, CacheKind.bandMember, link.id);
    }
  }

  // ---- Bands ---------------------------------------------------------------

  @override
  Stream<List<Band>> watchBands(String organizationId) => watchCached<Band>(
    CacheKind.band,
    Band.fromJson,
    scopeId: organizationId,
    refresh: () async {
      await refreshBands(organizationId);
    },
    sort: (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );

  @override
  Stream<List<BandMember>> watchBandMembers(String organizationId) =>
      watchCached<BandMember>(
        CacheKind.bandMember,
        BandMember.fromJson,
        scopeId: organizationId,
      );

  @override
  Future<Result<Unit>> refreshBands(String organizationId) =>
      guard((accountId) async {
        final bands = await remote.fetchBands(organizationId);
        final links = await remote.fetchBandMembers(organizationId);
        await cache.replaceAll(
          accountId,
          CacheKind.band,
          bands.map((b) => (id: b.id, json: b.toJson())),
          scopeId: organizationId,
        );
        await cache.replaceAll(
          accountId,
          CacheKind.bandMember,
          links.map((l) => (id: l.id, json: l.toJson())),
          scopeId: organizationId,
        );
        return unit;
      });

  @override
  Future<Result<Band>> createBand(
    String organizationId,
    String name, {
    String? description,
    int colorValue = Band.defaultColorValue,
  }) => guardWrite(organizationId, (accountId) async {
    final band = await remote.createBand(
      Band(
        id: newEntityId(),
        organizationId: organizationId,
        name: name,
        description: description,
        colorValue: colorValue,
      ),
    );
    await _upsert(
      accountId,
      CacheKind.band,
      band.id,
      band.toJson(),
      scopeId: organizationId,
    );
    return band;
  });

  @override
  Future<Result<Band>> updateBand(Band band) =>
      guardWrite(band.organizationId, (accountId) async {
        final updated = await remote.updateBand(band);
        await _upsert(
          accountId,
          CacheKind.band,
          updated.id,
          updated.toJson(),
          scopeId: updated.organizationId,
        );
        return updated;
      });

  @override
  Future<Result<Unit>> deleteBand(String organizationId, String bandId) =>
      guardWrite(organizationId, (accountId) async {
        await remote.deleteBand(bandId);
        await cache.remove(accountId, CacheKind.band, bandId);
        final links = await cache.read(
          accountId,
          CacheKind.bandMember,
          BandMember.fromJson,
          scopeId: organizationId,
        );
        for (final link in links.where((l) => l.bandId == bandId)) {
          await cache.remove(accountId, CacheKind.bandMember, link.id);
        }
        return unit;
      });

  @override
  Future<Result<BandMember>> addBandMember(
    String organizationId,
    String bandId,
    String memberId,
  ) => guardWrite(organizationId, (accountId) async {
    final link = await remote.addBandMember(
      organizationId: organizationId,
      bandId: bandId,
      memberId: memberId,
    );
    await _upsert(
      accountId,
      CacheKind.bandMember,
      link.id,
      link.toJson(),
      scopeId: organizationId,
    );
    return link;
  });

  @override
  Future<Result<Unit>> removeBandMember(
    String organizationId,
    String bandMemberId,
  ) => guardWrite(organizationId, (accountId) async {
    await remote.removeBandMember(bandMemberId);
    await cache.remove(accountId, CacheKind.bandMember, bandMemberId);
    return unit;
  });

  // ---- Invite links and invitations ----------------------------------------

  @override
  Stream<List<InviteLink>> watchInviteLinks(String organizationId) =>
      watchCached<InviteLink>(
        CacheKind.inviteLink,
        InviteLink.fromJson,
        scopeId: organizationId,
        refresh: () async {
          await refreshInviteLinks(organizationId);
        },
        sort: (a, b) =>
            (b.createdAt ?? b.expiresAt).compareTo(a.createdAt ?? a.expiresAt),
      );

  @override
  Future<Result<Unit>> refreshInviteLinks(String organizationId) =>
      guard((accountId) async {
        final links = await remote.fetchInviteLinks(organizationId);
        await cache.replaceAll(
          accountId,
          CacheKind.inviteLink,
          links.map((l) => (id: l.id, json: l.toJson())),
          scopeId: organizationId,
        );
        return unit;
      });

  @override
  Future<Result<InviteLink>> createInviteLink(
    String organizationId, {
    String? bandId,
    Duration expiresIn = const Duration(days: 7),
    int? maxUses,
  }) => guardWrite(organizationId, (accountId) async {
    final link = await remote.createInviteLink(
      organizationId,
      bandId: bandId,
      expiresIn: expiresIn,
      maxUses: maxUses,
    );
    await _upsert(
      accountId,
      CacheKind.inviteLink,
      link.id,
      link.toJson(),
      scopeId: organizationId,
    );
    return link;
  });

  @override
  Future<Result<InviteLink>> revokeInviteLink(
    String organizationId,
    String linkId,
  ) => guardWrite(organizationId, (accountId) async {
    final link = await remote.revokeInviteLink(linkId);
    await _upsert(
      accountId,
      CacheKind.inviteLink,
      link.id,
      link.toJson(),
      scopeId: organizationId,
    );
    return link;
  });

  @override
  Future<Result<OrganizationMember>> joinWithInviteLink(String token) =>
      guard((accountId) async {
        final joined = await remote.joinWithInviteLink(token);
        await _cacheMember(accountId, joined);
        await _ignoreFailure(refreshOrganizations);
        return joined;
      });

  @override
  Stream<List<Invitation>> watchInvitations(String organizationId) =>
      watchCached<Invitation>(
        CacheKind.invitation,
        Invitation.fromJson,
        scopeId: organizationId,
        refresh: () async {
          await refreshInvitations(organizationId);
        },
        sort: _newestInvitationFirst,
      );

  static int _newestInvitationFirst(Invitation a, Invitation b) =>
      (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      );

  @override
  Future<Result<Unit>> refreshInvitations(String organizationId) =>
      guard((accountId) async {
        final rows = await remote.fetchInvitations(organizationId);
        await cache.replaceAll(
          accountId,
          CacheKind.invitation,
          rows.map((i) => (id: i.id, json: i.toJson())),
          scopeId: organizationId,
        );
        return unit;
      });

  @override
  Stream<List<Invitation>> watchMyInvitations() => watchCached<Invitation>(
    CacheKind.myInvitation,
    Invitation.fromJson,
    refresh: () async {
      await refreshMyInvitations();
    },
    sort: _newestInvitationFirst,
  );

  @override
  Future<Result<Unit>> refreshMyInvitations() => guard((accountId) async {
    final rows = await remote.fetchMyInvitations();
    await cache.replaceAll(
      accountId,
      CacheKind.myInvitation,
      rows.map((i) => (id: i.id, json: i.toJson())),
    );
    return unit;
  });

  @override
  Future<Result<Invitation>> inviteUserByUsername(
    String organizationId,
    String username, {
    String? bandId,
  }) => guardWrite(organizationId, (accountId) async {
    final invitation = await remote.inviteUserByUsername(
      organizationId,
      username.trim(),
      bandId: bandId,
    );
    await _upsert(
      accountId,
      CacheKind.invitation,
      invitation.id,
      invitation.toJson(),
      scopeId: organizationId,
    );
    return invitation;
  });

  @override
  Future<Result<Invitation>> respondToInvitation(
    Invitation invitation, {
    required bool accept,
  }) => guard((accountId) async {
    final updated = (await remote.respondToInvitation(
      invitation.id,
      accept,
    )).withOrganizationName(invitation.organizationName);
    await _upsert(
      accountId,
      CacheKind.myInvitation,
      updated.id,
      updated.toJson(),
    );
    if (accept) await _ignoreFailure(refreshOrganizations);
    return updated;
  });

  @override
  Future<Result<Invitation>> cancelInvitation(
    String organizationId,
    String invitationId,
  ) => guardWrite(organizationId, (accountId) async {
    final updated = await remote.cancelInvitation(invitationId);
    await _upsert(
      accountId,
      CacheKind.invitation,
      updated.id,
      updated.toJson(),
      scopeId: organizationId,
    );
    return updated;
  });

  @override
  Future<Result<List<UserProfile>>> searchProfiles(String query) =>
      guard((_) => remote.searchProfiles(query.trim()));

  // ---- Archiving -----------------------------------------------------------

  @override
  Stream<ArchiveRequest?> watchArchiveRequest(String organizationId) =>
      watchCached<ArchiveRequest>(
        CacheKind.archiveRequest,
        ArchiveRequest.fromJson,
        scopeId: organizationId,
        refresh: () async {
          await refreshArchiveRequest(organizationId);
        },
      ).map((rows) => rows.firstOrNull);

  @override
  Future<Result<Unit>> refreshArchiveRequest(String organizationId) =>
      guard((accountId) async {
        final request = await remote.fetchArchiveRequest(organizationId);
        await cache.replaceAll(accountId, CacheKind.archiveRequest, [
          if (request != null) (id: organizationId, json: request.toJson()),
        ], scopeId: organizationId);
        return unit;
      });

  @override
  Future<Result<Organization>> requestArchive(String organizationId) =>
      _archive(organizationId, remote.requestOrganizationArchive);

  @override
  Future<Result<Organization>> approveArchive(String organizationId) =>
      _archive(organizationId, remote.approveOrganizationArchive);

  @override
  Future<Result<Organization>> cancelArchive(String organizationId) =>
      _archive(organizationId, remote.cancelOrganizationArchive);

  Future<Result<Organization>> _archive(
    String organizationId,
    Future<Organization> Function(String) call,
  ) => guardWrite(organizationId, (accountId) async {
    final org = await _withCachedRole(accountId, await call(organizationId));
    await _upsertOrganization(accountId, org);
    await _ignoreFailure(
      () => remote
          .fetchArchiveRequest(organizationId)
          .then(
            (request) => cache.replaceAll(accountId, CacheKind.archiveRequest, [
              if (request != null) (id: organizationId, json: request.toJson()),
            ], scopeId: organizationId),
          ),
    );
    return org;
  });

  // ---- Notifications -------------------------------------------------------

  @override
  Stream<List<AppNotification>> watchNotifications() =>
      watchCached<AppNotification>(
        CacheKind.notification,
        AppNotification.fromJson,
        refresh: () async {
          await refreshNotifications();
        },
        sort: (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );

  @override
  Future<Result<Unit>> refreshNotifications() => guard((accountId) async {
    final rows = await remote.fetchNotifications();
    await cache.replaceAll(
      accountId,
      CacheKind.notification,
      rows.map((n) => (id: n.id, json: n.toJson())),
    );
    return unit;
  });

  @override
  Future<Result<Unit>> markNotificationsRead([List<String>? ids]) =>
      guard((accountId) async {
        await remote.markNotificationsRead(ids);
        final now = _clock();
        final cached = await cache.read(
          accountId,
          CacheKind.notification,
          AppNotification.fromJson,
        );
        for (final n in cached) {
          if (n.isRead || (ids != null && !ids.contains(n.id))) continue;
          await _upsert(
            accountId,
            CacheKind.notification,
            n.id,
            n.markRead(now).toJson(),
          );
        }
        return unit;
      });

  // ---- Everything ----------------------------------------------------------

  @override
  Future<Result<Unit>> refreshAll() async {
    final orgs = await refreshOrganizations();
    if (orgs.isLeft()) return orgs;
    await refreshMyInvitations();
    await refreshNotifications();
    final accountId = session.userId;
    if (accountId == null) return orgs;
    final cached = await cache.read(
      accountId,
      CacheKind.organization,
      Organization.fromJson,
    );
    for (final org in cached) {
      await refreshMembers(org.id);
      await refreshBands(org.id);
      await refreshInvitations(org.id);
      await refreshArchiveRequest(org.id);
      if (org.isAdmin) await refreshInviteLinks(org.id);
    }
    return orgs;
  }
}
