import 'package:battuta/core/services/device_preferences_storage.dart';
import 'package:battuta/features/live_session/domain/performance_plan.dart';
import 'package:battuta/features/live_session/presentation/providers/performance_controller.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/settings/presentation/providers/stage_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/memory_storage.dart';

Song song(String id, List<String> sectionNames, {int repeatLast = 1}) => Song(
  id: id,
  title: 'Song $id',
  artist: 'A',
  key: 'E',
  tempo: 70,
  sections: [
    for (var i = 0; i < sectionNames.length; i++)
      SongSection(
        id: '$id-$i',
        name: sectionNames[i],
        orderIndex: i,
        repeatCount: i == sectionNames.length - 1 ? repeatLast : 1,
      ),
  ],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

PerformancePlan twoSongs() => PerformancePlan.fromSetlist(
  Setlist(
    id: 'set',
    title: 'Sunday',
    items: const [
      SetlistItem(id: 'i1', songId: 'a', orderIndex: 0),
      SetlistItem(id: 'i2', songId: 'b', orderIndex: 1),
    ],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  {
    'a': song('a', ['Verse', 'Chorus']),
    'b': song('b', ['Intro', 'Verse', 'Chorus'], repeatLast: 2),
  },
);

void main() {
  late MemoryStorage storage;
  late ProviderContainer container;

  ProviderContainer make() {
    final c = ProviderContainer(
      overrides: [devicePreferencesStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(c.dispose);
    // Keeps the autoDispose controller alive between reads.
    c.listen(performanceControllerProvider, (_, _) {});
    return c;
  }

  PerformanceController controller() =>
      container.read(performanceControllerProvider.notifier);
  PerformanceState state() => container.read(performanceControllerProvider);

  setUp(() {
    storage = MemoryStorage();
    container = make();
    controller().setPlan(twoSongs());
  });

  test('starts on the first cue of the first song, not scrolling', () {
    expect(state().songIndex, 0);
    expect(state().cueIndex, 0);
    expect(state().isScrolling, isFalse);
    expect(state().speed, 1.0);
    expect(state().finished, isFalse);
  });

  group('cue navigation', () {
    test('nextCue steps through the sections', () {
      controller().nextCue();
      expect((state().songIndex, state().cueIndex), (0, 1));
    });

    test('next past the last section goes to the next song first cue', () {
      controller()
        ..nextCue()
        ..nextCue();
      expect((state().songIndex, state().cueIndex), (1, 0));
    });

    test('previous at the first cue goes to the previous song last cue', () {
      controller()
        ..nextCue()
        ..nextCue(); // song 2, cue 0
      controller().prevCue();
      expect((state().songIndex, state().cueIndex), (0, 1));
    });

    test('previous at the very start stays put', () {
      controller().prevCue();
      expect((state().songIndex, state().cueIndex), (0, 0));
    });

    test('repeated sections count as steps', () {
      controller().nextSong();
      // Intro, Verse, Chorus (1/2), Chorus (2/2).
      expect(state().currentSong!.cues, hasLength(4));
      for (var i = 0; i < 3; i++) {
        controller().nextCue();
      }
      expect(state().cueIndex, 3);
      expect(state().isLastStep, isTrue);
    });

    test('next after the last section of the set finishes it', () {
      controller().nextSong();
      for (var i = 0; i < 3; i++) {
        controller().nextCue();
      }
      controller().nextCue();
      expect(state().finished, isTrue);
      expect(state().isScrolling, isFalse);
    });

    test('restart goes back to the first song', () {
      controller()
        ..nextSong()
        ..nextSong();
      expect(state().finished, isTrue);
      controller().restart();
      expect(state().finished, isFalse);
      expect((state().songIndex, state().cueIndex), (0, 0));
    });

    test('nextSong and prevSong move by songs', () {
      controller().nextSong();
      expect(state().songIndex, 1);
      controller().prevSong();
      expect(state().songIndex, 0);
      controller().prevSong();
      expect(state().songIndex, 0);
    });

    test('jumpToCue goes to a section, ignoring bad indexes', () {
      controller().jumpToCue(1);
      expect(state().cueIndex, 1);
      controller().jumpToCue(9);
      controller().jumpToCue(-1);
      expect(state().cueIndex, 1);
      controller().jumpToCue(2, songIndex: 1);
      expect((state().songIndex, state().cueIndex), (1, 2));
      controller().jumpToCue(0, songIndex: 7);
      expect((state().songIndex, state().cueIndex), (1, 2));
    });

    test(
      'moves the player asks for bump navSerial, scroll follow does not',
      () {
        final before = state().navSerial;
        controller().followScroll(1);
        expect(state().cueIndex, 1);
        expect(state().navSerial, before);
        controller().nextCue();
        expect(state().navSerial, before + 1);
      },
    );
  });

  group('scrolling and speed', () {
    test('toggleScroll plays and pauses', () {
      controller().toggleScroll();
      expect(state().isScrolling, isTrue);
      controller().toggleScroll();
      expect(state().isScrolling, isFalse);
    });

    test('speed steps by 0.1 and stays between 50 and 200 percent', () {
      controller().stepSpeed(1);
      expect(state().speed, 1.1);
      for (var i = 0; i < 30; i++) {
        controller().stepSpeed(1);
      }
      expect(state().speed, 2.0);
      for (var i = 0; i < 40; i++) {
        controller().stepSpeed(-1);
      }
      expect(state().speed, 0.5);
    });

    test('speed is remembered per song on this device', () async {
      controller().setSpeed(1.4);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(stagePreferencesProvider).songSpeeds['a'], 1.4);

      controller().nextSong();
      expect(state().speed, 1.0, reason: 'song b has its own speed');
      controller().setSpeed(0.8);
      controller().prevSong();
      expect(state().speed, 1.4);
    });

    test('a saved speed is used when the performance starts', () async {
      await container
          .read(stagePreferencesProvider.notifier)
          .setSongSpeed('a', 1.3);
      container = make();
      controller().setPlan(twoSongs());
      // The first load of the preferences is async.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      controller().setPlan(
        PerformancePlan.fromSetlist(
          Setlist(
            id: 'set',
            title: 'Sunday',
            items: const [SetlistItem(id: 'i9', songId: 'a', orderIndex: 0)],
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
          {
            'a': song('a', ['Verse']),
          },
        ),
      );
      expect(state().speed, 1.3);
    });
  });

  group('setPlan', () {
    test('keeps the current song by item id when the setlist is edited', () {
      controller().nextSong(); // on song b
      final edited = PerformancePlan.fromSetlist(
        Setlist(
          id: 'set',
          title: 'Sunday',
          items: const [
            SetlistItem(id: 'i0', songId: 'a', orderIndex: 0),
            SetlistItem(id: 'i1', songId: 'a', orderIndex: 1),
            SetlistItem(id: 'i2', songId: 'b', orderIndex: 2),
          ],
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        {
          'a': song('a', ['Verse', 'Chorus']),
          'b': song('b', ['Intro', 'Verse', 'Chorus'], repeatLast: 2),
        },
      );
      controller().setPlan(edited);
      expect(state().songIndex, 2);
      expect(state().currentSong!.itemId, 'i2');
    });

    test('goes to the start when the current song was removed', () {
      controller().nextSong();
      controller().setPlan(
        PerformancePlan.fromSetlist(
          Setlist(
            id: 'set',
            title: 'Sunday',
            items: const [SetlistItem(id: 'i1', songId: 'a', orderIndex: 0)],
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
          {
            'a': song('a', ['Verse', 'Chorus']),
          },
        ),
      );
      expect((state().songIndex, state().cueIndex), (0, 0));
    });

    test('the same plan again changes nothing', () {
      controller().nextCue();
      final serial = state().navSerial;
      controller().setPlan(twoSongs());
      expect(state().cueIndex, 1);
      expect(state().navSerial, serial);
    });

    test('an unrelated edit keeps the place and does not move the chart', () {
      controller().nextCue();
      final serial = state().navSerial;
      // Same songs and order, one song's tempo changed.
      controller().setPlan(
        PerformancePlan.fromSetlist(
          Setlist(
            id: 'set',
            title: 'Sunday',
            items: const [
              SetlistItem(
                id: 'i1',
                songId: 'a',
                orderIndex: 0,
                tempoOverride: 90,
              ),
              SetlistItem(id: 'i2', songId: 'b', orderIndex: 1),
            ],
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
          {
            'a': song('a', ['Verse', 'Chorus']),
            'b': song('b', ['Intro', 'Verse', 'Chorus'], repeatLast: 2),
          },
        ),
      );
      expect(state().currentSong!.tempo, 90);
      expect(state().cueIndex, 1);
      expect(state().navSerial, serial);
    });

    test('a removed current song moves the chart (navSerial changes)', () {
      controller().nextSong();
      final serial = state().navSerial;
      controller().setPlan(
        PerformancePlan.fromSetlist(
          Setlist(
            id: 'set',
            title: 'Sunday',
            items: const [SetlistItem(id: 'i1', songId: 'a', orderIndex: 0)],
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
          {
            'a': song('a', ['Verse', 'Chorus']),
          },
        ),
      );
      expect(state().navSerial, serial + 1);
    });

    test('a missing song counts as one step', () {
      controller().setPlan(
        PerformancePlan.fromSetlist(
          Setlist(
            id: 'set',
            title: 'Sunday',
            items: const [
              SetlistItem(id: 'i1', songId: 'gone', orderIndex: 0),
              SetlistItem(id: 'i2', songId: 'a', orderIndex: 1),
            ],
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
          {
            'a': song('a', ['Verse']),
          },
        ),
      );
      expect(state().currentSong!.isMissing, isTrue);
      controller().nextCue();
      expect((state().songIndex, state().cueIndex), (1, 0));
    });
  });
}
