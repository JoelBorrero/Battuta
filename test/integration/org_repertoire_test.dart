/// Organization repertoire and admin tools against the local Supabase stack:
/// an admin curates the repertoire with a member's shared version, readers get
/// it read-only after a sync, org setlists are admin-only, and an
/// organization is archived once every admin approved.
///
///   supabase db reset
///   flutter test --tags supabase --run-skipped test/integration
@Tags(['supabase'])
library;

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/data/organization_repertoire_remote_data_source.dart';
import 'package:battuta/features/organizations/data/organization_repertoire_repository_impl.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'support/song_device.dart';
import 'support/stack.dart';
import 'support/test_user.dart';

const _uuid = Uuid();

Song newSong(String title) {
  final now = DateTime.now();
  return Song(
    id: _uuid.v4(),
    title: title,
    artist: 'Artist',
    key: 'G',
    tempo: 90,
    sections: const [SongSection(id: 'sec-1', name: 'Verse', orderIndex: 0)],
    createdAt: now,
    updatedAt: now,
  );
}

OrganizationRepertoireRepositoryImpl repertoireOf(TestUser user) =>
    OrganizationRepertoireRepositoryImpl(
      remote: SupabaseOrganizationRepertoireRemoteDataSource(() => user.client),
      cache: user.cache,
      session: user.session,
    );

