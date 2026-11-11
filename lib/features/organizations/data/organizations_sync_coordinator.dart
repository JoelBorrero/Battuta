/// Keeps the cache in step with the signed-in account.
///
/// * Clears the cache of the previous account on sign-out / account switch.
/// * Refreshes everything when an account signs in.
/// * Applies realtime changes to the cache and does a full refresh after a
///   reconnect (no duplicates: rows are upserted by id).
library;

import 'dart:async';

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/data/backend_gateway.dart';
import 'package:battuta/features/organizations/data/organizations_local_cache.dart';
import 'package:battuta/features/organizations/data/organizations_remote_data_source.dart';
import 'package:battuta/features/organizations/domain/entities/invites.dart';
import 'package:battuta/features/organizations/domain/entities/notification.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/organizations/domain/repositories/account_session.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repertoire_repository.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repository.dart';
import 'package:battuta/features/organizations/domain/repositories/schedule_repository.dart';

class OrganizationsSyncCoordinator {
  OrganizationsSyncCoordinator({
    required this.session,
    required this.cache,
    required this.remote,
    required this.organizations,
    required this.schedules,
    this.repertoire,
  });

  final AccountSession session;
  final OrganizationsLocalCache cache;
  final OrganizationsRemoteDataSource remote;
  final OrganizationRepository organizations;
  final ScheduleRepository schedules;

  /// Keeps the cached repertoire of each organization fresh (optional).
  final OrganizationRepertoireRepository? repertoire;

  StreamSubscription<String?>? _sessionSub;
  StreamSubscription<BackendChange>? _changesSub;
  String? _activeAccount;
  Future<void> _queue = Future.value();

  /// Starts following the session. Safe to call more than once.
  Future<void> start() async {
    if (_sessionSub != null) return;
    _sessionSub = session.userIdChanges.listen(
      (id) => _enqueue(() => _onAccountChanged(id)),
    );
    await _enqueue(() => _onAccountChanged(session.userId));
  }

  Future<void> stop() async {
    await _sessionSub?.cancel();
    _sessionSub = null;
    await _stopRealtime();
  }

  /// Serializes work so quick account switches never interleave.
  Future<void> _enqueue(Future<void> Function() task) {
    _queue = _queue.then((_) => task()).catchError((_) {});
    return _queue;
  }

  Future<void> _onAccountChanged(String? accountId) async {
    if (accountId == _activeAccount && _changesSub != null) return;
    await _stopRealtime();
    _activeAccount = accountId;
    // Drops every other account's data (everything when signed out).
    await cache.clearAllExcept(accountId);
    if (accountId == null) return;
    _startRealtime();
    await refreshAll();
  }

  Future<void> refreshAll() async {
    await organizations.refreshAll();
    final accountId = session.userId;
    if (accountId == null) return;
    final orgs = await cache.read(
      accountId,
      CacheKind.organization,
      Organization.fromJson,
    );
    for (final org in orgs) {
      await schedules.refreshOrganization(org.id);
      await repertoire?.refreshRepertoire(org.id);
    }
  }

  void _startRealtime() {
    _changesSub = remote.changes().listen(
      (change) => _enqueue(() => applyChange(change)),
      onError: _onRealtimeError,
    );
  }

  /// A deactivated account ends its session and loses its cache; every other
  /// realtime error is ignored (the channel resyncs on reconnect).
  Future<void> _onRealtimeError(Object error, StackTrace stackTrace) async {
    if (mapBackendError(error, stackTrace).errorCode !=
        BackendErrorCode.accountDeactivated) {
      return;
    }
    try {
      await session.signOut();
    } catch (_) {
      // The cache is cleared regardless.
    }
    await cache.clearAllExcept(null);
  }

  Future<void> _stopRealtime() async {
    await _changesSub?.cancel();
    _changesSub = null;
  }

