import 'dart:async';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/database/database_providers.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_account_session.dart';

/// `canAdministerOrganization` of the real setlist repository follows the
/// account's memberships: admins write organization setlists, members get
/// `not_admin`.
void main() {
  late AppDatabase db;
  late StreamController<List<Organization>> memberships;
  late ProviderContainer container;

  Setlist setlist(String id, {String? org}) => Setlist(
    id: id,
    title: 'Set $id',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    organizationId: org,
  );

  Future<void> setRoles(Map<String, OrganizationRole> roles) async {
    memberships.add([
      for (final e in roles.entries)
        Organization(id: e.key, name: e.key, myRole: e.value),
    ]);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    memberships = StreamController<List<Organization>>.broadcast();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        accountSessionProvider.overrideWithValue(FakeAccountSession('u1')),
        myOrganizationsProvider.overrideWith((ref) => memberships.stream),
      ],
    );
    container.listen(myOrganizationsProvider, (_, _) {});
    await setRoles({
      'admin-org': OrganizationRole.admin,
      'member-org': OrganizationRole.member,
    });
  });

  tearDown(() async {
    container.dispose();
    await memberships.close();
    await db.close();
  });

  test('an admin saves and deletes the setlists of their organization', () async {
    final repo = container.read(driftSetlistRepositoryProvider);
    expect(
      (await repo.saveSetlist(setlist('s1', org: 'admin-org'))).isRight(),
      isTrue,
    );
    expect((await repo.deleteSetlist('s1')).isRight(), isTrue);
  });

  test('a member gets not_admin and nothing is written', () async {
    final repo = container.read(driftSetlistRepositoryProvider);
    final saved = await repo.saveSetlist(setlist('s2', org: 'member-org'));
    expect(
      saved.swap().getOrElse((_) => throw 'x').errorCode,
      BackendErrorCode.notAdmin,
    );
    expect((await repo.getAllSetlists()).getOrElse((_) => []), isEmpty);
  });

  test('personal setlists need no role', () async {
    final repo = container.read(driftSetlistRepositoryProvider);
    expect((await repo.saveSetlist(setlist('s3'))).isRight(), isTrue);
  });

  test('a role change applies without rebuilding the repository', () async {
    final repo = container.read(driftSetlistRepositoryProvider);
    expect(
      (await repo.saveSetlist(setlist('s4', org: 'member-org'))).isLeft(),
      isTrue,
    );

    await setRoles({'member-org': OrganizationRole.admin});
    expect(
      (await repo.saveSetlist(setlist('s4', org: 'member-org'))).isRight(),
      isTrue,
    );

    await setRoles({'member-org': OrganizationRole.member});
    expect(
      (await repo.saveSetlist(setlist('s4', org: 'member-org'))).isLeft(),
      isTrue,
    );
  });

  test('an organization that is no longer mine (left, archived) is not admin',
      () async {
    final repo = container.read(driftSetlistRepositoryProvider);
    await setRoles({});
    expect(
      (await repo.saveSetlist(setlist('s5', org: 'admin-org'))).isLeft(),
      isTrue,
    );
    expect(container.read(organizationAdminCheckProvider)('admin-org'), isFalse);
  });
}
