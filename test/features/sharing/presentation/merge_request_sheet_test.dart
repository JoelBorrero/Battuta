import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:battuta/features/sharing/presentation/widgets/merge_request_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_song_sharing.dart';
import 'sharing_harness.dart';

class _Opener extends StatelessWidget {
  const _Opener({required this.createdByMe});

  final bool createdByMe;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ElevatedButton(
        key: const ValueKey('open_sheet'),
        onPressed: () => showMergeRequestSheet(
          context,
          songWorkId: 'work-1',
          title: 'Amazing Grace',
          createdByMe: createdByMe,
        ),
        child: const Text('open'),
      ),
    ),
  );
}

void main() {
  SharingHarness harness({bool signedIn = true}) {
    final h = SharingHarness(songs: [versionOf('v1')], signedIn: signedIn);
    h.sharing.songs = const [
      SongWork(id: 'work-1', title: 'Amazing Grace', createdBy: 'u-me'),
      SongWork(id: 'work-2', title: 'Amazing Grace (copy)', createdBy: 'u-me'),
      SongWork(id: 'work-3', title: 'Grace Alone', createdBy: 'u-x'),
    ];
    return h;
  }

  Future<void> open(
    WidgetTester tester,
    SharingHarness h, {
    bool createdByMe = true,
    double width = 1024,
  }) async {
    await h.pump(tester, _Opener(createdByMe: createdByMe), width: width);
    await tester.tap(find.byKey(const ValueKey('open_sheet')));
    await tester.pumpAndSettle();
  }

  testWidgets('from my song: lists other songs, never itself', (tester) async {
    final h = harness();
    await open(tester, h);

    expect(find.byKey(const ValueKey('merge_intro')), findsOneWidget);
    expect(
      find.textContaining('Pick the song that “Amazing Grace” duplicates'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('merge_candidate_work-1')), findsNothing);
    expect(
      find.byKey(const ValueKey('merge_candidate_work-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('merge_candidate_work-3')),
      findsOneWidget,
    );
    expect(h.sharing.calls, contains('songs::mine=false'));
  });

  testWidgets('from my song: confirms, then merges my song into the pick', (
    tester,
  ) async {
    final h = harness();
    await open(tester, h);

    await tester.tap(find.byKey(const ValueKey('merge_request_work-3')));
    await tester.pumpAndSettle();
    expect(find.text('Request this merge?'), findsOneWidget);
    expect(
      find.text('Versions of “Amazing Grace” will move under “Grace Alone”.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('merge_confirm_btn')));
    await tester.pumpAndSettle();

    expect(h.sharing.calls, contains('merge:work-1>work-3'));
    expect(find.text('Merge request sent'), findsOneWidget);
    // The sheet closed.
    expect(find.byKey(const ValueKey('merge_search_field')), findsNothing);
    expect(h.cloudSync.syncs, 0);
  });

  testWidgets('from somebody else\'s song: only my songs, merged into it', (
    tester,
  ) async {
    final h = harness();
    await open(tester, h, createdByMe: false);

    expect(h.sharing.calls, contains('songs::mine=true'));
    expect(
      find.byKey(const ValueKey('merge_candidate_work-2')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('merge_candidate_work-3')), findsNothing);
    expect(find.textContaining('was created by someone else'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('merge_request_work-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('merge_confirm_btn')));
    await tester.pumpAndSettle();
    expect(h.sharing.calls, contains('merge:work-2>work-1'));
  });

  testWidgets('a pending request between two songs cannot be sent again', (
    tester,
  ) async {
    final h = harness();
    h.sharing.pending = const [
      SongMergeRequest(
        id: 'r1',
        sourceSongId: 'work-3',
        targetSongId: 'work-1',
        sourceTitle: 'Grace Alone',
        targetTitle: 'Amazing Grace',
      ),
    ];
    await open(tester, h);

    expect(find.byKey(const ValueKey('merge_pending_work-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('merge_request_work-3')), findsNothing);
    // The other song can still be requested.
    expect(find.byKey(const ValueKey('merge_request_work-2')), findsOneWidget);
  });

  testWidgets('a request answered at once says the songs were merged', (
    tester,
  ) async {
    final h = harness();
    h.sharing.mergeStatus = MergeRequestStatus.accepted;
    await open(tester, h);
    await tester.tap(find.byKey(const ValueKey('merge_request_work-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('merge_confirm_btn')));
    await tester.pumpAndSettle();

    expect(find.text('The songs were merged'), findsOneWidget);
    expect(h.cloudSync.syncs, 1);
  });

  testWidgets('a refused request stays in the sheet with the reason', (
    tester,
  ) async {
    final h = harness();
    await open(tester, h);
    h.sharing.failure = BackendErrorCode.mergeAlreadyRequested.failure(
      message: 'dup',
    );
    await tester.tap(find.byKey(const ValueKey('merge_request_work-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('merge_confirm_btn')));
    await tester.pumpAndSettle();

    expect(
      find.text('A merge request for these songs is already pending.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('merge_search_field')), findsOneWidget);
  });

  testWidgets('offline it explains that merging needs a connection', (
    tester,
  ) async {
    final h = harness();
    h.sharing.failure = offlineFailure();
    await open(tester, h);
    expect(
      find.text('Merging songs needs an internet connection.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('searching filters the songs', (tester) async {
    final h = harness();
    await open(tester, h);
    await tester.enterText(
      find.byKey(const ValueKey('merge_search_field')),
      'alone',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('merge_candidate_work-3')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('merge_candidate_work-2')), findsNothing);
  });

  testWidgets('no matches', (tester) async {
    final h = harness();
    h.sharing.songs = const [];
    await open(tester, h);
    expect(find.byKey(const ValueKey('merge_empty')), findsOneWidget);
  });

  for (final width in [320.0, 375.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${width.toInt()} px', (tester) async {
      final h = harness();
      h.sharing.pending = const [
        SongMergeRequest(
          id: 'r1',
          sourceSongId: 'work-3',
          targetSongId: 'work-1',
          sourceTitle: 'Grace Alone',
          targetTitle: 'Amazing Grace',
        ),
      ];
      await open(tester, h, width: width);
      expect(tester.takeException(), isNull);
    });
  }
}