  /// Applies one realtime [change] to the cache (visible for testing).
  Future<void> applyChange(BackendChange change) async {
    final me = session.userId;
    if (me == null) return;
    if (change.type == BackendChangeType.resync) {
      await refreshAll();
      return;
    }
    final isDelete = change.type == BackendChangeType.delete;
    final row = isDelete ? change.oldRecord : change.record;
    final id = row['id'] as String?;
    if (id == null) return;

    Future<void> upsertOrRemove(
      String kind,
      String? scope,
      Map<String, dynamic> json,
    ) async {
      if (isDelete) {
        await cache.remove(me, kind, id);
      } else {
        await cache.upsert(me, kind, id, json, scopeId: scope ?? '');
      }
    }

    switch (change.table) {
      case 'organization_members':
        await _applyMember(me, change, id);
      case 'invitations':
        if (isDelete) {
          await cache.remove(me, CacheKind.invitation, id);
          await cache.remove(me, CacheKind.myInvitation, id);
          return;
        }
        final invitation = Invitation.fromJson(change.record);
        final orgName = (await cache.readOne(
          me,
          CacheKind.organization,
          invitation.organizationId,
          Organization.fromJson,
        ))?.name;
        final json = invitation.withOrganizationName(orgName).toJson();
        if (await _isCachedOrg(me, invitation.organizationId)) {
          await cache.upsert(
            me,
            CacheKind.invitation,
            id,
            json,
            scopeId: invitation.organizationId,
          );
        }
        if (invitation.invitedUserId == me) {
          await cache.upsert(me, CacheKind.myInvitation, id, json);
          if (invitation.status == InvitationStatus.accepted) {
            await organizations.refreshOrganizations();
          }
        }
      case 'notifications':
        await upsertOrRemove(
          CacheKind.notification,
          '',
          isDelete
              ? const {}
              : AppNotification.fromJson(change.record).toJson(),
        );
      case 'calendar_events':
        if (!isDelete &&
            !await _isCachedOrg(me, row['organization_id'] as String?)) {
          return;
        }
        await upsertOrRemove(
          CacheKind.event,
          row['organization_id'] as String?,
          isDelete ? const {} : CalendarEvent.fromJson(change.record).toJson(),
        );
      case 'event_assignments':
        if (!isDelete &&
            !await _isCachedOrg(me, row['organization_id'] as String?)) {
          return;
        }
        await upsertOrRemove(
          CacheKind.assignment,
          row['organization_id'] as String?,
          isDelete
              ? const {}
              : EventAssignment.fromJson(change.record).toJson(),
        );
    }
  }

  Future<bool> _isCachedOrg(String me, String? organizationId) async {
    if (organizationId == null) return false;
    return await cache.readOne(
          me,
          CacheKind.organization,
          organizationId,
          Organization.fromJson,
        ) !=
        null;
  }

  Future<void> _applyMember(String me, BackendChange change, String id) async {
    final cached = await cache.readOne(
      me,
      CacheKind.member,
      id,
      OrganizationMember.fromJson,
    );
    if (change.type == BackendChangeType.delete) {
      await cache.remove(me, CacheKind.member, id);
      if (cached == null) return;
      // Band memberships go with the member.
      final links = await cache.read(
        me,
        CacheKind.bandMember,
        BandMember.fromJson,
        scopeId: cached.organizationId,
      );
      for (final link in links.where((l) => l.memberId == id)) {
        await cache.remove(me, CacheKind.bandMember, link.id);
      }
      // My own membership vanished: I left or was removed.
      if (cached.userId == me) await organizations.refreshOrganizations();
      return;
    }
    final member = OrganizationMember.fromJson(change.record);
    if (!await _isCachedOrg(me, member.organizationId) && member.userId != me) {
      return;
    }
    final merged = member.withProfileOf(cached);
    await cache.upsert(
      me,
      CacheKind.member,
      id,
      merged.toJson(),
      scopeId: member.organizationId,
    );
    // A new member has no cached profile yet: fetch it with the list.
    if (merged.username == null) {
      await organizations.refreshMembers(member.organizationId);
    }
    if (member.userId == me) await organizations.refreshOrganizations();
  }
}
