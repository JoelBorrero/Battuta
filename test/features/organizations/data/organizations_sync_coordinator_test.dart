import 'dart:async';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/data/organization_repository_impl.dart';
import 'package:battuta/features/organizations/data/organizations_local_cache.dart';
import 'package:battuta/features/organizations/data/organizations_remote_data_source.dart';
import 'package:battuta/features/organizations/data/organizations_sync_coordinator.dart';
import 'package:battuta/features/organizations/data/schedule_repository_impl.dart';
import 'package:battuta/features/organizations/domain/entities/invites.dart';
import 'package:battuta/features/organizations/domain/entities/notification.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'test_support.dart';

void main() {
  late AppDatabase db;
  late OrganizationsLocalCache cache;
  late MockOrganizationsRemote remote;
  late MockSchedulesRemote schedulesRemote;
  late FakeSession session;
  late StreamController<BackendChange> changes;
  late OrganizationsSyncCoordinator coordinator;

  const orgA = Organization(id: 'oa', name: 'Alpha');
  const orgB = Organization(id: 'ob', name: 'Beta');

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 80));

  void stubRemoteFor(List<Organization> orgs) {
    when(() => remote.myOrganizations(includeArchived: true))
        .thenAnswer((_) async => orgs);
    when(() => remote.fetchMyMemberships()).thenAnswer((_) async => []);
    when(() => remote.fetchMyInvitations()).thenAnswer((_) async => []);
    when(() => remote.fetchNotifications()).thenAnswer((_) async => []);
    when(() => remote.fetchMembers(any())).thenAnswer((_) async => []);
    when(() => remote.fetchBands(any())).thenAnswer((_) async => []);
    when(() => remote.fetchBandMembers(any())).thenAnswer((_) async => []);
    when(() => remote.fetchInvitations(any())).thenAnswer((_) async => []);
    when(() => remote.fetchArchiveRequest(any())).thenAnswer((_) async => null);
    when(() => remote.fetchInviteLinks(any())).thenAnswer((_) async => []);
    when(() => schedulesRemote.fetchEvents(any())).thenAnswer((_) async => []);
    when(() => schedulesRemote.fetchSchedules(any()))
        .thenAnswer((_) async => []);
    when(() => schedulesRemote.fetchAssignments(any()))
        .thenAnswer((_) async => []);
    when(() => schedulesRemote.fetchAbsences(any()))
        .thenAnswer((_) async => []);
  }

  setUp(() {
    db = newMemoryDb();
    session = FakeSession('a');
    cache = newCache(db, session);
    remote = MockOrganizationsRemote();
    schedulesRemote = MockSchedulesRemote();
    changes = StreamController<BackendChange>.broadcast();
    when(() => remote.changes()).thenAnswer((_) => changes.stream);
    stubRemoteFor([orgA]);
    coordinator = OrganizationsSyncCoordinator(
      session: session,
      cache: cache,
      remote: remote,
      organizations: OrganizationRepositoryImpl(
        remote: remote,
        cache: cache,
        session: session,
      ),
      schedules: ScheduleRepositoryImpl(
        remote: schedulesRemote,
        cache: cache,
        session: session,
      ),
    );
  });
  tearDown(() async {
    await coordinator.stop();
    await changes.close();
    await db.close();
  });

  Future<List<String>> orgIds(String account) async => (await cache.read(
    account,
    CacheKind.organization,
    Organization.fromJson,
  )).map((o) => o.id).toList()..sort();

  group('account changes', () {
    test(
      'start clears every other account and refreshes the current one',
      () async {
        await cache.upsert(
          'stale',
          CacheKind.organization,
          'zz',
          const Organization(id: 'zz', name: 'Z').toJson(),
        );
        await coordinator.start();
        expect(await orgIds('stale'), isEmpty);
        expect(await orgIds('a'), ['oa']);
      },
    );

    test('switching account clears the previous account cache', () async {
      await coordinator.start();
      expect(await orgIds('a'), ['oa']);

      stubRemoteFor([orgB]);
      session.signIn('b');
      await settle();

      expect(await orgIds('a'), isEmpty);
      expect(await orgIds('b'), ['ob']);
    });

    test('signing out clears the cache', () async {
      await coordinator.start();
      session.signIn(null);
      await settle();
      expect(await orgIds('a'), isEmpty);
    });
  });

  test(
    'a deactivated-account realtime error signs out and clears the cache',
    () async {
      await coordinator.start();
      expect(await orgIds('a'), ['oa']);
      changes.addError(
        BackendErrorCode.accountDeactivated.failure(message: 'x'),
      );
      await settle();
      expect(session.userId, isNull);
      expect(await orgIds('a'), isEmpty);
    },
  );

  group('realtime', () {
    setUp(() async {
      await coordinator.start();
    });

    test(
      'calendar events and assignments are applied, updated and removed',
      () async {
        final eventRow = {
          'id': 'e1',
          'organization_id': 'oa',
          'title': 'Sunday',
          'date_time': '2026-11-15T09:00:00+00:00',
        };
        changes.add(
          BackendChange(
            table: 'calendar_events',
            type: BackendChangeType.insert,
            record: eventRow,
          ),
        );
        await settle();
        changes.add(
          BackendChange(
            table: 'calendar_events',
            type: BackendChangeType.update,
            record: {...eventRow, 'title': 'Sunday service'},
          ),
        );
        changes.add(
          const BackendChange(
            table: 'event_assignments',
            type: BackendChangeType.insert,
            record: {
              'id': 'a1',
              'organization_id': 'oa',
              'event_id': 'e1',
              'instrument': 'piano',
              'member_id': 'm1',
            },
          ),
        );
        await settle();

        final events = await cache.read(
          'a',
          CacheKind.event,
          CalendarEvent.fromJson,
        );
        expect(events.single.title, 'Sunday service');
        expect(
          await cache.read('a', CacheKind.assignment, EventAssignment.fromJson),
          hasLength(1),
        );

        changes.add(
          const BackendChange(
            table: 'event_assignments',
            type: BackendChangeType.delete,
            oldRecord: {'id': 'a1'},
          ),
        );
        changes.add(
          const BackendChange(
            table: 'calendar_events',
            type: BackendChangeType.delete,
            oldRecord: {'id': 'e1'},
          ),
        );
        await settle();
        expect(
          await cache.read('a', CacheKind.event, CalendarEvent.fromJson),
          isEmpty,
        );
        expect(
          await cache.read('a', CacheKind.assignment, EventAssignment.fromJson),
          isEmpty,
        );
      },
    );

    test(
      'events of an organization the user does not belong to are ignored',
      () async {
        changes.add(
          const BackendChange(
            table: 'calendar_events',
            type: BackendChangeType.insert,
            record: {
              'id': 'e9',
              'organization_id': 'other',
              'title': 'x',
              'date_time': '2026-11-15T09:00:00Z',
            },
          ),
        );
        await settle();
        expect(
          await cache.read('a', CacheKind.event, CalendarEvent.fromJson),
          isEmpty,
        );
      },
    );

    test('a notification arrives and an invitation for me is cached', () async {
      changes.add(
        const BackendChange(
          table: 'notifications',
          type: BackendChangeType.insert,
          record: {
            'id': 'n1',
            'recipient_id': 'a',
            'type': 'invitation',
            'payload': {'x': 1},
          },
        ),
      );
      changes.add(
        const BackendChange(
          table: 'invitations',
          type: BackendChangeType.insert,
          record: {
            'id': 'i1',
            'organization_id': 'oa',
            'invited_user_id': 'a',
            'status': 'pending',
          },
        ),
      );
      await settle();

      final notes = await cache.read(
        'a',
        CacheKind.notification,
        AppNotification.fromJson,
      );
      expect(notes.single.type, NotificationType.invitation);
      final mine = await cache.read(
        'a',
        CacheKind.myInvitation,
        Invitation.fromJson,
      );
      expect(mine.single.organizationName, 'Alpha');
    });

    test('member insert is cached with the profile kept on update', () async {
      await cache.upsert(
        'a',
        CacheKind.member,
        'm1',
        const OrganizationMember(
          id: 'm1',
          organizationId: 'oa',
          userId: 'u1',
          username: 'jane',
          displayName: 'Jane',
        ).toJson(),
        scopeId: 'oa',
      );
      changes.add(
        const BackendChange(
          table: 'organization_members',
          type: BackendChangeType.update,
          record: {
            'id': 'm1',
            'organization_id': 'oa',
            'user_id': 'u1',
            'role': 'admin',
          },
        ),
      );
      await settle();
      final members = await cache.read(
        'a',
        CacheKind.member,
        OrganizationMember.fromJson,
      );
      expect(members.single.role, OrganizationRole.admin);
      expect(members.single.displayName, 'Jane');
    });

    test(
      'my own membership deleted: the organization leaves the cache',
      () async {
        await cache.upsert(
          'a',
          CacheKind.member,
          'mine',
          const OrganizationMember(
            id: 'mine',
            organizationId: 'oa',
            userId: 'a',
          ).toJson(),
          scopeId: 'oa',
        );
        stubRemoteFor([]); // the server no longer lists oa
        changes.add(
          const BackendChange(
            table: 'organization_members',
            type: BackendChangeType.delete,
            oldRecord: {'id': 'mine'},
          ),
        );
        await settle();
        expect(await orgIds('a'), isEmpty);
      },
    );

    test(
      'resync after a reconnect refreshes everything without duplicates',
      () async {
        when(() => schedulesRemote.fetchEvents('oa')).thenAnswer(
          (_) async => [
            CalendarEvent(
              id: 'e1',
              organizationId: 'oa',
              title: 'Sunday',
              dateTime: DateTime.utc(2026, 11, 15),
            ),
          ],
        );
        changes.add(const BackendChange.resync());
        await settle();
        changes.add(const BackendChange.resync());
        await settle();

        expect(await orgIds('a'), ['oa']);
        expect(
          await cache.read('a', CacheKind.event, CalendarEvent.fromJson),
          hasLength(1),
        );
      },
    );
  });
}
