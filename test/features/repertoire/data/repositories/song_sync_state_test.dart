import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/repertoire/data/repositories/drift_setlist_repository.dart';
import 'package:battuta/features/repertoire/data/repositories/drift_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/features/score/data/repositories/drift_score_repository.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/score/domain/entities/time_signature.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_account_session.dart';

void main() {
  late AppDatabase db;
  late FakeAccountSession session;
  late DriftSongRepository songs;
  late DriftSetlistRepository setlists;
  late DriftScoreRepository scores;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    session = FakeAccountSession();
    songs = DriftSongRepository(db, session: session);
    setlists = DriftSetlistRepository(db, session: session);
    scores = DriftScoreRepository(db, session: session);
  });
  tearDown(() => db.close());

  Song song(String id, {String title = 'Song'}) => Song(
    id: id,
    title: title,
    artist: 'Artist',
    key: 'C',
    tempo: 100,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Setlist setlist(String id, {String? org}) => Setlist(
    id: id,
    title: id,
    organizationId: org,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Future<SongEntry> row(String id) =>
      (db.select(db.songs)..where((t) => t.id.equals(id))).getSingle();

  group('songs in local mode', () {
    test('are unowned and not marked for upload', () async {
      await songs.saveSong(song('a'));
      final r = await row('a');
      expect(r.ownerId, isNull);
      expect(r.accountId, isNull);
      expect(r.isDirty, isFalse);
    });

    test('delete removes the row for good', () async {
      await songs.saveSong(song('a'));
      expect((await songs.deleteSong('a')).isRight(), isTrue);
      expect(await db.select(db.songs).get(), isEmpty);
    });
  });

  group('songs of a signed-in account', () {
    setUp(() => session.signInAs('u1'));

    test('new songs belong to the account and wait for upload', () async {
      final saved = (await songs.saveSong(song('a')))
          .getOrElse((_) => throw 'x');
      expect(saved.ownerId, 'u1');
      final r = await row('a');
      expect(r.accountId, 'u1');
      expect(r.isDirty, isTrue);
      expect(r.visibility, 'private');
    });

    test('bundled samples stay unowned and local', () async {
      await songs.saveSong(song('seed-sample'));
      final r = await row('seed-sample');
      expect(r.ownerId, isNull);
      expect(r.accountId, isNull);
      expect(r.isDirty, isFalse);
    });

    test(
      'editing keeps the sync identity even if the editor rebuilt the song',
      () async {
        await db
            .into(db.songs)
            .insert(
              SongsCompanion.insert(
                id: 'v1',
                title: 'Old',
                artist: 'a',
                key: 'C',
                tempo: 100,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
                songWorkId: const Value('work-1'),
                ownerId: const Value('u1'),
                accountId: const Value('u1'),
                label: const Value('Acoustic'),
                visibility: const Value('organizations'),
                sharedOrganizationIdsJson: const Value('["o1"]'),
                remoteUpdatedAt: const Value('2026-11-10T10:00:00.000Z'),
              ),
            );
        final saved = (await songs.saveSong(song('v1', title: 'New')))
            .getOrElse((_) => throw 'x');
        expect(saved.songWorkId, 'work-1');
        expect(saved.label, 'Acoustic');
        expect(saved.visibility, SongVisibility.organizations);
        expect(saved.sharedOrganizationIds, ['o1']);
        final r = await row('v1');
        expect(r.title, 'New');
        expect(r.remoteUpdatedAt, '2026-11-10T10:00:00.000Z');
        expect(r.isDirty, isTrue);
      },
    );

    test('deleting a synced version leaves a hidden tombstone', () async {
      await db
          .into(db.songs)
          .insert(
            SongsCompanion.insert(
              id: 'v1',
              title: 'x',
              artist: 'a',
              key: 'C',
              tempo: 100,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
              ownerId: const Value('u1'),
              accountId: const Value('u1'),
              remoteUpdatedAt: const Value('2026-11-10T10:00:00.000Z'),
            ),
          );
      expect((await songs.deleteSong('v1')).isRight(), isTrue);
      final r = await row('v1');
      expect(r.deletedAt, isNotNull);
      expect(r.isDirty, isTrue);
      expect((await songs.getAllSongs()).getOrElse((_) => []), isEmpty);
      expect((await songs.getSongById('v1')).isLeft(), isTrue);
      expect((await songs.deleteSong('v1')).isLeft(), isTrue);
      // Saving it again brings it back.
      await songs.saveSong(song('v1'));
      expect((await row('v1')).deletedAt, isNull);
      expect((await songs.getAllSongs()).getOrElse((_) => []), hasLength(1));
    });

    test('versions of other users are read-only', () async {
      await db
          .into(db.songs)
          .insert(
            SongsCompanion.insert(
              id: 'theirs',
              title: 'Theirs',
              artist: 'a',
              key: 'C',
              tempo: 100,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
              ownerId: const Value('someone-else'),
              accountId: const Value('u1'),
              remoteUpdatedAt: const Value('2026-11-10T10:00:00.000Z'),
            ),
          );
      final listed = (await songs.getAllSongs()).getOrElse((_) => []);
      expect(listed.single.isEditableBy('u1'), isFalse);

      final save = await songs.saveSong(song('theirs', title: 'Mine now'));
      expect(
        save.swap().getOrElse((_) => throw 'x').errorCode,
        BackendErrorCode.notOwner,
      );
      final delete = await songs.deleteSong('theirs');
      expect(
        delete.swap().getOrElse((_) => throw 'x').errorCode,
        BackendErrorCode.notOwner,
      );
      expect((await row('theirs')).title, 'Theirs');
    });
  });

  group('edit time and sharing', () {
    setUp(() => session.signInAs('u1'));

    test(
      'every save moves the edit time forward, even within a millisecond',
      () async {
        await songs.saveSong(song('a'));
        final first = (await row('a')).editedAtMs;
        expect(first, greaterThan(0));
        // Pretend the previous save is in the future: the next one still moves on.
        await (db.update(db.songs)..where((t) => t.id.equals('a'))).write(
          SongsCompanion(editedAtMs: Value(first + 5000)),
        );
        await songs.saveSong(song('a'));
        expect((await row('a')).editedAtMs, first + 5001);

        await setlists.saveSetlist(setlist('l'));
        final listFirst = (await db.select(db.setlists).getSingle()).editedAtMs;
        await setlists.saveSetlist(setlist('l'));
        expect(
          (await db.select(db.setlists).getSingle()).editedAtMs,
          greaterThan(listFirst),
        );
      },
    );

    test('a save while a push is in flight keeps the row dirty', () async {
      await songs.saveSong(song('a'));
      final pushing = await row('a'); // what the push read
      // The push finishes and clears the flag only if the row is unchanged...
      Future<int> finishPush() =>
          (db.update(db.songs)..where(
                (t) =>
                    t.id.equals('a') & t.editedAtMs.equals(pushing.editedAtMs),
              ))
              .write(const SongsCompanion(isDirty: Value(false)));

      // ...which it is not when the user saved again in the same millisecond.
      await songs.saveSong(song('a', title: 'Edited again'));
      expect(await finishPush(), 0);
      expect((await row('a')).isDirty, isTrue);
    });

    test('updateSharing marks only the sharing for upload', () async {
      await songs.saveSong(song('a'));
      await (db.update(db.songs)).write(
        const SongsCompanion(
          isDirty: Value(false),
          remoteUpdatedAt: Value('A'),
        ),
      );
      final before = (await row('a')).editedAtMs;
      final updated = (await songs.updateSharing(
        'a',
        label: ' Band arrangement ',
        visibility: SongVisibility.organizations,
        sharedOrganizationIds: ['org-1'],
      )).getOrElse((_) => throw 'x');
      expect(updated.label, 'Band arrangement');
      expect(updated.visibility, SongVisibility.organizations);
      expect(updated.sharedOrganizationIds, ['org-1']);
      final r = await row('a');
      expect(r.isDirty, isTrue);
      expect(r.sharingDirty, isTrue);
      expect(r.editedAtMs, before);

      // Nothing changes: nothing is marked.
      await (db.update(db.songs)).write(
        const SongsCompanion(isDirty: Value(false), sharingDirty: Value(false)),
      );
      await songs.updateSharing('a', sharedOrganizationIds: ['org-1']);
      expect((await row('a')).isDirty, isFalse);

      // Going private drops the shares.
      final priv = (await songs.updateSharing(
        'a',
        visibility: SongVisibility.private,
      )).getOrElse((_) => throw 'x');
      expect(priv.sharedOrganizationIds, isEmpty);
      expect((await row('a')).sharedOrganizationIdsJson, '[]');
    });

    test('a normal save keeps pending sharing changes', () async {
      await songs.saveSong(song('a'));
      await songs.updateSharing('a', visibility: SongVisibility.public);
      await songs.saveSong(song('a', title: 'New title'));
      final r = await row('a');
      expect(r.sharingDirty, isTrue);
      expect(r.visibility, 'public');
    });

    test('updateSharing fails for versions of other users', () async {
      await db
          .into(db.songs)
          .insert(
            SongsCompanion.insert(
              id: 'theirs',
              title: 'Theirs',
              artist: 'a',
              key: 'C',
              tempo: 100,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
              ownerId: const Value('someone-else'),
              accountId: const Value('u1'),
            ),
          );
      final result = await songs.updateSharing(
        'theirs',
        visibility: SongVisibility.public,
      );
      expect(
        result.swap().getOrElse((_) => throw 'x').errorCode,
        BackendErrorCode.notOwner,
      );
    });
  });

  group('account scoping', () {
    test('each account only sees its own songs plus unclaimed ones', () async {
      await songs.saveSong(song('local'));
      session.signInAs('u1');
      await songs.saveSong(song('of-u1'));
      expect(
        (await songs.getAllSongs()).getOrElse((_) => []).map((s) => s.id),
        unorderedEquals(['local', 'of-u1']),
      );

      session.signInAs('u2');
      expect(
        (await songs.getAllSongs()).getOrElse((_) => []).map((s) => s.id),
        ['local'],
      );
      expect((await songs.getSongById('of-u1')).isLeft(), isTrue);
      // u2 cannot overwrite u1's row either.
      expect((await songs.saveSong(song('of-u1'))).isLeft(), isTrue);

      session.signInAs(null);
      expect(
        (await songs.getAllSongs()).getOrElse((_) => []).map((s) => s.id),
        ['local'],
      );
    });

    test('watchAllSongs switches with the account', () async {
      session.signInAs('u1');
      await songs.saveSong(song('of-u1'));
      final seen = <List<String>>[];
      final sub = songs.watchAllSongs().listen(
        (list) => seen.add(list.map((s) => s.id).toList()),
      );
      await pumpEventQueue();
      expect(seen.last, ['of-u1']);

      session.signInAs('u2');
      await pumpEventQueue();
      expect(seen.last, isEmpty);

      session.signInAs('u1');
      await pumpEventQueue();
      expect(seen.last, ['of-u1']);
      await sub.cancel();
    });
  });

  group('setlists', () {
    test(
      'local-mode setlists are unclaimed; account ones wait for upload',
      () async {
        await setlists.saveSetlist(setlist('l1'));
        expect((await db.select(db.setlists).getSingle()).accountId, isNull);
        expect((await db.select(db.setlists).getSingle()).isDirty, isFalse);

        session.signInAs('u1');
        await setlists.saveSetlist(setlist('l2'));
        final r = await (db.select(
          db.setlists,
        )..where((t) => t.id.equals('l2'))).getSingle();
        expect(r.accountId, 'u1');
        expect(r.isDirty, isTrue);
        expect(r.organizationId, isNull);
      },
    );

    test(
      'organization setlists are read-only unless the account is an admin',
      () async {
        session.signInAs('u1');
        final denied = await setlists.saveSetlist(
          setlist('org-list', org: 'o1'),
        );
        expect(
          denied.swap().getOrElse((_) => throw 'x').errorCode,
          BackendErrorCode.notAdmin,
        );

        final admin = DriftSetlistRepository(
          db,
          session: session,
          canAdministerOrganization: (org) => org == 'o1',
        );
        expect(
          (await admin.saveSetlist(setlist('org-list', org: 'o1'))).isRight(),
          isTrue,
        );
        // A setlist never moves between personal and organization.
        final moved = (await admin.saveSetlist(setlist('org-list')))
            .getOrElse((_) => throw 'x');
        expect(moved.organizationId, 'o1');

        // Members only read it.
        expect(
          (await setlists.deleteSetlist('org-list'))
              .swap()
              .getOrElse((_) => throw 'x')
              .errorCode,
          BackendErrorCode.notAdmin,
        );
        expect((await admin.deleteSetlist('org-list')).isRight(), isTrue);
      },
    );

    test('deleting a synced setlist leaves a hidden tombstone', () async {
      session.signInAs('u1');
      await db
          .into(db.setlists)
          .insert(
            SetlistsCompanion.insert(
              id: 'l1',
              title: 'x',
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
              accountId: const Value('u1'),
              remoteUpdatedAt: const Value('2026-11-10T10:00:00.000Z'),
            ),
          );
      expect((await setlists.deleteSetlist('l1')).isRight(), isTrue);
      expect((await setlists.getAllSetlists()).getOrElse((_) => []), isEmpty);
      final r = await db.select(db.setlists).getSingle();
      expect(r.deletedAt, isNotNull);
      expect(r.isDirty, isTrue);
    });

    test('tombstone entries and overrides survive a save', () async {
      session.signInAs('u1');
      const item = SetlistItem(
        id: 'i1',
        songId: '',
        orderIndex: 0,
        keyOverride: 'Bb',
        tempoOverride: 70,
        notes: 'n',
        titleSnapshot: 'Gone',
      );
      await setlists.saveSetlist(setlist('l1').copyWith(items: [item]));
      final back = (await setlists.getSetlistById('l1'))
          .getOrElse((_) => throw 'x');
      expect(back.items.single, item);
      expect(back.items.single.isTombstone, isTrue);
    });
  });

  group('scores', () {
    Score score(String id) => Score(
      id: id,
      title: 'Chart',
      timeSignature: const TimeSignature(4, 4),
      keySignature: 'C',
      tempo: 100,
      sections: const [],
    );

    test('a never synced score is deleted for good, a synced one leaves a tombstone', () async {
      await scores.saveScore(score('s1'), songId: 'v1');
      expect((await scores.deleteScore('s1')).isRight(), isTrue);
      expect(await db.select(db.scores).get(), isEmpty);

      await scores.saveScore(score('s2'), songId: 'v1');
      await (db.update(db.scores))
          .write(const ScoresCompanion(remoteUpdatedAt: Value('A')));
      expect((await scores.deleteScore('s2')).isRight(), isTrue);
      expect((await scores.getScoreById('s2')).isLeft(), isTrue);
      expect(
        (await scores.getScoreBySongId('v1')).getOrElse((_) => throw 'x'),
        isNull,
      );
      expect((await db.select(db.scores).getSingle()).deletedAt, isNotNull);
    });

    test('scores of another user\'s version are read-only', () async {
      session.signInAs('u1');
      await db
          .into(db.songs)
          .insert(
            SongsCompanion.insert(
              id: 'theirs',
              title: 'x',
              artist: 'a',
              key: 'C',
              tempo: 100,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
              ownerId: const Value('other'),
              accountId: const Value('u1'),
              remoteUpdatedAt: const Value('A'),
            ),
          );
      final save = await scores.saveScore(score('s1'), songId: 'theirs');
      expect(
        save.swap().getOrElse((_) => throw 'x').errorCode,
        BackendErrorCode.notOwner,
      );
    });

    test(
      'saving marks the score for upload and keeps its remote stamp',
      () async {
        await scores.saveScore(score('s1'), songId: 'v1');
        await (db.update(db.scores)).write(
          const ScoresCompanion(
            isDirty: Value(false),
            remoteUpdatedAt: Value('A'),
          ),
        );
        await scores.saveScore(score('s1'), songId: 'v1');
        final r = await db.select(db.scores).getSingle();
        expect(r.isDirty, isTrue);
        expect(r.remoteUpdatedAt, 'A');
      },
    );
  });
}
