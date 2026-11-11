import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/features/sharing/presentation/widgets/sharing_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/team_fixtures.dart';
import 'sharing_harness.dart';

class _Opener extends ConsumerWidget {
  const _Opener(this.songId);

  final String songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: ElevatedButton(
        key: const ValueKey('open_sheet'),
        onPressed: () => showSharingSheet(context, ref, songId),
        child: const Text('open'),
      ),
    ),
  );
}

void main() {
  Future<SharingHarness> open(
    WidgetTester tester, {
    List<Organization>? organizations,
    double width = 1024,
    bool owned = true,
  }) async {
    final h = SharingHarness(
      songs: [versionOf('v1', owner: owned ? 'u-me' : 'u-x')],
      organizations:
          organizations ??
          [
            org('org-1', 'Grace Church'),
            org('org-2', 'Youth Band', role: OrganizationRole.member),
            org('org-old', 'Archived', archivedAt: DateTime(2026)),
          ],
    );
    await h.pump(tester, const _Opener('v1'), width: width);
    await tester.tap(find.byKey(const ValueKey('open_sheet')));
    await tester.pumpAndSettle();
    return h;
  }

  testWidgets('shows the name, the three options and the offline note', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Sharing'), findsOneWidget);
    expect(find.text('Only me'), findsOneWidget);
    expect(find.text('My organizations'), findsOneWidget);
    expect(find.text('Public'), findsOneWidget);
    expect(find.byKey(const ValueKey('sharing_sync_note')), findsOneWidget);
    // Private is selected: no organizations to pick yet.
    expect(find.byKey(const ValueKey('sharing_org_org-1')), findsNothing);
  });

  testWidgets('only my active organizations are offered', (tester) async {
    await open(tester);
    await tester.tap(
      find.byKey(const ValueKey('sharing_option_organizations')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('sharing_org_org-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('sharing_org_org-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('sharing_org_org-old')), findsNothing);
  });

  testWidgets('organizations need at least one pick before saving', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(
      find.byKey(const ValueKey('sharing_option_organizations')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('sharing_pick_one')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('sharing_save_btn')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('saves the shares, marks the version for sync and syncs', (
    tester,
  ) async {
    final h = await open(tester);
    await tester.enterText(
      find.byKey(const ValueKey('sharing_label_field')),
      'Acoustic',
    );
    await tester.tap(
      find.byKey(const ValueKey('sharing_option_organizations')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sharing_org_org-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sharing_save_btn')));
    await tester.pumpAndSettle();

    final song = (await h.songs.getSongById('v1')).getOrElse((_) => throw 'x');
    expect(song.label, 'Acoustic');
    expect(song.visibility, SongVisibility.organizations);
    expect(song.sharedOrganizationIds, ['org-1']);
    expect(h.cloudSync.syncs, 1);
    expect(find.text('Sharing updated'), findsOneWidget);
    // The sheet closed.
    expect(find.byKey(const ValueKey('sharing_save_btn')), findsNothing);
  });

  testWidgets('an organization I left is dropped from the shares', (
    tester,
  ) async {
    final h = SharingHarness(
      songs: [
        versionOf(
          'v1',
          visibility: SongVisibility.organizations,
          shared: const ['org-left', 'org-1'],
        ),
      ],
      organizations: [org('org-1', 'Grace Church')],
    );
    await h.pump(tester, const _Opener('v1'));
    await tester.tap(find.byKey(const ValueKey('open_sheet')));
    await tester.pumpAndSettle();

    // Only the organization I still belong to is listed, and checked.
    expect(find.byKey(const ValueKey('sharing_org_org-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('sharing_org_org-left')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('sharing_save_btn')));
    await tester.pumpAndSettle();

    final song = (await h.songs.getSongById('v1')).getOrElse((_) => throw 'x');
    expect(song.sharedOrganizationIds, ['org-1']);
  });

  testWidgets('going public needs no organization', (tester) async {
    final h = await open(tester, organizations: const []);
    await tester.tap(
      find.byKey(const ValueKey('sharing_option_organizations')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sharing_no_orgs')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sharing_option_public')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sharing_save_btn')));
    await tester.pumpAndSettle();

    final song = (await h.songs.getSongById('v1')).getOrElse((_) => throw 'x');
    expect(song.visibility, SongVisibility.public);
    expect(song.sharedOrganizationIds, isEmpty);
  });

  for (final width in [320.0, 375.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${width.toInt()} px', (tester) async {
      await open(tester, width: width);
      await tester.tap(
        find.byKey(const ValueKey('sharing_option_organizations')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
