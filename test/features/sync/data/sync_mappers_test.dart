import 'dart:convert';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/sync/data/sync_mappers.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<SongEntry> insertSong() async {
    await db
        .into(db.songs)
        .insert(
          SongsCompanion.insert(
            id: 'v1',
            title: 'Title',
            artist: 'Artist',
            key: 'G',
            tempo: 90,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
            label: const Value('Acoustic'),
            visibility: const Value('organizations'),
            sectionsJson: const Value('[{"id":"s"}]'),
            notes: const Value('n'),
          ),
        );
    return db.select(db.songs).getSingle();
  }

  group('version payloads', () {
    test('insert carries identity, label, visibility and content', () async {
      final song = await insertSong();
      final payload = versionInsertPayload(song, workId: 'w1', ownerId: 'u1');
      expect(payload['id'], 'v1');
      expect(payload['song_id'], 'w1');
      expect(payload['owner_id'], 'u1');
      expect(payload['label'], 'Acoustic');
      expect(payload['visibility'], 'organizations');
      expect(payload['key'], 'G');
      expect(payload['tempo'], 90);
      expect(payload['sections_json'], '[{"id":"s"}]');
      expect(payload['notes'], 'n');
      expect(payload.containsKey('forked_from_version_id'), isTrue);
      expect(payload['forked_from_version_id'], isNull);
    });

    test('insert can drop the lineage of a fork whose parent is gone', () async {
      await insertSong();
      await (db.update(db.songs)).write(
        const SongsCompanion(forkedFromVersionId: Value('parent')),
      );
      final song = await db.select(db.songs).getSingle();
      expect(
        versionInsertPayload(
          song,
          workId: 'w1',
          ownerId: 'u1',
        )['forked_from_version_id'],
        'parent',
      );
      expect(
        versionInsertPayload(
          song,
          workId: 'w1',
          ownerId: 'u1',
          keepLineage: false,
        )['forked_from_version_id'],
        isNull,
      );
    });

    test('insert keeps the parent of a fork and the edit time', () async {
      await insertSong();
      await (db.update(db.songs)).write(
        const SongsCompanion(
          forkedFromVersionId: Value('parent'),
          editedAtMs: Value(1794304800123),
        ),
      );
      final song = await db.select(db.songs).getSingle();
      final payload = versionInsertPayload(song, workId: 'w1', ownerId: 'u1');
      expect(payload['forked_from_version_id'], 'parent');
      expect(payload['edited_at'], '2026-11-10T10:00:00.123Z');
    });

    test('update carries content and edit time, not identity', () async {
      final payload = versionUpdatePayload(await insertSong());
      for (final key in [
        'id',
        'song_id',
        'owner_id',
        'label',
        'visibility',
        'forked_from_version_id',
      ]) {
        expect(payload.containsKey(key), isFalse, reason: key);
      }
      expect(payload['key'], 'G');
      expect(payload.containsKey('edited_at'), isTrue);
    });

    test(
      'update carries label and visibility only for a sharing change',
      () async {
        final song = await insertSong();
        final payload = versionUpdatePayload(song, withSharing: true);
        expect(payload['label'], 'Acoustic');
        expect(payload['visibility'], 'organizations');
        expect(versionSharingPayload(song), {
          'label': 'Acoustic',
          'visibility': 'organizations',
        });
      },
    );
  });

  group('songCompanionFromRemote', () {
    Map<String, dynamic> remote({String owner = 'me'}) => {
      'id': 'v1',
      'song_id': 'w1',
      'owner_id': owner,
      'label': 'Live',
      'visibility': 'organizations',
      'key': 'D',
      'tempo': 100,
      'time_signature_beats': 3,
      'time_signature_beat_value': 4,
      'sections_json': '[]',
      'tags_json': '["a"]',
      'cover_image_path': null,
      'notes': null,
      'forked_from_version_id': 'v0',
      'created_at': '2026-01-01T00:00:00+00:00',
      'updated_at': '2026-11-10T10:00:00.123456+00:00',
      'songs': {
        'id': 'w1',
        'title': 'Work',
        'artist': 'Band',
        'created_by': 'creator',
      },
      'version_shares': [
        {'organization_id': 'o1'},
        {'organization_id': 'o2'},
      ],
    };

    test('maps work, version and sync state', () {
      final c = songCompanionFromRemote(remote(), accountId: 'me');
      expect(c.title.value, 'Work');
      expect(c.artist.value, 'Band');
      expect(c.songWorkId.value, 'w1');
      expect(c.songCreatorId.value, 'creator');
      expect(c.ownerId.value, 'me');
      expect(c.label.value, 'Live');
      expect(c.visibility.value, 'organizations');
      expect(c.forkedFromVersionId.value, 'v0');
      expect(jsonDecode(c.sharedOrganizationIdsJson.value), ['o1', 'o2']);
      expect(c.timeSignatureBeats.value, 3);
      expect(c.isDirty.value, isFalse);
      expect(c.sharingDirty.value, isFalse);
      // Without `edited_at` (old rows) the last update stands in for it.
      expect(
        c.editedAtMs.value,
        DateTime.utc(2026, 11, 10, 10).millisecondsSinceEpoch + 123,
      );
      final edited = songCompanionFromRemote({
        ...remote(),
        'edited_at': '2026-11-09T08:00:00.500+00:00',
      }, accountId: 'me');
      expect(
        edited.editedAtMs.value,
        DateTime.utc(2026, 11, 9, 8, 0, 0, 500).millisecondsSinceEpoch,
      );
      expect(c.deletedAt.value, isNull);
      expect(c.accountId.value, 'me');
      expect(c.remoteUpdatedAt.value, '2026-11-10T10:00:00.123456Z');
    });

    test('shares of other users\' versions are not mirrored', () {
      final c = songCompanionFromRemote(
        remote(owner: 'someone'),
        accountId: 'me',
      );
      expect(c.ownerId.value, 'someone');
      expect(jsonDecode(c.sharedOrganizationIdsJson.value), isEmpty);
    });
  });

  group('scores', () {
    test('payload and companion round trip the content', () async {
      await db
          .into(db.scores)
          .insert(
            ScoresCompanion.insert(
              id: 's1',
              songId: const Value('v1'),
              title: 'Chart',
              timeSignatureJson: '{"numerator":3,"denominator":4}',
              keySignature: 'D',
              tempo: 80,
              sectionsJson: '[{"id":"a"}]',
              updatedAt: DateTime(2026),
            ),
          );
      final row = await db.select(db.scores).getSingle();
      final payload = scorePayload(row, 'v1');
      expect(payload['version_id'], 'v1');
      expect(payload['time_signature'], {'numerator': 3, 'denominator': 4});
      expect(payload['sections'], [
        {'id': 'a'},
      ]);
      expect(payload['deleted_at'], isNull);

      final companion = scoreCompanionFromRemote({
        ...payload,
        'updated_at': '2026-11-10T10:00:00+00:00',
      });
      expect(companion.songId.value, 'v1');
      expect(jsonDecode(companion.sectionsJson.value), [
        {'id': 'a'},
      ]);
      expect(companion.remoteUpdatedAt.value, '2026-11-10T10:00:00.000Z');
      expect(companion.isDirty.value, isFalse);
    });
  });

  group('setlist entries', () {
    const item = SetlistItem(
      id: 'i1',
      songId: 'v1',
      orderIndex: 2,
      keyOverride: 'Bb',
      tempoOverride: 70,
      notes: 'slow',
    );

    test('payload keeps overrides and links the version', () {
      final p = setlistItemPayload(
        item,
        setlistId: 'sl',
        organizationId: null,
        versionId: 'v1',
        info: const ItemSongInfo(title: 'T', artist: 'A', label: 'L', key: 'G'),
      );
      expect(p['position'], 2);
      expect(p['version_id'], 'v1');
      expect(p['key_override'], 'Bb');
      expect(p['tempo_override'], 70);
      expect(p['notes'], 'slow');
      expect(p['title_snapshot'], 'T');
      expect(p['organization_id'], isNull);
    });

    test('an entry without a version keeps its own snapshot', () {
      final p = setlistItemPayload(
        item.copyWith(titleSnapshot: 'Old Title'),
        setlistId: 'sl',
        organizationId: 'org',
        versionId: null,
      );
      expect(p['version_id'], isNull);
      expect(p['title_snapshot'], 'Old Title');
      expect(p['organization_id'], 'org');
    });

    Map<String, dynamic> remoteItem({String? version = 'v1'}) => {
      'id': 'i1',
      'version_id': version,
      'position': 4,
      'key_override': 'C',
      'tempo_override': 60,
      'notes': 'n',
      'title_snapshot': 'T',
      'artist_snapshot': 'A',
      'label_snapshot': 'L',
      'key_snapshot': 'G',
    };

    test('a visible version links the entry', () {
      final i = setlistItemFromRemote(
        remoteItem(),
        visibleVersionIds: {'v1'},
        localOnlySongIds: {},
      );
      expect(i.songId, 'v1');
      expect(i.isTombstone, isFalse);
      expect(i.keyOverride, 'C');
      expect(i.tempoOverride, 60);
      expect(i.titleSnapshot, 'T');
    });

    test(
      'a missing or invisible version makes a tombstone with the snapshot',
      () {
        for (final version in <String?>[null, 'v1']) {
          final i = setlistItemFromRemote(
            remoteItem(version: version),
            visibleVersionIds: {},
            localOnlySongIds: {},
          );
          expect(i.isTombstone, isTrue);
          expect(i.titleSnapshot, 'T');
          expect(i.keyOverride, 'C');
        }
      },
    );

    test('a link to a song that only exists on this device survives', () {
      final i = setlistItemFromRemote(
        remoteItem(version: null),
        visibleVersionIds: {},
        localOnlySongIds: {'seed-way-maker'},
        local: const SetlistItem(
          id: 'i1',
          songId: 'seed-way-maker',
          orderIndex: 0,
        ),
      );
      expect(i.songId, 'seed-way-maker');
      expect(i.isTombstone, isFalse);
    });
  });
}
