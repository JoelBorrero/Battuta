import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:battuta/features/sharing/domain/entities/song_version_row.dart';
import 'package:flutter_test/flutter_test.dart';

import '../presentation/sharing_harness.dart';

SongVersionListing listing(
  String id, {
  String label = 'Original',
  String? owner = 'u-x',
  String? name = 'Grace',
  SongVisibility visibility = SongVisibility.public,
  String? forkedFrom,
}) => SongVersionListing(
  versionId: id,
  songWorkId: 'work-1',
  title: 'Amazing Grace',
  label: label,
  visibility: visibility,
  ownerId: owner,
  ownerDisplayName: name,
  forkedFromVersionId: forkedFrom,
);

void main() {
  group('Song.canEditTitleBy', () {
    test('local-mode songs and the creator edit the title', () {
      expect(versionOf('v', owner: null).canEditTitleBy(null), isTrue);
      expect(versionOf('v', creator: 'u-me').canEditTitleBy('u-me'), isTrue);
    });

    test('another creator locks the title for every owner', () {
      expect(versionOf('v', creator: 'u-x').canEditTitleBy('u-me'), isFalse);
      // My own version, but the song is somebody else's.
      expect(
        versionOf('v', owner: 'u-me', creator: 'u-x').canEditTitleBy('u-me'),
        isFalse,
      );
    });

    test('an unknown creator counts as the owner unless it is a fork', () {
      expect(versionOf('v').canEditTitleBy('u-me'), isTrue);
      expect(versionOf('v', owner: 'u-x').canEditTitleBy('u-me'), isFalse);
      expect(
        versionOf('v', forkedFrom: 'other').canEditTitleBy('u-me'),
        isFalse,
      );
    });
  });

  group('parsing', () {
    test('a listing reads its song and owner', () {
      final parsed = SongVersionListing.fromJson({
        'id': 'v1',
        'song_id': 'w1',
        'label': 'Acoustic',
        'key': 'D',
        'visibility': 'organizations',
        'owner_id': 'u1',
        'forked_from_version_id': 'v0',
        'updated_at': '2026-11-01T10:00:00Z',
        'songs': {'title': 'Grace', 'artist': 'Newton'},
        'owner': {
          'username': 'jane',
          'display_name': 'Jane',
          'deactivated_at': '2026-11-02T10:00:00Z',
        },
      });
      expect(parsed.title, 'Grace');
      expect(parsed.visibility, SongVisibility.organizations);
      expect(parsed.ownerName, 'Jane');
      expect(parsed.ownerDeactivated, isTrue);
      expect(parsed.forkedFromVersionId, 'v0');
    });
  });

  group('mergeVersionRows', () {
    test('lists a version once, preferring the backend data', () {
      final rows = mergeVersionRows(
        cached: [versionOf('v1', owner: 'u-x')],
        remote: [
          listing('v1'),
          listing('v2', label: 'Choir'),
        ],
        accountId: 'u-me',
      );
      expect(rows.map((r) => r.versionId), ['v2', 'v1']);
      expect(rows.last.isCached, isTrue);
      expect(rows.last.ownerName, 'Grace');
      expect(rows.first.isCached, isFalse);
    });

    test('keeps a cached version the backend did not list (offline)', () {
      final rows = mergeVersionRows(
        cached: [
          versionOf('v1'),
          versionOf('v3', owner: 'u-x'),
        ],
        remote: const [],
        accountId: 'u-me',
      );
      expect(rows.map((r) => r.versionId), ['v1', 'v3']);
      expect(rows.every((r) => r.isCached), isTrue);
    });

    test('mine come first, then the others by label', () {
      final rows = mergeVersionRows(
        cached: [versionOf('mine', label: 'Zeta')],
        remote: [
          listing('b', label: 'Beta'),
          listing('a', label: 'alpha'),
        ],
        accountId: 'u-me',
      );
      expect(rows.map((r) => r.versionId), ['mine', 'a', 'b']);
      expect(rows.first.isMine('u-me'), isTrue);
    });
  });
}
