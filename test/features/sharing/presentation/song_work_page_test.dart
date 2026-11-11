import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:battuta/features/sharing/presentation/pages/song_work_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_song_sharing.dart';
import 'sharing_harness.dart';

void main() {
  SharingHarness harness() {
    final h = SharingHarness(songs: [versionOf('v1', workId: 'work-1')]);
    h.sharing.songs = const [
      SongWork(id: 'work-1', title: 'Amazing Grace', artist: 'Newton'),
    ];
    h.sharing.versions = const [
      SongVersionListing(
        versionId: 'v9',
        songWorkId: 'work-1',
        title: 'Amazing Grace',
        label: 'Choir',
        ownerId: 'u-x',
        ownerDisplayName: 'Grace',
      ),
    ];
    return h;
  }

  testWidgets('shows the song with all its versions', (tester) async {
    final h = harness();
    await h.pump(tester, const SongWorkPage(songWorkId: 'work-1'));

    expect(find.byKey(const ValueKey('song_page_title')), findsOneWidget);
    expect(find.text('Newton'), findsOneWidget);
    expect(find.byKey(const ValueKey('version_row_v1')), findsOneWidget);
    expect(find.byKey(const ValueKey('version_row_v9')), findsOneWidget);
    expect(find.text('Versions'), findsOneWidget);
  });

  testWidgets('offline it shows the cached versions and says so', (
    tester,
  ) async {
    final h = harness()..sharing.failure = offlineFailure();
    await h.pump(tester, const SongWorkPage(songWorkId: 'work-1'));

    expect(find.byKey(const ValueKey('song_page_offline')), findsOneWidget);
    expect(find.byKey(const ValueKey('version_row_v1')), findsOneWidget);
    expect(find.byKey(const ValueKey('version_row_v9')), findsNothing);
    // The title still comes from the version on the device.
    expect(find.byKey(const ValueKey('song_page_title')), findsOneWidget);
  });

  testWidgets('an unknown song says it is not available', (tester) async {
    final h = SharingHarness();
    h.sharing.failure = BackendErrorCode.songNotFound.failure(message: 'x');
    await h.pump(tester, const SongWorkPage(songWorkId: 'nope'));
    expect(find.byKey(const ValueKey('song_page_offline')), findsOneWidget);
  });

  for (final width in [320.0, 375.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${width.toInt()} px', (tester) async {
      final h = harness();
      await h.pump(
        tester,
        const SongWorkPage(songWorkId: 'work-1'),
        width: width,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
