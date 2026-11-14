import 'package:battuta/features/live_session/domain/performance_plan.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:flutter_test/flutter_test.dart';

Song song(
  String id, {
  String key = 'E',
  int tempo = 68,
  List<SongSection> sections = const [],
}) => Song(
  id: id,
  title: 'Song $id',
  artist: 'Artist',
  key: key,
  tempo: tempo,
  sections: sections,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

SongSection section(String id, String name, int order, {int repeat = 1}) =>
    SongSection(id: id, name: name, orderIndex: order, repeatCount: repeat);

Setlist setlist(List<SetlistItem> items) => Setlist(
  id: 'set',
  title: 'Sunday',
  items: items,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  group('cues', () {
    test('sections come in orderIndex order, not list order', () {
      final s = song(
        'a',
        sections: [
          section('c', 'Chorus', 2),
          section('v', 'Verse', 0),
          section('p', 'Pre', 1),
        ],
      );
      final plan = PerformancePlan.fromSong(s);
      expect(plan.songs.single.cues.map((c) => c.label), [
        'Verse',
        'Pre',
        'Chorus',
      ]);
    });

    test('a repeated section gives one cue per pass', () {
      final s = song(
        'a',
        sections: [
          section('v', 'Verse', 0),
          section('c', 'Chorus', 1, repeat: 2),
        ],
      );
      final cues = PerformancePlan.fromSong(s).songs.single.cues;
      expect(cues.map((c) => c.label), [
        'Verse',
        'Chorus (1/2)',
        'Chorus (2/2)',
      ]);
      expect(cues.map((c) => c.id).toSet().length, 3);
    });

    test('a song with no sections has one whole-song cue', () {
      final cues = PerformancePlan.fromSong(song('a')).songs.single.cues;
      expect(cues, hasLength(1));
      expect(cues.single.isWholeSong, isTrue);
    });

    test('a repeat count below 1 counts once', () {
      final s = song('a', sections: [section('v', 'Verse', 0, repeat: 0)]);
      expect(PerformancePlan.fromSong(s).songs.single.cues, hasLength(1));
    });
  });

  group('keys and tempo', () {
    test('the override is the key and gives the semitone shift', () {
      final plan = PerformancePlan.fromSetlist(
        setlist(const [
          SetlistItem(id: 'i', songId: 'a', orderIndex: 0, keyOverride: 'G'),
        ]),
        {'a': song('a', key: 'E')},
      );
      expect(plan.songs.single.key, 'G');
      expect(plan.songs.single.semitones, 3);
    });

    test('shifts take the nearer direction', () {
      expect(PerformancePlan.keyShift('E', 'D'), -2);
      expect(PerformancePlan.keyShift('C', 'Bb'), -2);
      expect(PerformancePlan.keyShift('C', 'F#'), 6);
      expect(PerformancePlan.keyShift('G', 'G'), 0);
    });

    test('unknown keys do not shift', () {
      expect(PerformancePlan.keyShift('E', 'banana'), 0);
      expect(PerformancePlan.keyShift('???', 'G'), 0);
      expect(PerformancePlan.keyShift('E', null), 0);
    });

    test('without an override the song keeps its own key', () {
      final plan = PerformancePlan.fromSong(song('a', key: 'E'));
      expect(plan.songs.single.key, 'E');
      expect(plan.songs.single.semitones, 0);
    });

    test('the tempo override wins and no tempo falls back to 72', () {
      final plan = PerformancePlan.fromSetlist(
        setlist(const [
          SetlistItem(id: 'i', songId: 'a', orderIndex: 0, tempoOverride: 90),
          SetlistItem(id: 'j', songId: 'b', orderIndex: 1),
        ]),
        {'a': song('a'), 'b': song('b', tempo: 0)},
      );
      expect(plan.songs[0].bpm, 90);
      expect(plan.songs[1].bpm, 72);
    });
  });

  group('fromSetlist', () {
    test('follows the setlist order', () {
      final plan = PerformancePlan.fromSetlist(
        setlist(const [
          SetlistItem(id: 'i2', songId: 'b', orderIndex: 1),
          SetlistItem(id: 'i1', songId: 'a', orderIndex: 0),
        ]),
        {'a': song('a'), 'b': song('b')},
      );
      expect(plan.songs.map((s) => s.songId), ['a', 'b']);
    });

    test('a missing song and a tombstone keep their place', () {
      final plan = PerformancePlan.fromSetlist(
        setlist(const [
          SetlistItem(id: 'i1', songId: 'a', orderIndex: 0),
          SetlistItem(
            id: 'i2',
            songId: 'gone',
            orderIndex: 1,
            titleSnapshot: 'Old song',
            keySnapshot: 'D',
          ),
          SetlistItem(id: 'i3', songId: '', orderIndex: 2),
        ]),
        {'a': song('a')},
      );
      expect(plan.songs, hasLength(3));
      expect(plan.songs[0].isMissing, isFalse);
      expect(plan.songs[1].isMissing, isTrue);
      expect(plan.songs[1].title, 'Old song');
      expect(plan.songs[1].key, 'D');
      expect(plan.songs[1].stepCount, 1);
      expect(plan.songs[2].isMissing, isTrue);
    });

    test('finds a song by its setlist item id', () {
      final plan = PerformancePlan.fromSetlist(
        setlist(const [
          SetlistItem(id: 'i1', songId: 'a', orderIndex: 0),
          SetlistItem(id: 'i2', songId: 'b', orderIndex: 1),
        ]),
        {'a': song('a'), 'b': song('b')},
      );
      expect(plan.indexOfItem('i2'), 1);
      expect(plan.indexOfItem('nope'), -1);
    });

    test('equal setlists give equal plans', () {
      PerformancePlan build() => PerformancePlan.fromSetlist(
        setlist(const [SetlistItem(id: 'i1', songId: 'a', orderIndex: 0)]),
        {'a': song('a')},
      );
      expect(build(), build());
      expect(build().hashCode, build().hashCode);
    });
  });
}
