import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/data/organizations_local_cache.dart';
import 'package:battuta/features/organizations/data/schedule_repository_impl.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'test_support.dart';

void main() {
  late AppDatabase db;
  late OrganizationsLocalCache cache;
  late MockSchedulesRemote remote;
  late ScheduleRepositoryImpl repo;

  final event = CalendarEvent(
    id: 'e1',
    organizationId: 'oa',
    title: 'Sunday',
    dateTime: DateTime.utc(2026, 11, 15, 9),
  );
  const assignment = EventAssignment(
    id: 'a1',
    organizationId: 'oa',
    eventId: 'e1',
    instrument: 'piano',
    memberId: 'm1',
  );
  final absence = MemberAbsence(
    id: 'x1',
    organizationId: 'oa',
    memberId: 'm1',
    startsOn: DateTime(2026, 12, 30),
    endsOn: DateTime(2027, 1, 2),
  );

  setUpAll(() {
    registerFallbackValue(event);
    registerFallbackValue(absence);
    registerFallbackValue(
      const RecurringSchedule(id: 's', organizationId: 'o', title: 't'),
    );
    registerFallbackValue(AssignmentResponse.pending);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() async {
    db = newMemoryDb();
    final session = FakeSession('me');
    cache = newCache(db, session);
    remote = MockSchedulesRemote();
    repo = ScheduleRepositoryImpl(
      remote: remote,
      cache: cache,
      session: session,
    );
    await cache.upsert(
      'me',
      CacheKind.organization,
      'oa',
      const Organization(id: 'oa', name: 'A').toJson(),
    );
  });
  tearDown(() => db.close());

  test('refresh caches events, schedules, assignments and absences', () async {
    when(() => remote.fetchEvents('oa')).thenAnswer((_) async => [event]);
    when(() => remote.fetchSchedules('oa')).thenAnswer(
      (_) async => [
        const RecurringSchedule(
          id: 's1',
          organizationId: 'oa',
          title: 'Weekly',
        ),
      ],
    );
    when(() => remote.fetchAssignments('oa'))
        .thenAnswer((_) async => [assignment]);
    when(() => remote.fetchAbsences('oa')).thenAnswer((_) async => [absence]);

    expect((await repo.refreshOrganization('oa')).isRight(), isTrue);

    expect((await repo.watchEvents('oa').first).single, event);
    expect((await repo.watchSchedules('oa').first).single.title, 'Weekly');
    expect((await repo.watchAssignments('oa').first).single, assignment);
    final absences = await repo.watchAbsences('oa').first;
    expect(absences.single.covers(DateTime(2027, 1, 1)), isTrue);
  });

  test(
    'offline: reads come from the cache and writes return offline',
    () async {
      await cache.upsert(
        'me',
        CacheKind.event,
        'e1',
        event.toJson(),
        scopeId: 'oa',
      );
      when(() => remote.fetchEvents('oa'))
          .thenThrow(BackendErrorCode.offline.failure());
      when(() => remote.upsertEvent(any()))
          .thenThrow(BackendErrorCode.offline.failure());
      when(() => remote.deleteEvent(any()))
          .thenThrow(BackendErrorCode.offline.failure());

      expect((await repo.watchEvents('oa').first).single.id, 'e1');
      final save = await repo.saveEvent(event);
      expect(
        save.fold((f) => f.errorCode, (_) => null),
        BackendErrorCode.offline,
      );
      final del = await repo.deleteEvent('oa', 'e1');
      expect(
        del.fold((f) => f.errorCode, (_) => null),
        BackendErrorCode.offline,
      );
      expect((await repo.watchEvents('oa').first), hasLength(1));
    },
  );

  test(
    'saveEvent and deleteEvent keep the cache in step, assignments included',
    () async {
      when(
        () => remote.upsertEvent(any()),
      ).thenAnswer((i) async => i.positionalArguments.first as CalendarEvent);
      when(() => remote.deleteEvent('e1')).thenAnswer((_) async {});
      await repo.saveEvent(event);
      await cache.upsert(
        'me',
        CacheKind.assignment,
        'a1',
        assignment.toJson(),
        scopeId: 'oa',
      );
      expect(await repo.watchEvents('oa').first, hasLength(1));

      await repo.deleteEvent('oa', 'e1');
      expect(await repo.watchEvents('oa').first, isEmpty);
      expect(await repo.watchAssignments('oa').first, isEmpty);
    },
  );

  test('archived organization: every write fails fast', () async {
    await cache.upsert(
      'me',
      CacheKind.organization,
      'oa',
      Organization(
        id: 'oa',
        name: 'A',
        archivedAt: DateTime.utc(2026),
      ).toJson(),
    );
    final results = [
      await repo.saveEvent(event),
      await repo.deleteEvent('oa', 'e1'),
      await repo.saveSchedule(
        const RecurringSchedule(id: 's', organizationId: 'oa', title: 't'),
      ),
      await repo.assign(
        organizationId: 'oa',
        eventId: 'e1',
        memberId: 'm1',
        instrument: 'piano',
      ),
      await repo.respond('oa', 'a1', AssignmentResponse.accepted),
      await repo.saveAbsence(absence),
    ];
    for (final r in results) {
      expect(
        r.fold((f) => f.errorCode, (_) => null),
        BackendErrorCode.organizationArchived,
      );
    }
    verifyNever(() => remote.upsertEvent(any()));
  });

  test('assign, decline and unassign', () async {
    when(
      () => remote.assign(
        organizationId: 'oa',
        eventId: 'e1',
        memberId: 'm1',
        instrument: 'piano',
      ),
    ).thenAnswer((_) async => assignment);
    when(
      () => remote.respond(
        'a1',
        AssignmentResponse.declined,
        declineReason: 'sick',
      ),
    ).thenAnswer(
      (_) async => const EventAssignment(
        id: 'a1',
        organizationId: 'oa',
        eventId: 'e1',
        instrument: 'piano',
        memberId: 'm1',
        response: AssignmentResponse.declined,
        declineReason: 'sick',
      ),
    );
    when(() => remote.unassign('a1')).thenAnswer((_) async {});

    await repo.assign(
      organizationId: 'oa',
      eventId: 'e1',
      memberId: 'm1',
      instrument: 'piano',
    );
    expect(
      (await repo.watchAssignments('oa').first).single.response,
      AssignmentResponse.pending,
    );

    await repo.respond(
      'oa',
      'a1',
      AssignmentResponse.declined,
      declineReason: 'sick',
    );
    final declined = (await repo.watchAssignments('oa').first).single;
    expect(declined.response, AssignmentResponse.declined);
    expect(declined.declineReason, 'sick');

    await repo.unassign('oa', 'a1');
    expect(await repo.watchAssignments('oa').first, isEmpty);
  });

  test('a server permission error is surfaced typed', () async {
    when(
      () => remote.respond(
        any(),
        any(),
        declineReason: any(named: 'declineReason'),
      ),
    ).thenThrow(BackendErrorCode.notAssignee.failure());
    final result = await repo.respond('oa', 'a1', AssignmentResponse.accepted);
    expect(
      result.fold((f) => f.errorCode, (_) => null),
      BackendErrorCode.notAssignee,
    );
  });

  test(
    'absence saved across the year boundary and members available lookup',
    () async {
      when(
        () => remote.upsertAbsence(any()),
      ).thenAnswer((i) async => i.positionalArguments.first as MemberAbsence);
      when(() => remote.membersAvailableOn('oa', any())).thenAnswer(
        (_) async => const [
          AvailableMember(
            memberId: 'm2',
            userId: 'u2',
            username: 'bob',
            displayName: 'Bob',
          ),
        ],
      );
      await repo.saveAbsence(absence);
      expect(
        (await repo.watchAbsences('oa').first).single.endsOn,
        DateTime(2027, 1, 2),
      );

      final available = await repo.membersAvailableOn(
        'oa',
        DateTime(2026, 12, 31),
      );
      expect(available.getOrElse((_) => []).single.username, 'bob');
    },
  );
}
