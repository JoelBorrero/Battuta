/// GoRouter configuration for the Battuta app.
///
/// Defines the full navigation graph including a [ShellRoute] for the
/// bottom-navigation scaffold and nested song / live-session routes.
/// Exposed as a Riverpod provider via `@riverpod`.
library;

import 'package:battuta/app/design_system/motion/page_transitions.dart';
import 'package:battuta/app/routes/app_redirect.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/app/shell/scaffold_with_nav_bar.dart';
import 'package:battuta/features/auth/presentation/pages/create_account_page.dart';
import 'package:battuta/features/auth/presentation/pages/sign_in_page.dart';
import 'package:battuta/features/auth/presentation/pages/welcome_page.dart';
import 'package:battuta/features/auth/presentation/providers/account_notice_provider.dart';
import 'package:battuta/features/auth/presentation/providers/app_entry_provider.dart';
import 'package:battuta/features/live_session/presentation/pages/live_session_page.dart';
import 'package:battuta/features/organizations/domain/services/invite_link_parser.dart';
import 'package:battuta/features/organizations/presentation/pages/inbox_page.dart';
import 'package:battuta/features/organizations/presentation/pages/join_page.dart';
import 'package:battuta/features/organizations/presentation/providers/pending_invite_provider.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
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
  // Re-evaluates the redirect whenever the entry state or notice changes.
  final refresh = ValueNotifier<int>(0);
  ref
    ..onDispose(refresh.dispose)
    ..listen(appEntryProvider, (_, _) => refresh.value++)
    ..listen(accountNoticeProvider, (_, _) => refresh.value++)
    ..listen(pendingInviteTokenProvider, (_, _) => refresh.value++);

  // The entry seen by the previous redirect. When a session ends while the
  // join page is open, the redirect re-runs on that same `/join/<token>`
  // location: the token belonged to the account that just left and must not
  // be kept for whoever signs in next.
  AppEntry? previousEntry;

  return GoRouter(
    initialLocation: AppRoutes.initial,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (context, state) {
      // A `battuta://join/<token>` link arrives with the token as its path.
      final linkToken = inviteTokenFromUri(state.uri);
      final location = linkToken != null
          ? AppRoutes.join(linkToken)
          : state.uri.path;
      final entry = ref.read(appEntryProvider);
      final sessionJustEnded =
          previousEntry == AppEntry.signedIn && entry != AppEntry.signedIn;
      previousEntry = entry;
      final joinToken = AppRoutes.joinTokenOf(location);
      // Signed out: keep the token until an account exists.
      if (joinToken != null &&
          entry != null &&
          entry != AppEntry.signedIn &&
          !sessionJustEnded) {
        Future(
          () => ref.read(pendingInviteTokenProvider.notifier).set(joinToken),
        );
      }
      final target = resolveAppRedirect(
        entry: entry,
        hasNotice: ref.read(accountNoticeProvider) != null,
        location: location,
        pendingInviteToken: ref.read(pendingInviteTokenProvider),
      );
      return target ?? (location != state.uri.path ? location : null);
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        name: 'signIn',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: AppRoutes.createAccount,
        name: 'createAccount',
        builder: (context, state) => const CreateAccountPage(),
      ),

      GoRoute(
        path: AppRoutes.joinPath,
        name: 'join',
        builder: (context, state) =>
            JoinPage(token: state.pathParameters['token']!),
      ),
      GoRoute(
        path: AppRoutes.inbox,
        name: 'inbox',
        builder: (context, state) => const InboxPage(),
      ),

      // ── Shell for bottom navigation ────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          // Tab 1 — Repertoire
          GoRoute(
            path: AppRoutes.repertoire,
            name: 'repertoire',
            pageBuilder: (context, state) => battutaTabPage(
              key: state.pageKey,
              child: const RepertoirePage(),
            ),
            routes: [
              // New song creation
              GoRoute(
                path: 'new',
                name: 'newSong',
                builder: (context, state) => SongEditorPage(
                  initialSong: state.extra is Song ? state.extra as Song : null,
                ),
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

          // Tab 2 — Team
          GoRoute(
            path: AppRoutes.team,
            name: 'team',
            pageBuilder: (context, state) =>
                battutaTabPage(key: state.pageKey, child: const TeamPage()),
          ),

          // Tab 3 — Live session
          GoRoute(
            path: AppRoutes.live,
            name: 'live',
            pageBuilder: (context, state) => battutaTabPage(
              key: state.pageKey,
              child: const LiveSessionPage(),
            ),
            routes: [
              GoRoute(
                path: ':sessionId',
                name: 'liveSession',
                builder: (context, state) => const LiveSessionPage(),
              ),
            ],
          ),

          // Tab 4 — Settings
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) =>
                battutaTabPage(key: state.pageKey, child: const SettingsPage()),
          ),
        ],
      ),

      // Standalone Scanner Route (Accessible directly or via deep link)
      GoRoute(
        path: AppRoutes.scanner,
        name: 'scanner',
        builder: (context, state) => const ScannerPage(),
      ),
    ],
  );
}
