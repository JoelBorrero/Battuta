import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/sharing/domain/entities/song_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';

Song version(
  String id,
  String title,
  String artist, {
  String? work = 'w1',
  String? creator,
}) => Song(
  id: id,
  title: title,
  artist: artist,
  key: 'C',
  tempo: 90,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  songWorkId: work,
  songCreatorId: creator,
);

void main() {
  group('normalizeSongText', () {
    test('ignores case, accents, punctuation and spacing', () {
      expect(normalizeSongText('  Tú  Fidelidad! '), 'tu fidelidad');
      expect(normalizeSongText('Don\'t Stop'), 'dont stop');
      expect(normalizeSongText('Ñandú, Ça va'), 'nandu ca va');
    });

    test('a live version is a different song', () {
      expect(
        songKey('Way Maker (Live)', 'Sinach'),
        isNot(songKey('Way Maker', 'Sinach')),
      );
      expect(songKey('Way  maker', 'SINACH'), songKey('Way Maker', 'Sinach'));
    });
  });

  group('suggestionsFromCache', () {
    final cached = [
      version('a', 'Way Maker', 'Sinach', creator: 'u-x'),
      version('b', 'Way Maker', 'Sinach'),
      version('c', 'Tú Fidelidad', 'Marcos Witt', work: 'w2'),
      version('d', 'Local only', 'Me', work: null),
    ];

    test('groups the versions of a song and counts them', () {
      final found = suggestionsFromCache(cached, 'way maker');
      expect(found, hasLength(1));
      expect(found.single.songWorkId, 'w1');
      expect(found.single.versionCount, 2);
      expect(found.single.createdBy, 'u-x');
    });

    test('matches without accents or case', () {
      expect(
        suggestionsFromCache(cached, 'TU fidel').single.songWorkId,
        'w2',
      );
    });

    test('tolerates a typo in the title', () {
      expect(suggestionsFromCache(cached, 'way makr').single.songWorkId, 'w1');
    });

    test('songs without a song id and short queries find nothing', () {
      expect(suggestionsFromCache(cached, 'local'), isEmpty);
      expect(suggestionsFromCache(cached, 'w'), isEmpty);
      expect(suggestionsFromCache(cached, '  '), isEmpty);
    });
  });

  test('mergeSuggestions keeps one entry per song, preferring the backend', () {
    const cached = [SongSuggestion(songWorkId: 'w1', title: 'Way Maker')];
    const remote = [
      SongSuggestion(songWorkId: 'w1', title: 'Way Maker', versionCount: 5),
      SongSuggestion(songWorkId: 'w3', title: 'Way Maker (Live)'),
    ];
    final merged = mergeSuggestions(cached, remote, 'way maker');
    expect(merged.map((s) => s.songWorkId), ['w1', 'w3']);
    expect(merged.first.versionCount, 5);
  });

  test('linking a version takes the identity of the song', () {
    final linked = version('a', 'typed', 'me', work: null).linkedTo(
      const SongSuggestion(
        songWorkId: 'w9',
        title: 'Real Title',
        artist: 'Real Artist',
        createdBy: 'u-x',
      ),
    );
    expect(linked.songWorkId, 'w9');
    expect(linked.title, 'Real Title');
    expect(linked.artist, 'Real Artist');
    expect(linked.songCreatorId, 'u-x');
  });
}
