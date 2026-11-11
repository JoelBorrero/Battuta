import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/team/presentation/pages/team_page.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_organization_repository.dart';
import '../../../support/memory_storage.dart';
import '../../../support/team_fixtures.dart';

void main() {
  late MemoryStorage storage;

  setUp(() => storage = MemoryStorage());

  Future<void> pump(
    WidgetTester tester,
    FakeOrganizationRepository repository, {
    Size size = const Size(1024, 2048),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: signedInOverrides(repository, storage: storage),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TeamPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  FakeOrganizationRepository twoOrgs() => FakeOrganizationRepository(
    organizations: [
      org('org-1', 'Grace Church'),
      org('org-2', 'Youth Band', role: OrganizationRole.member),
      org('org-old', 'Archived Choir', archivedAt: DateTime(2026)),
    ],
    members: [
      member('m1', 'u-me', 'Me', orgId: 'org-1', role: OrganizationRole.admin),
      member('m2', 'u-me', 'Me', orgId: 'org-2'),
      member('m3', 'u-x', 'Xavi', orgId: 'org-2'),
    ],
    bands: const [Band(id: 'b1', organizationId: 'org-1', name: 'Alpha')],
  );

  testWidgets('lists my organizations with role badges, hiding archived ones', (
    tester,
  ) async {
    await pump(tester, twoOrgs());

    await tester.tap(find.byKey(const ValueKey('org_switcher_btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('org_item_org-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('org_item_org-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('org_item_org-old')), findsNothing);
    expect(find.text('Archived Choir'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('org_item_org-1')),
        matching: find.text('Admin'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('org_item_org-2')),
        matching: find.text('Member'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('switching organization changes the roster and is remembered', (
    tester,
  ) async {
    await pump(tester, twoOrgs());
    expect(find.text('Grace Church'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('org_switcher_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('org_item_org-2')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // dismiss the sheet
    await tester.pumpAndSettle();

    expect(find.text('Youth Band'), findsOneWidget);
    expect(find.text('Xavi'), findsOneWidget);
    expect(storage.values[activeOrganizationStorageKey('u-me')], 'org-2');
  });

  testWidgets('starts in the remembered organization', (tester) async {
    storage.values[activeOrganizationStorageKey('u-me')] = 'org-2';
    await pump(tester, twoOrgs());

    expect(find.text('Youth Band'), findsOneWidget);
  });

  testWidgets('picking a band filters the roster; All bands clears it', (
    tester,
  ) async {
    await pump(tester, twoOrgs());

    await tester.tap(find.byKey(const ValueKey('org_switcher_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('switcher_band_b1')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('switcher_band_b1')))
          .selected,
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('switcher_all_bands')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('switcher_all_bands')))
          .selected,
      isTrue,
    );
  });

  testWidgets('creates an organization and switches to it', (tester) async {
    final repository = twoOrgs();
    await pump(tester, repository);

    await tester.tap(find.byKey(const ValueKey('org_switcher_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_org_btn')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('org_name_field')),
      'New Team',
    );
    await tester.tap(find.byKey(const ValueKey('org_create_confirm_btn')));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('createOrganization:New Team'));
    expect(find.text('New Team'), findsOneWidget);
  });

  testWidgets(
    'a failed creation shows the localized error and keeps the dialog',
    (tester) async {
      final repository = twoOrgs();
      await pump(tester, repository);

      await tester.tap(find.byKey(const ValueKey('org_switcher_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create_org_btn')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('org_name_field')),
        'New Team',
      );
      repository.nextFailure = backendFailure(BackendErrorCode.offline);
      await tester.tap(find.byKey(const ValueKey('org_create_confirm_btn')));
      await tester.pumpAndSettle();

      expect(
        find.text("You're offline. Connect to the internet and try again."),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('org_name_field')), findsOneWidget);
    },
  );

  testWidgets('no organization yet: empty state creates the first one', (
    tester,
  ) async {
    final repository = FakeOrganizationRepository();
    await pump(tester, repository);

    expect(find.text('No organization yet'), findsOneWidget);
    expect(
      find.textContaining('Invitations to join one will arrive'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('empty_create_org_btn')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('org_name_field')),
      'First Team',
    );
    await tester.tap(find.byKey(const ValueKey('org_create_confirm_btn')));
    await tester.pumpAndSettle();

    expect(find.text('First Team'), findsWidgets);
    expect(find.text('No organization yet'), findsNothing);
  });

  testWidgets('long names and many organizations do not overflow', (
    tester,
  ) async {
    final repository = FakeOrganizationRepository(
      organizations: [
        for (var i = 0; i < 12; i++)
          org(
            'org-$i',
            'A very long organization name number $i that keeps going and going',
          ),
      ],
    );
    await pump(tester, repository, size: const Size(320, 640));

    await tester.tap(find.byKey(const ValueKey('org_switcher_btn')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