void main() {
  StackConfig? stack;
  late TestUser admin;
  late TestUser owner;
  late TestUser reader;
  final created = <TestUser>[];
  final devices = <SongDevice>[];

  setUpAll(() async {
    stack = await resolveStack();
    if (stack == null) return;
    admin = await TestUser.signUp(stack!, 'rpadmin');
    owner = await TestUser.signUp(stack!, 'rpowner');
    reader = await TestUser.signUp(stack!, 'rpreader');
    created.addAll([admin, owner, reader]);
  });

  tearDownAll(() async {
    for (final d in devices) {
      await d.dispose();
    }
    for (final user in created) {
      await user.dispose();
    }
  });

  void itest(String name, Future<void> Function() body) {
    test(name, () async {
      if (stack == null) {
        markTestSkipped(
          'Supabase stack not available: set SUPABASE_TEST_URL / '
          'SUPABASE_TEST_ANON_KEY or run `supabase start`.',
        );
        return;
      }
      await body();
    });
  }

  SongDevice track(SongDevice d) {
    devices.add(d);
    return d;
  }

  Future<Organization> newOrg(String label, List<TestUser> members) async {
    final org = ok(
      await admin.orgs.createOrganization(
        '$label ${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    final link = ok(await admin.orgs.createInviteLink(org.id, maxUses: 5));
    for (final user in members) {
      ok(await user.orgs.joinWithInviteLink(link.token));
    }
    return org;
  }

  itest(
    'an admin curates the repertoire; a reader gets it read-only after a sync, '
    'org setlists are admin-only',
    () async {
      final org = await newOrg('Repertoire', [owner, reader]);

      // The owner (a member) writes a song and shares it with the organization.
      final ownerDevice = track(SongDevice.of(owner));
      final song = newSong('Shared Hymn');
      ok(await ownerDevice.songs.saveSong(song));
      await ownerDevice.syncOk();
      ok(
        await ownerDevice.songs.updateSharing(
          song.id,
          visibility: SongVisibility.organizations,
          sharedOrganizationIds: [org.id],
        ),
      );
      await ownerDevice.syncOk();

      // The admin finds it in the picker, labelled with its owner, and adds it.
      final adminRepertoire = repertoireOf(admin);
      final found = ok(
        await adminRepertoire.searchCandidates(org.id, 'shared'),
      );
      final candidate = found.firstWhere(
        (c) => c.versionId == song.id,
        orElse: () => fail('the shared version is not offered'),
      );
      expect(candidate.ownerName, owner.displayName);
      ok(await adminRepertoire.addToRepertoire(org.id, candidate));

      // A private version of the owner is never offered.
      final secret = newSong('Secret Draft');
      ok(await ownerDevice.songs.saveSong(secret));
      await ownerDevice.syncOk();
      expect(
        ok(await adminRepertoire.searchCandidates(org.id, 'secret')),
        isEmpty,
      );

      // A member cannot curate.
      final readerRepertoire = repertoireOf(reader);
      final denied = failed(
        await readerRepertoire.addToRepertoire(org.id, candidate),
      );
      expect(
        denied,
        anyOf(BackendErrorCode.notAdmin, BackendErrorCode.permissionDenied),
      );

      // The reader sees the entry (cached, with the owner) and, after a sync,
      // the version itself, which they cannot edit.
      ok(await readerRepertoire.refreshRepertoire(org.id));
      final entries = await readerRepertoire.watchRepertoire(org.id).first;
      expect(entries.map((e) => e.versionId), [song.id]);
      expect(entries.single.title, 'Shared Hymn');
      expect(entries.single.ownerName, owner.displayName);
      expect(entries.single.ownerDeactivated, isFalse);

      final readerDevice = track(
        SongDevice.of(reader, canAdminister: (_) => false),
      );
      await readerDevice.syncOk();
      final cached = (await readerDevice.songs.getSongById(song.id))
          .getOrElse((_) => throw 'not cached');
      expect(cached.isEditableBy(reader.id), isFalse);
      expect(cached.ownerId, owner.id);
      final edit = await readerDevice.songs.saveSong(cached.copyWith(key: 'F'));
      expect(failed(edit), BackendErrorCode.notOwner);

      // The admin builds an organization setlist from the repertoire.
      final adminDevice = track(
        SongDevice.of(admin, canAdminister: (id) => id == org.id),
      );
      await adminDevice.syncOk();
      final setlist = Setlist(
        id: _uuid.v4(),
        title: 'Sunday',
        organizationId: org.id,
        items: [SetlistItem(id: _uuid.v4(), songId: song.id, orderIndex: 0)],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      ok(await adminDevice.setlists.saveSetlist(setlist));
      await adminDevice.syncOk();

      // Readers get it, but a member cannot save it.
      await readerDevice.syncOk();
      final seen = (await readerDevice.setlists.getAllSetlists()).getOrElse(
        (_) => [],
      );
      expect(seen.map((s) => s.title), ['Sunday']);
      expect(seen.single.organizationId, org.id);
      expect(seen.single.items.single.songId, song.id);
      expect(
        failed(await readerDevice.setlists.saveSetlist(seen.single)),
        BackendErrorCode.notAdmin,
      );

      // Removing the version from the repertoire keeps the setlist entry as a
      // title snapshot (tombstone) and drops the version for the reader.
      ok(await adminRepertoire.removeFromRepertoire(org.id, song.id));
      ok(await readerRepertoire.refreshRepertoire(org.id));
      expect(await readerRepertoire.watchRepertoire(org.id).first, isEmpty);
      final items = await admin.client
          .from('setlist_items')
          .select('version_id, title_snapshot')
          .eq('setlist_id', setlist.id);
      expect(items.single['version_id'], isNull);
      expect(items.single['title_snapshot'], 'Shared Hymn');
    },
  );

  itest('two admins archive the organization', () async {
    final org = await newOrg('Archive', [owner]);
    ok(await owner.orgs.refreshMembers(org.id));
    final members = await owner.orgs.watchMembers(org.id).first;
    final ownerMember = members.firstWhere((m) => m.userId == owner.id);
    ok(
      await admin.orgs.setMemberRole(
        org.id,
        ownerMember.id,
        OrganizationRole.admin,
      ),
    );

    // The first admin requests; the organization is still active.
    final requested = ok(await admin.orgs.requestArchive(org.id));
    expect(requested.isArchived, isFalse);
    ok(await owner.orgs.refreshArchiveRequest(org.id));
    final request = await owner.orgs.watchArchiveRequest(org.id).first;
    expect(request, isNotNull);
    expect(request!.isApprovedBy(admin.id), isTrue);
    expect(request.isApprovedBy(owner.id), isFalse);

    // The second approves: archived, and it leaves the switcher.
    final archived = ok(await owner.orgs.approveArchive(org.id));
    expect(archived.isArchived, isTrue);
    ok(await admin.orgs.refreshOrganizations());
    final visible = await admin.orgs.watchOrganizations().first;
    expect(visible.map((o) => o.id), isNot(contains(org.id)));
    final all = await admin.orgs
        .watchOrganizations(includeArchived: true)
        .first;
    expect(all.firstWhere((o) => o.id == org.id).isArchived, isTrue);

    // Archived organizations are read-only.
    expect(
      failed(await admin.orgs.renameOrganization(org.id, 'Nope')),
      BackendErrorCode.organizationArchived,
    );
  });

  itest('a request can be cancelled before everyone approves', () async {
    final org = await newOrg('Cancel', [owner]);
    ok(await owner.orgs.refreshMembers(org.id));
    final ownerMember = (await owner.orgs.watchMembers(org.id).first)
        .firstWhere((m) => m.userId == owner.id);
    ok(
      await admin.orgs.setMemberRole(
        org.id,
        ownerMember.id,
        OrganizationRole.admin,
      ),
    );

    ok(await admin.orgs.requestArchive(org.id));
    ok(await admin.orgs.cancelArchive(org.id));
    ok(await admin.orgs.refreshArchiveRequest(org.id));
    expect(await admin.orgs.watchArchiveRequest(org.id).first, isNull);

    // Nothing is left to approve.
    expect(
      failed(await owner.orgs.approveArchive(org.id)),
      BackendErrorCode.archiveNotRequested,
    );
    final stillActive = await admin.orgs.watchOrganizations().first;
    expect(stillActive.map((o) => o.id), contains(org.id));
  });
}
