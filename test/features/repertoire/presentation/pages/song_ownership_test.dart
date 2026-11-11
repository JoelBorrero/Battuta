import 'package:battuta/app/routes/app_router.dart';
import 'package:battuta/app/routes/song_edit_guard.dart';
import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/auth/domain/entities/auth_user.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/pages/song_detail_page.dart';
import 'package:battuta/features/repertoire/presentation/pages/song_editor_page.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/score/presentation/pages/score_editor_page.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/app_harness.dart';
import '../../../../support/fake_auth_repository.dart';
import '../../../../support/fake_organization_repertoire_repository.dart';
import '../../../../support/fake_organization_repository.dart';
import '../../../../support/team_fixtures.dart';

Song song(String id, {String? owner}) => Song(
  id: id,
  title: 'Song $id',
  artist: 'Artist',
  key: 'G',
  tempo: 90,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  ownerId: owner,
);

Finder _buttonLabelled(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((w) => w is FilledButton),
);

void main() {
  group('songEditRedirect', () {
    test('sends the editor of somebody else\'s version to the viewer', () {
      expect(
        songEditRedirect(song: song('v1', owner: 'u-x'), accountId: 'u-me'),
        '/repertoire/v1',
      );
      expect(
        songEditRedirect(song: song('v1', owner: 'u-x'), accountId: null),
        '/repertoire/v1',
      );
    });

    test('lets owners, local-mode songs and unknown songs through', () {
      expect(
        songEditRedirect(song: song('v1', owner: 'u-me'), accountId: 'u-me'),
        isNull,
      );
      expect(songEditRedirect(song: song('v1'), accountId: 'u-me'), isNull);
      expect(songEditRedirect(song: song('v1'), accountId: null), isNull);
      expect(songEditRedirect(song: null, accountId: 'u-me'), isNull);
    });
  });

  group('viewer and editor', () {
    late FakeOrganizationRepertoireRepository repertoire;
    late FakeOrganizationRepository orgs;
    late InMemorySongRepository songs;

    setUp(() {
      repertoire = FakeOrganizationRepertoireRepository(
        entries: [
          const RepertoireEntry(
            organizationId: 'org-1',
            versionId: 'v-foreign',
            title: 'Song v-foreign',
            ownerDisplayName: 'Grace',
          ),
        ],
      );
      orgs = FakeOrganizationRepository(
        organizations: [org('org-1', 'Grace', role: OrganizationRole.member)],
        members: [member('m1', 'u-me', 'Me', orgId: 'org-1')],
      );
    });

    Future<void> pump(
      WidgetTester tester,
      Widget home, {
      bool signedIn = true,
    }) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      songs = InMemorySongRepository(
        initialSongs: [
          song('v-mine', owner: 'u-me'),
          song('v-foreign', owner: 'u-x'),
          song('v-unknown', owner: 'u-y'),
          song('v-local'),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            if (signedIn)
              ...signedInOverrides(orgs, repertoire: repertoire),
            songRepositoryProvider.overrideWithValue(songs),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('my own version shows edit and delete, even as a plain member', (
      tester,
    ) async {
      await pump(tester, const SongDetailPage(songId: 'v-mine'));

      expect(find.byTooltip('Edit Song'), findsOneWidget);
      expect(find.byTooltip('Delete Song'), findsOneWidget);
      expect(find.byTooltip('Notation Editor'), findsOneWidget);
      expect(find.byKey(const ValueKey('read_only_version_banner')), findsNothing);
    });

    testWidgets('a version of somebody else is a viewer with "Owned by"', (
      tester,
    ) async {
      await pump(tester, const SongDetailPage(songId: 'v-foreign'));

      expect(find.byTooltip('Edit Song'), findsNothing);
      expect(find.byTooltip('Delete Song'), findsNothing);
      expect(find.byTooltip('Notation Editor'), findsNothing);
      expect(find.text('Edit in Notation Editor'), findsNothing);
      expect(find.byKey(const ValueKey('read_only_version_banner')), findsOneWidget);
      expect(find.text('Owned by Grace'), findsOneWidget);
      // Reading and transposing stay available.
      expect(find.byTooltip('Transpose Key'), findsOneWidget);
    });

    testWidgets('transposing somebody else\'s version offers no save', (
      tester,
    ) async {
      await pump(tester, const SongDetailPage(songId: 'v-foreign'));

      await tester.tap(find.byTooltip('Transpose Key'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Up 1 semitone'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Save Transposed Key'), findsNothing);
      expect(find.text('Done'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      // Nothing was written.
      final stored = (await songs.getSongById('v-foreign')).getOrElse(
        (_) => throw 'x',
      );
      expect(stored.key, 'G');
    });

    testWidgets('transposing my own version saves the new key', (tester) async {
      await pump(tester, const SongDetailPage(songId: 'v-mine'));

      await tester.tap(find.byTooltip('Transpose Key'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Up 1 semitone'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Save Transposed Key'));
      await tester.pumpAndSettle();

      final stored = (await songs.getSongById('v-mine')).getOrElse(
        (_) => throw 'x',
      );
      expect(stored.key, isNot('G'));
    });

    testWidgets('an owner nobody told me about is "another user"', (tester) async {
      await pump(tester, const SongDetailPage(songId: 'v-unknown'));
      expect(find.text('Owned by another user'), findsOneWidget);
    });

    testWidgets('local mode: songs without an owner are editable', (tester) async {
      await pump(tester, const SongDetailPage(songId: 'v-local'), signedIn: false);
      expect(find.byTooltip('Edit Song'), findsOneWidget);
      expect(find.byKey(const ValueKey('read_only_version_banner')), findsNothing);
    });

    testWidgets('the editor of my version can save', (tester) async {
      await pump(tester, const SongEditorPage(songId: 'v-mine'));
      expect(find.text('Save'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(_buttonLabelled('Save')).onPressed,
        isNotNull,
      );
    });

    testWidgets('a plain member saves changes to their own version', (
      tester,
    ) async {
      await pump(tester, const SongEditorPage(songId: 'v-mine'));
      await tester.enterText(
        find.byKey(const Key('song_title_field')),
        'Renamed by a member',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final saved = (await songs.getSongById('v-mine')).getOrElse(
        (_) => throw 'x',
      );
      expect(saved.title, 'Renamed by a member');
    });

    testWidgets('the editor refuses somebody else\'s version', (tester) async {
      await pump(tester, const SongEditorPage(songId: 'v-foreign'));

      expect(find.text('View Only'), findsOneWidget);
      expect(find.text('Only the owner can edit this version.'), findsOneWidget);
      expect(find.byTooltip('Delete Song'), findsNothing);
      expect(
        tester.widget<FilledButton>(_buttonLabelled('View Only')).onPressed,
        isNull,
      );
    });

    testWidgets('a new song can be created by a plain member', (tester) async {
      await pump(tester, const SongEditorPage());
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('route guard', () {
    late AppHarness harness;

    setUp(() async {
      harness = AppHarness(
        auth: FakeAuthRepository(
          user: const AuthUser(id: 'u-me', email: 'me@example.com'),
        ),
      );
      Future<void> insert(String id, String? owner) =>
          harness.db.into(harness.db.songs).insert(
            SongsCompanion.insert(
              id: id,
              title: 'Song $id',
              artist: 'Artist',
              key: 'G',
              tempo: 90,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
              ownerId: Value(owner),
            ),
          );
      await insert('v-mine', 'u-me');
      await insert('v-foreign', 'u-x');
    });
    tearDown(() => harness.dispose());

    Future<ProviderContainer> start(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 2048);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    }

    testWidgets('the editor of somebody else\'s version never opens', (
      tester,
    ) async {
      final container = await start(tester);
      container.read(appRouterProvider).go('/repertoire/v-foreign/edit');
      await tester.pumpAndSettle();

      expect(find.byType(SongEditorPage), findsNothing);
      expect(find.byType(SongDetailPage), findsOneWidget);
      expect(find.byKey(const ValueKey('read_only_version_banner')), findsOneWidget);
    });

    testWidgets('neither does its notation editor', (tester) async {
      final container = await start(tester);
      container.read(appRouterProvider).go('/repertoire/v-foreign/notation');
      await tester.pumpAndSettle();

      expect(find.byType(ScoreEditorPage), findsNothing);
      expect(find.byType(SongDetailPage), findsOneWidget);
    });

    testWidgets('my own version opens in the editor', (tester) async {
      final container = await start(tester);
      container.read(appRouterProvider).go('/repertoire/v-mine/edit');
      await tester.pumpAndSettle();

      expect(find.byType(SongEditorPage), findsOneWidget);
    });
  });
}
