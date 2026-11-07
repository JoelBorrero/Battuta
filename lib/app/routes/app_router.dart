/// GoRouter configuration for the Battuta app.
///
/// Defines the full navigation graph including a [ShellRoute] for the
/// bottom-navigation scaffold and nested song / live-session routes.
/// Exposed as a Riverpod provider via `@riverpod`.
library;

import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/app/shell/scaffold_with_nav_bar.dart';
import 'package:battuta/features/live_session/presentation/pages/live_session_page.dart';
import 'package:battuta/features/repertoire/presentation/pages/repertoire_page.dart';
import 'package:battuta/features/repertoire/presentation/pages/setlist_detail_page.dart';
import 'package:battuta/features/repertoire/presentation/pages/song_detail_page.dart';
import 'package:battuta/features/repertoire/presentation/pages/song_editor_page.dart';
import 'package:battuta/features/scanner/presentation/pages/scanner_page.dart';
import 'package:battuta/features/score/presentation/pages/score_editor_page.dart';
import 'package:battuta/features/settings/presentation/pages/settings_page.dart';
import 'package:battuta/features/team/presentation/pages/team_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

// ── Router provider ─────────────────────────────────────────────────────────

/// Provides the singleton [GoRouter] instance to the widget tree.
///
/// Inject via `ref.watch(appRouterProvider)` in your top-level
/// [MaterialApp.router].
@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.initial,
    debugLogDiagnostics: false,
    routes: [
      // ── Shell for bottom navigation ────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          // Tab 1 — Repertoire
          GoRoute(
            path: AppRoutes.repertoire,
            name: 'repertoire',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RepertoirePage()),
            routes: [
              // New song creation
              GoRoute(
                path: 'new',
                name: 'newSong',
                builder: (context, state) => const SongEditorPage(),
              ),
              // Setlist detail & song editor
              GoRoute(
                path: 'setlists/:setlistId',
                name: 'setlistDetail',
                builder: (context, state) {
                  final setlistId = state.pathParameters['setlistId']!;
                  return SetlistDetailPage(setlistId: setlistId);
                },
              ),
              // Song detail
              GoRoute(
                path: ':songId',
                name: 'songDetail',
                builder: (context, state) {
                  final songId = state.pathParameters['songId']!;
                  return SongDetailPage(songId: songId);
                },
                routes: [
                  // Song editor
                  GoRoute(
                    path: 'edit',
                    name: 'songEditor',
                    builder: (context, state) {
                      final songId = state.pathParameters['songId']!;
                      return SongEditorPage(songId: songId);
                    },
                  ),
                  // Score / Staff notation editor
                  GoRoute(
                    path: 'notation',
                    name: 'scoreNotation',
                    builder: (context, state) {
                      final songId = state.pathParameters['songId']!;
                      return ScoreEditorPage(songId: songId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Tab 2 — Scanner
          GoRoute(
            path: AppRoutes.scanner,
            name: 'scanner',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ScannerPage()),
          ),

          // Tab 3 — Team
          GoRoute(
            path: AppRoutes.team,
            name: 'team',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TeamPage()),
          ),

          // Tab 4 — Live session
          GoRoute(
            path: AppRoutes.live,
            name: 'live',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LiveSessionPage()),
            routes: [
              GoRoute(
                path: ':sessionId',
                name: 'liveSession',
                builder: (context, state) => const LiveSessionPage(),
              ),
            ],
          ),

          // Tab 5 — Settings
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),
    ],
  );
}
