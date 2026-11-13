import 'package:battuta/core/database/database_providers.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_setlist_repository.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/pages/setlist_detail_page.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_organization_repertoire_repository.dart';
import '../../../../support/fake_organization_repository.dart';
import '../../../../support/team_fixtures.dart';

Song song(String id, String title, {String? owner = 'u-x'}) => Song(
  id: id,
  title: title,
  artist: 'Artist',
  key: 'G',
  tempo: 72,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  ownerId: owner,
);

Setlist setlist(String id, {String? org}) => Setlist(
  id: id,
  title: 'Set $id',
  items: const [SetlistItem(id: 'i1', songId: 'song-1', orderIndex: 0)],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  organizationId: org,
);

void main() {
  late InMemorySetlistRepository setlists;
  late FakeOrganizationRepository orgs;

  setUp(() {
    setlists = InMemorySetlistRepository(
      initialSetlists: [
        setlist('personal'),
        setlist('admin-set', org: 'org-admin'),
        setlist('member-set', org: 'org-member'),
      ],
    );
    orgs = FakeOrganizationRepository(
      organizations: [
        org('org-admin', 'Admin Org'),
        org('org-member', 'Member Org', role: OrganizationRole.member),
      ],
    );
  });

  Future<void> pump(WidgetTester tester, String setlistId) async {
    tester.view.physicalSize = const Size(1024, 2048);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final repertoire = FakeOrganizationRepertoireRepository(
      entries: [
        const RepertoireEntry(
          organizationId: 'org-admin',
          versionId: 'song-1',
          title: 'Amazing Grace',
        ),
        const RepertoireEntry(
          organizationId: 'org-admin',
          versionId: 'song-2',
          title: 'Way Maker',
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...signedInOverrides(
            orgs,
            repertoire: repertoire,
            fixedSetlists: false,
          ),
          songRepositoryProvider.overrideWithValue(
            InMemorySongRepository(
              initialSongs: [
                song('song-1', 'Amazing Grace'),
                song('song-2', 'Way Maker'),
                song('song-3', 'Not In Repertoire'),
                song('song-mine', 'My Own Song', owner: 'u-me'),
                song('song-local', 'Local Song', owner: null),
              ],
            ),
          ),
          setlistRepositoryProvider.overrideWithValue(setlists),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SetlistDetailPage(setlistId: setlistId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an admin edits the setlists of their organization', (
    tester,
  ) async {
    await pump(tester, 'admin-set');

    await tester.tap(find.byKey(const ValueKey('setlist_menu')));
    await tester.pumpAndSettle();
    expect(find.text('Edit setlist info'), findsOneWidget);
    expect(find.text('Delete setlist'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add Song to Setlist'), findsOneWidget);
    expect(find.byTooltip('Remove from setlist'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('setlist_read_only_notice')),
      findsNothing,
    );
  });

  testWidgets(
    'the picker of an organization setlist offers its repertoire only',
    (tester) async {
      await pump(tester, 'admin-set');

      await tester.tap(find.byTooltip('Add Song to Setlist'));
      await tester.pumpAndSettle();

      // song-1 is already in the setlist; song-3 is not in the repertoire.
      expect(find.text('Way Maker'), findsOneWidget);
      expect(find.text('Not In Repertoire'), findsNothing);
    },
  );

  testWidgets('the picker of a personal setlist offers my library only', (
    tester,
  ) async {
    await pump(tester, 'personal');

    await tester.tap(find.byTooltip('Add Song to Setlist'));
    await tester.pumpAndSettle();

    // song-2 and song-3 are cached versions of somebody else (u-x); only my
    // own and local-mode songs are offered.
    expect(find.text('Way Maker'), findsNothing);
    expect(find.text('Not In Repertoire'), findsNothing);
    expect(find.text('My Own Song'), findsOneWidget);
    expect(find.text('Local Song'), findsOneWidget);
  });

  testWidgets('a member reads the setlist and can still open its songs', (
    tester,
  ) async {
    await pump(tester, 'member-set');

    expect(find.text('Amazing Grace'), findsOneWidget);
    expect(find.byKey(const ValueKey('setlist_menu')), findsNothing);
    expect(find.byTooltip('Remove from setlist'), findsNothing);
    expect(find.byTooltip('Add Song to Setlist'), findsNothing);
    expect(find.byIcon(Icons.drag_handle), findsNothing);
    expect(
      find.byKey(const ValueKey('setlist_read_only_notice')),
      findsOneWidget,
    );
  });

  testWidgets('personal setlists stay editable whatever the role', (
    tester,
  ) async {
    orgs.setOrganizations([
      org('org-member', 'Member Org', role: OrganizationRole.member),
    ]);
    await pump(tester, 'personal');

    expect(find.byKey(const ValueKey('setlist_menu')), findsOneWidget);
    expect(find.byTooltip('Add Song to Setlist'), findsOneWidget);
  });

  testWidgets('an admin demoted while the page is open loses the actions', (
    tester,
  ) async {
    await pump(tester, 'admin-set');
    expect(find.byTooltip('Add Song to Setlist'), findsOneWidget);

    orgs.setOrganizations([
      org('org-admin', 'Admin Org', role: OrganizationRole.member),
    ]);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Add Song to Setlist'), findsNothing);
    expect(
      find.byKey(const ValueKey('setlist_read_only_notice')),
      findsOneWidget,
    );
  });
}
