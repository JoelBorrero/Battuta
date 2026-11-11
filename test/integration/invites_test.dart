/// Invites and the inbox against the local Supabase stack: a link joined
/// through the deep-link contract, a username invitation accepted from the
/// inbox, and the assigned-event notification.
///
///   supabase db reset
///   flutter test --tags supabase --run-skipped test/integration
///
@Tags(['supabase'])
library;

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/domain/entities/invites.dart';
import 'package:battuta/features/organizations/domain/entities/notification.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/organizations/domain/services/invite_link_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/stack.dart';
import 'support/test_user.dart';

void main() {
  StackConfig? stack;
  late TestUser admin;
  late TestUser joiner;
  late TestUser invitee;
  final created = <TestUser>[];

  setUpAll(() async {
    stack = await resolveStack();
    if (stack == null) return;
    admin = await TestUser.signUp(stack!, 'invadmin');
    joiner = await TestUser.signUp(stack!, 'invjoin');
    invitee = await TestUser.signUp(stack!, 'invuser');
    created.addAll([admin, joiner, invitee]);
  });

  tearDownAll(() async {
    for (final user in created) {
      await user.dispose();
    }
  });

  test('link, username invitation and the assigned-event notification', () async {
    if (stack == null) {
      markTestSkipped(
        'Supabase stack not available: set SUPABASE_TEST_URL / '
        'SUPABASE_TEST_ANON_KEY or run `supabase start`.',
      );
      return;
    }

    final org = ok(await admin.orgs.createOrganization('Invites Org'));

    // 1. Admin creates a link; the second user opens it as a deep link. The
    // app's handler reads the token with the same parser and joins.
    final link = ok(
      await admin.orgs.createInviteLink(
        org.id,
        expiresIn: const Duration(days: 1),
        maxUses: 2,
      ),
    );
    final deepLink = Uri.parse(inviteLinkFor(link.token));
    final token = inviteTokenFromUri(deepLink);
    expect(token, link.token);
    final joined = ok(await joiner.orgs.joinWithInviteLink(token!));
    expect(joined.organizationId, org.id);
    expect(joined.role, OrganizationRole.member);
    // Opening it again is idempotent.
    ok(await joiner.orgs.joinWithInviteLink(token));

    // A revoked link is refused with its own code.
    ok(await admin.orgs.revokeInviteLink(org.id, link.id));
    expect(
      failed(await invitee.orgs.joinWithInviteLink(token)),
      BackendErrorCode.inviteRevoked,
    );

    // 2. Admin invites a third user by username (search never shows email).
    final found = ok(await admin.orgs.searchProfiles(invitee.username));
    expect(found.map((p) => p.username), contains(invitee.username));
    final invitation = ok(
      await admin.orgs.inviteUserByUsername(org.id, invitee.username),
    );
    expect(invitation.status, InvitationStatus.pending);
    expect(
      failed(await admin.orgs.inviteUserByUsername(org.id, invitee.username)),
      anyOf(BackendErrorCode.alreadyInvited, BackendErrorCode.conflict),
    );

    // Admins read the invitee's public profile with the invitation.
    ok(await admin.orgs.refreshInvitations(org.id));
    final listed = (await admin.orgs.watchInvitations(org.id).first)
        .firstWhere((i) => i.id == invitation.id);
    expect(listed.inviteeUsername, invitee.username);
    expect(listed.inviteeDisplayName, invitee.displayName);

    // The invitee sees the invitation and its notification, and accepts.
    ok(await invitee.orgs.refreshNotifications());
    ok(await invitee.orgs.refreshMyInvitations());
    final inbox = await invitee.orgs.watchNotifications().first;
    expect(
      inbox.where((n) => n.type == NotificationType.invitation),
      isNotEmpty,
    );
    final mine = (await invitee.orgs.watchMyInvitations().first)
        .where((i) => i.isPending)
        .single;
    final accepted = ok(await invitee.orgs.respondToInvitation(mine, accept: true));
    expect(accepted.status, InvitationStatus.accepted);
    expect(
      failed(await invitee.orgs.joinWithInviteLink(token)),
      BackendErrorCode.inviteRevoked,
    );
    ok(await invitee.orgs.markNotificationsRead());

    // 3. An assignment produces an inbox notification for the member.
    ok(await admin.orgs.refreshMembers(org.id));
    final members = await admin.orgs.watchMembers(org.id).first;
    final target = members.firstWhere((m) => m.userId == joiner.id);
    final event = ok(
      await admin.schedules.saveEvent(
        CalendarEvent(
          id: newEntityId(),
          organizationId: org.id,
          title: 'Sunday service',
          dateTime: DateTime.now().toUtc().add(const Duration(days: 3)),
        ),
      ),
    );
    ok(
      await admin.schedules.assign(
        organizationId: org.id,
        eventId: event.id,
        memberId: target.id,
        instrument: 'bass',
      ),
    );
    ok(await joiner.orgs.refreshNotifications());
    final joinerInbox = await joiner.orgs.watchNotifications().first;
    final assigned = joinerInbox.where(
      (n) => n.type == NotificationType.eventAssigned,
    );
    expect(assigned, isNotEmpty);
    expect(assigned.first.payload['event_title'], 'Sunday service');
    expect(assigned.first.isRead, isFalse);

    ok(await joiner.orgs.markNotificationsRead([assigned.first.id]));
    final after = await joiner.orgs.watchNotifications().first;
    expect(after.firstWhere((n) => n.id == assigned.first.id).isRead, isTrue);
  });
}
