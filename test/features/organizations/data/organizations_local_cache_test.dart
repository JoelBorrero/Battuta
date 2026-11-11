import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/organizations/data/organizations_local_cache.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

void main() {
  late AppDatabase db;
  late OrganizationsLocalCache cache;

  setUp(() {
    db = newMemoryDb();
    cache = newCache(db);
  });
  tearDown(() => db.close());

  CacheRow orgRow(String id, String name) =>
      (id: id, json: Organization(id: id, name: name).toJson());

  test(
    'replaceAll inserts, updates and drops rows without duplicating',
    () async {
      await cache.replaceAll('u1', CacheKind.organization, [
        orgRow('a', 'A'),
        orgRow('b', 'B'),
      ]);
      await cache.replaceAll('u1', CacheKind.organization, [
        orgRow('b', 'B2'),
        orgRow('c', 'C'),
      ]);
      // A repeated refresh (e.g. after a realtime reconnect) changes nothing.
      await cache.replaceAll('u1', CacheKind.organization, [
        orgRow('b', 'B2'),
        orgRow('c', 'C'),
      ]);

      final rows = await cache.read(
        'u1',
        CacheKind.organization,
        Organization.fromJson,
      );
      expect(rows.map((o) => o.id).toList()..sort(), ['b', 'c']);
      expect(rows.firstWhere((o) => o.id == 'b').name, 'B2');
    },
  );

  test('replaceAll only touches its own scope and kind', () async {
    await cache.replaceAll('u1', CacheKind.band, [
      (
        id: 'b1',
        json: const Band(id: 'b1', organizationId: 'o1', name: 'One').toJson(),
      ),
    ], scopeId: 'o1');
    await cache.replaceAll('u1', CacheKind.band, [
      (
        id: 'b2',
        json: const Band(id: 'b2', organizationId: 'o2', name: 'Two').toJson(),
      ),
    ], scopeId: 'o2');
    await cache.replaceAll('u1', CacheKind.band, const [], scopeId: 'o1');

    final remaining = await cache.read('u1', CacheKind.band, Band.fromJson);
    expect(remaining.single.id, 'b2');
  });

  test('watch emits again after every change', () async {
    final emissions = <List<String>>[];
    final sub = cache
        .watch('u1', CacheKind.organization, Organization.fromJson)
        .listen(
          (rows) => emissions.add(rows.map((o) => o.id).toList()..sort()),
        );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await cache.upsert(
      'u1',
      CacheKind.organization,
      'a',
      orgRow('a', 'A').json,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await cache.remove('u1', CacheKind.organization, 'a');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();

    expect(
      emissions,
      containsAllInOrder([
        <String>[],
        ['a'],
        <String>[],
      ]),
    );
  });

  test('accounts are isolated from each other', () async {
    await cache.upsert(
      'u1',
      CacheKind.organization,
      'a',
      orgRow('a', 'A').json,
    );
    await cache.upsert(
      'u2',
      CacheKind.organization,
      'z',
      orgRow('z', 'Z').json,
    );

    expect(
      (await cache.read(
        'u1',
        CacheKind.organization,
        Organization.fromJson,
      )).single.id,
      'a',
    );
    expect(
      (await cache.read(
        'u2',
        CacheKind.organization,
        Organization.fromJson,
      )).single.id,
      'z',
    );
  });

  test(
    'clearAllExcept keeps only the given account (everything on null)',
    () async {
      await cache.upsert(
        'u1',
        CacheKind.organization,
        'a',
        orgRow('a', 'A').json,
      );
      await cache.upsert(
        'u2',
        CacheKind.organization,
        'z',
        orgRow('z', 'Z').json,
      );
      await cache.markRefreshed('u1', CacheKind.organization);

      await cache.clearAllExcept('u2');
      expect(
        await cache.read('u1', CacheKind.organization, Organization.fromJson),
        isEmpty,
      );
      expect(await cache.lastRefreshed('u1', CacheKind.organization), isNull);
      expect(
        await cache.read('u2', CacheKind.organization, Organization.fromJson),
        hasLength(1),
      );

      await cache.clearAllExcept(null);
      expect(
        await cache.read('u2', CacheKind.organization, Organization.fromJson),
        isEmpty,
      );
    },
  );

  test('removeScope drops everything of an organization', () async {
    await cache.upsert(
      'u1',
      CacheKind.organization,
      'o1',
      orgRow('o1', 'A').json,
    );
    await cache.upsert(
      'u1',
      CacheKind.band,
      'b1',
      const Band(id: 'b1', organizationId: 'o1', name: 'B').toJson(),
      scopeId: 'o1',
    );
    await cache.removeScope('u1', 'o1');

    expect(await cache.read('u1', CacheKind.band, Band.fromJson), isEmpty);
    expect(
      await cache.read('u1', CacheKind.organization, Organization.fromJson),
      hasLength(1),
    );
  });

  test('a corrupt row is skipped instead of failing the read', () async {
    await cache.upsert('u1', CacheKind.organization, 'bad', {
      'unexpected': true,
    });
    await cache.upsert(
      'u1',
      CacheKind.organization,
      'a',
      orgRow('a', 'A').json,
    );
    final rows = await cache.read(
      'u1',
      CacheKind.organization,
      Organization.fromJson,
    );
    expect(rows.single.id, 'a');
  });
}
