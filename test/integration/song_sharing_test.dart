/// Song sharing against the local Supabase stack: an owner shares a version
/// with an organization, a member sees it in "Other versions" and forks it
/// (the owner is told), the owner makes it public and a third user finds it
/// in Discover, an offline fork is pushed later (with or without lineage),
/// and two creators merge duplicates.
///
///   supabase db reset
///   flutter test --tags supabase --run-skipped test/integration
@Tags(['supabase'])
library;

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/features/sharing/data/song_sharing_remote_data_source.dart';
import 'package:battuta/features/sharing/data/song_sharing_repository_impl.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
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

SongSharingRepositoryImpl sharingOf(SongDevice device, {bool online = true}) =>
    SongSharingRepositoryImpl(
      remote: SupabaseSongSharingRemoteDataSource(
        () => online ? device.client : null,
      ),
      db: device.db,
      session: device.session,
      songs: device.songs,
      scores: device.scores,
    );

void main() {
  StackConfig? stack;
  late TestUser alice;
  late TestUser bob;
  late TestUser carol;
  final created = <TestUser>[];
  final devices = <SongDevice>[];

  setUpAll(() async {
    stack = await resolveStack();
    if (stack == null) return;
    alice = await TestUser.signUp(stack!, 'shalice');
    bob = await TestUser.signUp(stack!, 'shbob');
    carol = await TestUser.signUp(stack!, 'shcarol');
    created.addAll([alice, bob, carol]);
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

  /// Alice creates an organization and Bob joins it. Carol stays outside.
  Future<Organization> aliceAndBobOrg() async {
    final org = ok(
      await alice.orgs.createOrganization(
        'Sharing ${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    final link = ok(await alice.orgs.createInviteLink(org.id));
    ok(await bob.orgs.joinWithInviteLink(link.token));
    return org;
  }

  /// Saves [song] on [device], syncs and returns the id of its work.
  Future<String> publish(SongDevice device, Song song) async {
    ok(await device.songs.saveSong(song));
    await device.syncOk();
    final stored = ok(await device.songs.getSongById(song.id));
    return stored.songWorkId!;
  }

  Future<void> share(
    SongDevice device,
    String id,
    SongVisibility visibility, {
    List<String> orgs = const [],
  }) async {
    ok(
      await device.songs.updateSharing(
        id,
        visibility: visibility,
        sharedOrganizationIds: orgs,
      ),
    );
    await device.syncOk();
  }

  Future<Map<String, dynamic>?> remoteVersion(TestUser u, String id) => u.client
      .from('song_versions')
      .select('*, songs(*)')
      .eq('id', id)
      .maybeSingle();

  itest(
    'share with an organization, fork, go public and be found in Discover',
    () async {
      final org = await aliceAndBobOrg();
      final aliceDevice = track(SongDevice.of(alice));
      final bobDevice = track(SongDevice.of(bob));
      final carolDevice = track(SongDevice.of(carol));
      final title = 'Shared Hymn ${DateTime.now().microsecondsSinceEpoch}';
      final song = newSong(title);
      final work = await publish(aliceDevice, song);

      // Private: nobody else sees it yet.
      expect(ok(await sharingOf(bobDevice).fetchVersionsOfSong(work)), isEmpty);

      await share(
        aliceDevice,
        song.id,
        SongVisibility.organizations,
        orgs: [org.id],
      );

      // The member sees it in "Other versions" with its owner; the outsider
      // does not.
      final bobSharing = sharingOf(bobDevice);
      final listed = ok(await bobSharing.fetchVersionsOfSong(work));
      expect(listed.map((v) => v.versionId), [song.id]);
      expect(listed.single.ownerName, alice.displayName);
      expect(listed.single.visibility, SongVisibility.organizations);
      expect(
        ok(await sharingOf(carolDevice).fetchVersionsOfSong(work)),
        isEmpty,
      );

      // The member opens it read-only, then forks it.
      final opened = ok(await bobSharing.openVersion(song.id));
      expect(opened.isEditableBy(bob.id), isFalse);
      expect(opened.songCreatorId, alice.id);
      final forked = ok(
        await bobSharing.forkVersion(song.id, label: 'Bob take'),
      );
      expect(forked.madeOffline, isFalse);
      expect(forked.song.ownerId, bob.id);
      expect(forked.song.songWorkId, work);
      expect(forked.song.forkedFromVersionId, song.id);
      expect(forked.song.visibility, SongVisibility.private);
      // The song is Alice's: Bob cannot rename it.
      expect(forked.song.canEditTitleBy(bob.id), isFalse);
      final renamed = ok(
        await bobDevice.songs.saveSong(
          forked.song.copyWith(title: 'Bob renamed it', key: 'A'),
        ),
      );
      expect(renamed.title, title);
      expect(renamed.key, 'A');

      // The owner was told.
      await eventually(() async {
        final notes = await alice.client
            .from('notifications')
            .select('payload')
            .eq('type', 'song_version_forked');
        return notes.any((n) => (n['payload'] as Map)['version_id'] == song.id);
      }, reason: 'the fork notification');

      // Bob's own list now shows both versions, once each.
      final both = ok(await bobSharing.fetchVersionsOfSong(work));
      expect({for (final v in both) v.versionId}, {song.id, forked.song.id});

      // Public: a third user finds it in Discover, opens it and forks it.
      await share(aliceDevice, song.id, SongVisibility.public);
      final carolSharing = sharingOf(carolDevice);
      final found = ok(await carolSharing.searchPublicVersions(title));
      expect(found.map((v) => v.versionId), [song.id]);
      expect(found.single.ownerName, alice.displayName);
      final carolCopy = ok(await carolSharing.openVersion(song.id));
      expect(carolCopy.isEditableBy(carol.id), isFalse);
      final carolFork = ok(await carolSharing.forkVersion(song.id));
      expect(carolFork.song.ownerId, carol.id);

      // Back to private: it leaves Discover.
      await share(aliceDevice, song.id, SongVisibility.private);
      expect(ok(await carolSharing.searchPublicVersions(title)), isEmpty);
    },
  );

  itest('a fork made offline is pushed later with its lineage', () async {
    final org = await aliceAndBobOrg();
    final aliceDevice = track(SongDevice.of(alice));
    final bobDevice = track(SongDevice.of(bob));
    final song = newSong(
      'Offline Fork ${DateTime.now().microsecondsSinceEpoch}',
    );
    final work = await publish(aliceDevice, song);
    await share(
      aliceDevice,
      song.id,
      SongVisibility.organizations,
      orgs: [org.id],
    );

    ok(await sharingOf(bobDevice).openVersion(song.id));
    // No connection: the copy is made on the device.
    final offline = sharingOf(bobDevice, online: false);
    final forked = ok(
      await offline.forkVersion(
        song.id,
        label: 'Offline copy',
        cachedSource: ok(await bobDevice.songs.getSongById(song.id)),
      ),
    );
    expect(forked.madeOffline, isTrue);

    await bobDevice.syncOk();
    final remote = await remoteVersion(bob, forked.song.id);
    expect(remote, isNotNull);
    expect(remote!['forked_from_version_id'], song.id);
    expect(remote['label'], 'Offline copy');
    expect(remote['song_id'], work);
    expect(remote['owner_id'], bob.id);
  });

  itest('an offline fork whose parent went private keeps its content, not the lineage', () async {
    final org = await aliceAndBobOrg();
    final aliceDevice = track(SongDevice.of(alice));
    final bobDevice = track(SongDevice.of(bob));
    final song = newSong(
      'Parent Hidden ${DateTime.now().microsecondsSinceEpoch}',
    );
    final work = await publish(aliceDevice, song);
    await share(
      aliceDevice,
      song.id,
      SongVisibility.organizations,
      orgs: [org.id],
    );
    ok(await sharingOf(bobDevice).openVersion(song.id));
    final forked = ok(
      await sharingOf(bobDevice, online: false).forkVersion(
        song.id,
        label: 'Orphan',
        cachedSource: ok(await bobDevice.songs.getSongById(song.id)),
      ),
    );

    // The parent goes private before Bob is back online.
    await share(aliceDevice, song.id, SongVisibility.private);
    await bobDevice.syncOk();

    final remote = await remoteVersion(bob, forked.song.id);
    expect(remote, isNotNull, reason: 'the copy still reaches the backend');
    expect(remote!['forked_from_version_id'], isNull);
    expect(remote['label'], 'Orphan');
    // The song is private to Alice again, so the copy starts one of its own.
    expect(remote['song_id'], isNot(work));
    expect((remote['songs'] as Map)['created_by'], bob.id);
  });

  itest(
    'two creators merge duplicates and the member\'s fork follows the survivor',
    () async {
      final org = await aliceAndBobOrg();
      final aliceDevice = track(SongDevice.of(alice));
      final bobDevice = track(SongDevice.of(bob));

      // Alice's song A (shared), Bob's fork of it, and Bob's own duplicate B.
      final a = newSong('Dup Hymn A ${DateTime.now().microsecondsSinceEpoch}');
      final workA = await publish(aliceDevice, a);
      await share(
        aliceDevice,
        a.id,
        SongVisibility.organizations,
        orgs: [org.id],
      );
      final bobSharing = sharingOf(bobDevice);
      final fork = ok(await bobSharing.forkVersion(a.id, label: 'Bob on A'));

      final b = newSong('Dup Hymn B ${DateTime.now().microsecondsSinceEpoch}');
      final workB = await publish(bobDevice, b);
      await share(
        bobDevice,
        b.id,
        SongVisibility.organizations,
        orgs: [org.id],
      );

      // Alice finds Bob's song when she searches, and asks to merge A into B.
      final aliceSharing = sharingOf(aliceDevice);
      final candidates = ok(await aliceSharing.searchSongs(b.title));
      expect(candidates.map((s) => s.id), contains(workB));
      final request = ok(
        await aliceSharing.requestMerge(
          sourceSongId: workA,
          targetSongId: workB,
        ),
      );
      expect(request.isPending, isTrue);
      expect(request.sourceTitle, a.title);
      expect(request.targetTitle, b.title);

      // The same pair cannot be requested twice, and both sides see it pending.
      expect(
        failed(
          await aliceSharing.requestMerge(
            sourceSongId: workA,
            targetSongId: workB,
          ),
        ),
        BackendErrorCode.mergeAlreadyRequested,
      );
      final bobPending = ok(await bobSharing.pendingMergeRequests());
      expect(bobPending.any((r) => r.id == request.id), isTrue);
      expect(
        ok(await aliceSharing.pendingMergeRequests())
            .any((r) => r.connects(workA, workB)),
        isTrue,
      );

      // Bob (the approver) reads the request with both titles and accepts.
      final seen = ok(await bobSharing.fetchMergeRequest(request.id));
      expect(seen.sourceTitle, a.title);
      expect(seen.requesterName, alice.displayName);
      expect(seen.approverId, bob.id);
      // Alice cannot answer her own request.
      expect(
        failed(await aliceSharing.respondToMerge(request.id, accept: true)),
        BackendErrorCode.mergeRequestNotFound,
      );
      final answered = ok(
        await bobSharing.respondToMerge(request.id, accept: true),
      );
      expect(answered.status, MergeRequestStatus.accepted);
      expect(
        failed(await bobSharing.respondToMerge(request.id, accept: true)),
        BackendErrorCode.mergeNotPending,
      );

      // Alice is told, and the surviving song is Bob's.
      await eventually(() async {
        final notes = await alice.client
            .from('notifications')
            .select('payload')
            .eq('type', 'song_merge_accepted');
        return notes.any(
          (n) => (n['payload'] as Map)['target_song_id'] == workB,
        );
      }, reason: 'the merge result notification');
      final survivor = ok(await aliceSharing.fetchSong(workA));
      expect(survivor.id, workB);
      expect(survivor.title, b.title);

      // Bob's fork (and Alice's version) now live under the surviving song.
      await bobDevice.syncOk();
      await aliceDevice.syncOk();
      final bobFork = ok(await bobDevice.songs.getSongById(fork.song.id));
      expect(bobFork.songWorkId, workB);
      expect(bobFork.title, b.title);
      final aliceVersion = ok(await aliceDevice.songs.getSongById(a.id));
      expect(aliceVersion.songWorkId, workB);
      // The title now belongs to Bob's song: Alice can no longer rename it.
      expect(aliceVersion.canEditTitleBy(alice.id), isFalse);
      final versions = ok(await bobSharing.fetchVersionsOfSong(workB));
      expect({
        for (final v in versions) v.versionId,
      }, containsAll([a.id, fork.song.id, b.id]));
    },
  );

  itest('a merge between two songs of the same creator is immediate', () async {
    final device = track(SongDevice.of(carol));
    final one = newSong(
      'Same Creator One ${DateTime.now().microsecondsSinceEpoch}',
    );
    final two = newSong(
      'Same Creator Two ${DateTime.now().microsecondsSinceEpoch}',
    );
    final workOne = await publish(device, one);
    final workTwo = await publish(device, two);

    final sharing = sharingOf(device);
    final merged = ok(
      await sharing.requestMerge(sourceSongId: workOne, targetSongId: workTwo),
    );
    expect(merged.status, MergeRequestStatus.accepted);
    expect(ok(await sharing.fetchSong(workOne)).id, workTwo);
    // Searching leaves merged-away songs out.
    final found = ok(await sharing.searchSongs('Same Creator One'));
    expect(found.map((s) => s.id), isNot(contains(workOne)));
  });

  itest('declining a merge leaves both songs alone', () async {
    final org = await aliceAndBobOrg();
    final aliceDevice = track(SongDevice.of(alice));
    final bobDevice = track(SongDevice.of(bob));
    final a = newSong('Keep Apart A ${DateTime.now().microsecondsSinceEpoch}');
    final b = newSong('Keep Apart B ${DateTime.now().microsecondsSinceEpoch}');
    final workA = await publish(aliceDevice, a);
    final workB = await publish(bobDevice, b);
    await share(bobDevice, b.id, SongVisibility.organizations, orgs: [org.id]);

    final aliceSharing = sharingOf(aliceDevice);
    final request = ok(
      await aliceSharing.requestMerge(sourceSongId: workA, targetSongId: workB),
    );
    final declined = ok(
      await sharingOf(bobDevice).respondToMerge(request.id, accept: false),
    );
    expect(declined.status, MergeRequestStatus.declined);
    expect(ok(await aliceSharing.fetchSong(workA)).id, workA);
    expect(ok(await aliceSharing.fetchSong(workB)).id, workB);
  });
}
