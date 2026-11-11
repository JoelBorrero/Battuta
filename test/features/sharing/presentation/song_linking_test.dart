import 'package:battuta/features/repertoire/presentation/pages/song_detail_page.dart';
import 'package:battuta/features/repertoire/presentation/pages/song_editor_page.dart';
import 'package:battuta/features/sharing/domain/entities/song_suggestion.dart';
import 'package:battuta/features/sharing/presentation/widgets/move_to_song_sheet.dart';
import 'package:battuta/features/sharing/presentation/widgets/song_suggestions_panel.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_song_sharing.dart';
import 'sharing_harness.dart';

const wayMaker = SongSuggestion(
  songWorkId: 'w-way',
  title: 'Way Maker',
  artist: 'Sinach',
  createdBy: 'u-x',
  versionCount: 3,
);

Future<void> typeTitle(WidgetTester tester, String text) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(const Key('song_title_field')),
      matching: find.byType(TextField),
    ),
    text,
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

bool readOnly(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      ),
    )
    .readOnly;

void main() {
  group('suggestions while creating a version', () {
    testWidgets('typing a title offers matching songs; picking links it', (
      tester,
    ) async {
      final h = SharingHarness(songs: const []);
      h.sharing.suggestions = [wayMaker];
      await h.pump(tester, const SongEditorPage());

      expect(find.byKey(const ValueKey('song_suggestions')), findsNothing);
      await typeTitle(tester, 'way mak');
      expect(find.byKey(const ValueKey('song_suggestions')), findsOneWidget);
      expect(find.text('3 versions'), findsOneWidget);
      expect(find.byKey(const ValueKey('song_suggestion_new')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('song_suggestion_w-way')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('song_link_selected')), findsOneWidget);
      expect(readOnly(tester, 'song_title_field'), isTrue);
      expect(readOnly(tester, 'song_artist_field'), isTrue);
      expect(find.text('Sinach'), findsOneWidget);

      // Saving attaches the new version to that song.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final saved = (await h.songs.getAllSongs()).getOrElse((_) => []);
      expect(saved.single.songWorkId, 'w-way');
      expect(saved.single.title, 'Way Maker');
      expect(saved.single.songCreatorId, 'u-x');
    });

    testWidgets('"Change" goes back to typing a new song', (tester) async {
      final h = SharingHarness();
      h.sharing.suggestions = [wayMaker];
      await h.pump(tester, const SongEditorPage());
      await typeTitle(tester, 'way mak');
      await tester.tap(find.byKey(const ValueKey('song_suggestion_w-way')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('song_link_change')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('song_link_selected')), findsNothing);
      expect(readOnly(tester, 'song_title_field'), isFalse);
    });

    testWidgets('no match, no panel', (tester) async {
      final h = SharingHarness();
      await h.pump(tester, const SongEditorPage());
      await typeTitle(tester, 'something nobody wrote');
      expect(find.byKey(const ValueKey('song_suggestions')), findsNothing);
    });

    testWidgets('offline it suggests the songs saved on the device', (
      tester,
    ) async {
      final h = SharingHarness(
        songs: [versionOf('v1', title: 'Amazing Grace', owner: 'u-x')],
      );
      h.sharing.failure = offlineFailure();
      await h.pump(tester, const SongEditorPage());
      await typeTitle(tester, 'amazing');
      expect(
        find.byKey(const ValueKey('song_suggestion_work-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('song_suggestions_offline')),
        findsOneWidget,
      );
    });

    testWidgets('editing an existing version shows no suggestions', (
      tester,
    ) async {
      final h = SharingHarness(songs: [versionOf('v1', creator: 'u-me')]);
      h.sharing.suggestions = [wayMaker];
      await h.pump(tester, const SongEditorPage(songId: 'v1'));
      expect(find.byType(SongSuggestionsPanel), findsNothing);
    });

    // The editor itself overflows below ~480 px (not part of this task), so
    // the panel is checked on its own.
    for (final width in [320.0, 375.0, 768.0, 1440.0]) {
      testWidgets('panel: no overflow at ${width.toInt()} px', (tester) async {
        final h = SharingHarness();
        h.sharing.suggestions = [
          const SongSuggestion(
            songWorkId: 'w-long',
            title: 'A very long song title that keeps going and going',
            artist: 'An artist with a rather long name as well, to be sure',
            versionCount: 12,
          ),
        ];
        final title = TextEditingController(text: 'a very long');
        addTearDown(title.dispose);
        SongSuggestion? picked;
        await h.pump(
          tester,
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SongSuggestionsPanel(
                    titleController: title,
                    selected: picked,
                    debounce: Duration.zero,
                    onSelected: (s) => setState(() => picked = s),
                  ),
                ],
              ),
            ),
          ),
          width: width,
        );
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('song_suggestions')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('song_suggestion_w-long')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('song_link_selected')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('move to another song', () {
    testWidgets('the owner moves a version; the sync applies it', (
      tester,
    ) async {
      final h = SharingHarness(songs: [versionOf('v1', creator: 'u-me')]);
      h.sharing.suggestions = [
        const SongSuggestion(songWorkId: 'work-1', title: 'Amazing Grace'),
        const SongSuggestion(
          songWorkId: 'w-right',
          title: 'Amazing Grace (right)',
          artist: 'Newton',
          createdBy: 'u-x',
          versionCount: 4,
        ),
      ];
      await h.pump(tester, const SongDetailPage(songId: 'v1'));

      await tester.tap(find.byKey(const ValueKey('move_song_btn')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      // The song the version already has is not offered.
      expect(find.byKey(const ValueKey('move_candidate_work-1')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('move_candidate_w-right')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('move_confirm_btn')));
      await tester.pumpAndSettle();

      final moved = (await h.songs.getSongById('v1'))
          .getOrElse((_) => throw 'x');
      expect(moved.songWorkId, 'w-right');
      expect(moved.title, 'Amazing Grace (right)');
      expect(moved.songCreatorId, 'u-x');
      expect(h.cloudSync.syncs, greaterThan(0));
    });

    testWidgets('someone else\'s version cannot be moved', (tester) async {
      final h = SharingHarness(songs: [versionOf('v1', owner: 'u-x')]);
      await h.pump(tester, const SongDetailPage(songId: 'v1'));
      expect(find.byKey(const ValueKey('move_song_btn')), findsNothing);
    });

    testWidgets('no matching songs says so', (tester) async {
      final h = SharingHarness(songs: [versionOf('v1', creator: 'u-me')]);
      await h.pump(
        tester,
        Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showMoveToSongSheet(
                context,
                versionOf('v1', creator: 'u-me', title: 'zzzzzz'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('move_empty')), findsOneWidget);
    });

    for (final width in [320.0, 375.0, 1440.0]) {
      testWidgets('sheet: no overflow at ${width.toInt()} px', (tester) async {
        final h = SharingHarness(songs: [versionOf('v1', creator: 'u-me')]);
        h.sharing.suggestions = [
          const SongSuggestion(
            songWorkId: 'w-long',
            title: 'Amazing Grace but with a very long title indeed',
            artist: 'An artist with a rather long name as well',
            versionCount: 120,
          ),
        ];
        await h.pump(
          tester,
          Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showMoveToSongSheet(context, versionOf('v1')),
                child: const Text('open'),
              ),
            ),
          ),
          width: width,
          height: 800,
        );
        await tester.tap(find.text('open'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('move_candidate_w-long')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('a viewer whose version a sync removed', () {
    testWidgets('says it is no longer available and offers a way back', (
      tester,
    ) async {
      final h = SharingHarness();
      await h.pump(tester, const SongDetailPage(songId: 'gone'));
      expect(find.byKey(const ValueKey('version_unavailable')), findsOneWidget);
      expect(find.text('This version is no longer available'), findsOneWidget);
      expect(find.text('Back to Repertoire'), findsOneWidget);
      expect(find.textContaining('Error loading'), findsNothing);
    });
  });

  test('the sync keeps what the viewers pinned', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final pins = container.read(pinnedVersionsProvider)..pin('v-open');
    expect(pins.ids, contains('v-open'));
    pins.release('v-open');
    expect(pins.ids, isEmpty);
  });
}
