import 'package:battuta/features/live_session/domain/scroll_pace.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('beats and bars', () {
    test('count the beats of the time signature', () {
      expect(ScrollPace.beatsPerBar(4, 4), 4);
      expect(ScrollPace.beatsPerBar(3, 4), 3);
    });

    test('compound meters count dotted-quarter beats', () {
      expect(ScrollPace.beatsPerBar(6, 8), 2);
      expect(ScrollPace.beatsPerBar(9, 8), 3);
      expect(ScrollPace.beatsPerBar(12, 8), 4);
    });

    test('a bar of 4/4 at 120 BPM lasts 2 seconds', () {
      expect(ScrollPace.barSeconds(bpm: 120, timeSignature: (4, 4)), 2);
    });

    test('a bar of 6/8 at 60 BPM lasts 2 seconds', () {
      expect(ScrollPace.barSeconds(bpm: 60, timeSignature: (6, 8)), 2);
    });
  });

  group('pointsPerSecond', () {
    test('is the measured height over the duration', () {
      expect(ScrollPace.pointsPerSecond(height: 320, seconds: 20), 16);
    });

    test('the adjustment scales it', () {
      expect(
        ScrollPace.pointsPerSecond(height: 320, seconds: 20, adjustment: 1.5),
        24,
      );
    });

    test('is 0 without a height or a duration', () {
      expect(ScrollPace.pointsPerSecond(height: 0, seconds: 20), 0);
      expect(ScrollPace.pointsPerSecond(height: 100, seconds: 0), 0);
    });
  });

  group('sectionSeconds', () {
    final fourChords = [
      for (final r in ['G', 'C', 'D', 'Em']) ChordCell(root: r, beats: 4),
    ];

    double seconds({
      int lines = 4,
      List<ChordCell> chords = const [],
      int bpm = 68,
      (int, int) ts = (4, 4),
      int bars = 2,
    }) => ScrollPace.sectionSeconds(
      lyricLines: lines,
      chords: chords,
      bpm: bpm,
      timeSignature: ts,
      barsPerLine: bars,
    );

    test('4 lyric lines and 4 chords at 68 BPM, 4/4, 2 bars: about 28 s', () {
      // 4 lines x 2 bars x (4 x 60 / 68) s. The 16 chord beats (14 s) are
      // one progression, not the length of the section.
      expect(seconds(chords: fourChords), closeTo(28.2, 0.1));
    });

    test('bars per line changes it: 4 bars doubles it, 1 bar halves it', () {
      final two = seconds(chords: fourChords);
      expect(seconds(chords: fourChords, bars: 4), closeTo(two * 2, 0.001));
      expect(seconds(chords: fourChords, bars: 1), closeTo(two / 2, 0.001));
    });

    test('chord beats are a lower bound', () {
      final long = [const ChordCell(root: 'G', beats: 64)];
      expect(seconds(lines: 1, chords: long), closeTo(64 * 60 / 68, 0.001));
    });

    test('a chords-only section lasts its chord beats', () {
      expect(
        seconds(lines: 0, chords: fourChords),
        closeTo(16 * 60 / 68, 0.001),
      );
    });

    test('a section with neither lasts one line', () {
      expect(seconds(lines: 0), closeTo(2 * 4 * 60 / 68, 0.001));
    });

    test('counts only lines that are not blank', () {
      expect(ScrollPace.lyricLineCount('a\n\n  \nb'), 2);
      expect(ScrollPace.lyricLineCount(null), 0);
    });
  });

  group('normalizeAdjustment', () {
    test('snaps to 0.1 inside 0.5 to 2.0', () {
      expect(ScrollPace.normalizeAdjustment(0.1), 0.5);
      expect(ScrollPace.normalizeAdjustment(3), 2.0);
      expect(ScrollPace.normalizeAdjustment(1.04), 1.0);
      expect(ScrollPace.normalizeAdjustment(1.26), 1.3);
    });

    test('not-a-number gives 1.0', () {
      expect(ScrollPace.normalizeAdjustment(double.nan), 1.0);
      expect(ScrollPace.normalizeAdjustment(double.infinity), 1.0);
    });

    test('bars per line accepts only 1, 2 and 4', () {
      expect(ScrollPace.normalizeBarsPerLine(4), 4);
      expect(ScrollPace.normalizeBarsPerLine(3), 2);
    });
  });
}
