import 'dart:async';
import 'dart:typed_data';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/data/organization_repository_impl.dart';
import 'package:battuta/features/organizations/data/organizations_local_cache.dart';
import 'package:battuta/features/organizations/domain/entities/invites.dart';
import 'package:battuta/features/organizations/domain/entities/notification.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'test_support.dart';

void main() {
  late AppDatabase db;
  late OrganizationsLocalCache cache;
  late MockOrganizationsRemote remote;
  late FakeSession session;
  late OrganizationRepositoryImpl repo;

  const orgA = Organization(id: 'oa', name: 'Alpha');
  const orgB = Organization(id: 'ob', name: 'Beta');
  OrganizationMember member(
    String id,
    String org,
    String user, {
    OrganizationRole role = OrganizationRole.member,
  }) => OrganizationMember(
    id: id,
    organizationId: org,
    userId: user,
    role: role,
    username: 'user_$user',
    displayName: 'User $user',
  );

  setUpAll(() {
    registerFallbackValue(const Band(id: 'x', organizationId: 'o', name: 'n'));
    registerFallbackValue(Duration.zero);
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    db = newMemoryDb();
    session = FakeSession('me');
    cache = newCache(db, session);
    remote = MockOrganizationsRemote();
    repo = OrganizationRepositoryImpl(
      remote: remote,
      cache: cache,
      session: session,
      clock: () => DateTime.utc(2026, 11, 10),
    );
  });
  tearDown(() => db.close());

  Failure offlineFailure() =>
      BackendErrorCode.offline.failure(message: 'offline');

  Future<void> seedOrg(Organization org) =>
      cache.upsert('me', CacheKind.organization, org.id, org.toJson());

  group('organizations', () {
    test(
      'refresh stores organizations with my role from the memberships',
      () async {
        when(() => remote.myOrganizations(includeArchived: true))
            .thenAnswer((_) async => [orgA, orgB]);
        when(() => remote.fetchMyMemberships()).thenAnswer(
          (_) async => [
            member('m1', 'oa', 'me', role: OrganizationRole.admin),
            member('m2', 'ob', 'me'),
          ],
        );

        final result = await repo.refreshOrganizations();
        expect(result.isRight(), isTrue);
        final orgs = await repo.watchOrganizations().first;
        expect(orgs.map((o) => (o.id, o.myRole)).toList(), [
          ('oa', OrganizationRole.admin),
          ('ob', OrganizationRole.member),
        ]);
      },
    );

    test('offline: reads return the cache, refresh and writes return offline, nothing throws', () async {
      await seedOrg(orgA.copyWith(myRole: OrganizationRole.admin));
      when(() => remote.myOrganizations(includeArchived: true))
          .thenThrow(offlineFailure());
      when(() => remote.createOrganization(any())).thenThrow(offlineFailure());

      final orgs = await repo.watchOrganizations().first;
      expect(orgs.single.id, 'oa');

      final refresh = await repo.refreshOrganizations();
      expect(
        refresh.fold((f) => f.errorCode, (_) => null),
        BackendErrorCode.offline,
      );
      final create = await repo.createOrganization('New');
      expect(
        create.fold((f) => f.errorCode, (_) => null),
        BackendErrorCode.offline,
      );
      // The cache is untouched.
      expect((await repo.watchOrganizations().first).single.id, 'oa');
    });

    test('unexpected exceptions become failures instead of throwing', () async {
      when(() => remote.createOrganization(any()))
          .thenThrow(StateError('boom'));
      final result = await repo.createOrganization('X');
      expect(result.fold((f) => f, (_) => null), isA<UnexpectedFailure>());
    });

    test('signed out: writes return notSignedIn and reads are empty', () async {
      session.signIn(null);
      final result = await repo.createOrganization('X');
      expect(
        result.fold((f) => f.errorCode, (_) => null),
        BackendErrorCode.notSignedIn,
      );
      expect(await repo.watchOrganizations().first, isEmpty);
      verifyNever(() => remote.createOrganization(any()));
    });

    test('watchOrganizations hides archived ones unless asked', () async {
      await seedOrg(orgA);
      await seedOrg(
        Organization(id: 'ob', name: 'Beta', archivedAt: DateTime.utc(2026)),
      );
      when(() => remote.myOrganizations(includeArchived: true))
          .thenThrow(offlineFailure());

      expect((await repo.watchOrganizations().first).map((o) => o.id), ['oa']);
      expect(
        (await repo.watchOrganizations(includeArchived: true).first).map(
          (o) => o.id,
        ),
        ['oa', 'ob'],
      );
    });

    test(
      'a removed membership drops the organization and all its cached data',
      () async {
        await seedOrg(orgA);
        await seedOrg(orgB);
        await cache.upsert(
          'me',
          CacheKind.band,
          'b1',
          const Band(id: 'b1', organizationId: 'ob', name: 'B').toJson(),
          scopeId: 'ob',
        );
        when(() => remote.myOrganizations(includeArchived: true))
            .thenAnswer((_) async => [orgA]);
        when(() => remote.fetchMyMemberships())
            .thenAnswer((_) async => [member('m1', 'oa', 'me')]);

        await repo.refreshOrganizations();

        expect((await repo.watchOrganizations().first).map((o) => o.id), [
          'oa',
        ]);
        expect(await cache.read('me', CacheKind.band, Band.fromJson), isEmpty);
      },
    );

    test('createOrganization caches the new organization as admin', () async {
      when(() => remote.createOrganization('Gamma'))
          .thenAnswer((_) async => const Organization(id: 'og', name: 'Gamma'));
      final result = await repo.createOrganization('Gamma');
      expect(
        result.getOrElse((_) => throw StateError('x')).myRole,
        OrganizationRole.admin,
      );
      expect((await repo.watchOrganizations().first).single.isAdmin, isTrue);
    });

    test('leaveOrganization removes the organization from the cache', () async {
      await seedOrg(orgA);
      when(() => remote.leaveOrganization('oa')).thenAnswer((_) async {});
      await repo.leaveOrganization('oa');
      expect(await repo.watchOrganizations().first, isEmpty);
    });
  });

  group('logo and profile', () {
    const admin = Organization(
      id: 'oa',
      name: 'Alpha',
      myRole: OrganizationRole.admin,
    );

    test('setOrganizationLogo caches the new path and keeps my role', () async {
      await seedOrg(admin);
      final jpeg = Uint8List.fromList([1, 2, 3]);
      when(() => remote.setOrganizationLogo('oa', jpeg)).thenAnswer(
        (_) async =>
            const Organization(id: 'oa', name: 'Alpha', logoPath: 'oa/new.jpg'),
      );

      final result = await repo.setOrganizationLogo('oa', jpeg);

      expect(result.isRight(), isTrue);
      final cached = (await repo.watchOrganizations().first).single;
      expect(cached.logoPath, 'oa/new.jpg');
      expect(cached.isAdmin, isTrue);
    });

    test('a refused upload leaves the cached logo alone', () async {
      await seedOrg(admin.copyWith(logoPath: 'oa/old.jpg'));
      final jpeg = Uint8List.fromList([1]);
      when(() => remote.setOrganizationLogo('oa', jpeg))
          .thenThrow(BackendErrorCode.notAdmin.failure(message: 'not_admin'));

      final result = await repo.setOrganizationLogo('oa', jpeg);

      expect(
        result.fold((f) => f.errorCode, (_) => null),
        BackendErrorCode.notAdmin,
      );
      expect(
        (await repo.watchOrganizations().first).single.logoPath,
        'oa/old.jpg',
      );
    });

    test('removeOrganizationLogo clears the cached path', () async {
      await seedOrg(admin.copyWith(logoPath: 'oa/old.jpg'));
      when(() => remote.removeOrganizationLogo('oa'))
          .thenAnswer((_) async => const Organization(id: 'oa', name: 'Alpha'));

      await repo.removeOrganizationLogo('oa');

      final cached = (await repo.watchOrganizations().first).single;
      expect(cached.logoPath, isNull);
      expect(cached.isAdmin, isTrue);
    });

    test(
      'updateOrganizationProfile trims and clears a blank description',
      () async {
        await seedOrg(admin);
        when(
          () => remote.updateOrganizationProfile(
            'oa',
            name: 'Alpha 2',
            description: null,
          ),
        ).thenAnswer(
          (_) async => const Organization(id: 'oa', name: 'Alpha 2'),
        );

        final result = await repo.updateOrganizationProfile(
          'oa',
          name: ' Alpha 2 ',
          description: '   ',
        );

        expect(result.isRight(), isTrue);
        expect((await repo.watchOrganizations().first).single.name, 'Alpha 2');
      },
    );

    test('updateOrganizationProfile sends the trimmed description', () async {
      await seedOrg(admin);
      when(
        () => remote.updateOrganizationProfile(
          'oa',
          name: 'Alpha',
          description: 'Thursdays',
        ),
      ).thenAnswer(
        (_) async => const Organization(
          id: 'oa',
          name: 'Alpha',
          description: 'Thursdays',
        ),
      );

      await repo.updateOrganizationProfile(
        'oa',
        name: 'Alpha',
        description: ' Thursdays ',
      );

      verify(
        () => remote.updateOrganizationProfile(
          'oa',
          name: 'Alpha',
          description: 'Thursdays',
        ),
      ).called(1);
    });

    test(
      'logo and profile writes fail fast on an archived organization',
      () async {
        await seedOrg(admin.copyWith(archivedAt: DateTime.utc(2026)));
        final results = [
          await repo.setOrganizationLogo('oa', Uint8List(1)),
          await repo.removeOrganizationLogo('oa'),
          await repo.updateOrganizationProfile('oa', name: 'X'),
        ];
        for (final r in results) {
          expect(
            r.fold((f) => f.errorCode, (_) => null),
            BackendErrorCode.organizationArchived,
          );
        }
        verifyNever(() => remote.setOrganizationLogo(any(), any()));
      },
    );
  });

  group('archived organizations are read-only', () {
    final archived = Organization(
      id: 'oa',
      name: 'Alpha',
      archivedAt: DateTime.utc(2026),
      myRole: OrganizationRole.admin,
    );

    test(
      'writes fail fast with organization_archived, without a request',
      () async {
        await seedOrg(archived);
        final results = [
          await repo.createBand('oa', 'Band'),
          await repo.createInviteLink('oa'),
          await repo.inviteUserByUsername('oa', 'jane'),
          await repo.setMemberRole('oa', 'm1', OrganizationRole.admin),
          await repo.removeMember('oa', 'm1'),
          await repo.renameOrganization('oa', 'New'),
        ];
        for (final r in results) {
          expect(
            r.fold((f) => f.errorCode, (_) => null),
            BackendErrorCode.organizationArchived,
          );
        }
        verifyNever(() => remote.createBand(any()));
        verifyNever(
          () => remote.createInviteLink(
            any(),
            bandId: any(named: 'bandId'),
            expiresIn: any(named: 'expiresIn'),
            maxUses: any(named: 'maxUses'),
          ),
        );
      },
    );

    test('leaving is still allowed', () async {
      await seedOrg(archived);
      when(() => remote.leaveOrganization('oa')).thenAnswer((_) async {});
      expect((await repo.leaveOrganization('oa')).isRight(), isTrue);
    });
  });

  group('members', () {
    test('refresh replaces members of that organization only', () async {
      await cache.upsert(
        'me',
        CacheKind.member,
        'old',
        member('old', 'oa', 'x').toJson(),
        scopeId: 'oa',
      );
      await cache.upsert(
        'me',
        CacheKind.member,
        'keep',
        member('keep', 'ob', 'y').toJson(),
        scopeId: 'ob',
      );
      when(() => remote.fetchMembers('oa'))
          .thenAnswer((_) async => [member('m1', 'oa', 'me')]);

      await repo.refreshMembers('oa');

      expect((await repo.watchMembers('oa').first).map((m) => m.id), ['m1']);
      expect((await repo.watchMembers('ob').first).map((m) => m.id), ['keep']);
    });

    test(
      'setMemberRole keeps the cached profile (the RPC row has none)',
      () async {
        await seedOrg(orgA);
        await cache.upsert(
          'me',
          CacheKind.member,
          'm2',
          member('m2', 'oa', 'u2').toJson(),
          scopeId: 'oa',
        );
        when(() => remote.setMemberRole('m2', OrganizationRole.admin))
            .thenAnswer(
              (_) async => const OrganizationMember(
                id: 'm2',
                organizationId: 'oa',
                userId: 'u2',
                role: OrganizationRole.admin,
              ),
            );
        final result = await repo.setMemberRole(
          'oa',
          'm2',
          OrganizationRole.admin,
        );
        final updated = result.getOrElse((_) => throw StateError('x'));
        expect(updated.displayName, 'User u2');
        expect(updated.role, OrganizationRole.admin);
        expect(
          (await repo.watchMembers('oa').first).single.role,
          OrganizationRole.admin,
        );
      },
    );

    test('removeMember also drops their band memberships', () async {
      await seedOrg(orgA);
      await cache.upsert(
        'me',
        CacheKind.member,
        'm2',
        member('m2', 'oa', 'u2').toJson(),
        scopeId: 'oa',
      );
      await cache.upsert(
        'me',
        CacheKind.bandMember,
        'bm1',
        const BandMember(
          id: 'bm1',
          organizationId: 'oa',
          bandId: 'b1',
          memberId: 'm2',
        ).toJson(),
        scopeId: 'oa',
      );
      await cache.upsert(
        'me',
        CacheKind.bandMember,
        'bm2',
        const BandMember(
          id: 'bm2',
          organizationId: 'oa',
          bandId: 'b1',
          memberId: 'm3',
        ).toJson(),
        scopeId: 'oa',
      );
      when(() => remote.removeMember('m2')).thenAnswer((_) async {});

      await repo.removeMember('oa', 'm2');

      expect(await repo.watchMembers('oa').first, isEmpty);
      expect((await repo.watchBandMembers('oa').first).map((b) => b.id), [
        'bm2',
      ]);
    });

    test('a server error is returned typed', () async {
      await seedOrg(orgA);
      when(() => remote.removeMember('m1'))
          .thenThrow(BackendErrorCode.lastAdmin.failure());
      final result = await repo.removeMember('oa', 'm1');
      expect(
        result.fold((f) => f.errorCode, (_) => null),
        BackendErrorCode.lastAdmin,
      );
    });
  });

  group('bands', () {
    test('createBand uses a UUID v4 id and caches the row', () async {
      await seedOrg(orgA);
      when(() => remote.createBand(any()))
          .thenAnswer((i) async => i.positionalArguments.first as Band);

      final result = await repo.createBand(
        'oa',
        'Worship',
        description: 'Sunday',
      );
      final band = result.getOrElse((_) => throw StateError('x'));
      expect(band.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect((await repo.watchBands('oa').first).single.name, 'Worship');
    });

    test('deleteBand removes its band members from the cache', () async {
      await seedOrg(orgA);
      await cache.upsert(
        'me',
        CacheKind.band,
        'b1',
        const Band(id: 'b1', organizationId: 'oa', name: 'B').toJson(),
        scopeId: 'oa',
      );
      await cache.upsert(
        'me',
        CacheKind.bandMember,
        'bm1',
        const BandMember(
          id: 'bm1',
          organizationId: 'oa',
          bandId: 'b1',
          memberId: 'm',
        ).toJson(),
        scopeId: 'oa',
      );
      when(() => remote.deleteBand('b1')).thenAnswer((_) async {});
      await repo.deleteBand('oa', 'b1');
      expect(await repo.watchBands('oa').first, isEmpty);
      expect(await repo.watchBandMembers('oa').first, isEmpty);
    });
  });

  group('invites', () {
    test(
      'join with an invite link caches the member and refreshes organizations',
      () async {
        when(() => remote.joinWithInviteLink('tok'))
            .thenAnswer((_) async => member('m9', 'oa', 'me'));
        when(() => remote.myOrganizations(includeArchived: true))
            .thenAnswer((_) async => [orgA]);
        when(() => remote.fetchMyMemberships())
            .thenAnswer((_) async => [member('m9', 'oa', 'me')]);

        final result = await repo.joinWithInviteLink('tok');
        expect(result.isRight(), isTrue);
        expect((await repo.watchOrganizations().first).single.id, 'oa');
      },
    );

    test('join failures are typed (expired link)', () async {
      when(() => remote.joinWithInviteLink('tok'))
          .thenThrow(BackendErrorCode.inviteExpired.failure());
      final result = await repo.joinWithInviteLink('tok');
      expect(
        result.fold((f) => f.errorCode, (_) => null),
        BackendErrorCode.inviteExpired,
      );
    });

    test(
      'accepting an invitation updates it and refreshes organizations',
      () async {
        const invitation = Invitation(
          id: 'i1',
          organizationId: 'oa',
          invitedUserId: 'me',
          organizationName: 'Alpha',
        );
        await cache.upsert(
          'me',
          CacheKind.myInvitation,
          'i1',
          invitation.toJson(),
        );
        when(() => remote.respondToInvitation('i1', true)).thenAnswer(
          (_) async => const Invitation(
            id: 'i1',
            organizationId: 'oa',
            invitedUserId: 'me',
            status: InvitationStatus.accepted,
          ),
        );
        when(() => remote.myOrganizations(includeArchived: true))
            .thenAnswer((_) async => [orgA]);
        when(() => remote.fetchMyMemberships())
            .thenAnswer((_) async => [member('m1', 'oa', 'me')]);

        await repo.respondToInvitation(invitation, accept: true);

        final mine = await repo.watchMyInvitations().first;
        expect(mine.single.status, InvitationStatus.accepted);
        expect(mine.single.organizationName, 'Alpha');
        expect((await repo.watchOrganizations().first).single.id, 'oa');
      },
    );

    test(
      'invite by username trims the name and caches the invitation',
      () async {
        await seedOrg(orgA);
        when(() => remote.inviteUserByUsername('oa', 'jane', bandId: null))
            .thenAnswer(
              (_) async => const Invitation(
                id: 'i2',
                organizationId: 'oa',
                invitedUserId: 'u9',
              ),
            );
        await repo.inviteUserByUsername('oa', '  jane ');
        expect((await repo.watchInvitations('oa').first).single.id, 'i2');
      },
    );
  });

  group('archive', () {
    test('approving keeps my role and stores the archived state', () async {
      await seedOrg(orgA.copyWith(myRole: OrganizationRole.admin));
      when(() => remote.approveOrganizationArchive('oa')).thenAnswer(
        (_) async => Organization(
          id: 'oa',
          name: 'Alpha',
          archivedAt: DateTime.utc(2026, 11, 10),
        ),
      );
      when(() => remote.fetchArchiveRequest('oa'))
          .thenAnswer((_) async => null);

      final result = await repo.approveArchive('oa');
      expect(result.isRight(), isTrue);
      final org =
          (await repo.watchOrganizations(includeArchived: true).first).single;
      expect(org.isArchived, isTrue);
      expect(org.isAdmin, isTrue);
    });

    test('the open request is cached with its approvals', () async {
      when(() => remote.fetchArchiveRequest('oa')).thenAnswer(
        (_) async => const ArchiveRequest(
          organizationId: 'oa',
          requestedBy: 'me',
          approvals: [ArchiveApproval(userId: 'me')],
        ),
      );
      await repo.refreshArchiveRequest('oa');
      final request = await repo.watchArchiveRequest('oa').first;
      expect(request!.isApprovedBy('me'), isTrue);

      when(() => remote.fetchArchiveRequest('oa'))
          .thenAnswer((_) async => null);
      await repo.refreshArchiveRequest('oa');
      expect(await repo.watchArchiveRequest('oa').first, isNull);
    });
  });

  group('notifications', () {
    AppNotification note(String id, {DateTime? readAt}) => AppNotification(
      id: id,
      recipientId: 'me',
      type: NotificationType.removed,
      createdAt: DateTime.utc(2026, 1, int.parse(id)),
      readAt: readAt,
    );

    test(
      'refresh sorts newest first and mark-read updates the cache',
      () async {
        when(() => remote.fetchNotifications())
            .thenAnswer((_) async => [note('1'), note('2')]);
        when(() => remote.markNotificationsRead(['1']))
            .thenAnswer((_) async => 1);
        await repo.refreshNotifications();

        var list = await repo.watchNotifications().first;
        expect(list.map((n) => n.id), ['2', '1']);

        await repo.markNotificationsRead(['1']);
        list = await repo.watchNotifications().first;
        expect(list.firstWhere((n) => n.id == '1').isRead, isTrue);
        expect(list.firstWhere((n) => n.id == '2').isRead, isFalse);
      },
    );

    test('mark all read touches every unread notification', () async {
      when(() => remote.fetchNotifications())
          .thenAnswer((_) async => [note('1'), note('2')]);
      when(() => remote.markNotificationsRead(null)).thenAnswer((_) async => 2);
      await repo.refreshNotifications();
      await repo.markNotificationsRead();
      expect(
        (await repo.watchNotifications().first).every((n) => n.isRead),
        isTrue,
      );
    });
  });

  test('watch triggers a background refresh when listened', () async {
    when(() => remote.myOrganizations(includeArchived: true))
        .thenAnswer((_) async => [orgA]);
    when(() => remote.fetchMyMemberships()).thenAnswer((_) async => []);
    final emissions = repo.watchOrganizations();
    final first = await emissions
        .firstWhere((l) => l.isNotEmpty)
        .timeout(const Duration(seconds: 5));
    expect(first.single.id, 'oa');
  });

  group('account changes during an operation', () {
    test(
      'a stale account_deactivated failure does not sign out the new account',
      () async {
        final gate = Completer<List<Organization>>();
        when(() => remote.myOrganizations(includeArchived: true))
            .thenAnswer((_) => gate.future);
        when(() => remote.fetchMyMemberships()).thenAnswer((_) async => []);

        final pending = repo.refreshOrganizations();
        await Future<void>.delayed(Duration.zero);
        session.signIn('other');
        await cache.upsert(
          'other',
          CacheKind.organization,
          orgB.id,
          orgB.toJson(),
        );
        gate.completeError(
          BackendErrorCode.accountDeactivated.failure(message: 'deactivated'),
        );
        final result = await pending;

        expect(result.isLeft(), isTrue);
        expect(session.userId, 'other');
        expect(
          await cache.read(
            'other',
            CacheKind.organization,
            Organization.fromJson,
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'a refresh in flight when the account switches writes nothing',
      () async {
        final gate = Completer<List<Organization>>();
        when(() => remote.myOrganizations(includeArchived: true))
            .thenAnswer((_) => gate.future);
        when(() => remote.fetchMyMemberships()).thenAnswer((_) async => []);

        final pending = repo.refreshOrganizations();
        await Future<void>.delayed(Duration.zero);
        session.signIn('other');
        await cache.clearAllExcept('other');
        gate.complete([orgA]);
        await pending;

        expect(
          await cache.read('me', CacheKind.organization, Organization.fromJson),
          isEmpty,
        );
        expect(
          await cache.read(
            'other',
            CacheKind.organization,
            Organization.fromJson,
          ),
          isEmpty,
        );
      },
    );

    test(
      'a refresh in flight when the user signs out leaves no rows',
      () async {
        final gate = Completer<List<Organization>>();
        when(() => remote.myOrganizations(includeArchived: true))
            .thenAnswer((_) => gate.future);
        when(() => remote.fetchMyMemberships()).thenAnswer((_) async => []);

        final pending = repo.refreshOrganizations();
        await Future<void>.delayed(Duration.zero);
        session.signIn(null);
        await cache.clearAllExcept(null);
        gate.complete([orgA]);
        await pending;

        expect(
          await cache.read('me', CacheKind.organization, Organization.fromJson),
          isEmpty,
        );
      },
    );
  });

  group('session-following streams', () {
    test(
      'switches to the new account cache and is empty when signed out',
      () async {
        await seedOrg(orgA);
        await cache.upsert('b', CacheKind.organization, 'ob', orgB.toJson());
        when(() => remote.myOrganizations(includeArchived: true))
            .thenAnswer((_) async => session.userId == 'b' ? [orgB] : [orgA]);
        when(() => remote.fetchMyMemberships()).thenAnswer((_) async => []);

        final seen = <List<String>>[];
        final sub = repo.watchOrganizations().listen(
          (l) => seen.add(l.map((o) => o.id).toList()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        session.signIn('b');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        session.signIn(null);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        expect(seen.any((l) => l.contains('oa')), isTrue);
        expect(seen.any((l) => l.contains('ob')), isTrue);
        expect(seen.last, isEmpty);
      },
    );

    test(
      'subscribing while signed out starts showing data after sign-in',
      () async {
        session.signIn(null);
        await cache.upsert('b', CacheKind.organization, 'ob', orgB.toJson());
        when(() => remote.myOrganizations(includeArchived: true))
            .thenAnswer((_) async => [orgB]);
        when(() => remote.fetchMyMemberships()).thenAnswer((_) async => []);

        final future = repo.watchOrganizations().firstWhere(
          (l) => l.isNotEmpty,
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        session.signIn('b');
        expect(
          (await future.timeout(const Duration(seconds: 5))).single.id,
          'ob',
        );
      },
    );
  });

  group('ordering', () {
    test(
      'a row written during an older refresh survives its snapshot',
      () async {
        final gate = Completer<List<Organization>>();
        when(() => remote.myOrganizations(includeArchived: true))
            .thenAnswer((_) => gate.future);
        when(() => remote.fetchMyMemberships()).thenAnswer((_) async => []);

        final pending = repo.refreshOrganizations();
        await Future<void>.delayed(Duration.zero);
        await cache.upsert('me', CacheKind.organization, 'ob', orgB.toJson());
        gate.complete([orgA]);
        await pending;

        final ids = (await cache.read(
          'me',
          CacheKind.organization,
          Organization.fromJson,
        )).map((o) => o.id).toSet();
        expect(ids, {'oa', 'ob'});
      },
    );
  });

  group('deactivation', () {
    test(
      'an account_deactivated failure signs out and clears the cache',
      () async {
        await seedOrg(orgA);
        when(() => remote.myOrganizations(includeArchived: true)).thenThrow(
          BackendErrorCode.accountDeactivated.failure(message: 'deactivated'),
        );

        final result = await repo.refreshOrganizations();

        expect(result.isLeft(), isTrue);
        expect(session.userId, isNull);
        expect(
          await cache.read('me', CacheKind.organization, Organization.fromJson),
          isEmpty,
        );
      },
    );
  });
}
