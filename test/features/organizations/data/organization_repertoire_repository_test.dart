import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/data/organization_repertoire_repository_impl.dart';
import 'package:battuta/features/organizations/data/organizations_local_cache.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'test_support.dart';

void main() {
  late AppDatabase db;
  late OrganizationsLocalCache cache;
  late MockRepertoireRemote remote;
  late FakeSession session;
  late OrganizationRepertoireRepositoryImpl repo;

  RepertoireEntry entry(
    String version, {
    String org = 'o1',
    String title = 'Song',
    String? ownerName = 'Grace',
    bool deactivated = false,
  }) => RepertoireEntry(
    organizationId: org,
    versionId: version,
    title: title,
    artist: 'Artist',
    ownerId: 'owner-$version',
    ownerDisplayName: ownerName,
    ownerDeactivated: deactivated,
  );

  RepertoireCandidate candidate(
    String version, {
    String title = 'Song',
    String owner = 'someone',
  }) => RepertoireCandidate(
    versionId: version,
    title: title,
    ownerId: owner,
    visibility: SongVisibility.public,
  );

  setUp(() {
    db = newMemoryDb();
    session = FakeSession('me');
    cache = newCache(db, session);
    remote = MockRepertoireRemote();
    repo = OrganizationRepertoireRepositoryImpl(
      remote: remote,
      cache: cache,
      session: session,
    );
  });
  tearDown(() => db.close());

  Failure failure(BackendErrorCode code) => code.failure(message: code.code);

  Future<void> seedArchivedOrg() => cache.upsert(
    'me',
    CacheKind.organization,
    'o1',
    Organization(
      id: 'o1',
      name: 'Grace',
      archivedAt: DateTime.utc(2026),
    ).toJson(),
  );

  test('refresh caches the repertoire per organization', () async {
    when(() => remote.fetchRepertoire('o1')).thenAnswer(
      (_) async => [entry('v2', title: 'Zion'), entry('v1', title: 'Amazing')],
    );
    when(() => remote.fetchRepertoire('o2'))
        .thenAnswer((_) async => [entry('v1', org: 'o2', title: 'Amazing')]);

    expect((await repo.refreshRepertoire('o1')).isRight(), isTrue);
    expect((await repo.refreshRepertoire('o2')).isRight(), isTrue);

    // The same version can be in two repertoires.
    final first = await repo.watchRepertoire('o1').first;
    expect(first.map((e) => e.title), ['Amazing', 'Zion']);
    expect(
      (await repo.watchRepertoire('o2').first).single.organizationId,
      'o2',
    );
    expect(await repo.watchAllRepertoire().first, hasLength(3));
  });

  test(
    'refresh drops what left the repertoire and keeps the owner snapshot',
    () async {
      when(
        () => remote.fetchRepertoire('o1'),
      ).thenAnswer((_) async => [entry('v1', deactivated: true), entry('v2')]);
      await repo.refreshRepertoire('o1');
      when(() => remote.fetchRepertoire('o1'))
          .thenAnswer((_) async => [entry('v1', deactivated: true)]);
      await repo.refreshRepertoire('o1');

      final rows = await repo.watchRepertoire('o1').first;
      expect(rows.map((e) => e.versionId), ['v1']);
      expect(rows.single.ownerName, 'Grace');
      expect(rows.single.ownerDeactivated, isTrue);
    },
  );

  test(
    'offline: the cache is still readable and the refresh reports offline',
    () async {
      when(() => remote.fetchRepertoire('o1'))
          .thenAnswer((_) async => [entry('v1')]);
      await repo.refreshRepertoire('o1');

      when(() => remote.fetchRepertoire('o1'))
          .thenThrow(failure(BackendErrorCode.offline));
      final result = await repo.refreshRepertoire('o1');
      expect(
        result.swap().getOrElse((_) => throw 'x').errorCode,
        BackendErrorCode.offline,
      );
      expect((await repo.watchRepertoire('o1').first).single.versionId, 'v1');
    },
  );

  test('add stores the entry; a refusal stores nothing', () async {
    when(() => remote.addToRepertoire('o1', 'v1')).thenAnswer((_) async {});
    final added = await repo.addToRepertoire(
      'o1',
      candidate('v1', title: 'New'),
    );
    expect(added.isRight(), isTrue);
    expect((await repo.watchRepertoire('o1').first).single.title, 'New');

    when(() => remote.addToRepertoire('o1', 'v2'))
        .thenThrow(failure(BackendErrorCode.notAdmin));
    final denied = await repo.addToRepertoire('o1', candidate('v2'));
    expect(
      denied.swap().getOrElse((_) => throw 'x').errorCode,
      BackendErrorCode.notAdmin,
    );
    expect(await repo.watchRepertoire('o1').first, hasLength(1));
  });

  test(
    'a version that is no longer visible is refused with permission_denied',
    () async {
      when(() => remote.addToRepertoire('o1', 'v9'))
          .thenThrow(failure(BackendErrorCode.permissionDenied));
      final result = await repo.addToRepertoire('o1', candidate('v9'));
      expect(
        result.swap().getOrElse((_) => throw 'x').errorCode,
        BackendErrorCode.permissionDenied,
      );
    },
  );

  test(
    'remove deletes remotely and from the cache; offline keeps it',
    () async {
      when(() => remote.fetchRepertoire('o1'))
          .thenAnswer((_) async => [entry('v1'), entry('v2')]);
      await repo.refreshRepertoire('o1');

      when(() => remote.removeFromRepertoire('o1', 'v1'))
          .thenThrow(failure(BackendErrorCode.offline));
      expect((await repo.removeFromRepertoire('o1', 'v1')).isLeft(), isTrue);
      expect(await repo.watchRepertoire('o1').first, hasLength(2));

      when(() => remote.removeFromRepertoire('o1', 'v1'))
          .thenAnswer((_) async {});
      expect((await repo.removeFromRepertoire('o1', 'v1')).isRight(), isTrue);
      expect((await repo.watchRepertoire('o1').first).single.versionId, 'v2');
    },
  );

  test(
    'an archived organization is read-only before reaching the network',
    () async {
      await seedArchivedOrg();
      final result = await repo.addToRepertoire('o1', candidate('v1'));
      expect(
        result.swap().getOrElse((_) => throw 'x').errorCode,
        BackendErrorCode.organizationArchived,
      );
      verifyNever(() => remote.addToRepertoire(any(), any()));
      expect((await repo.removeFromRepertoire('o1', 'v1')).isLeft(), isTrue);
      verifyNever(() => remote.removeFromRepertoire(any(), any()));
    },
  );

  test('search lists my own versions first, then by title', () async {
    when(
      () => remote.searchCandidates(
        'o1',
        'a',
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async => [
        candidate('v1', title: 'Beta'),
        candidate('v2', title: 'Zebra', owner: 'me'),
        candidate('v3', title: 'Alpha'),
      ],
    );
    final found = (await repo.searchCandidates(
      'o1',
      ' a ',
    )).getOrElse((_) => throw 'x');
    expect(found.map((c) => c.title), ['Zebra', 'Alpha', 'Beta']);
  });

  test('search reads every server page, so nothing is cut off', () async {
    when(
      () => remote.searchCandidates(
        'o1',
        '',
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((invocation) async {
      final offset = invocation.namedArguments[#offset] as int;
      final limit = invocation.namedArguments[#limit] as int;
      // 230 visible versions; mine is the very last one.
      const total = 230;
      return [
        for (var i = offset; i < offset + limit && i < total; i++)
          candidate(
            'v$i',
            title: 'Song ${i.toString().padLeft(3, '0')}',
            owner: i == total - 1 ? 'me' : 'someone',
          ),
      ];
    });
    final found = (await repo.searchCandidates(
      'o1',
      '',
    )).getOrElse((_) => throw 'x');
    expect(found, hasLength(230));
    expect(found.first.ownerId, 'me');
  });

  test('signed out: every call says not_signed_in', () async {
    session.signIn(null);
    expect(
      (await repo.refreshRepertoire('o1'))
          .swap()
          .getOrElse((_) => throw 'x')
          .errorCode,
      BackendErrorCode.notSignedIn,
    );
    expect(
      (await repo.searchCandidates(
        'o1',
        '',
      )).swap().getOrElse((_) => throw 'x').errorCode,
      BackendErrorCode.notSignedIn,
    );
    expect(await repo.watchRepertoire('o1').first, isEmpty);
  });

  test('leaving an organization clears its cached repertoire', () async {
    when(() => remote.fetchRepertoire('o1'))
        .thenAnswer((_) async => [entry('v1')]);
    await repo.refreshRepertoire('o1');
    await cache.removeScope('me', 'o1');
    expect(await repo.watchRepertoire('o1').first, isEmpty);
  });

  group('entities', () {
    test('a repertoire row with its embeds is parsed', () {
      final parsed = RepertoireEntry.fromJson({
        'organization_id': 'o1',
        'version_id': 'v1',
        'added_by': 'u1',
        'created_at': '2026-11-10T10:00:00Z',
        'song_versions': {
          'id': 'v1',
          'label': 'Acoustic',
          'key': 'D',
          'owner_id': 'u2',
          'songs': {'title': 'Amazing Grace', 'artist': 'Newton'},
          'owner': {
            'username': 'grace',
            'display_name': '  ',
            'deactivated_at': '2026-11-01T00:00:00Z',
          },
        },
      });
      expect(parsed.title, 'Amazing Grace');
      expect(parsed.label, 'Acoustic');
      expect(parsed.ownerName, 'grace');
      expect(parsed.ownerDeactivated, isTrue);
      expect(RepertoireEntry.fromJson(parsed.toJson()), parsed);
    });

    test('a candidate is visible to an organization when public or shared', () {
      RepertoireCandidate with_(
        SongVisibility v, [
        List<String> shares = const [],
      ]) => RepertoireCandidate(
        versionId: 'v',
        title: 't',
        visibility: v,
        sharedOrganizationIds: shares,
      );
      expect(with_(SongVisibility.public).isVisibleTo('o1'), isTrue);
      expect(
        with_(SongVisibility.organizations, ['o1']).isVisibleTo('o1'),
        isTrue,
      );
      expect(
        with_(SongVisibility.organizations, ['o2']).isVisibleTo('o1'),
        isFalse,
      );
      expect(with_(SongVisibility.private, ['o1']).isVisibleTo('o1'), isFalse);
    });
  });
}
