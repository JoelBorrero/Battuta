import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_song_repository.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_organization_repertoire_repository.dart';
import '../../../support/fake_organization_repository.dart';
import '../../../support/fake_song_sharing.dart';
import '../../../support/team_fixtures.dart';

Song versionOf(
  String id, {
  String? owner = 'u-me',
  String title = 'Amazing Grace',
  String label = 'Original',
  String? workId = 'work-1',
  SongVisibility visibility = SongVisibility.private,
  List<String> shared = const [],
  String? creator,
  String? forkedFrom,
}) => Song(
  id: id,
  title: title,
  artist: 'John Newton',
  key: 'G',
  tempo: 72,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  songWorkId: workId,
  ownerId: owner,
  label: label,
  visibility: visibility,
  sharedOrganizationIds: shared,
  songCreatorId: creator,
  forkedFromVersionId: forkedFrom,
);

/// Everything a sharing widget test needs on fakes: signed in as `u-me`, the
/// songs in memory, the backend scripted, the router recording where it goes.
class SharingHarness {
  SharingHarness({
    List<Song> songs = const [],
    List<Organization>? organizations,
    FakeSongSharingRepository? sharing,
    this.signedIn = true,
  }) : songs = InMemorySongRepository(initialSongs: songs),
       sharing = sharing ?? FakeSongSharingRepository(),
       orgs = FakeOrganizationRepository(
         organizations: organizations ?? [org('org-1', 'Grace')],
         members: [member('m1', 'u-me', 'Me', orgId: 'org-1')],
       );

  final InMemorySongRepository songs;
  final FakeSongSharingRepository sharing;
  final FakeOrganizationRepository orgs;
  final bool signedIn;
  final cloudSync = FakeCloudSyncService();

  /// The stub screens the router showed, in order.
  final visited = <String>[];
  late final GoRouter router;

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    double width = 1024,
    double height = 2048,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    Widget stub(String label) {
      visited.add(label);
      return Scaffold(body: Text(label));
    }

    router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(
          path: '/repertoire/:songId',
          builder: (_, s) => stub('viewer:${s.pathParameters['songId']}'),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, s) => stub('editor:${s.pathParameters['songId']}'),
            ),
          ],
        ),
        GoRoute(
          path: '/songs/:id',
          builder: (_, s) => stub('song-page:${s.pathParameters['id']}'),
        ),
        GoRoute(path: '/sign-in', builder: (_, _) => stub('sign-in')),
        GoRoute(path: '/discover', builder: (_, _) => stub('discover')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (signedIn)
            ...signedInOverrides(
              orgs,
              repertoire: FakeOrganizationRepertoireRepository(),
            ),
          songRepositoryProvider.overrideWithValue(songs),
          songSharingRepositoryProvider.overrideWithValue(sharing),
          cloudSyncServiceProvider.overrideWithValue(cloudSync),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The last stub screen shown (`home` when none was).
  String get location => visited.isEmpty ? 'home' : visited.last;
}
