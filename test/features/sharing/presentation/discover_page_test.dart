import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:battuta/features/sharing/presentation/pages/discover_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_song_sharing.dart';
import 'sharing_harness.dart';

SongVersionListing pub(
  String id,
  String title, {
  String owner = 'u-x',
  String name = 'Grace',
}) => SongVersionListing(
  versionId: id,
  songWorkId: 'work-$id',
  title: title,
  artist: 'Artist',
  label: 'Original',
  key: 'D',
  visibility: SongVisibility.public,
  ownerId: owner,
  ownerDisplayName: name,
);

void main() {
  SharingHarness harness({bool signedIn = true}) {
    final h = SharingHarness(signedIn: signedIn);
    h.sharing.publicVersions = [
      pub('p1', 'Amazing Grace'),
      pub('p2', 'Way Maker', name: 'Jane'),
      pub('p3', 'My Own Song', owner: 'u-me', name: 'Me'),
    ];
    return h;
  }

  Future<void> open(
    WidgetTester tester,
    SharingHarness h, {
    double width = 1024,
    int pageSize = 30,
  }) => h.pump(
    tester,
    DiscoverPage(debounce: Duration.zero, pageSize: pageSize),
    width: width,
  );

  testWidgets('lists public versions with their owner and label', (
    tester,
  ) async {
    final h = harness();
    await open(tester, h);

    expect(find.byKey(const ValueKey('discover_p1')), findsOneWidget);
    expect(find.byKey(const ValueKey('discover_p2')), findsOneWidget);
    expect(find.textContaining('Owned by Grace'), findsOneWidget);
    expect(find.textContaining('Owned by Jane'), findsOneWidget);
    expect(find.textContaining('Yours'), findsOneWidget);
  });

  testWidgets('searches by title or artist', (tester) async {
    final h = harness();
    await open(tester, h);

    await tester.enterText(
      find.byKey(const ValueKey('discover_search_field')),
      'way',
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(h.sharing.calls, contains('public:way:0'));
    expect(find.byKey(const ValueKey('discover_p2')), findsOneWidget);
    expect(find.byKey(const ValueKey('discover_p1')), findsNothing);
  });

  testWidgets('no matches', (tester) async {
    final h = harness();
    h.sharing.publicVersions = [];
    await open(tester, h);
    expect(find.byKey(const ValueKey('discover_empty')), findsOneWidget);
  });

  testWidgets('opening a version downloads it and shows the viewer', (
    tester,
  ) async {
    final h = harness();
    h.sharing.opened = versionOf('p1', owner: 'u-x');
    await open(tester, h);

    await tester.tap(find.text('Amazing Grace'));
    await tester.pumpAndSettle();

    expect(h.sharing.calls, contains('open:p1'));
    expect(h.location, 'viewer:p1');
  });

  testWidgets('a version that cannot be opened says why', (tester) async {
    final h = harness();
    await open(tester, h);
    // `opened` is unset: the backend no longer has it.
    await tester.tap(find.text('Amazing Grace'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('discover_open_error')), findsOneWidget);
    expect(h.location, 'home');
  });

  testWidgets('forking from Discover opens the copy in the editor', (
    tester,
  ) async {
    final h = harness();
    h.sharing.forked = ForkedVersion(versionOf('v-new', forkedFrom: 'p1'));
    await open(tester, h);

    await tester.tap(find.byKey(const ValueKey('discover_fork_p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fork_confirm_btn')));
    await tester.pumpAndSettle();

    expect(h.sharing.calls, contains('fork:p1:Original (copy)'));
    expect(h.location, 'editor:v-new');
  });

  testWidgets('offline it needs internet and can retry', (tester) async {
    final h = harness()..sharing.failure = offlineFailure();
    await open(tester, h);

    expect(find.byKey(const ValueKey('discover_error')), findsOneWidget);
    expect(find.text('Discover needs an internet connection.'), findsOneWidget);
    h.sharing.failure = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('discover_p1')), findsOneWidget);
  });

  testWidgets('signed out it asks to sign in', (tester) async {
    final h = harness(signedIn: false);
    await open(tester, h);

    expect(find.byKey(const ValueKey('discover_sign_in')), findsOneWidget);
    expect(h.sharing.calls, isEmpty);
    expect(find.byKey(const ValueKey('discover_search_field')), findsNothing);
  });

  testWidgets('loads more pages without repeating versions', (tester) async {
    final h = harness();
    await open(tester, h, pageSize: 2);

    expect(find.byKey(const ValueKey('discover_p3')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('discover_load_more')));
    await tester.pumpAndSettle();

    expect(h.sharing.calls, contains('public::2'));
    expect(find.byKey(const ValueKey('discover_p3')), findsOneWidget);
    expect(find.byKey(const ValueKey('discover_load_more')), findsNothing);
  });

  for (final width in [320.0, 375.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${width.toInt()} px', (tester) async {
      final h = harness();
      h.sharing.publicVersions = [
        pub(
          'p1',
          'A very long public song title that has to wrap around the card',
          name: 'Someone With A Quite Long Display Name',
        ),
      ];
      await open(tester, h, width: width);
      expect(tester.takeException(), isNull);
    });
  }
}
