import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Song song({String? ownerId}) => Song(
    id: 'v1',
    title: 'T',
    artist: 'A',
    key: 'C',
    tempo: 100,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    ownerId: ownerId,
  );

  test(
    'local-mode songs are editable by anybody, owned ones only by the owner',
    () {
      expect(song().isEditableBy(null), isTrue);
      expect(song().isEditableBy('u1'), isTrue);
      expect(song(ownerId: 'u1').isEditableBy('u1'), isTrue);
      expect(song(ownerId: 'u1').isEditableBy('u2'), isFalse);
      expect(song(ownerId: 'u1').isEditableBy(null), isFalse);
    },
  );

  test('version fields default to a private "Original"', () {
    final s = song();
    expect(s.label, 'Original');
    expect(s.visibility, SongVisibility.private);
    expect(s.sharedOrganizationIds, isEmpty);
  });

  test('version fields survive JSON', () {
    final s = song(ownerId: 'u1').copyWith(
      songWorkId: 'w1',
      label: 'Live',
      visibility: SongVisibility.organizations,
      forkedFromVersionId: 'v0',
      sharedOrganizationIds: const ['o1'],
    );
    expect(Song.fromJson(s.toJson()), s);
  });

  test('old JSON without version fields still parses', () {
    final json = song().toJson()
      ..remove('songWorkId')
      ..remove('ownerId')
      ..remove('label')
      ..remove('visibility')
      ..remove('forkedFromVersionId')
      ..remove('sharedOrganizationIds');
    final s = Song.fromJson(json);
    expect(s.label, 'Original');
    expect(s.visibility, SongVisibility.private);
  });

  test('unknown visibility text is read as private', () {
    expect(SongVisibility.parse('public'), SongVisibility.public);
    expect(SongVisibility.parse('organizations'), SongVisibility.organizations);
    expect(SongVisibility.parse('whatever'), SongVisibility.private);
    expect(SongVisibility.parse(null), SongVisibility.private);
  });

  test(
    'setlist entries without a song are tombstones and keep their snapshot',
    () {
      const tomb = SetlistItem(
        id: 'i',
        songId: '',
        orderIndex: 0,
        titleSnapshot: 'Gone',
      );
      expect(tomb.isTombstone, isTrue);
      expect(SetlistItem.fromJson(tomb.toJson()), tomb);
      expect(
        const SetlistItem(id: 'i', songId: 'v1', orderIndex: 0).isTombstone,
        isFalse,
      );
    },
  );
}
