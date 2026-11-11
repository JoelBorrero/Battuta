import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_organization_repository.dart';
import '../../../support/memory_storage.dart';
import '../../../support/team_fixtures.dart';

void main() {
  late FakeOrganizationRepository repository;
  late MemoryStorage storage;

  setUp(() {
    storage = MemoryStorage();
    repository = FakeOrganizationRepository(
      organizations: [
        org('org-1', 'Grace Church'),
        org('org-2', 'Youth', role: OrganizationRole.member),
        org('org-old', 'Old', archivedAt: DateTime(2026)),
      ],
      members: [
        member('m-me', 'u-me', 'Me', instruments: ['keys']),
        member('m-b', 'u-b', 'Bea', instruments: ['bass']),
        member('m-x', 'u-x', 'Xavi', orgId: 'org-2'),
        member('m-me2', 'u-me', 'Me', orgId: 'org-2'),
      ],
      bands: const [Band(id: 'band-1', organizationId: 'org-1', name: 'Alpha')],
      bandMembers: const [
        BandMember(
          id: 'bm-1',
          organizationId: 'org-1',
          bandId: 'band-1',
          memberId: 'm-b',
        ),
      ],
    );
  });

  ProviderContainer container({bool signedIn = true}) {
    final c = ProviderContainer(
      overrides: signedIn
          ? signedInOverrides(repository, storage: storage)
          : [],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Keeps the stream providers alive and lets them emit.
  Future<void> settle(ProviderContainer c) async {
    c.listen(activeMembersProvider, (_, _) {});
    c.listen(activeBandsProvider, (_, _) {});
    c.listen(activeBandMembersProvider, (_, _) {});
    c.listen(myOrganizationsProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('lists my organizations without the archived ones', () async {
    final c = container();
    await settle(c);

    expect(c.read(myOrganizationsProvider).value!.map((o) => o.id), [
      'org-1',
      'org-2',
    ]);
  });

  test('falls back to the first organization', () async {
    final c = container();
    await settle(c);

    expect(c.read(activeOrganizationProvider)!.id, 'org-1');
  });

  test('selecting an organization is persisted for this account', () async {
    final c = container();
    await settle(c);

    await c.read(activeOrganizationSelectionProvider.notifier).select('org-2');
    await settle(c);

    expect(c.read(activeOrganizationProvider)!.id, 'org-2');
    expect(storage.values[activeOrganizationStorageKey('u-me')], 'org-2');
  });

  test('restores the saved choice of the account', () async {
    storage.values[activeOrganizationStorageKey('u-me')] = 'org-2';
    final c = container();
    await settle(c);
    await settle(c);

    expect(c.read(activeOrganizationProvider)!.id, 'org-2');
  });

  test('a saved organization that is gone falls back to the first', () async {
    storage.values[activeOrganizationStorageKey('u-me')] = 'org-gone';
    final c = container();
    await settle(c);
    await settle(c);

    expect(c.read(activeOrganizationProvider)!.id, 'org-1');
  });

  test('losing the active organization switches to another one', () async {
    final c = container();
    await settle(c);
    await c.read(activeOrganizationSelectionProvider.notifier).select('org-2');
    await settle(c);

    repository.setOrganizations([org('org-1', 'Grace Church')]);
    await settle(c);
    expect(c.read(activeOrganizationProvider)!.id, 'org-1');

    repository.setOrganizations(const []);
    await settle(c);
    expect(c.read(activeOrganizationProvider), isNull);
  });

  test('local mode: no organization, personal library is admin', () async {
    final c = container(signedIn: false);
    await settle(c);

    expect(c.read(activeOrganizationProvider), isNull);
    expect(c.read(isCurrentUserAdminProvider), isTrue);
    expect(c.read(teamMembersProvider), isEmpty);
  });

  test('admin is my role in the active organization', () async {
    final c = container();
    await settle(c);
    expect(c.read(isCurrentUserAdminProvider), isTrue);

    await c.read(activeOrganizationSelectionProvider.notifier).select('org-2');
    await settle(c);
    expect(c.read(isCurrentUserAdminProvider), isFalse);
  });

  test(
    'the current member is my membership in the active organization',
    () async {
      final c = container();
      await settle(c);
      expect(c.read(currentMemberProvider)!.id, 'm-me');

      await c
          .read(activeOrganizationSelectionProvider.notifier)
          .select('org-2');
      await settle(c);
      expect(c.read(currentMemberProvider)!.id, 'm-me2');
    },
  );

  test(
    'roster adapter maps members, skips deactivated ones, flags me',
    () async {
      repository.setMembers([
        member('m-me', 'u-me', 'Me', instruments: ['keys']),
        member('m-b', 'u-b', 'Bea', instruments: ['bass']),
        member('m-gone', 'u-g', 'Gone', deactivatedAt: DateTime(2026)),
      ]);
      final c = container();
      await settle(c);

      final roster = c.read(teamMembersProvider);
      expect(roster.map((m) => m.id), ['m-me', 'm-b']);
      expect(roster.first.isMe, isTrue);
      expect(roster.last.isMe, isFalse);
      expect(roster.last.groupIds, ['band-1']);
    },
  );

  test(
    'the active band filters the roster; switching organization resets it',
    () async {
      final c = container();
      await settle(c);

      c.read(activeBandIdProvider.notifier).select('band-1');
      expect(c.read(activeBandProvider)!.name, 'Alpha');
      expect(c.read(teamMembersProvider).map((m) => m.id), ['m-b']);

      await c
          .read(activeOrganizationSelectionProvider.notifier)
          .select('org-2');
      await settle(c);
      expect(c.read(activeBandIdProvider), isNull);
      expect(c.read(activeBandProvider), isNull);
    },
  );

  test(
    'account switch: the new account starts from its own saved choice',
    () async {
      storage.values[activeOrganizationStorageKey('u-other')] = 'org-2';
      final c = container();
      await settle(c);
      expect(c.read(currentAccountIdProvider), 'u-me');
      expect(c.read(activeOrganizationProvider)!.id, 'org-1');

      final other = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(meUser.copyWith(id: 'u-other')),
          ...signedInOverrides(repository, storage: storage).skip(1),
        ],
      );
      addTearDown(other.dispose);
      await settle(other);
      await settle(other);
      expect(other.read(activeOrganizationProvider)!.id, 'org-2');
    },
  );
}
