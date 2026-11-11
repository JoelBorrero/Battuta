/// Song sharing against the local Supabase stack: an owner shares a version
/// with an organization, a member sees it in "Other versions" and forks it
/// (the owner is told), the owner makes it public and a third user finds it
/// in Discover, an offline fork is pushed later (with or without lineage),
/// two users typing the same song land on one song, and a version moves
/// to another song.
///
///   supabase db reset
///   flutter test --tags supabase --run-skipped test/integration
@Tags(['supabase'])
library;

import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/features/sharing/data/song_sharing_remote_data_source.dart';
import 'package:battuta/features/sharing/data/song_sharing_repository_impl.dart';
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
    // The song is private to Alice again, but the copy still joins it (the
    // backend matches by title and artist), so no empty song is left behind.
    expect(remote['song_id'], work);
  });

  itest(
    'two users create the same song independently and share one song',
    () async {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final aliceDevice = track(SongDevice.of(alice));
      final bobDevice = track(SongDevice.of(bob));
      final mine = newSong('Tú Fidelidad $stamp')
          .copyWith(artist: 'Marcos Witt');
      final theirs = newSong('tu  FIDELIDAD $stamp')
          .copyWith(artist: 'marcos witt');
      final workA = await publish(aliceDevice, mine);
      final workB = await publish(bobDevice, theirs);
      expect(workB, workA, reason: 'accents and case do not split a song');

      await share(aliceDevice, mine.id, SongVisibility.public);
      await share(bobDevice, theirs.id, SongVisibility.public);
      final versions = ok(
        await sharingOf(bobDevice).fetchVersionsOfSong(workA),
      );
      expect({for (final v in versions) v.versionId}, {mine.id, theirs.id});

      // Bob joined Alice's song: its title is hers to change.
      await bobDevice.syncOk();
      final bobVersion = ok(await bobDevice.songs.getSongById(theirs.id));
      expect(bobVersion.title, mine.title);
      expect(bobVersion.songCreatorId, alice.id);
      expect(bobVersion.canEditTitleBy(bob.id), isFalse);
    },
  );

  itest('a song typed while its only version is private still joins', () async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final aliceDevice = track(SongDevice.of(alice));
    final bobDevice = track(SongDevice.of(bob));
    final mine = newSong('Private Only $stamp');
    final workA = await publish(aliceDevice, mine);
    final theirs = newSong('private only $stamp');
    final workB = await publish(bobDevice, theirs);
    expect(workB, workA);
    // Bob never saw Alice's version.
    expect(
      ok(await sharingOf(bobDevice).fetchVersionsOfSong(workA))
          .map((v) => v.versionId),
      [theirs.id],
    );
  });

  itest(
    'a version moves to another song and the empty song disappears',
    () async {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final device = track(SongDevice.of(carol));
      final wrong = newSong('Wrong Song $stamp');
      final right = newSong('Right Song $stamp');
      final workWrong = await publish(device, wrong);
      final workRight = await publish(device, right);
      expect(workWrong, isNot(workRight));

      ok(
        await device.songs.moveToSong(
          wrong.id,
          songWorkId: workRight,
          title: right.title,
          artist: right.artist,
          songCreatorId: carol.id,
        ),
      );
      await device.syncOk();

      final moved = ok(await device.songs.getSongById(wrong.id));
      expect(moved.songWorkId, workRight);
      expect(moved.title, right.title);
      final remote = await remoteVersion(carol, wrong.id);
      expect(remote!['song_id'], workRight);
      final gone = await carol.client
          .from('songs')
          .select('id')
          .eq('id', workWrong);
      expect(
        gone,
        isEmpty,
        reason: 'the song left without versions is removed',
      );
    },
  );

  itest('renaming a song onto another one is refused', () async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final device = track(SongDevice.of(carol));
    final one = newSong('Rename One $stamp');
    final two = newSong('Rename Two $stamp');
    await publish(device, one);
    final workTwo = await publish(device, two);
    await expectLater(
      carol.client
          .from('songs')
          .update({'title': one.title, 'artist': one.artist})
          .eq('id', workTwo),
      throwsA(
        isA<Object>().having((e) => '$e', 'message', contains('song_exists')),
      ),
    );
  });

  itest('song search finds visible songs with their version count', () async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final device = track(SongDevice.of(carol));
    final song = newSong('Searchable Ñandú $stamp');
    final work = await publish(device, song);
    final found = ok(await sharingOf(device).searchSongs('nandu $stamp'));
    expect(found.map((s) => s.songWorkId), contains(work));
    expect(found.firstWhere((s) => s.songWorkId == work).versionCount, 1);
  });
}
