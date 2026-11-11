/// The Roster on real data: two real accounts, the sync coordinator filling
/// the cache, and the roster providers (as the Team page reads them).
///
///   supabase db reset
///   flutter test --tags supabase --run-skipped test/integration
@Tags(['supabase'])
library;

import 'package:battuta/app/account_lifecycle.dart';
import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show FakeCloudSyncService;
import '../support/memory_storage.dart';
import 'support/stack.dart';
import 'support/test_user.dart';

void main() {
  StackConfig? stack;
  late TestUser admin;
  late TestUser joiner;
  final created = <TestUser>[];

  setUpAll(() async {
    stack = await resolveStack();
    if (stack == null) return;
    admin = await TestUser.signUp(stack!, 'rosteradmin');
    created.add(admin);
    joiner = await TestUser.signUp(stack!, 'rosterjoin');
    created.add(joiner);
  });

  tearDownAll(() async {
    for (final user in created) {
      await user.dispose();
    }
  });

  test('roster shows both members after the second joins by invite link', () async {
    if (stack == null) {
      markTestSkipped(
        'Supabase stack not available: set SUPABASE_TEST_URL / '
        'SUPABASE_TEST_ANON_KEY or run `supabase start`.',
      );
      return;
    }

    // The admin's device: real repositories on the admin's client and cache.
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(
          AuthUser(id: admin.id, email: admin.email),
        ),
        organizationRepositoryProvider.overrideWithValue(admin.orgs),
        organizationsSyncCoordinatorProvider.overrideWithValue(
          admin.coordinator,
        ),
        // Song sync is covered by its own integration test.
        cloudSyncServiceProvider.overrideWithValue(FakeCloudSyncService()),
        activeOrganizationStorageProvider.overrideWithValue(MemoryStorage()),
      ],
    );
    addTearDown(container.dispose);
    container
      ..listen(accountLifecycleProvider, (_, _) {})
      ..listen(teamMembersProvider, (_, _) {})
      ..listen(activeOrganizationProvider, (_, _) {});

    // `accountLifecycleProvider` starts the coordinator, which fills the cache
    // (organizations, members, bands, realtime) for the signed-in admin.

    final org = ok(await admin.orgs.createOrganization('Roster Org'));
    await eventually(
      () async => container.read(activeOrganizationProvider)?.id == org.id,
      reason: 'the new organization to become active',
    );
    await eventually(
      () async => container.read(teamMembersProvider).length == 1,
      reason: 'the admin to appear in the roster',
    );
    final first = container.read(teamMembersProvider).single;
    expect(first.isMe, isTrue);
    expect(first.isAdmin, isTrue);
    expect(first.name, admin.displayName);
    expect(container.read(isCurrentUserAdminProvider), isTrue);

    // The second account joins through an invite link made by the repository.
    final link = ok(await admin.orgs.createInviteLink(org.id));
    ok(await joiner.orgs.joinWithInviteLink(link.token));

    // Realtime normally delivers it; fall back to an explicit refresh.
    var refreshed = false;
    await eventually(() async {
      if (container.read(teamMembersProvider).length == 2) return true;
      if (!refreshed) {
        refreshed = true;
        await Future<void>.delayed(const Duration(seconds: 3));
        if (container.read(teamMembersProvider).length == 2) return true;
        await admin.orgs.refreshMembers(org.id);
      }
      return container.read(teamMembersProvider).length == 2;
    }, reason: 'the joiner to appear in the roster');
    final roster = container.read(teamMembersProvider);
    expect(
      roster.map((m) => m.name),
      containsAll([admin.displayName, joiner.displayName]),
    );
    expect(roster.where((m) => m.isMe), hasLength(1));
    expect(roster.firstWhere((m) => !m.isMe).isAdmin, isFalse);

    // Roster edits go through the repositories and come back through the cache.
    final other = roster.firstWhere((m) => !m.isMe);
    final saved = await container
        .read(rosterActionsProvider)
        .saveMember(
          original: other,
          roles: [TeamRole.leadVocal],
          tessitura: VocalTessitura.alto,
          notes: 'Lead on Sundays',
          isAdmin: true,
          bandIds: const {},
          canEditRoleAndBands: true,
        );
    expect(saved.isRight(), isTrue);
    await eventually(() async {
      final updated = container
          .read(teamMembersProvider)
          .where((m) => m.id == other.id);
      return updated.isNotEmpty &&
          updated.single.isAdmin &&
          updated.single.roles.contains(TeamRole.leadVocal) &&
          updated.single.vocalRange == VocalTessitura.alto;
    }, reason: 'the edited member in the roster');

    // Make the joiner a plain member again so the admin can leave the test org.
    ok(
      await admin.orgs.setMemberRole(org.id, other.id, OrganizationRole.member),
    );
  });
}
