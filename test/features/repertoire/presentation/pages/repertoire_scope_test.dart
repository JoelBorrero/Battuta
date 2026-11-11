import 'package:battuta/core/database/database_providers.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_setlist_repository.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/features/repertoire/presentation/pages/repertoire_page.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_scope_providers.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/app_harness.dart' show FakeCloudSyncService;
import '../../../../support/fake_organization_repertoire_repository.dart';
import '../../../../support/fake_organization_repository.dart';
import '../../../../support/team_fixtures.dart';

Song song(String id, String title, {String? owner}) => Song(
  id: id,
  title: title,
  artist: 'Artist',
  key: 'G',
  tempo: 72,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  ownerId: owner,
);

RepertoireEntry entry(
  String version,
  String title, {
  String org = 'org-1',
  String? owner = 'Grace',
  bool deactivated = false,
}) => RepertoireEntry(
  organizationId: org,
  versionId: version,
  title: title,
  artist: 'Artist',
  label: 'Original',
  ownerId: 'u-$version',
  ownerDisplayName: owner,
  ownerDeactivated: deactivated,
);

void main() {
  late FakeOrganizationRepository orgs;
  late FakeOrganizationRepertoireRepository repertoire;
  late InMemorySetlistRepository setlists;

  setUp(() {
    orgs = FakeOrganizationRepository(
      organizations: [
        org('org-1', 'Grace Church'),
        org('org-2', 'Youth Band', role: OrganizationRole.member),
      ],
      members: [
        member('m1', 'u-me', 'Me', orgId: 'org-1', role: OrganizationRole.admin),
        member('m2', 'u-me', 'Me', orgId: 'org-2'),
      ],
    );
    repertoire = FakeOrganizationRepertoireRepository(
      entries: [
        entry('v1', 'Amazing Grace'),
        entry('v2', 'Way Maker', owner: 'Old Friend', deactivated: true),
        entry('w1', 'Goodness of God', org: 'org-2', owner: null),
      ],
      candidates: [
        const RepertoireCandidate(
          versionId: 'c1',
          title: 'Zion',
          artist: 'Hillsong',
          ownerId: 'u-other',
          ownerDisplayName: 'Someone',
          visibility: SongVisibility.public,
        ),
        const RepertoireCandidate(
          versionId: 'c2',
          title: 'Mine Shared',
          ownerId: 'u-me',
          visibility: SongVisibility.organizations,
          sharedOrganizationIds: ['org-1'],
        ),
        const RepertoireCandidate(
          versionId: 'c3',
          title: 'Shared Elsewhere',
          ownerId: 'u-other',
          visibility: SongVisibility.organizations,
          sharedOrganizationIds: ['org-9'],
        ),
      ],
    );
    setlists = InMemorySetlistRepository(
      initialSetlists: [
        Setlist(
          id: 'personal',
          title: 'My Personal Set',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        Setlist(
          id: 'org-set',
          title: 'Grace Sunday',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          organizationId: 'org-1',
        ),
        Setlist(
          id: 'youth-set',
          title: 'Youth Night',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          organizationId: 'org-2',
        ),
      ],
    );
  });

  Future<void> pump(
    WidgetTester tester, {
    FakeOrganizationRepository? repo,
    double width = 1024,
    bool signedIn = true,
  }) async {
    tester.view.physicalSize = Size(width, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final songs = InMemorySongRepository(
      initialSongs: [
        song('s-mine', 'My Own Song', owner: 'u-me'),
        song('s-local', 'Local Song'),
        song('s-foreign', 'Cached From Org', owner: 'u-x'),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (signedIn)
            ...signedInOverrides(
              repo ?? orgs,
              repertoire: repertoire,
              fixedSetlists: false,
            ),
          songRepositoryProvider.overrideWithValue(songs),
          setlistRepositoryProvider.overrideWithValue(setlists),
          cloudSyncServiceProvider.overrideWithValue(FakeCloudSyncService()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepertoirePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectOrg(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(ValueKey('scope_org_$id')));
    await tester.pumpAndSettle();
  }

  Future<void> openSetlists(WidgetTester tester) async {
    await tester.tap(find.textContaining('Setlists ('));
    await tester.pumpAndSettle();
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(RepertoirePage)));

  group('scope switcher', () {
    testWidgets('is hidden without organizations', (tester) async {
      await pump(tester, signedIn: false);
      expect(find.byKey(const ValueKey('scope_mine')), findsNothing);
    });

    testWidgets('my library holds what I own, not other users\' versions', (
      tester,
    ) async {
      await pump(tester);

      expect(find.byKey(const ValueKey('scope_mine')), findsOneWidget);
      expect(find.text('Grace Church repertoire'), findsOneWidget);
      expect(find.text('Youth Band repertoire'), findsOneWidget);
      expect(find.text('My Own Song'), findsOneWidget);
      expect(find.text('Local Song'), findsOneWidget);
      expect(find.text('Cached From Org'), findsNothing);
      // The library is mine to edit whatever my role is.
      expect(find.text('New Song'), findsOneWidget);
    });

    testWidgets('an organization shows its repertoire with owner labels', (
      tester,
    ) async {
      await pump(tester);
      await selectOrg(tester, 'org-1');

      expect(find.text('Amazing Grace'), findsOneWidget);
      expect(find.text('Way Maker'), findsOneWidget);
      expect(find.text('My Own Song'), findsNothing);
      expect(find.textContaining('Owned by Grace'), findsOneWidget);
      expect(
        find.textContaining('Owned by Old Friend (deactivated)'),
        findsOneWidget,
      );
      // The other organization's repertoire stays out.
      expect(find.text('Goodness of God'), findsNothing);
      expect(find.textContaining('Songs (2)'), findsOneWidget);
    });

    testWidgets('an organization I can no longer see falls back to my library', (
      tester,
    ) async {
      await pump(tester);
      await selectOrg(tester, 'org-1');
      expect(find.text('Amazing Grace'), findsOneWidget);

      orgs.setOrganizations([org('org-2', 'Youth Band', role: OrganizationRole.member)]);
      await tester.pumpAndSettle();

      expect(container(tester).read(scopeOrganizationProvider), isNull);
      expect(find.text('Amazing Grace'), findsNothing);
      expect(find.text('My Own Song'), findsOneWidget);
    });
  });

  group('versions not on this device yet', () {
    testWidgets('show a hint and do not open "Song not found"', (tester) async {
      await pump(tester);
      await selectOrg(tester, 'org-1');

      // v1 and v2 are in the repertoire but not in the local songs.
      expect(
        find.byKey(const ValueKey('entry_pending_v1')),
        findsOneWidget,
      );
      expect(find.text('Available after the next sync'), findsNWidgets(2));

      await tester.tap(find.text('Amazing Grace'));
      await tester.pumpAndSettle();
      expect(find.text('Song not found in repertoire'), findsNothing);
      expect(find.byType(RepertoirePage), findsOneWidget);
    });

    testWidgets('tapping one pulls it with a sync', (tester) async {
      await pump(tester);
      await selectOrg(tester, 'org-1');
      final sync = container(tester).read(cloudSyncServiceProvider);

      await tester.tap(find.text('Amazing Grace'));
      await tester.pumpAndSettle();

      expect((sync as FakeCloudSyncService).syncs, 1);
    });

    testWidgets('versions already local carry no hint', (tester) async {
      repertoire.setEntries([entry('s-foreign', 'Cached From Org')]);
      await pump(tester);
      await selectOrg(tester, 'org-1');

      expect(find.text('Cached From Org'), findsOneWidget);
      expect(find.byKey(const ValueKey('entry_pending_s-foreign')), findsNothing);
    });
  });

  group('curation', () {
    testWidgets('a member reads the repertoire without curation actions', (
      tester,
    ) async {
      await pump(tester);
      await selectOrg(tester, 'org-2');

      expect(find.text('Goodness of God'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
    });

    testWidgets('a member sees the guidance of an empty repertoire', (
      tester,
    ) async {
      repertoire.setEntries([]);
      await pump(tester);
      await selectOrg(tester, 'org-2');

      expect(find.text('No songs in this repertoire yet'), findsOneWidget);
      expect(
        find.text('Your admins have not added any songs yet.'),
        findsOneWidget,
      );
      expect(find.text('Add to repertoire'), findsNothing);
    });

    testWidgets('an admin removes a version after confirming', (tester) async {
      await pump(tester);
      await selectOrg(tester, 'org-1');

      await tester.tap(find.byKey(const ValueKey('remove_entry_v1')));
      await tester.pumpAndSettle();
      expect(find.text('Remove from repertoire?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm_remove_from_repertoire')));
      await tester.pumpAndSettle();

      expect(repertoire.calls, contains('remove:org-1:v1'));
      expect(find.text('Amazing Grace'), findsNothing);
      expect(find.text('Way Maker'), findsOneWidget);
    });

    testWidgets('cancelling the confirmation removes nothing', (tester) async {
      await pump(tester);
      await selectOrg(tester, 'org-1');

      await tester.tap(find.byKey(const ValueKey('remove_entry_v1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repertoire.calls.where((c) => c.startsWith('remove')), isEmpty);
      expect(find.text('Amazing Grace'), findsOneWidget);
    });

    testWidgets('a refused removal says why', (tester) async {
      await pump(tester);
      await selectOrg(tester, 'org-1');
      repertoire.nextFailure = BackendErrorCode.notAdmin.failure();

      await tester.tap(find.byKey(const ValueKey('remove_entry_v1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm_remove_from_repertoire')));
      await tester.pumpAndSettle();

      expect(find.textContaining('admin'), findsWidgets);
      expect(find.text('Amazing Grace'), findsOneWidget);
    });

    testWidgets('an admin adds a version visible to the organization', (
      tester,
    ) async {
      await pump(tester);
      await selectOrg(tester, 'org-1');

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('candidate_c1')), findsOneWidget);
      expect(find.byKey(const ValueKey('candidate_c2')), findsOneWidget);
      // Shared only with another organization: not offered.
      expect(find.byKey(const ValueKey('candidate_c3')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('add_candidate_c1')));
      await tester.pumpAndSettle();

      expect(repertoire.calls, contains('add:org-1:c1'));
      expect(find.text('Added'), findsOneWidget);
      // The added version is pulled so that it can be opened.
      expect(
        (container(tester).read(cloudSyncServiceProvider)
                as FakeCloudSyncService)
            .syncs,
        1,
      );
    });

    testWidgets('the picker searches by title', (tester) async {
      await pump(tester);
      await selectOrg(tester, 'org-1');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('picker_search_field')),
        'zion',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(repertoire.calls, contains('search:org-1:zion'));
      expect(find.byKey(const ValueKey('candidate_c1')), findsOneWidget);
      expect(find.byKey(const ValueKey('candidate_c2')), findsNothing);
    });

    testWidgets('offline, the picker says so and can retry', (tester) async {
      await pump(tester);
      await selectOrg(tester, 'org-1');
      repertoire.nextFailure = BackendErrorCode.offline.failure();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('picker_error')), findsOneWidget);
      expect(find.textContaining('offline'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('candidate_c1')), findsOneWidget);
    });

    testWidgets('a version that is no longer visible is refused', (
      tester,
    ) async {
      await pump(tester);
      await selectOrg(tester, 'org-1');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      repertoire.nextFailure = BackendErrorCode.permissionDenied.failure();
      await tester.tap(find.byKey(const ValueKey('add_candidate_c1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('picker_add_error')), findsOneWidget);
      expect(find.textContaining('no longer available'), findsOneWidget);
      expect(find.text('Added'), findsNothing);
    });

    testWidgets('curation appears and disappears when my role changes', (
      tester,
    ) async {
      await pump(tester);
      await selectOrg(tester, 'org-1');
      expect(find.byType(FloatingActionButton), findsOneWidget);

      orgs.setOrganizations([
        org('org-1', 'Grace Church', role: OrganizationRole.member),
        org('org-2', 'Youth Band', role: OrganizationRole.member),
      ]);
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);

      orgs.setOrganizations([
        org('org-1', 'Grace Church'),
        org('org-2', 'Youth Band', role: OrganizationRole.member),
      ]);
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('search looks inside the shown repertoire', (tester) async {
      await pump(tester);
      await selectOrg(tester, 'org-1');

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'maker');
      await tester.pumpAndSettle();

      expect(find.text('Way Maker'), findsOneWidget);
      expect(find.text('Amazing Grace'), findsNothing);
    });
  });

  group('organization setlists', () {
    testWidgets('each scope lists its own setlists', (tester) async {
      await pump(tester);
      await openSetlists(tester);
      expect(find.text('My Personal Set'), findsOneWidget);
      expect(find.text('Grace Sunday'), findsNothing);

      await selectOrg(tester, 'org-1');
      expect(find.text('Grace Sunday'), findsOneWidget);
      expect(find.text('My Personal Set'), findsNothing);
      expect(find.text('Youth Night'), findsNothing);
    });

    testWidgets('an admin creates a setlist that belongs to the organization', (
      tester,
    ) async {
      await pump(tester);
      await selectOrg(tester, 'org-1');
      await openSetlists(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Easter');
      await tester.tap(find.text('Create Setlist'));
      await tester.pumpAndSettle();

      final saved = (await setlists.getAllSetlists()).getOrElse((_) => []);
      expect(saved.firstWhere((s) => s.title == 'Easter').organizationId, 'org-1');
      expect(find.text('Easter'), findsOneWidget);
    });

    testWidgets('an admin deletes an organization setlist', (tester) async {
      await pump(tester);
      await selectOrg(tester, 'org-1');
      await openSetlists(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(find.text('Grace Sunday'), findsNothing);
      expect(
        (await setlists.getAllSetlists())
            .getOrElse((_) => [])
            .any((s) => s.id == 'org-set'),
        isFalse,
      );
    });

    testWidgets('a member reads them without create or delete', (tester) async {
      await pump(tester);
      await selectOrg(tester, 'org-2');
      await openSetlists(tester);

      expect(find.text('Youth Night'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('a personal setlist is created without an organization', (
      tester,
    ) async {
      await pump(tester);
      await openSetlists(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Rehearsal');
      await tester.tap(find.text('Create Setlist'));
      await tester.pumpAndSettle();

      final saved = (await setlists.getAllSetlists()).getOrElse((_) => []);
      expect(saved.firstWhere((s) => s.title == 'Rehearsal').organizationId, isNull);
    });
  });

  group('layout', () {
    for (final width in [320.0, 375.0, 768.0, 1024.0, 1440.0]) {
      testWidgets('has no overflow at ${width.toInt()} px', (tester) async {
        orgs = FakeOrganizationRepository(
          organizations: [
            org('org-1', 'An organization with a really very long name indeed'),
            org('org-2', 'Another long organization name for wrapping'),
            org('org-3', 'Third', role: OrganizationRole.member),
          ],
        );
        repertoire.setEntries([
          for (var i = 0; i < 6; i++)
            entry(
              'v$i',
              'A very long song title that has to be ellipsized number $i',
              owner: 'An owner with a very long display name number $i',
              deactivated: i.isEven,
            ),
        ]);
        await pump(tester, width: width);
        expect(tester.takeException(), isNull);

        await selectOrg(tester, 'org-1');
        expect(tester.takeException(), isNull);

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('picker_search_field')), findsOneWidget);
      });
    }
  });
}
