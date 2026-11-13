import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/features/repertoire/presentation/pages/song_detail_page.dart';
import 'package:battuta/features/repertoire/presentation/pages/song_editor_page.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:battuta/features/sharing/presentation/widgets/song_sharing_actions.dart';
import 'package:battuta/features/sharing/presentation/widgets/song_versions_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_song_sharing.dart';
import 'sharing_harness.dart';

SongVersionListing listing(
  String id, {
  String label = 'Original',
  String owner = 'u-x',
  String name = 'Grace',
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
  group('actions on the viewer', () {
    testWidgets('my version offers sharing and move, no fork', (tester) async {
      final h = SharingHarness(songs: [versionOf('v1')]);
      await h.pump(tester, const SongDetailPage(songId: 'v1'));

      expect(find.byKey(const ValueKey('sharing_btn')), findsOneWidget);
      expect(find.text('Sharing · Private'), findsOneWidget);
      expect(find.byKey(const ValueKey('fork_btn')), findsNothing);
      expect(find.byKey(const ValueKey('move_song_btn')), findsOneWidget);
      expect(find.text('Move to another song'), findsOneWidget);
    });

    testWidgets('the sharing button shows the current visibility', (
      tester,
    ) async {
      final h = SharingHarness(
        songs: [versionOf('v1', visibility: SongVisibility.public)],
      );
      await h.pump(tester, const SongDetailPage(songId: 'v1'));
      expect(find.text('Sharing · Public'), findsOneWidget);
    });

    testWidgets('somebody else\'s version: only fork', (tester) async {
      final h = SharingHarness(
        songs: [versionOf('v1', owner: 'u-x', creator: 'u-x')],
      );
      await h.pump(tester, const SongDetailPage(songId: 'v1'));

      expect(find.byKey(const ValueKey('sharing_btn')), findsNothing);
      expect(find.byKey(const ValueKey('fork_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('move_song_btn')), findsNothing);
    });

    testWidgets('a local-mode song can only be forked', (tester) async {
      final h = SharingHarness(
        songs: [versionOf('v1', owner: null, workId: null)],
        signedIn: false,
      );
      await h.pump(tester, const SongDetailPage(songId: 'v1'));

      expect(find.byKey(const ValueKey('sharing_btn')), findsNothing);
      expect(find.byKey(const ValueKey('move_song_btn')), findsNothing);
      expect(find.byKey(const ValueKey('fork_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('song_versions_section')), findsNothing);
    });
  });

  group('other versions', () {
    SharingHarness harness() {
      final h = SharingHarness(
        songs: [
          versionOf('v1'),
          versionOf('v2', owner: 'u-x', label: 'Choir'),
        ],
      );
      h.sharing.versions = [
        listing('v2', label: 'Choir'),
        listing(
          'v3',
          label: 'Acoustic',
          name: 'Jane',
          owner: 'u-j',
          forkedFrom: 'v1',
          visibility: SongVisibility.organizations,
        ),
      ];
      return h;
    }

    testWidgets('merges cached and online versions without duplicates', (
      tester,
    ) async {
      final h = harness();
      await h.pump(tester, const SongDetailPage(songId: 'v1'));

      expect(find.byKey(const ValueKey('version_row_v1')), findsNothing);
      expect(find.byKey(const ValueKey('version_row_v2')), findsOneWidget);
      expect(find.byKey(const ValueKey('version_row_v3')), findsOneWidget);
      expect(find.text('Owned by Grace'), findsOneWidget);
      expect(find.text('Owned by Jane'), findsOneWidget);
      // Badges: visibility, fork lineage and "on this device".
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('version_row_v2')),
          matching: find.text('Public'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('version_row_v3')),
          matching: find.text('Organizations'),
        ),
        findsOneWidget,
      );
      expect(find.text('Fork of Original'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('version_row_v2')),
          matching: find.text('On this device'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('version_row_v3')),
          matching: find.text('On this device'),
        ),
        findsNothing,
      );
    });

    testWidgets('offline it still lists the versions on the device', (
      tester,
    ) async {
      final h = harness()..sharing.failure = offlineFailure();
      await h.pump(tester, const SongDetailPage(songId: 'v1'));

      expect(find.byKey(const ValueKey('version_row_v2')), findsOneWidget);
      expect(find.byKey(const ValueKey('version_row_v3')), findsNothing);
      expect(find.byKey(const ValueKey('versions_failure')), findsOneWidget);
      expect(
        find.text('Offline: showing the versions saved on this device.'),
        findsOneWidget,
      );
    });

    testWidgets('says so when there are no other versions', (tester) async {
      final h = SharingHarness(songs: [versionOf('v1')]);
      await h.pump(tester, const SongDetailPage(songId: 'v1'));
      expect(find.byKey(const ValueKey('versions_empty')), findsOneWidget);
    });

    testWidgets('opening an online-only version downloads it first', (
      tester,
    ) async {
      final h = harness();
      h.sharing.opened = versionOf('v3', owner: 'u-j');
      await h.pump(tester, const SongDetailPage(songId: 'v1'));

      await tester.tap(find.text('Acoustic'));
      await tester.pumpAndSettle();

      expect(h.sharing.calls, contains('open:v3'));
      expect(h.location, 'viewer:v3');
    });

    testWidgets('a cached version opens without asking the backend', (
      tester,
    ) async {
      final h = harness();
      await h.pump(tester, const SongDetailPage(songId: 'v1'));
      await tester.tap(find.text('Choir'));
      await tester.pumpAndSettle();

      expect(h.sharing.calls.where((c) => c.startsWith('open:')), isEmpty);
      expect(h.location, 'viewer:v2');
    });

    testWidgets('forking a row asks for a name and opens the copy', (
      tester,
    ) async {
      final h = harness();
      h.sharing.forked = ForkedVersion(versionOf('v-new', forkedFrom: 'v3'));
      await h.pump(tester, const SongDetailPage(songId: 'v1'));

      await tester.tap(find.byKey(const ValueKey('fork_version_v3')));
      await tester.pumpAndSettle();
      expect(find.text('Fork this version'), findsOneWidget);
      // The name is prefilled from the version being forked.
      expect(find.text('Acoustic (copy)'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('fork_label_field')),
        'Our take',
      );
      await tester.tap(find.byKey(const ValueKey('fork_confirm_btn')));
      await tester.pumpAndSettle();

      expect(h.sharing.calls, contains('fork:v3:Our take'));
      expect(h.location, 'editor:v-new');
      expect(h.cloudSync.syncs, greaterThan(0));
    });
  });

  group('fork button on the viewer', () {
    testWidgets('an offline fork says it will sync later', (tester) async {
      final h = SharingHarness(songs: [versionOf('v1', owner: 'u-x')]);
      h.sharing.forked = ForkedVersion(
        versionOf('v-new', forkedFrom: 'v1'),
        madeOffline: true,
      );
      await h.pump(tester, const SongDetailPage(songId: 'v1'));

      await tester.tap(find.byKey(const ValueKey('fork_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('fork_confirm_btn')));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Forked on this device. It syncs when you are online.'),
        findsOneWidget,
      );
      expect(h.location, 'editor:v-new');
    });

    testWidgets('cancelling the dialog forks nothing', (tester) async {
      final h = SharingHarness(songs: [versionOf('v1', owner: 'u-x')]);
      await h.pump(tester, const SongDetailPage(songId: 'v1'));
      await tester.tap(find.byKey(const ValueKey('fork_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(h.sharing.calls.where((c) => c.startsWith('fork')), isEmpty);
    });

    testWidgets('a failed fork shows the reason', (tester) async {
      final h = SharingHarness(songs: [versionOf('v1', owner: 'u-x')]);
      h.sharing.failure = offlineFailure();
      await h.pump(tester, const SongDetailPage(songId: 'v1'));
      await tester.tap(find.byKey(const ValueKey('fork_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('fork_confirm_btn')));
      await tester.pump();
      await tester.pump();
      expect(h.location, 'home');
      expect(find.textContaining('offline'), findsWidgets);
    });
  });

  group('title and artist in the editor', () {
    testWidgets('are read-only on a song somebody else created', (
      tester,
    ) async {
      final h = SharingHarness(songs: [versionOf('v1', creator: 'u-x')]);
      await h.pump(tester, const SongEditorPage(songId: 'v1'));

      final title = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('song_title_field')),
          matching: find.byType(TextField),
        ),
      );
      final artist = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('song_artist_field')),
          matching: find.byType(TextField),
        ),
      );
      expect(title.readOnly, isTrue);
      expect(artist.readOnly, isTrue);
      expect(
        find.textContaining('Only the person who created it'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('editor_move_btn')), findsOneWidget);
      // The rest of the version stays editable.
      expect(find.byKey(const ValueKey('editor_sharing_btn')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.ancestor(
                of: find.text('Save'),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('are editable by the creator of the song', (tester) async {
      final h = SharingHarness(songs: [versionOf('v1', creator: 'u-me')]);
      await h.pump(tester, const SongEditorPage(songId: 'v1'));

      final title = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('song_title_field')),
          matching: find.byType(TextField),
        ),
      );
      expect(title.readOnly, isFalse);
      expect(find.byKey(const ValueKey('editor_move_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('editor_sharing_btn')), findsOneWidget);
    });

    testWidgets('saving keeps the song\'s title when it is locked', (
      tester,
    ) async {
      final h = SharingHarness(songs: [versionOf('v1', creator: 'u-x')]);
      await h.pump(tester, const SongEditorPage(songId: 'v1'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final saved = (await h.songs.getSongById('v1'))
          .getOrElse((_) => throw 'x');
      expect(saved.title, 'Amazing Grace');
    });
  });

  SharingHarness longNames() {
    final h = SharingHarness(
      songs: [
        versionOf('v1'),
        versionOf(
          'v2',
          owner: 'u-x',
          label: 'A very long arrangement name for the choir',
        ),
      ],
    );
    h.sharing.versions = [
      listing(
        'v3',
        label: 'Another really long arrangement label to wrap around',
        name: 'Someone With A Quite Long Display Name',
        forkedFrom: 'v1',
      ),
    ];
    return h;
  }

  // The viewer's practice player bar already overflows below 360 px (not part
  // of this task), so the whole page is checked from 360 px up and the new
  // pieces on their own down to 320 px.
  for (final width in [360.0, 375.0, 768.0, 1024.0, 1440.0]) {
    testWidgets(
      'viewer with sharing and versions: no overflow at ${width.toInt()} px',
      (tester) async {
        await longNames().pump(
          tester,
          const SongDetailPage(songId: 'v1'),
          width: width,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [320.0, 375.0]) {
    testWidgets('actions and versions: no overflow at ${width.toInt()} px', (
      tester,
    ) async {
      final h = longNames();
      await h.pump(
        tester,
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SongSharingActions(song: versionOf('v1')),
              const SongVersionsSection(
                songWorkId: 'work-1',
                title: 'Other versions',
              ),
            ],
          ),
        ),
        width: width,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('version_row_v3')), findsOneWidget);
    });
  }
}
