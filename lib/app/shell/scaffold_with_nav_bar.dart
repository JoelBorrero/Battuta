/// Shell scaffold with bottom navigation for Battuta's main tabs.
///
/// Wraps the routed child in a [Scaffold] with a [NavigationBar]
/// providing three primary destinations: Repertoire, Live, and Settings.
library;

import 'package:battuta/app/routes/app_routes.dart';
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
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Repertoire',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Team',
          ),
          NavigationDestination(
            icon: Icon(Icons.cell_tower_outlined),
            selectedIcon: Icon(Icons.cell_tower),
            label: 'Live',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.scanner)) return 1;
    if (location.startsWith(AppRoutes.team)) return 2;
    if (location.startsWith(AppRoutes.live)) return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
    return 0; // Repertoire is default
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.repertoire);
      case 1:
        context.go(AppRoutes.scanner);
      case 2:
        context.go(AppRoutes.team);
      case 3:
        context.go(AppRoutes.live);
      case 4:
        context.go(AppRoutes.settings);
    }
  }
}

