import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/organizations/presentation/pages/organization_profile_page.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/profile/presentation/pages/profile_page.dart';
import 'package:battuta/features/profile/presentation/providers/photo_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_scope_providers.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import 'fake_auth_repository.dart';
import 'fake_organization_repertoire_repository.dart';
import 'fake_organization_repository.dart';
import 'fake_schedule_repository.dart';
import 'memory_storage.dart';

/// The Profile page (and the pages it opens) on fakes: the initial route is a stand-in for
/// a tab, `/profile` the real page. The signed-in user comes from [auth].
Widget profileApp({
  required FakeAuthRepository auth,
  required FakeOrganizationRepository organizations,
  String initialLocation = AppRoutes.profile,
  Widget tab = const Text('tab page'),
  FakeScheduleRepository? schedules,
  FakeOrganizationRepertoireRepository? repertoire,
  List<Override> overrides = const [],
}) => ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(auth),
    organizationRepositoryProvider.overrideWithValue(organizations),
    scheduleRepositoryProvider.overrideWithValue(
      schedules ?? FakeScheduleRepository(),
    ),
    organizationRepertoireRepositoryProvider.overrideWithValue(
      repertoire ?? FakeOrganizationRepertoireRepository(),
    ),
    myLibraryProvider.overrideWithValue(const AsyncData(<Song>[])),
    // No real server: photos never resolve to a URL unless a test says so.
    photoUrlBuilderProvider.overrideWithValue((_, _) => null),
    activeOrganizationStorageProvider.overrideWithValue(MemoryStorage()),
    ...overrides,
  ],
  child: MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.initial,
          builder: (_, _) => Scaffold(body: Center(child: tab)),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const ProfilePage(),
        ),
        GoRoute(
          path: AppRoutes.signIn,
          builder: (_, _) => const Text('sign in page'),
        ),
        GoRoute(
          path: AppRoutes.organizationPath,
          builder: (_, state) => OrganizationProfilePage(
            organizationId: state.pathParameters['organizationId']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.team,
          builder: (_, _) => const Text('team page'),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, _) => const Text('app settings page'),
        ),
        GoRoute(
          path: AppRoutes.organizationSettingsPath,
          builder: (_, state) =>
              Text('settings of ${state.pathParameters['organizationId']}'),
        ),
      ],
    ),
  ),
);
