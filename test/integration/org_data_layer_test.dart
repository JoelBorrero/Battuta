/// End-to-end tests of the organization data layer against the local Supabase
/// stack, with real sign-ups (admin, member, outsider).
///
///   supabase db reset
///   flutter test --tags supabase --run-skipped
@Tags(['supabase'])
library;

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/data/organizations_local_cache.dart';
import 'package:battuta/features/organizations/domain/entities/invites.dart';
import 'package:battuta/features/organizations/domain/entities/notification.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/stack.dart';
import 'support/test_user.dart';

void main() {
  StackConfig? stack;
  late TestUser admin;
  late TestUser member;
  late TestUser outsider;
  final created = <TestUser>[];

  setUpAll(() async {
    stack = await resolveStack();
    if (stack == null) return;
    admin = await TestUser.signUp(stack!, 'admin');
    created.add(admin);
    member = await TestUser.signUp(stack!, 'member');
    created.add(member);
    outsider = await TestUser.signUp(stack!, 'outsider');
    created.add(outsider);
  });

  tearDownAll(() async {
    for (final user in created) {
      await user.dispose();
    }
  });

  /// Registers a test that is skipped (with a clear message) when the stack is down.
  void itest(String name, Future<void> Function() body) {
    test(name, () async {
      if (stack == null) {
        markTestSkipped(
          'Supabase stack not available: set SUPABASE_TEST_URL / '
          'SUPABASE_TEST_ANON_KEY or run `supabase start`.',
        );
        return;
      }
      await body();
    });
  }

  /// Admin creates an organization and the member joins it by invite link.
  Future<Organization> orgWithMember() async {
    final org = ok(await admin.orgs.createOrganization('Org ${DateTime.now().microsecondsSinceEpoch}'));
    final link = ok(await admin.orgs.createInviteLink(org.id));
    ok(await member.orgs.joinWithInviteLink(link.token));
    return org;
  }

  group('accounts', () {
    itest('sign-up created profiles with the chosen username', () async {
      final profile = await admin.auth.fetchMyProfile();
      expect(profile!.username, admin.username);
      expect(profile.displayName, admin.displayName);
      expect(profile.isDeactivated, isFalse);
    });

    itest('username availability is checked case-insensitively', () async {
      expect(await outsider.auth.isUsernameAvailable(admin.username.toUpperCase()), isFalse);
      expect(await outsider.auth.isUsernameAvailable('it_free_${admin.username.substring(admin.username.length - 8)}'), isTrue);
    });

    itest('a duplicate username or a malformed one is rejected at sign-up', () async {
      final other = await TestUser.signUp(stack!, 'dup');
      addTearDown(other.dispose);
      await expectLater(
        TestUser.signUp(stack!, 'clone', username: other.username.toUpperCase()),
        throwsA(
          isA<Failure>().having(
            (f) => f.errorCode,
            'errorCode',
            BackendErrorCode.usernameTaken,
          ),
        ),
      );
      await expectLater(
        TestUser.signUp(stack!, 'bad', username: 'no'),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.errorCode,
            'errorCode',
            BackendErrorCode.invalidUsername,
          ),
        ),
      );
    });

    itest('searching profiles finds people by username, not the caller', () async {
      final found = ok(await outsider.orgs.searchProfiles(admin.username.substring(0, 12)));
      expect(found.map((p) => p.username), contains(admin.username));
      final self = ok(await outsider.orgs.searchProfiles(outsider.username));
      expect(self.map((p) => p.username), isNot(contains(outsider.username)));
    });
  });

  group('organizations and invites', () {
    itest('create organization, invite link join, roles and members', () async {
      final org = ok(await admin.orgs.createOrganization('Grace Church'));
      expect(org.myRole, OrganizationRole.admin);

      final link = ok(await admin.orgs.createInviteLink(org.id, maxUses: 5));
      expect(link.token, hasLength(64));
      expect(link.isUsable(DateTime.now().toUtc()), isTrue);

      final joined = ok(await member.orgs.joinWithInviteLink(link.token));
      expect(joined.role, OrganizationRole.member);
      // Joining twice is idempotent.
      ok(await member.orgs.joinWithInviteLink(link.token));

      final myOrgs = await member.orgs.watchOrganizations().first;
      expect(myOrgs.map((o) => o.id), contains(org.id));
      expect(myOrgs.firstWhere((o) => o.id == org.id).myRole, OrganizationRole.member);

      ok(await admin.orgs.refreshMembers(org.id));
      final members = await admin.orgs.watchMembers(org.id).first;
      expect(members.map((m) => m.username), containsAll([admin.username, member.username]));

      // Outsider sees nothing of this organization.
      ok(await outsider.orgs.refreshOrganizations());
      expect((await outsider.orgs.watchOrganizations().first).map((o) => o.id), isNot(contains(org.id)));
    });

    itest('revoked, expired and used-up links fail with typed codes', () async {
      final org = ok(await admin.orgs.createOrganization('Links'));
      final revoked = ok(await admin.orgs.createInviteLink(org.id));
      ok(await admin.orgs.revokeInviteLink(org.id, revoked.id));
      expect(failed(await outsider.orgs.joinWithInviteLink(revoked.token)), BackendErrorCode.inviteRevoked);

      final once = ok(await admin.orgs.createInviteLink(org.id, maxUses: 1));
      ok(await member.orgs.joinWithInviteLink(once.token));
      expect(failed(await outsider.orgs.joinWithInviteLink(once.token)), BackendErrorCode.inviteUsedUp);

      expect(failed(await outsider.orgs.joinWithInviteLink('0' * 64)), BackendErrorCode.inviteNotFound);
      expect(
        failed(await admin.orgs.createInviteLink(org.id, expiresIn: const Duration(seconds: -5))),
        BackendErrorCode.invalidExpiry,
      );
    });

    itest('a member cannot use admin actions', () async {
      final org = await orgWithMember();
      expect(failed(await member.orgs.createInviteLink(org.id)), BackendErrorCode.notAdmin);
      ok(await member.orgs.refreshMembers(org.id));
      final adminRow = (await member.orgs.watchMembers(org.id).first).firstWhere((m) => m.userId == admin.id);
      expect(
        failed(await member.orgs.setMemberRole(org.id, adminRow.id, OrganizationRole.member)),
        isIn([BackendErrorCode.notAdmin, BackendErrorCode.permissionDenied]),
      );
    });

    itest('invite by username: accept and decline', () async {
      final org = ok(await admin.orgs.createOrganization('Invites'));

      final first = ok(await admin.orgs.inviteUserByUsername(org.id, ' ${member.username.toUpperCase()} '));
      expect(first.isPending, isTrue);
      expect(failed(await admin.orgs.inviteUserByUsername(org.id, member.username)), BackendErrorCode.alreadyInvited);
      expect(failed(await admin.orgs.inviteUserByUsername(org.id, admin.username)), BackendErrorCode.cannotInviteSelf);
      expect(failed(await admin.orgs.inviteUserByUsername(org.id, 'nobody_here_xyz')), BackendErrorCode.userNotFound);

      ok(await member.orgs.refreshMyInvitations());
      var mine = await member.orgs.watchMyInvitations().first;
      final received = mine.firstWhere((i) => i.id == first.id);
      expect(received.organizationName, 'Invites');

      ok(await member.orgs.respondToInvitation(received, accept: true));
      expect((await member.orgs.watchOrganizations().first).map((o) => o.id), contains(org.id));

      // Decline path with another user.
      final second = ok(await admin.orgs.inviteUserByUsername(org.id, outsider.username));
      ok(await outsider.orgs.refreshMyInvitations());
      mine = await outsider.orgs.watchMyInvitations().first;
      final toDecline = mine.firstWhere((i) => i.id == second.id);
      final declined = ok(await outsider.orgs.respondToInvitation(toDecline, accept: false));
      expect(declined.status, InvitationStatus.declined);
      expect((await outsider.orgs.watchOrganizations().first).map((o) => o.id), isNot(contains(org.id)));
      expect(
        failed(await outsider.orgs.respondToInvitation(toDecline, accept: true)),
        BackendErrorCode.invitationNotPending,
      );
    });

    itest('cancelling an invitation', () async {
      final org = ok(await admin.orgs.createOrganization('Cancel'));
      final inv = ok(await admin.orgs.inviteUserByUsername(org.id, outsider.username));
      final cancelled = ok(await admin.orgs.cancelInvitation(org.id, inv.id));
      expect(cancelled.status, InvitationStatus.cancelled);
    });

    itest('role change, last admin protection, remove and leave', () async {
      final org = await orgWithMember();
      ok(await admin.orgs.refreshMembers(org.id));
      final rows = await admin.orgs.watchMembers(org.id).first;
      final adminRow = rows.firstWhere((m) => m.userId == admin.id);
      final memberRow = rows.firstWhere((m) => m.userId == member.id);

      expect(
        failed(await admin.orgs.setMemberRole(org.id, adminRow.id, OrganizationRole.member)),
        BackendErrorCode.lastAdmin,
      );

      final promoted = ok(await admin.orgs.setMemberRole(org.id, memberRow.id, OrganizationRole.admin));
      expect(promoted.role, OrganizationRole.admin);
      expect(promoted.username, member.username, reason: 'cached profile is kept');

      // The promoted member sees the new role after a refresh and got a notification.
      ok(await member.orgs.refreshOrganizations());
      expect((await member.orgs.watchOrganizations().first).firstWhere((o) => o.id == org.id).isAdmin, isTrue);
      ok(await member.orgs.refreshNotifications());
      final notes = await member.orgs.watchNotifications().first;
      expect(notes.map((n) => n.type), contains(NotificationType.roleChanged));

      // Member (now admin) removes the former admin, who then loses the organization.
      ok(await member.orgs.removeMember(org.id, adminRow.id));
      ok(await admin.orgs.refreshOrganizations());
      expect((await admin.orgs.watchOrganizations().first).map((o) => o.id), isNot(contains(org.id)));
      expect(await admin.cache.read(admin.id, CacheKind.band, Band.fromJson, scopeId: org.id), isEmpty);

      // The last admin cannot leave.
      expect(failed(await member.orgs.leaveOrganization(org.id)), BackendErrorCode.lastAdmin);
    });

    itest('musician profile: members edit their own, admins edit and the member is notified', () async {
      final org = await orgWithMember();
      ok(await member.orgs.refreshMembers(org.id));
      final mine = (await member.orgs.watchMembers(org.id).first).firstWhere((m) => m.userId == member.id);

      final updated = ok(await member.orgs.updateMusicianProfile(
        org.id, mine.id, instruments: ['piano', 'voice'], minPitch: 'C3', maxPitch: 'G5', notes: 'No Mondays',
      ));
      expect(updated.instruments, ['piano', 'voice']);
      expect(updated.maxPitch, 'G5');

      ok(await admin.orgs.updateMusicianProfile(org.id, mine.id, notes: 'Lead keys'));
      ok(await member.orgs.refreshNotifications());
      final notes = await member.orgs.watchNotifications().first;
      final edited = notes.firstWhere((n) => n.type == NotificationType.memberProfileEdited);
      expect(edited.payload['changed_fields'], contains('notes'));
    });
  });

  group('bands', () {
    itest('admins manage bands and members; plain members cannot', () async {
      final org = await orgWithMember();
      ok(await admin.orgs.refreshMembers(org.id));
      final memberRow = (await admin.orgs.watchMembers(org.id).first).firstWhere((m) => m.userId == member.id);

      final band = ok(await admin.orgs.createBand(org.id, 'Worship', description: 'Sunday band', colorValue: 0xFF336699));
      ok(await admin.orgs.updateBand(Band(
        id: band.id, organizationId: org.id, name: 'Worship Team', colorValue: band.colorValue,
      )));
      final link = ok(await admin.orgs.addBandMember(org.id, band.id, memberRow.id));

      ok(await member.orgs.refreshBands(org.id));
      expect((await member.orgs.watchBands(org.id).first).single.name, 'Worship Team');
      expect((await member.orgs.watchBandMembers(org.id).first).single.memberId, memberRow.id);

      expect(
        failed(await member.orgs.createBand(org.id, 'Rogue')),
        isIn([BackendErrorCode.permissionDenied, BackendErrorCode.notAdmin]),
      );

      ok(await admin.orgs.removeBandMember(org.id, link.id));
      ok(await admin.orgs.deleteBand(org.id, band.id));
      expect(await admin.orgs.watchBands(org.id).first, isEmpty);
    });

    itest('an invite link into a band adds the joining member to it', () async {
      final org = ok(await admin.orgs.createOrganization('Bands via link'));
      final band = ok(await admin.orgs.createBand(org.id, 'Choir'));
      final link = ok(await admin.orgs.createInviteLink(org.id, bandId: band.id));
      ok(await member.orgs.joinWithInviteLink(link.token));
      ok(await admin.orgs.refreshBands(org.id));
      expect((await admin.orgs.watchBandMembers(org.id).first), hasLength(1));
    });
  });

  group('events, assignments and absences', () {
    itest('event, assignment, decline, reassign and absences', () async {
      final org = await orgWithMember();
      ok(await admin.orgs.refreshMembers(org.id));
      final memberRow = (await admin.orgs.watchMembers(org.id).first).firstWhere((m) => m.userId == member.id);

      final event = ok(await admin.schedules.saveEvent(CalendarEvent(
        id: newEntityId(),
        organizationId: org.id,
        title: 'Sunday service',
        dateTime: DateTime.now().toUtc().add(const Duration(days: 3)),
        location: 'Main hall',
      )));
      // Update through the same call (upsert).
      ok(await admin.schedules.saveEvent(CalendarEvent(
        id: event.id, organizationId: org.id, title: 'Sunday service 10am',
        dateTime: event.dateTime, location: 'Main hall',
      )));
      expect((await admin.schedules.watchEvents(org.id).first).single.title, 'Sunday service 10am');

      final schedule = ok(await admin.schedules.saveSchedule(RecurringSchedule(
        id: newEntityId(), organizationId: org.id, title: 'Weekly rehearsal', dayOfWeek: 4,
      )));
      expect(schedule.dayOfWeek, 4);

      final assignment = ok(await admin.schedules.assign(
        organizationId: org.id, eventId: event.id, memberId: memberRow.id, instrument: 'piano',
      ));
      expect(assignment.response, AssignmentResponse.pending);

      // The assigned member sees it and declines it.
      ok(await member.schedules.refreshOrganization(org.id));
      final seen = await member.schedules.watchAssignments(org.id).first;
      expect(seen.single.id, assignment.id);
      expect(
        failed(await admin.schedules.respond(org.id, assignment.id, AssignmentResponse.accepted)),
        isIn([BackendErrorCode.notAssignee, BackendErrorCode.permissionDenied]),
      );
      final declined = ok(await member.schedules.respond(
        org.id, assignment.id, AssignmentResponse.declined, declineReason: 'Out of town',
      ));
      expect(declined.response, AssignmentResponse.declined);
      expect(declined.declineReason, 'Out of town');
      expect(declined.respondedAt, isNotNull);

      // The admin is notified about the decline.
      ok(await admin.orgs.refreshNotifications());
      final adminNotes = await admin.orgs.watchNotifications().first;
      expect(adminNotes.map((n) => n.type), contains(NotificationType.assignmentDeclined));

      // Absence across the year boundary, then availability lookup.
      final absence = ok(await member.schedules.saveAbsence(MemberAbsence(
        id: newEntityId(),
        organizationId: org.id,
        memberId: memberRow.id,
        startsOn: DateTime(2026, 12, 29),
        endsOn: DateTime(2027, 1, 4),
        note: 'Holidays',
      )));
      expect(absence.startsOn, DateTime(2026, 12, 29));
      expect(absence.endsOn, DateTime(2027, 1, 4));
      expect(absence.covers(DateTime(2027, 1, 1)), isTrue);

      final availableDuring = ok(await admin.schedules.membersAvailableOn(org.id, DateTime(2027, 1, 1)));
      expect(availableDuring.map((m) => m.memberId), isNot(contains(memberRow.id)));
      final availableAfter = ok(await admin.schedules.membersAvailableOn(org.id, DateTime(2027, 1, 5)));
      expect(availableAfter.map((m) => m.memberId), contains(memberRow.id));

      // Admins read absences too; deletion goes through the repository.
      ok(await admin.schedules.refreshOrganization(org.id));
      expect((await admin.schedules.watchAbsences(org.id).first).single.note, 'Holidays');
      ok(await member.schedules.deleteAbsence(org.id, absence.id));

      ok(await admin.schedules.unassign(org.id, assignment.id));
      ok(await admin.schedules.deleteSchedule(org.id, schedule.id));
      ok(await admin.schedules.deleteEvent(org.id, event.id));
      expect(await admin.schedules.watchEvents(org.id).first, isEmpty);
    });

    itest('a member cannot create events', () async {
      final org = await orgWithMember();
      final result = await member.schedules.saveEvent(CalendarEvent(
        id: newEntityId(), organizationId: org.id, title: 'Rogue', dateTime: DateTime.now().toUtc(),
      ));
      expect(failed(result), isIn([BackendErrorCode.permissionDenied, BackendErrorCode.notAdmin]));
    });

    itest('events at local midnight keep their instant (UTC) round trip', () async {
      final org = ok(await admin.orgs.createOrganization('Time zones'));
      final midnight = DateTime(2027, 3, 1); // local midnight
      final saved = ok(await admin.schedules.saveEvent(CalendarEvent(
        id: newEntityId(), organizationId: org.id, title: 'Midnight', dateTime: midnight.toUtc(),
      )));
      expect(saved.dateTime, midnight.toUtc());
      expect(saved.localDay, DateTime(2027, 3, 1));
    });
  });

  group('realtime', () {
    itest('a notification and an assigned event reach the cache without a manual refresh', () async {
      final org = await orgWithMember();
      ok(await member.orgs.refreshOrganizations());
      ok(await admin.orgs.refreshMembers(org.id));
      final memberRow = (await admin.orgs.watchMembers(org.id).first).firstWhere((m) => m.userId == member.id);

      await member.coordinator.start();
      addTearDown(member.coordinator.stop);
      await Future<void>.delayed(const Duration(seconds: 2)); // channel subscription

      final event = ok(await admin.schedules.saveEvent(CalendarEvent(
        id: newEntityId(), organizationId: org.id, title: 'Realtime service',
        dateTime: DateTime.now().toUtc().add(const Duration(days: 2)),
      )));
      ok(await admin.schedules.assign(
        organizationId: org.id, eventId: event.id, memberId: memberRow.id, instrument: 'drums',
      ));

      await eventually(
        () async => (await member.cache.read(
          member.id, CacheKind.notification, AppNotification.fromJson,
        )).any((n) => n.type == NotificationType.eventAssigned),
        reason: 'event_assigned notification via realtime',
      );
      await eventually(
        () async => (await member.cache.read(
          member.id, CacheKind.event, CalendarEvent.fromJson, scopeId: org.id,
        )).any((e) => e.id == event.id),
        reason: 'event via realtime',
      );
      await eventually(
        () async => (await member.cache.read(
          member.id, CacheKind.assignment, EventAssignment.fromJson, scopeId: org.id,
        )).any((a) => a.instrument == 'drums'),
        reason: 'assignment via realtime',
      );
    });
  });

  group('archiving', () {
    itest('needs every admin; afterwards the organization is read-only', () async {
      final org = await orgWithMember();
      ok(await admin.orgs.refreshMembers(org.id));
      final memberRow = (await admin.orgs.watchMembers(org.id).first).firstWhere((m) => m.userId == member.id);
      ok(await admin.orgs.setMemberRole(org.id, memberRow.id, OrganizationRole.admin));
      ok(await member.orgs.refreshOrganizations());

      final requested = ok(await admin.orgs.requestArchive(org.id));
      expect(requested.isArchived, isFalse, reason: 'the other admin has not approved yet');
      expect(failed(await admin.orgs.requestArchive(org.id)), BackendErrorCode.archiveAlreadyRequested);

      ok(await member.orgs.refreshArchiveRequest(org.id));
      final request = await member.orgs.watchArchiveRequest(org.id).first;
      expect(request!.isApprovedBy(admin.id), isTrue);
      expect(request.isApprovedBy(member.id), isFalse);

      final done = ok(await member.orgs.approveArchive(org.id));
      expect(done.isArchived, isTrue);
      expect(done.myRole, OrganizationRole.admin);

      // Cached state: hidden by default, present when asked, writes fail fast.
      expect((await member.orgs.watchOrganizations().first).map((o) => o.id), isNot(contains(org.id)));
      expect((await member.orgs.watchOrganizations(includeArchived: true).first).map((o) => o.id), contains(org.id));
      expect(failed(await member.orgs.createBand(org.id, 'Late')), BackendErrorCode.organizationArchived);

      // The server refuses too (bypassing the client side fast path).
      final direct = await _tryRemote(() => member.orgRemote.createBand(
        Band(id: newEntityId(), organizationId: org.id, name: 'Late'),
      ));
      expect(direct, isIn([BackendErrorCode.permissionDenied, BackendErrorCode.organizationArchived]));

      expect(
        failed(await admin.orgs.createInviteLink(org.id)),
        BackendErrorCode.organizationArchived,
      );
      // Everybody can still leave an archived organization.
      ok(await admin.orgs.refreshOrganizations());
    });

    itest('any admin can cancel an open request', () async {
      final org = await orgWithMember();
      ok(await admin.orgs.refreshMembers(org.id));
      final memberRow = (await admin.orgs.watchMembers(org.id).first).firstWhere((m) => m.userId == member.id);
      ok(await admin.orgs.setMemberRole(org.id, memberRow.id, OrganizationRole.admin));

      ok(await admin.orgs.requestArchive(org.id));
      final cancelled = ok(await member.orgs.cancelArchive(org.id));
      expect(cancelled.isArchived, isFalse);
      expect(failed(await member.orgs.approveArchive(org.id)), BackendErrorCode.archiveNotRequested);
    });
  });

  group('deactivation', () {
    itest('a deactivated account is signed out, cannot sign in again and keeps its username', () async {
      final user = await TestUser.signUp(stack!, 'gone');
      addTearDown(user.dispose);
      final org = ok(await user.orgs.createOrganization('Sole'));
      // A sole member must archive the organization first.
      ok(await user.orgs.requestArchive(org.id));

      await user.auth.deactivateAccount();
      expect(user.client.auth.currentUser, isNull, reason: 'deactivation signs out');

      await expectLater(
        user.signIn(),
        throwsA(isA<Failure>().having((f) => f.errorCode, 'errorCode', BackendErrorCode.accountDeactivated)),
      );
      expect(user.client.auth.currentUser, isNull, reason: 'the new session is ended at once');

      // The username stays reserved and the account cannot be found or invited.
      expect(await outsider.auth.isUsernameAvailable(user.username), isFalse);
      final found = ok(await outsider.orgs.searchProfiles(user.username));
      expect(found, isEmpty);
    });

    itest('a last admin with other members is blocked from deactivating', () async {
      final user = await TestUser.signUp(stack!, 'lastadm');
      addTearDown(user.dispose);
      final org = ok(await user.orgs.createOrganization('Blocked'));
      final link = ok(await user.orgs.createInviteLink(org.id));
      ok(await member.orgs.joinWithInviteLink(link.token));

      Object? error;
      try {
        await user.auth.deactivateAccount();
      } on Failure catch (f) {
        error = f.errorCode;
      }
      expect(error, BackendErrorCode.lastAdmin);
      expect(user.client.auth.currentUser, isNotNull);
    });
  });

  group('offline behaviour with a real client', () {
    itest('without a session writes return notSignedIn and reads are empty', () async {
      final fresh = await TestUser.signUp(stack!, 'fresh');
      addTearDown(fresh.dispose);
      await fresh.auth.signOut();
      expect(failed(await fresh.orgs.createOrganization('X')), BackendErrorCode.notSignedIn);
      expect(await fresh.orgs.watchOrganizations().first, isEmpty);
    });
  });
}

Future<BackendErrorCode?> _tryRemote(Future<Object?> Function() call) async {
  try {
    await call();
    return null;
  } on Failure catch (f) {
    return f.errorCode;
  }
}
