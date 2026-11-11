import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/sharing/domain/entities/song_suggestion.dart';
import 'package:battuta/features/sharing/presentation/widgets/song_link_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_song_sharing.dart';
import 'sharing_harness.dart';

Song scanned(String title) => Song(
  id: 'scan-1',
  title: title,
  artist: 'Scanned',
  key: 'C',
  tempo: 90,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late Song? result;
  late bool answered;

  Future<void> open(
    WidgetTester tester,
    SharingHarness h,
    Song song, {
    double width = 1024,
  }) async {
    result = null;
    answered = false;
    await h.pump(
      tester,
      Scaffold(
        body: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () async {
              result = await linkSongBeforeSave(context, ref, song);
              answered = true;
            },
            child: const Text('save'),
          ),
        ),
      ),
      width: width,
      height: 800,
    );
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();
  }

  const match = SongSuggestion(
    songWorkId: 'w-way',
    title: 'Way Maker',
    artist: 'Sinach',
    createdBy: 'u-x',
    versionCount: 2,
  );

  testWidgets('without candidates nothing is asked', (tester) async {
    final h = SharingHarness();
    await open(tester, h, scanned('Unknown tune'));
    expect(answered, isTrue);
    expect(result!.songWorkId, isNull);
    expect(find.byKey(const ValueKey('song_link_new')), findsNothing);
  });

  testWidgets('picking a candidate attaches the scan to that song', (
    tester,
  ) async {
    final h = SharingHarness();
    h.sharing.suggestions = [match];
    await open(tester, h, scanned('way maker'));
    await tester.tap(find.byKey(const ValueKey('song_link_option_w-way')));
    await tester.pumpAndSettle();
    expect(result!.songWorkId, 'w-way');
    expect(result!.title, 'Way Maker');
    expect(result!.artist, 'Sinach');
    expect(result!.songCreatorId, 'u-x');
  });

  testWidgets('"new song" keeps what was scanned', (tester) async {
    final h = SharingHarness();
    h.sharing.suggestions = [match];
    await open(tester, h, scanned('way maker'));
    await tester.tap(find.byKey(const ValueKey('song_link_new')));
    await tester.pumpAndSettle();
    expect(result!.songWorkId, isNull);
    expect(result!.title, 'way maker');
  });

  testWidgets('dismissing the question saves nothing', (tester) async {
    final h = SharingHarness();
    h.sharing.suggestions = [match];
    await open(tester, h, scanned('way maker'));
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(answered, isTrue);
    expect(result, isNull);
  });

  testWidgets('offline it still offers the songs on the device', (
    tester,
  ) async {
    final h = SharingHarness(
      songs: [versionOf('v1', title: 'Way Maker', owner: 'u-x')],
    );
    h.sharing.failure = offlineFailure();
    await open(tester, h, scanned('way maker'));
    expect(
      find.byKey(const ValueKey('song_link_option_work-1')),
      findsOneWidget,
    );
  });

  for (final width in [320.0, 1440.0]) {
    testWidgets('no overflow at ${width.toInt()} px', (tester) async {
      final h = SharingHarness();
      h.sharing.suggestions = [
        const SongSuggestion(
          songWorkId: 'w-long',
          title: 'A very long song title that keeps going and going on',
          artist: 'An artist with a rather long name as well',
          versionCount: 99,
        ),
      ];
      await open(
        tester,
        h,
        scanned('a very long song title that keeps going and going on'),
        width: width,
      );
      expect(
        find.byKey(const ValueKey('song_link_option_w-long')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
