/// Shell scaffold with bottom navigation for Battuta's main tabs.
///
/// Wraps the routed child in a [Scaffold] with a [NavigationBar]
/// providing three primary destinations: Repertoire, Live, and Settings.
library;

import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A shell widget that provides persistent bottom navigation across
/// the app's top-level destinations.
class ScaffoldWithNavBar extends StatelessWidget {
  /// Creates a [ScaffoldWithNavBar] wrapping the given [child].
  const ScaffoldWithNavBar({required this.child, super.key});

  /// The routed page content displayed above the navigation bar.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.library_music_outlined),
            selectedIcon: const Icon(Icons.library_music),
            label: l10n?.navRepertoire ?? 'Repertoire',
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups),
            label: l10n?.navTeam ?? 'Team',
          ),
          NavigationDestination(
            icon: const Icon(Icons.cell_tower_outlined),
            selectedIcon: const Icon(Icons.cell_tower),
            label: l10n?.navLive ?? 'Live',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n?.navSettings ?? 'Settings',
          ),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.team)) return 1;
    if (location.startsWith(AppRoutes.live)) return 2;
    if (location.startsWith(AppRoutes.settings)) return 3;
    return 0; // Repertoire is default
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.repertoire);
      case 1:
        context.go(AppRoutes.team);
      case 2:
        context.go(AppRoutes.live);
      case 3:
        context.go(AppRoutes.settings);
    }
  }
}
