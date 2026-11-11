import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/organizations/domain/entities/invites.dart';
import 'package:battuta/features/organizations/domain/entities/notification.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile', () {
    test('maps JSON and reports deactivation', () {
      final json = {
        'id': 'u1',
        'username': 'jane',
        'display_name': 'Jane',
        'avatar_url': null,
        'deactivated_at': '2026-11-10T10:00:00+00:00',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.isDeactivated, isTrue);
      expect(UserProfile.fromJson(profile.toJson()), profile);
      expect(
        UserProfile.fromJson({...json, 'deactivated_at': null}).isDeactivated,
        isFalse,
      );
    });
  });

  group('Organization', () {
    test('round trips with role and archive state', () {
      final org = Organization.fromJson({
        'id': 'o1',
        'name': 'Grace Church',
        'created_by': 'u1',
        'archived_at': '2026-11-01T00:00:00Z',
        'created_at': '2026-10-01T00:00:00Z',
        'my_role': 'admin',
      });
      expect(org.isArchived, isTrue);
      expect(org.isAdmin, isTrue);
      expect(Organization.fromJson(org.toJson()), org);
    });

    test('role defaults to unknown when the RPC row has none', () {
      final org = Organization.fromJson({'id': 'o1', 'name': 'X'});
      expect(org.myRole, isNull);
      expect(org.isAdmin, isFalse);
    });
  });

  group('OrganizationMember', () {
    final row = {
      'id': 'm1',
      'organization_id': 'o1',
      'user_id': 'u1',
      'role': 'member',
      'instruments': ['piano', 'voice'],
      'min_pitch': 'C3',
      'max_pitch': 'G5',
      'notes': null,
      'deactivated_at': null,
    };

    test('reads the embedded profile', () {
      final member = OrganizationMember.fromJson({
        ...row,
        'profiles': {
          'username': 'jane',
          'display_name': 'Jane',
          'avatar_url': null,
        },
      });
      expect(member.username, 'jane');
      expect(member.instruments, ['piano', 'voice']);
      expect(member.isActive, isTrue);
      expect(OrganizationMember.fromJson(member.toJson()), member);
    });

    test('keeps a cached profile when the row has none', () {
      final cached = OrganizationMember.fromJson({
        ...row,
        'username': 'jane',
        'display_name': 'Jane',
      });
      final fresh = OrganizationMember.fromJson({...row, 'role': 'admin'});
      final merged = fresh.withProfileOf(cached);
      expect(merged.role, OrganizationRole.admin);
      expect(merged.displayName, 'Jane');
    });
  });

  group('Bands and archive', () {
    test('Band applies the stage amber default', () {
      final band = Band.fromJson({
        'id': 'b1',
        'organization_id': 'o1',
        'name': 'Worship',
      });
      expect(band.colorValue, 0xFFE5A93C);
      expect(Band.fromJson(band.toJson()), band);
    });

    test('ArchiveRequest reads embedded approvals', () {
      final request = ArchiveRequest.fromJson({
        'organization_id': 'o1',
        'requested_by': 'u1',
        'requested_at': '2026-11-10T10:00:00Z',
        'organization_archive_approvals': [
          {'user_id': 'u1', 'approved_at': '2026-11-10T10:00:00Z'},
        ],
      });
      expect(request.isApprovedBy('u1'), isTrue);
      expect(request.isApprovedBy('u2'), isFalse);
      expect(ArchiveRequest.fromJson(request.toJson()), request);
    });
  });

  group('Invites', () {
    final now = DateTime.utc(2026, 11, 10, 12);
    InviteLink link({
      DateTime? expiresAt,
      int? maxUses,
      int useCount = 0,
      String? revokedAt,
    }) => InviteLink.fromJson({
      'id': 'l1',
      'organization_id': 'o1',
      'token': 'a' * 64,
      'expires_at': (expiresAt ?? now.add(const Duration(days: 1)))
          .toIso8601String(),
      'max_uses': maxUses,
      'use_count': useCount,
      'revoked_at': revokedAt,
    });

    test('is usable until revoked, expired or used up', () {
      expect(link().isUsable(now), isTrue);
      expect(link(revokedAt: '2026-11-10T00:00:00Z').isUsable(now), isFalse);
      expect(
        link(expiresAt: now.subtract(const Duration(seconds: 1))).isUsable(now),
        isFalse,
      );
      expect(link(maxUses: 2, useCount: 2).isUsable(now), isFalse);
      expect(link(maxUses: 2, useCount: 1).isUsable(now), isTrue);
    });

    test('link JSON round trip', () {
      final l = link(maxUses: 3);
      expect(InviteLink.fromJson(l.toJson()), l);
    });

    test('Invitation parses status and embedded organization name', () {
      final invitation = Invitation.fromJson({
        'id': 'i1',
        'organization_id': 'o1',
        'invited_user_id': 'u2',
        'status': 'declined',
        'organizations': {'name': 'Grace Church'},
      });
      expect(invitation.status, InvitationStatus.declined);
      expect(invitation.isPending, isFalse);
      expect(invitation.organizationName, 'Grace Church');
      expect(Invitation.fromJson(invitation.toJson()), invitation);
    });
  });

  group('AppNotification', () {
    test('parses known types and keeps unknown ones', () {
      final known = AppNotification.fromJson({
        'id': 'n1',
        'recipient_id': 'u1',
        'type': 'event_assigned',
        'payload': {'event_title': 'Sunday'},
      });
      expect(known.type, NotificationType.eventAssigned);
      expect(known.payload['event_title'], 'Sunday');
      expect(known.isRead, isFalse);

      final future = AppNotification.fromJson({
        'id': 'n2',
        'recipient_id': 'u1',
        'type': 'brand_new_type',
      });
      expect(future.type, NotificationType.unknown);
      expect(future.rawType, 'brand_new_type');
      expect(AppNotification.fromJson(future.toJson()), future);
    });

    test('every documented type has a case', () {
      const documented = [
        'invitation',
        'role_changed',
        'removed',
        'member_profile_edited',
        'event_assigned',
        'event_unassigned',
        'assignment_declined',
        'archive_requested',
        'archive_cancelled',
        'archive_completed',
        'song_version_forked',
        'song_merge_requested',
        'song_merge_accepted',
        'song_merge_declined',
      ];
      for (final type in documented) {
        expect(
          NotificationType.parse(type),
          isNot(NotificationType.unknown),
          reason: type,
        );
      }
    });

    test('markRead keeps the first read time', () {
      final n = AppNotification.fromJson({
        'id': 'n1',
        'recipient_id': 'u1',
        'type': 'removed',
      });
      final first = n.markRead(DateTime.utc(2026, 1, 1));
      expect(
        first.markRead(DateTime.utc(2026, 2, 1)).readAt,
        DateTime.utc(2026, 1, 1),
      );
    });
  });

  group('Schedule entities', () {
    test('CalendarEvent round trips and exposes the local calendar day', () {
      final event = CalendarEvent.fromJson({
        'id': 'e1',
        'organization_id': 'o1',
        'title': 'Sunday service',
        'date_time': '2026-11-15T00:00:00+00:00',
      });
      expect(event.dateTime.isUtc, isTrue);
      expect(CalendarEvent.fromJson(event.toJson()), event);
      final local = event.dateTime.toLocal();
      expect(event.localDay, DateTime(local.year, local.month, local.day));
      expect(event.toWriteJson().containsKey('created_by'), isFalse);
    });

    test('RecurringSchedule round trip', () {
      final s = RecurringSchedule.fromJson({
        'id': 's1',
        'organization_id': 'o1',
        'title': 'Weekly',
        'day_of_week': 3,
        'is_active': false,
      });
      expect(s.dayOfWeek, 3);
      expect(s.isActive, isFalse);
      expect(RecurringSchedule.fromJson(s.toJson()), s);
    });

    test('EventAssignment keeps a null member and the response', () {
      final a = EventAssignment.fromJson({
        'id': 'a1',
        'organization_id': 'o1',
        'event_id': 'e1',
        'instrument': 'piano',
        'member_id': null,
        'response': 'declined',
        'decline_reason': 'sick',
      });
      expect(a.memberId, isNull);
      expect(a.response, AssignmentResponse.declined);
      expect(EventAssignment.fromJson(a.toJson()), a);
    });

    test('absence dates are calendar days and round trip across year end', () {
      final absence = MemberAbsence.fromJson({
        'id': 'x1',
        'organization_id': 'o1',
        'member_id': 'm1',
        'starts_on': '2026-12-28',
        'ends_on': '2027-01-03',
      });
      expect(absence.startsOn, DateTime(2026, 12, 28));
      expect(absence.toWriteJson()['ends_on'], '2027-01-03');
      expect(MemberAbsence.fromJson(absence.toJson()), absence);

      expect(absence.covers(DateTime(2026, 12, 31, 23, 59)), isTrue);
      expect(absence.covers(DateTime(2027, 1, 1)), isTrue);
      expect(absence.covers(DateTime(2027, 1, 3, 18)), isTrue);
      expect(absence.covers(DateTime(2027, 1, 4)), isFalse);
      expect(absence.covers(DateTime(2026, 12, 27, 23, 59)), isFalse);
    });

    test('absence across a month boundary and leap day', () {
      final absence = MemberAbsence(
        id: 'x',
        organizationId: 'o',
        memberId: 'm',
        startsOn: DateTime(2028, 2, 28),
        endsOn: DateTime(2028, 3, 1),
      );
      expect(absence.covers(DateTime(2028, 2, 29)), isTrue);
      expect(absence.toWriteJson()['starts_on'], '2028-02-28');
    });

    test('coversEvent uses the device time zone day of the event', () {
      final event = CalendarEvent(
        id: 'e',
        organizationId: 'o',
        title: 'Late',
        dateTime: DateTime(2026, 11, 14, 23, 30).toUtc(), // local 23:30
      );
      final absence = MemberAbsence(
        id: 'x',
        organizationId: 'o',
        memberId: 'm',
        startsOn: DateTime(2026, 11, 14),
        endsOn: DateTime(2026, 11, 14),
      );
      expect(absence.coversEvent(event), isTrue);
      final next = CalendarEvent(
        id: 'e2',
        organizationId: 'o',
        title: 'Midnight',
        dateTime: DateTime(2026, 11, 15).toUtc(), // local midnight
      );
      expect(absence.coversEvent(next), isFalse);
    });

    test('newEntityId returns distinct UUID v4 values', () {
      final ids = {for (var i = 0; i < 50; i++) newEntityId()};
      expect(ids.length, 50);
      expect(
        ids.first,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('AvailableMember parses the RPC row', () {
      final m = AvailableMember.fromJson({
        'member_id': 'm1',
        'user_id': 'u1',
        'username': 'jane',
        'display_name': 'Jane',
      });
      expect(m.username, 'jane');
    });
  });
}
