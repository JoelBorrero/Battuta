import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/repertoire/data/repositories/drift_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/features/score/data/repositories/drift_score_repository.dart';
import 'package:battuta/features/sharing/data/song_sharing_repository_impl.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_account_session.dart';
import '../../../support/fake_song_sharing.dart';

Map<String, dynamic> remoteRow(
  String id, {
  String owner = 'u-x',
  String label = 'Original',
  String? forkedFrom,
  String creator = 'u-x',
  String visibility = 'public',
}) => {
  'id': id,
  'song_id': 'work-1',
  'owner_id': owner,
  'label': label,
  'visibility': visibility,
  'forked_from_version_id': forkedFrom,
  'key': 'D',
  'tempo': 80,
  'time_signature_beats': 4,
  'time_signature_beat_value': 4,
  'sections_json': '[]',
  'tags_json': '[]',
  'created_at': '2026-11-01T10:00:00Z',
  'updated_at': '2026-11-01T10:00:00Z',
  'edited_at': '2026-11-01T10:00:00Z',
  'songs': {
    'id': 'work-1',
    'title': 'Amazing Grace',
    'artist': 'Newton',
    'created_by': creator,
  },
  'version_shares': <Object>[],
};

void main() {
  late AppDatabase db;
  late FakeAccountSession session;
  late FakeSongSharingRemote remote;
  late DriftSongRepository songs;
  late DriftScoreRepository scores;
  late SongSharingRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    session = FakeAccountSession('u-me');
    remote = FakeSongSharingRemote();
    songs = DriftSongRepository(db, session: session);
    scores = DriftScoreRepository(db, session: session);
    repository = SongSharingRepositoryImpl(
      remote: remote,
      db: db,
      session: session,
      songs: songs,
      scores: scores,
    );
  });
  tearDown(() => db.close());

  Failure failureOf<T>(dynamic either) =>
      (either as dynamic).swap().getOrElse((_) => throw 'expected a failure')
          as Failure;

  Song localVersion({
    String id = 'v-src',
    String? owner,
    String? creator,
    String? forkedFrom,
  }) => Song(
    id: id,
    title: 'Amazing Grace',
    artist: 'Newton',
    key: 'G',
    tempo: 72,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    songWorkId: 'work-1',
    ownerId: owner,
    songCreatorId: creator,
    forkedFromVersionId: forkedFrom,
  );

  group('openVersion', () {
    test('caches another user\'s version read-only', () async {
      remote.rows['v-ext'] = remoteRow('v-ext');
      final song = (await repository.openVersion('v-ext'))
          .getOrElse((_) => throw 'x');

      expect(song.ownerId, 'u-x');
      expect(song.title, 'Amazing Grace');
      expect(song.songCreatorId, 'u-x');
      expect(song.visibility, SongVisibility.public);
      expect(song.isEditableBy('u-me'), isFalse);
      // It is in the local database, owned by somebody else, and clean.
      final stored = await (db.select(db.songs)).getSingle();
      expect(stored.accountId, 'u-me');
      expect(stored.isDirty, isFalse);
      expect(stored.remoteUpdatedAt, isNotNull);
      final save = await songs.saveSong(song.copyWith(key: 'A'));
      expect(failureOf(save).errorCode, BackendErrorCode.notOwner);
    });

    test('needs an account', () async {
      session.signInAs(null);
      final result = await repository.openVersion('v-ext');
      expect(failureOf(result).errorCode, BackendErrorCode.notSignedIn);
    });

    test('a missing version is a failure, not an exception', () async {
      final result = await repository.openVersion('nope');
      expect(failureOf(result).errorCode, BackendErrorCode.versionNotFound);
    });

    test('never overwrites a local edit of the same version', () async {
      remote.rows['v-mine'] = remoteRow(
        'v-mine',
        owner: 'u-me',
        creator: 'u-me',
      );
      await songs.saveSong(localVersion(id: 'v-mine').copyWith(key: 'E'));
      final song = (await repository.openVersion('v-mine'))
          .getOrElse((_) => throw 'x');
      expect(song.key, 'E');
    });
  });

  group('forkVersion', () {
    test('online it uses the backend and caches the copy as mine', () async {
      remote.forkRow = remoteRow(
        'v-new',
        owner: 'u-me',
        forkedFrom: 'v-ext',
        visibility: 'private',
      );
      final forked = (await repository.forkVersion(
        'v-ext',
        label: ' Mine ',
      )).getOrElse((_) => throw 'x');

      expect(remote.calls, ['fork:v-ext:Mine']);
      expect(forked.madeOffline, isFalse);
      expect(forked.song.id, 'v-new');
      expect(forked.song.label, 'Mine');
      expect(forked.song.ownerId, 'u-me');
      expect(forked.song.forkedFromVersionId, 'v-ext');
      expect(forked.song.isEditableBy('u-me'), isTrue);
      // The song belongs to somebody else: the title stays theirs.
      expect(forked.song.canEditTitleBy('u-me'), isFalse);
    });

    test(
      'offline it makes a local fork with the lineage and the score',
      () async {
        remote.failure = offlineFailure();
        final source = localVersion(owner: 'u-x', creator: 'u-x');
        // Cached copy of somebody else's version, as the sync leaves it.
        await db
            .into(db.songs)
            .insert(
              SongsCompanion.insert(
                id: source.id,
                title: source.title,
                artist: source.artist,
                key: source.key,
                tempo: source.tempo,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
                songWorkId: Value(source.songWorkId),
                ownerId: Value(source.ownerId),
                accountId: const Value('u-me'),
                songCreatorId: Value(source.songCreatorId),
              ),
            );
        // The cached copy is read-only, so seed its score directly.
        await db
            .into(db.scores)
            .insert(
              ScoresCompanion.insert(
                id: 'score-src',
                songId: const Value('v-src'),
                title: 'Chart',
                timeSignatureJson: '{"numerator":4,"denominator":4}',
                keySignature: 'G',
                tempo: 72,
                sectionsJson: '[]',
                updatedAt: DateTime(2026),
              ),
            );

        final forked = (await repository.forkVersion(
          'v-src',
          label: 'My take',
          cachedSource: source,
        )).getOrElse((_) => throw 'x');

        expect(forked.madeOffline, isTrue);
        expect(forked.song.id, isNot('v-src'));
        expect(forked.song.label, 'My take');
        expect(forked.song.forkedFromVersionId, 'v-src');
        expect(forked.song.songWorkId, 'work-1');
        expect(forked.song.ownerId, 'u-me');
        expect(forked.song.visibility, SongVisibility.private);
        expect(forked.song.songCreatorId, 'u-x');
        final row = await (db.select(
          db.songs,
        )..where((t) => t.id.equals(forked.song.id))).getSingle();
        // Pushed by the next sync.
        expect(row.isDirty, isTrue);
        // The score was copied under a new id.
        final copied = await (db.select(
          db.scores,
        )..where((t) => t.songId.equals(forked.song.id))).get();
        expect(copied, hasLength(1));
        expect(copied.single.id, isNot('score-src'));
      },
    );

    test(
      'a fork of my own version stays under my song (title editable)',
      () async {
        remote.failure = offlineFailure();
        final source = localVersion(owner: 'u-me');
        final forked = (await repository.forkVersion(
          'v-src',
          label: 'Variant',
          cachedSource: source,
        )).getOrElse((_) => throw 'x');
        expect(forked.song.songCreatorId, 'u-me');
        expect(forked.song.canEditTitleBy('u-me'), isTrue);
      },
    );

    test('a blank name falls back to "<label> (copy)"', () async {
      remote.failure = offlineFailure();
      final forked = (await repository.forkVersion(
        'v-src',
        label: '  ',
        cachedSource: localVersion(owner: 'u-me').copyWith(label: 'Live'),
      )).getOrElse((_) => throw 'x');
      expect(forked.song.label, 'Live (copy)');
    });

    test('offline without the version on the device is a failure', () async {
      remote.failure = offlineFailure();
      final result = await repository.forkVersion('v-ext', label: 'x');
      expect(failureOf(result).errorCode, BackendErrorCode.offline);
      expect(await db.select(db.songs).get(), isEmpty);
    });

    test('a version the backend does not know yet is forked locally', () async {
      // Mine, never synced: the backend answers version_not_found.
      final source = localVersion(owner: 'u-me');
      final forked = (await repository.forkVersion(
        'v-src',
        label: 'Copy',
        cachedSource: source,
      )).getOrElse((_) => throw 'x');
      expect(forked.madeOffline, isTrue);
    });

    test('other backend errors do not fall back to a local copy', () async {
      remote.failure = BackendErrorCode.permissionDenied.failure(message: 'no');
      final result = await repository.forkVersion(
        'v-src',
        label: 'Copy',
        cachedSource: localVersion(owner: 'u-x'),
      );
      expect(failureOf(result).errorCode, BackendErrorCode.permissionDenied);
      expect(await db.select(db.songs).get(), isEmpty);
    });

    test('in local mode a fork is a local copy', () async {
      session.signInAs(null);
      final source = localVersion();
      final forked = (await repository.forkVersion(
        'v-src',
        label: 'Copy',
        cachedSource: source,
      )).getOrElse((_) => throw 'x');
      expect(remote.calls, isEmpty);
      expect(forked.song.ownerId, isNull);
      expect(forked.song.forkedFromVersionId, 'v-src');
    });
  });

  group('merge requests', () {
    test('pass through and map failures', () async {
      remote.mergeStatus = MergeRequestStatus.pending;
      final sent = (await repository.requestMerge(
        sourceSongId: 'a',
        targetSongId: 'b',
      )).getOrElse((_) => throw 'x');
      expect(sent.isPending, isTrue);
      expect(remote.calls, ['merge:a>b']);

      remote.failure = BackendErrorCode.mergeAlreadyRequested.failure(
        message: 'dup',
      );
      final again = await repository.requestMerge(
        sourceSongId: 'a',
        targetSongId: 'b',
      );
      expect(
        failureOf(again).errorCode,
        BackendErrorCode.mergeAlreadyRequested,
      );

      remote.failure = null;
      final answered = (await repository.respondToMerge(
        'r1',
        accept: true,
      )).getOrElse((_) => throw 'x');
      expect(answered.status, MergeRequestStatus.accepted);
    });

    test('an unexpected error becomes a failure', () async {
      remote.failure = offlineFailure();
      final result = await repository.pendingMergeRequests();
      expect(failureOf(result).errorCode, BackendErrorCode.offline);
    });
  });
}
