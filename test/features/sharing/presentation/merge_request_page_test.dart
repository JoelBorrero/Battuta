import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:battuta/features/sharing/presentation/pages/merge_request_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_song_sharing.dart';
import 'sharing_harness.dart';

SongMergeRequest request({
  String approver = 'u-me',
  MergeRequestStatus status = MergeRequestStatus.pending,
}) => SongMergeRequest(
  id: 'r1',
  sourceSongId: 'song-a',
  targetSongId: 'song-b',
  sourceTitle: 'Amazing Grace (mine)',
  targetTitle: 'Amazing Grace',
  requestedBy: 'u-x',
  approverId: approver,
  requesterName: 'Jane',
  status: status,
);

void main() {
  SharingHarness harness(SongMergeRequest r) {
    final h = SharingHarness();
    h.sharing.requests['r1'] = r;
    return h;
  }

  testWidgets('shows both titles and who asks', (tester) async {
    final h = harness(request());
    await h.pump(tester, const MergeRequestPage(requestId: 'r1'));

    expect(
      find.text(
        'Jane asks to merge “Amazing Grace (mine)” into “Amazing Grace”. '
        'Every version of “Amazing Grace (mine)” would move under “Amazing Grace”.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('merge_accept_btn')), findsOneWidget);
    expect(find.byKey(const ValueKey('merge_decline_btn')), findsOneWidget);
  });

  testWidgets('accepting merges and opens the surviving song', (tester) async {
    final h = harness(request());
    await h.pump(tester, const MergeRequestPage(requestId: 'r1'));

    await tester.tap(find.byKey(const ValueKey('merge_accept_btn')));
    await tester.pumpAndSettle();

    expect(h.sharing.calls, contains('respond:r1:true'));
    expect(h.location, 'song-page:song-b');
    expect(h.cloudSync.syncs, 1);
  });

  testWidgets('declining answers and stays on the request', (tester) async {
    final h = harness(request());
    await h.pump(tester, const MergeRequestPage(requestId: 'r1'));

    await tester.tap(find.byKey(const ValueKey('merge_decline_btn')));
    await tester.pump();
    await tester.pump();

    expect(h.sharing.calls, contains('respond:r1:false'));
    expect(find.text('Request declined'), findsOneWidget);
    expect(h.location, 'home');
  });

  testWidgets('a failed answer shows the reason and keeps the buttons', (
    tester,
  ) async {
    final h = harness(request());
    await h.pump(tester, const MergeRequestPage(requestId: 'r1'));
    h.sharing.failure = BackendErrorCode.mergeNotPending.failure(message: 'x');

    await tester.tap(find.byKey(const ValueKey('merge_accept_btn')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('merge_request_send_error')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('merge_accept_btn')), findsOneWidget);
  });

  testWidgets('an answered request has no buttons', (tester) async {
    final h = harness(request(status: MergeRequestStatus.accepted));
    await h.pump(tester, const MergeRequestPage(requestId: 'r1'));

    expect(
      find.byKey(const ValueKey('merge_request_answered')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('merge_accept_btn')), findsNothing);
  });

  testWidgets('the requester cannot answer their own request', (tester) async {
    final h = harness(request(approver: 'u-x'));
    await h.pump(tester, const MergeRequestPage(requestId: 'r1'));
    expect(find.byKey(const ValueKey('merge_request_body')), findsOneWidget);
    expect(find.byKey(const ValueKey('merge_accept_btn')), findsNothing);
  });

  testWidgets('offline it says so and can retry', (tester) async {
    final h = harness(request())..sharing.failure = offlineFailure();
    await h.pump(tester, const MergeRequestPage(requestId: 'r1'));

    expect(find.byKey(const ValueKey('merge_request_error')), findsOneWidget);
    h.sharing.failure = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('merge_accept_btn')), findsOneWidget);
  });

  for (final width in [320.0, 375.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${width.toInt()} px', (tester) async {
      final h = harness(request());
      await h.pump(
        tester,
        const MergeRequestPage(requestId: 'r1'),
        width: width,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
