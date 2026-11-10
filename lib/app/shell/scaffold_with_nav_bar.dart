/// Shell scaffold with bottom navigation for Battuta's main tabs.
///
/// Wraps the routed child in a [Scaffold] with Battuta's adaptive stage
/// navigation: a bottom [StageNavigationBar] on compact widths and a side
/// [StageNavigationRail] (with the brand mark) on wide iPad / macOS windows.
/// Destinations: Repertoire, Team, Live, and Settings.
library;

import 'package:battuta/app/design_system/design_system.dart';
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
    final destinations = [
      StageDestination(
        icon: Icons.library_music_outlined,
        selectedIcon: Icons.library_music,
        label: l10n?.navRepertoire ?? 'Repertoire',
      ),
      StageDestination(
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups,
        label: l10n?.navTeam ?? 'Team',
      ),
      StageDestination(
        icon: Icons.cell_tower_outlined,
        selectedIcon: Icons.cell_tower,
        label: l10n?.navLive ?? 'Live',
      ),
      StageDestination(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n?.navSettings ?? 'Settings',
      ),
    ];
    final selectedIndex = _currentIndex(context);
    void onSelected(int index) => _onTap(context, index);

    final isWide = MediaQuery.sizeOf(context).width >= BattutaBreakpoints.rail;

    if (isWide) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StageNavigationRail(
              destinations: destinations,
              selectedIndex: selectedIndex,
              onSelected: onSelected,
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: StageNavigationBar(
        destinations: destinations,
        selectedIndex: selectedIndex,
        onSelected: onSelected,
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
