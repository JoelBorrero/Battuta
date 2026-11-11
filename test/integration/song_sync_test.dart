/// End-to-end tests of the song, score and setlist sync against the local
/// Supabase stack, with real sign-ups.
///
///   supabase db reset
///   flutter test --tags supabase --run-skipped test/integration
@Tags(['supabase'])
library;

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/repertoire/data/repositories/drift_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'support/song_device.dart';
import 'support/stack.dart';
import 'support/test_user.dart';

const _uuid = Uuid();

Song newSong(
  String title, {
  String? id,
  String key = 'G',
  DateTime? updatedAt,
  String lyrics = 'Amazing grace',
}) {
  final now = DateTime.now();
  return Song(
    id: id ?? _uuid.v4(),
    title: title,
    artist: 'Artist',
    key: key,
    tempo: 90,
    sections: [
      SongSection(id: 'sec-1', name: 'Verse', orderIndex: 0, lyrics: lyrics),
    ],
    createdAt: now,
    updatedAt: updatedAt ?? now,
  );
}

void main() {
  StackConfig? stack;
  late TestUser admin;
  late TestUser member;
  final created = <TestUser>[];
  final devices = <SongDevice>[];

  setUpAll(() async {
    stack = await resolveStack();
    if (stack == null) return;
    admin = await TestUser.signUp(stack!, 'sadmin');
    member = await TestUser.signUp(stack!, 'smember');
    created.addAll([admin, member]);
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

  Future<Map<String, dynamic>?> remoteVersion(TestUser u, String id) => u.client
      .from('song_versions')
      .select('*, songs(*)')
      .eq('id', id)
      .maybeSingle();

  /// Admin creates an organization and the member joins it.
  Future<Organization> orgWithMember() async {
    final org = ok(
      await admin.orgs.createOrganization(
        'Songs ${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    final link = ok(await admin.orgs.createInviteLink(org.id));
    ok(await member.orgs.joinWithInviteLink(link.token));
    return org;
  }

  /// The owner shares a (synced) version with an organization and the admin
  /// adds it to the repertoire.
  Future<void> publishToOrg(String versionId, String orgId) async {
    await admin.client
        .from('song_versions')
        .update({'visibility': 'organizations'})
        .eq('id', versionId);
    await admin.client.from('version_shares').insert({
      'version_id': versionId,
      'organization_id': orgId,
    });
    await admin.client.from('organization_repertoire').insert({
      'organization_id': orgId,
      'version_id': versionId,
      'added_by': admin.id,
    });
  }

  group('own songs', () {
    itest(
      'create, edit, delete and re-sync a version with its score',
      () async {
        final d = track(SongDevice.of(admin));
        final song = newSong('Create Edit Delete');
        ok(await d.songs.saveSong(song));
        final score = Score(
          id: _uuid.v4(),
          title: 'Chart',
          timeSignature: const TimeSignature(4, 4),
          keySignature: 'G',
          tempo: 90,
          sections: const [],
        );
        ok(await d.scores.saveScore(score, songId: song.id));

        final first = await d.syncOk();
        expect(first.pushedCount, greaterThanOrEqualTo(2));

        final remote = await remoteVersion(admin, song.id);
        expect(remote, isNotNull);
        expect(remote!['owner_id'], admin.id);
        expect(remote['visibility'], 'private');
        expect(remote['label'], 'Original');
        expect((remote['songs'] as Map)['title'], 'Create Edit Delete');
        final remoteScore = await admin.client
            .from('scores')
            .select()
            .eq('version_id', song.id);
        expect(remoteScore.single['id'], score.id);

        // Edit locally, sync, and the backend follows.
        ok(await d.songs.saveSong(song.copyWith(key: 'A', title: 'Renamed')));
        await d.syncOk();
        final edited = await remoteVersion(admin, song.id);
        expect(edited!['key'], 'A');
        expect((edited['songs'] as Map)['title'], 'Renamed');

        // A second sync with nothing to do pushes nothing.
        final idle = await d.syncOk();
        expect(idle.pushedCount, 0);

        // Delete: tombstone locally, gone remotely (score included) after sync.
        ok(await d.songs.deleteSong(song.id));
        expect(
          (await d.songs.getAllSongs())
              .getOrElse((_) => [])
              .where((s) => s.id == song.id),
          isEmpty,
        );
        await d.syncOk();
        expect(await remoteVersion(admin, song.id), isNull);
        expect(
          await admin.client.from('scores').select().eq('version_id', song.id),
          isEmpty,
        );
        expect(
          await d.db
              .select(d.db.songs)
              .get()
              .then((r) => r.where((s) => s.id == song.id)),
          isEmpty,
        );
      },
    );

    itest(
      'a second device of the same user converges (LWW) on edits and deletes',
      () async {
        final a = track(SongDevice.of(member));
        final b = track(await SongDevice.secondDeviceOf(member, stack!));

        final song = newSong('Two Devices', key: 'C');
        ok(await a.songs.saveSong(song));
        await a.syncOk();
        await b.syncOk();
        expect(
          (await b.songs.getSongById(song.id))
              .getOrElse((_) => throw 'missing')
              .key,
          'C',
        );

        // B edited first, A edited and synced afterwards: A's push is newer.
        ok(await b.songs.saveSong(song.copyWith(key: 'D')));
        ok(await a.songs.saveSong(song.copyWith(key: 'E')));
        await a.syncOk();
        await b.syncOk();
        expect(
          (await b.songs.getSongById(song.id))
              .getOrElse((_) => throw 'missing')
              .key,
          'E',
        );
        expect((await remoteVersion(member, song.id))!['key'], 'E');

        // B edits later than A's last push: B wins and A pulls it.
        ok(await b.songs.saveSong(song.copyWith(key: 'F')));
        await b.syncOk();
        await a.syncOk();
        expect(
          (await a.songs.getSongById(song.id))
              .getOrElse((_) => throw 'missing')
              .key,
          'F',
        );

        // A delete on one device reaches the other.
        ok(await a.songs.deleteSong(song.id));
        await a.syncOk();
        await b.syncOk();
        expect((await b.songs.getSongById(song.id)).isLeft(), isTrue);
        expect(await remoteVersion(member, song.id), isNull);
      },
    );

    itest('a delete loses against a later edit from another device', () async {
      final a = track(SongDevice.of(member));
      final b = track(await SongDevice.secondDeviceOf(member, stack!));
      final song = newSong('Delete Versus Edit');
      ok(await a.songs.saveSong(song));
      await a.syncOk();
      await b.syncOk();

      ok(await a.songs.deleteSong(song.id)); // offline on A
      ok(await b.songs.saveSong(song.copyWith(key: 'B')));
      await b.syncOk(); // the edit reaches the backend first
      await a.syncOk(); // A's delete is older than that edit: it is dropped
      expect((await remoteVersion(member, song.id))!['key'], 'B');
      expect(
        (await a.songs.getSongById(song.id))
            .getOrElse((_) => throw 'restored')
            .key,
        'B',
      );
    });
  });

  group('edit time decides conflicts', () {
    /// Two saves on different devices need different edit times.
    Future<void> tick() =>
        Future<void>.delayed(const Duration(milliseconds: 15));

    Future<String> keyOn(SongDevice d, String id) async =>
        (await d.songs.getSongById(id)).getOrElse((_) => throw 'missing').key;

    itest(
      'a later offline edit wins even when the earlier edit syncs first',
      () async {
        final a = track(SongDevice.of(member));
        final b = track(await SongDevice.secondDeviceOf(member, stack!));
        final song = newSong('Later Edit Wins', key: 'C');
        ok(await a.songs.saveSong(song));
        await a.syncOk();
        await b.syncOk();

        // B edits at T1, A edits at T2 > T1, B reaches the backend first.
        ok(await b.songs.saveSong(song.copyWith(key: 'D')));
        await tick();
        ok(await a.songs.saveSong(song.copyWith(key: 'E')));
        await b.syncOk();
        expect((await remoteVersion(member, song.id))!['key'], 'D');
        await a.syncOk();
        expect((await remoteVersion(member, song.id))!['key'], 'E');
        await b.syncOk();
        expect(await keyOn(b, song.id), 'E');
        expect(await keyOn(a, song.id), 'E');
      },
    );

    itest(
      'an earlier offline edit loses against a later one that synced first',
      () async {
        final a = track(SongDevice.of(member));
        final b = track(await SongDevice.secondDeviceOf(member, stack!));
        final song = newSong('Earlier Edit Loses', key: 'C');
        ok(await a.songs.saveSong(song));
        await a.syncOk();
        await b.syncOk();

        // A edits at T0, B edits at T1 > T0, B syncs first: A's push is stale.
        ok(await a.songs.saveSong(song.copyWith(key: 'E')));
        await tick();
        ok(await b.songs.saveSong(song.copyWith(key: 'D')));
        await b.syncOk();
        await a.syncOk();
        expect((await remoteVersion(member, song.id))!['key'], 'D');
        expect(await keyOn(a, song.id), 'D');
        final row = await (a.db.select(
          a.db.songs,
        )..where((t) => t.id.equals(song.id))).getSingle();
        expect(row.isDirty, isFalse);
      },
    );

    itest('the same rules apply to scores and setlists', () async {
      final a = track(SongDevice.of(member));
      final b = track(await SongDevice.secondDeviceOf(member, stack!));
      final song = newSong('Rules Everywhere');
      ok(await a.songs.saveSong(song));
      final setlist = Setlist(
        id: _uuid.v4(),
        title: 'Original',
        items: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      ok(await a.setlists.saveSetlist(setlist));
      await a.syncOk();
      await b.syncOk();

      ok(await b.setlists.saveSetlist(setlist.copyWith(title: 'From B')));
      await tick();
      ok(await a.setlists.saveSetlist(setlist.copyWith(title: 'From A')));
      await b.syncOk();
      await a.syncOk();
      await b.syncOk();
      for (final d in [a, b]) {
        expect(
          (await d.setlists.getSetlistById(setlist.id))
              .getOrElse((_) => throw 'missing')
              .title,
          'From A',
        );
      }
    });

    itest(
      'a song merge does not discard a pending edit of the owner',
      () async {
        final d = track(SongDevice.of(member));
        final one = newSong('Merge Pending One', key: 'C');
        final two = newSong('Merge Pending Two');
        ok(await d.songs.saveSong(one));
        ok(await d.songs.saveSong(two));
        await d.syncOk();

        // Edited offline, then a merge touches the backend row before the sync.
        ok(await d.songs.saveSong(one.copyWith(key: 'A')));
        final before = await remoteVersion(member, one.id);
        final sourceWork = before!['song_id'] as String;
        final targetWork =
            (await remoteVersion(member, two.id))!['song_id'] as String;
        await member.client.rpc(
          'request_song_merge',
          params: {'p_source_song': sourceWork, 'p_target_song': targetWork},
        );
        final merged = await remoteVersion(member, one.id);
        expect(merged!['song_id'], targetWork);
        expect(merged['updated_at'], isNot(before['updated_at']));
        expect(merged['edited_at'], before['edited_at']);

        await d.syncOk();
        expect((await remoteVersion(member, one.id))!['key'], 'A');
        expect(await keyOn(d, one.id), 'A');
        expect(
          (await d.songs.getSongById(one.id))
              .getOrElse((_) => throw 'missing')
              .songWorkId,
          targetWork,
        );
      },
    );
  });

  group('sharing', () {
    itest(
      'visibility, label and shares set locally reach the other members',
      () async {
        final org = await orgWithMember();
        final owner = track(SongDevice.of(admin));
        final reader = track(SongDevice.of(member));
        final song = newSong('Sharing Song');
        ok(await owner.songs.saveSong(song));
        await owner.syncOk();

        Future<void> addToRepertoire() =>
            admin.client.from('organization_repertoire').insert({
              'organization_id': org.id,
              'version_id': song.id,
              'added_by': admin.id,
            });
        Future<bool> memberSees() async {
          await reader.syncOk();
          return (await reader.songs.getSongById(song.id)).isRight();
        }

        // Share with the organization.
        ok(
          await owner.songs.updateSharing(
            song.id,
            label: 'Band arrangement',
            visibility: SongVisibility.organizations,
            sharedOrganizationIds: [org.id],
          ),
        );
        await owner.syncOk();
        final shared = await remoteVersion(admin, song.id);
        expect(shared!['visibility'], 'organizations');
        expect(shared['label'], 'Band arrangement');
        expect(
          await admin.client
              .from('version_shares')
              .select('organization_id')
              .eq('version_id', song.id),
          [
            {'organization_id': org.id},
          ],
        );
        await addToRepertoire();
        expect(await memberSees(), isTrue);

        // Remove the share, keeping the visibility: the member loses it.
        ok(
          await owner.songs.updateSharing(
            song.id,
            sharedOrganizationIds: const [],
          ),
        );
        await owner.syncOk();
        expect(
          await admin.client
              .from('version_shares')
              .select()
              .eq('version_id', song.id),
          isEmpty,
        );
        expect(await memberSees(), isFalse);

        // Add the share again: visible again.
        ok(
          await owner.songs.updateSharing(
            song.id,
            sharedOrganizationIds: [org.id],
          ),
        );
        await owner.syncOk();
        await addToRepertoire();
        expect(await memberSees(), isTrue);

        // Back to private.
        ok(
          await owner.songs.updateSharing(
            song.id,
            visibility: SongVisibility.private,
          ),
        );
        await owner.syncOk();
        expect((await remoteVersion(admin, song.id))!['visibility'], 'private');
        expect(await memberSees(), isFalse);
        final row = await (owner.db.select(
          owner.db.songs,
        )..where((t) => t.id.equals(song.id))).getSingle();
        expect(row.sharingDirty, isFalse);
        expect(row.isDirty, isFalse);
      },
    );

    itest(
      'a share the server refuses is reported once and not retried',
      () async {
        final stranger = await orgWithMember(); // admin and member belong to it
        final other = ok(
          await member.orgs.createOrganization(
            'Elsewhere ${DateTime.now().microsecondsSinceEpoch}',
          ),
        );
        final owner = track(SongDevice.of(admin));
        final song = newSong('Refused Share');
        ok(await owner.songs.saveSong(song));
        await owner.syncOk();

        // The admin is not a member of `other`.
        ok(
          await owner.songs.updateSharing(
            song.id,
            visibility: SongVisibility.organizations,
            sharedOrganizationIds: [stranger.id, other.id],
          ),
        );
        final first = await owner.sync.syncAll();
        expect(first.isSuccess, isFalse);
        expect(first.errorMessage, contains('sharing'));

        final row = await (owner.db.select(
          owner.db.songs,
        )..where((t) => t.id.equals(song.id))).getSingle();
        expect(row.sharingDirty, isFalse);
        expect(row.isDirty, isFalse);
        expect(row.sharedOrganizationIdsJson, isNot(contains(other.id)));
        // One refused organization does not drop the accepted one.
        expect(row.sharedOrganizationIdsJson, contains(stranger.id));

        final second = await owner.syncOk();
        expect(second.pushedCount, 0);
      },
    );

    itest('a locally created fork keeps its parent', () async {
      final owner = track(SongDevice.of(admin));
      final parent = newSong('Fork Parent');
      ok(await owner.songs.saveSong(parent));
      final fork = newSong('Fork Parent')
          .copyWith(forkedFromVersionId: parent.id, label: 'My copy');
      ok(await owner.songs.saveSong(fork));
      await owner.syncOk();
      expect(
        (await remoteVersion(admin, fork.id))!['forked_from_version_id'],
        parent.id,
      );
    });
  });

  group('first sign-in', () {
    itest('local-mode songs and setlists are claimed as private versions; samples stay local', () async {
      final user = await TestUser.signUp(stack!, 'claimer');
      created.add(user);
      final other = await TestUser.signUp(stack!, 'claimother');
      created.add(other);

      // Data created before any account existed.
      final db = AppDatabase(NativeDatabase.memory());
      final local = DriftSongRepository(db);
      ok(
        await local.saveSong(newSong('Legacy Song', id: 'song_1700000000000')),
      );
      ok(await local.saveSong(newSong('Bundled Sample', id: 'seed-sample')));

      final device = track(SongDevice(user.client, database: db));
      ok(
        await device.setlists.saveSetlist(
          Setlist(
            id: 'setlist_1700000000001',
            title: 'Old Setlist',
            items: const [
              SetlistItem(
                id: 'item_1_0',
                songId: 'song_1700000000000',
                orderIndex: 0,
                keyOverride: 'Bb',
              ),
              SetlistItem(id: 'item_1_1', songId: 'seed-sample', orderIndex: 1),
            ],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      );
      // Signed in now, so this one is already the user's own.
      final fresh = newSong('After Sign In');
      ok(await device.songs.saveSong(fresh));

      await device.syncOk();

      final remote = await user.client
          .from('song_versions')
          .select('id, label, visibility, owner_id, songs(title)')
          .eq('owner_id', user.id);
      expect(
        remote.map((r) => (r['songs'] as Map)['title']),
        unorderedEquals(['Legacy Song', 'After Sign In']),
      );
      expect(
        remote.every(
          (r) => r['visibility'] == 'private' && r['label'] == 'Original',
        ),
        isTrue,
      );
      final legacy = remote.firstWhere(
        (r) => (r['songs'] as Map)['title'] == 'Legacy Song',
      );
      expect(legacy['id'], isNot('song_1700000000000'));

      // The sample never left the device and is still listed.
      final listed = (await device.songs.getAllSongs()).getOrElse((_) => []);
      expect(
        listed.map((s) => s.title),
        containsAll(['Legacy Song', 'Bundled Sample', 'After Sign In']),
      );
      expect(
        listed.firstWhere((s) => s.title == 'Legacy Song').ownerId,
        user.id,
      );
      expect(listed.firstWhere((s) => s.id == 'seed-sample').ownerId, isNull);

      // The legacy setlist got UUIDs and links its song to the new version id.
      final lists = await user.client
          .from('setlists')
          .select('*, setlist_items!setlist_items_setlist_fkey(*)')
          .eq('owner_id', user.id);
      expect(lists, hasLength(1));
      expect(lists.single['id'], isNot('setlist_1700000000001'));
      final items =
          (lists.single['setlist_items'] as List).cast<Map<String, dynamic>>()
            ..sort(
              (a, b) => (a['position'] as int).compareTo(b['position'] as int),
            );
      expect(items.first['version_id'], legacy['id']);
      expect(items.first['key_override'], 'Bb');
      expect(items.last['version_id'], isNull);
      expect(items.last['title_snapshot'], 'Bundled Sample');
      // ...and keeps the link to the sample locally after a pull.
      final localLists = (await device.setlists.getAllSetlists()).getOrElse(
        (_) => [],
      );
      final local1 = localLists.single;
      expect(local1.items.map((i) => i.songId), [legacy['id'], 'seed-sample']);

      // A second account on the same device claims nothing and sees only the
      // unclaimed sample.
      final deviceB = track(SongDevice(other.client, database: db));
      await deviceB.syncOk();
      final seenByB = (await deviceB.songs.getAllSongs()).getOrElse((_) => []);
      expect(seenByB.map((s) => s.title), ['Bundled Sample']);
      final remoteB = await other.client
          .from('song_versions')
          .select('id')
          .eq('owner_id', other.id);
      expect(remoteB, isEmpty);
    });
  });

  group('organization repertoire', () {
    itest(
      'a member keeps an admin-curated version offline and cannot edit it',
      () async {
        final org = await orgWithMember();
        final adminDevice = track(SongDevice.of(admin));
        final song = newSong('Curated Song');
        ok(await adminDevice.songs.saveSong(song));
        await adminDevice.syncOk();
        await publishToOrg(song.id, org.id);

        final memberDevice = track(SongDevice.of(member));
        await memberDevice.syncOk();

        // Offline from now on: everything below reads the local database.
        final cached = (await memberDevice.songs.getSongById(song.id))
            .getOrElse((_) => throw 'not cached');
        expect(cached.title, 'Curated Song');
        expect(cached.ownerId, admin.id);
        expect(cached.visibility, SongVisibility.organizations);
        expect(cached.isEditableBy(member.id), isFalse);
        expect(cached.isEditableBy(admin.id), isTrue);

        final save = await memberDevice.songs.saveSong(
          cached.copyWith(key: 'F#'),
        );
        expect(save.isLeft(), isTrue);
        save.mapLeft((f) => expect(f.errorCode, BackendErrorCode.notOwner));
        final delete = await memberDevice.songs.deleteSong(song.id);
        delete.mapLeft((f) => expect(f.errorCode, BackendErrorCode.notOwner));
        expect(delete.isLeft(), isTrue);

        // The server refuses the same edit.
        final rows = await member.client
            .from('song_versions')
            .update({'key': 'F#'})
            .eq('id', song.id)
            .select();
        expect(rows, isEmpty);
        expect((await remoteVersion(admin, song.id))!['key'], 'G');

        // The admin's own device sees the sharing after its next sync.
        await adminDevice.syncOk();
        final own = (await adminDevice.songs.getSongById(song.id))
            .getOrElse((_) => throw 'missing');
        expect(own.visibility, SongVisibility.organizations);
        expect(own.sharedOrganizationIds, [org.id]);
      },
    );

    itest(
      'making a version private removes it from the member on the next sync',
      () async {
        final org = await orgWithMember();
        final adminDevice = track(SongDevice.of(admin));
        final song = newSong('Soon Private');
        ok(await adminDevice.songs.saveSong(song));
        await adminDevice.syncOk();
        await publishToOrg(song.id, org.id);

        final memberDevice = track(SongDevice.of(member));
        await memberDevice.syncOk();
        expect(
          (await memberDevice.songs.getSongById(song.id)).isRight(),
          isTrue,
        );

        await admin.client
            .from('song_versions')
            .update({'visibility': 'private'})
            .eq('id', song.id);
        await memberDevice.syncOk();
        expect(
          (await memberDevice.songs.getSongById(song.id)).isLeft(),
          isTrue,
        );
      },
    );

    itest(
      'after a merge the cached version follows the surviving song',
      () async {
        final org = await orgWithMember();
        final adminDevice = track(SongDevice.of(admin));
        final a = newSong('Merge Source Title');
        final b = newSong('Merge Target Title');
        ok(await adminDevice.songs.saveSong(a));
        ok(await adminDevice.songs.saveSong(b));
        await adminDevice.syncOk();
        await publishToOrg(a.id, org.id);
        await publishToOrg(b.id, org.id);

        final memberDevice = track(SongDevice.of(member));
        await memberDevice.syncOk();
        final before = (await memberDevice.songs.getSongById(a.id))
            .getOrElse((_) => throw 'missing');
        final targetWork =
            (await remoteVersion(admin, b.id))!['song_id'] as String;
        final sourceWork =
            (await remoteVersion(admin, a.id))!['song_id'] as String;
        expect(before.songWorkId, sourceWork);

        // The admin created both works, so the merge is accepted at once.
        await admin.client.rpc(
          'request_song_merge',
          params: {'p_source_song': sourceWork, 'p_target_song': targetWork},
        );

        await memberDevice.syncOk();
        final after = (await memberDevice.songs.getSongById(a.id))
            .getOrElse((_) => throw 'missing');
        expect(after.songWorkId, targetWork);
        expect(after.title, 'Merge Target Title');
      },
    );
  });

  group('setlists', () {
    itest(
      'a personal setlist with overrides round-trips to another device',
      () async {
        final a = track(SongDevice.of(member));
        final song = newSong('Setlist Song');
        ok(await a.songs.saveSong(song));
        final setlist = Setlist(
          id: _uuid.v4(),
          title: 'Sunday',
          description: 'Morning',
          eventDate: DateTime.utc(2027, 1, 3, 9),
          tags: const ['main'],
          items: [
            SetlistItem(
              id: _uuid.v4(),
              songId: song.id,
              orderIndex: 0,
              keyOverride: 'Bb',
              tempoOverride: 72,
              notes: 'slow intro',
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        ok(await a.setlists.saveSetlist(setlist));
        await a.syncOk();

        final b = track(await SongDevice.secondDeviceOf(member, stack!));
        await b.syncOk();
        final pulled = (await b.setlists.getSetlistById(setlist.id))
            .getOrElse((_) => throw 'missing');
        expect(pulled.title, 'Sunday');
        expect(pulled.description, 'Morning');
        expect(pulled.tags, ['main']);
        expect(pulled.organizationId, isNull);
        final item = pulled.items.single;
        expect(item.songId, song.id);
        expect(item.keyOverride, 'Bb');
        expect(item.tempoOverride, 72);
        expect(item.notes, 'slow intro');
        expect(item.titleSnapshot, 'Setlist Song');
        expect((await b.songs.getSongById(song.id)).isRight(), isTrue);

        // Edit on B (reorder + drop override), then A converges.
        ok(
          await b.setlists.saveSetlist(
            pulled.copyWith(
              title: 'Sunday 2',
              items: [pulled.items.single.copyWith(clearKeyOverride: true)],
            ),
          ),
        );
        await b.syncOk();
        await a.syncOk();
        final back = (await a.setlists.getSetlistById(setlist.id))
            .getOrElse((_) => throw 'missing');
        expect(back.title, 'Sunday 2');
        expect(back.items.single.keyOverride, isNull);
        expect(back.items.single.tempoOverride, 72);

        // Deleting the setlist propagates.
        ok(await a.setlists.deleteSetlist(setlist.id));
        await a.syncOk();
        await b.syncOk();
        expect((await b.setlists.getSetlistById(setlist.id)).isLeft(), isTrue);
      },
    );

    itest(
      'an entry whose version disappears becomes a read-only tombstone',
      () async {
        final a = track(SongDevice.of(member));
        final song = newSong('Vanishing Song');
        ok(await a.songs.saveSong(song));
        final setlist = Setlist(
          id: _uuid.v4(),
          title: 'Tombstones',
          items: [SetlistItem(id: _uuid.v4(), songId: song.id, orderIndex: 0)],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        ok(await a.setlists.saveSetlist(setlist));
        await a.syncOk();

        final b = track(await SongDevice.secondDeviceOf(member, stack!));
        await b.syncOk();

        // The owner deletes the version on A; the setlist keeps its entry.
        ok(await a.songs.deleteSong(song.id));
        await a.syncOk();
        // Touch the setlist so B downloads it again.
        final current = (await a.setlists.getSetlistById(setlist.id))
            .getOrElse((_) => throw 'missing');
        ok(await a.setlists.saveSetlist(current.copyWith()));
        await a.syncOk();
        await b.syncOk();

        expect((await b.songs.getSongById(song.id)).isLeft(), isTrue);
        final tomb = (await b.setlists.getSetlistById(setlist.id))
            .getOrElse((_) => throw 'missing')
            .items
            .single;
        expect(tomb.isTombstone, isTrue);
        expect(tomb.titleSnapshot, 'Vanishing Song');
      },
    );

    itest('organization setlists are read-only for members', () async {
      final org = await orgWithMember();
      final adminDevice = track(
        SongDevice.of(admin, canAdminister: (id) => id == org.id),
      );
      final song = newSong('Org Set Song');
      ok(await adminDevice.songs.saveSong(song));
      await adminDevice.syncOk();
      await publishToOrg(song.id, org.id);

      final setlist = Setlist(
        id: _uuid.v4(),
        title: 'Org Sunday',
        organizationId: org.id,
        items: [
          SetlistItem(
            id: _uuid.v4(),
            songId: song.id,
            orderIndex: 0,
            keyOverride: 'D',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      ok(await adminDevice.setlists.saveSetlist(setlist));
      await adminDevice.syncOk();

      final memberDevice = track(SongDevice.of(member));
      await memberDevice.syncOk();
      final seen = (await memberDevice.setlists.getSetlistById(setlist.id))
          .getOrElse((_) => throw 'missing');
      expect(seen.organizationId, org.id);
      expect(seen.items.single.keyOverride, 'D');
      expect(seen.items.single.songId, song.id);

      final save = await memberDevice.setlists.saveSetlist(
        seen.copyWith(title: 'Hacked'),
      );
      save.mapLeft((f) => expect(f.errorCode, BackendErrorCode.notAdmin));
      expect(save.isLeft(), isTrue);
      expect(
        (await memberDevice.setlists.deleteSetlist(setlist.id)).isLeft(),
        isTrue,
      );

      final updated = await member.client
          .from('setlists')
          .update({'title': 'Hacked'})
          .eq('id', setlist.id)
          .select();
      expect(updated, isEmpty);
      final deleted = await member.client
          .from('setlists')
          .delete()
          .eq('id', setlist.id)
          .select();
      expect(deleted, isEmpty);
    });
  });

  group('safety', () {
    itest('without a connection the sync reports offline and local saves still work', () async {
      final user = await TestUser.signUp(stack!, 'offliner');
      created.add(user);
      final device = track(SongDevice.of(user));
      ok(await device.songs.saveSong(newSong('Saved Offline')));

      // Sign out: no session means no sync, but nothing local changes.
      await user.client.auth.signOut();
      final result = await device.sync.syncAll();
      expect(result.isOffline, isTrue);
      expect(device.sync.isSyncing, isFalse);
      // Signed out the account's own songs are hidden, the data is intact.
      final rows = await device.db.select(device.db.songs).get();
      expect(rows.single.title, 'Saved Offline');
      expect(rows.single.isDirty, isTrue);
      await user.signIn();
      expect(
        (await device.songs.getAllSongs()).getOrElse((_) => []).single.title,
        'Saved Offline',
      );
      await device.syncOk();
    });

    itest('the account guard stops a sync when the account changes', () async {
      final user = await TestUser.signUp(stack!, 'switcher');
      created.add(user);
      final device = track(SongDevice.of(user));
      for (var i = 0; i < 5; i++) {
        ok(await device.songs.saveSong(newSong('Switch $i')));
      }
      final run = device.sync.syncAll();
      await user.client.auth.signOut();
      final result = await run;
      expect(result.isSuccess, isFalse);
      // The stale run did not mark rows as synced for a signed-out device after
      // the switch (some may have been pushed before it).
      expect(device.sync.isSyncing, isFalse);
      await device.db
          .update(device.db.songs)
          .write(const SongsCompanion(isDirty: Value(true)));
    });
  });
}
