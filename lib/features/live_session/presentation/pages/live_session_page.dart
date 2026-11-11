/// Battuta — Live Stage Session & Real-Time Sync Page.
///
/// Provides stage synchronization controls for directors and band members:
/// - Director Mode: Local LAN WebSocket host, LeaderLock section broadcasting, and cue lookahead.
/// - Follower Mode: Real-time section following, upcoming cue banner, and request queuing.
/// - Integrated [StageCueBanner] and [DirectorControlBar].
library;

import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/features/organizations/presentation/widgets/inbox_button.dart';
import 'package:battuta/features/sync/domain/services/live_sync_service.dart';
import 'package:battuta/features/sync/presentation/providers/live_sync_provider.dart';
import 'package:battuta/features/sync/presentation/widgets/stage_cue_banner.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LiveSessionPage extends ConsumerStatefulWidget {
  const LiveSessionPage({super.key});

  @override
  ConsumerState<LiveSessionPage> createState() => _LiveSessionPageState();
}

class _LiveSessionPageState extends ConsumerState<LiveSessionPage> {
  final _hostController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '8080');
  static const int _currentMeasure = 14;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _triggerSampleCue() {
    final notifier = ref.read(liveSyncControllerProvider.notifier);
    notifier.emitLookaheadCue(
      songId: 'way-maker',
      currentSectionId: 'verso-1',
      nextSectionLabel: 'NEXT: CORO GLORIOSO',
      currentMeasureIndex: _currentMeasure,
      lookaheadMeasures: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final syncState = ref.watch(liveSyncControllerProvider);
    final syncNotifier = ref.read(liveSyncControllerProvider.notifier);

    const activeSections = [
      'Intro',
      'Verso 1',
      'Coro',
      'Verso 2',
      'Puente',
      'Final',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.liveStageSync ?? 'Live Stage Sync'),
        actions: [
          const InboxButton(),
          // Connection Status Pill
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: syncState.isConnected
                  ? AppTheme.stageGreen.withValues(alpha: 0.2)
                  : (isDark
                        ? AppTheme.slateSurfaceLight
                        : AppTheme.pearlSurfaceLight),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: syncState.isConnected
                    ? AppTheme.stageGreen
                    : (isDark ? AppTheme.slateBorder : AppTheme.pearlBorder),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: syncState.isConnected
                        ? AppTheme.stageGreen
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  syncState.isConnected
                      ? (syncState.isDirector
                          ? (l10n?.hostingStatus ?? 'HOSTING')
                          : (l10n?.syncedStatus ?? 'SYNCED'))
                      : (l10n?.standaloneStatus ?? 'STANDALONE'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: syncState.isConnected
                        ? AppTheme.stageGreen
                        : (isDark
                              ? AppTheme.textMuted
                              : AppTheme.charcoalMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Mode Switcher (Director vs Follower) ──
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.slateSurface
                          : AppTheme.pearlSurfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.slateBorder
                            : AppTheme.pearlBorder,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                syncNotifier.setSyncMode(LiveSyncMode.director),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: syncState.isDirector
                                    ? AppTheme.amberAccent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cell_tower,
                                    size: 18,
                                    color: syncState.isDirector
                                        ? AppTheme.obsidianText
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n?.directorHost ?? 'Director (Host)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: syncState.isDirector
                                          ? AppTheme.obsidianText
                                          : (isDark
                                                ? AppTheme.textOffWhite
                                                : AppTheme.charcoalText),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                syncNotifier.setSyncMode(LiveSyncMode.follower),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !syncState.isDirector
                                    ? AppTheme.amberAccent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.group,
                                    size: 18,
                                    color: !syncState.isDirector
                                        ? AppTheme.obsidianText
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n?.musicianFollower ?? 'Musician (Follower)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: !syncState.isDirector
                                          ? AppTheme.obsidianText
                                          : (isDark
                                                ? AppTheme.textOffWhite
                                                : AppTheme.charcoalText),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Live Stage Cue Banner (If Active Cue Present) ──
                  if (syncState.activeCue != null) ...[
                    StageCueBanner(
                      cue: syncState.activeCue!,
                      currentMeasure: _currentMeasure,
                      onDismiss: syncNotifier.dismissCue,
                      onJumpNow: () {
                        final label = syncState.activeCue!.nextSectionLabel;
                        syncNotifier.jumpNowSection(label);
                        syncNotifier.dismissCue();
                      },
                      isDirector: syncState.isDirector,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Current Live Stage Section Prompter ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.slateSurface
                          : AppTheme.pureWhiteSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.slateBorder
                            : AppTheme.pearlBorder,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.onStageNow ?? 'ON STAGE NOW',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.textMuted
                                : AppTheme.charcoalMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: AppTheme.amberAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                syncState.activeSectionId ??
                                    (l10n?.introPreRoll ?? 'INTRO / PRE-ROLL'),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: AppTheme.amberAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              l10n?.queuedNext ?? 'Queued Next:',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.textMuted
                                    : AppTheme.charcoalMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.amberMuted,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                syncState.queuedSectionLabel ??
                                    (l10n?.waitingForCue ??
                                        'None (Waiting for cue)'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.amberAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Network Setup & Connection Card ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.slateSurface
                          : AppTheme.pureWhiteSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.slateBorder
                            : AppTheme.pearlBorder,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          syncState.isDirector
                              ? (l10n?.localLanDirectorServer ??
                                  'LOCAL LAN DIRECTOR SERVER')
                              : (l10n?.connectToDirectorDevice ??
                                  'CONNECT TO DIRECTOR DEVICE'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: isDark
                                ? AppTheme.textMuted
                                : AppTheme.charcoalMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (syncState.isDirector) ...[
                          Text(
                            syncState.isConnected
                                ? (l10n?.serverRunningOnPort(
                                        syncState.serverPort ?? 0) ??
                                    'Server running on ephemeral port ${syncState.serverPort}. Band member tablets can connect on this local Wi-Fi.')
                                : (l10n?.startZeroConfigServer ??
                                    'Start a zero-configuration local WebSocket server so all band members follow your live cues.'),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: syncState.isConnected
                                      ? AppTheme.stageRed
                                      : AppTheme.amberAccent,
                                  foregroundColor: syncState.isConnected
                                      ? Colors.white
                                      : AppTheme.obsidianText,
                                  minimumSize: const Size(44, 44),
                                ),
                                icon: Icon(
                                  syncState.isConnected
                                      ? Icons.stop
                                      : Icons.play_arrow,
                                ),
                                label: Text(
                                  syncState.isConnected
                                      ? (l10n?.stopHostServer ??
                                          'Stop Host Server')
                                      : (l10n?.startLanHost ??
                                          'Start LAN Host'),
                                ),
                                onPressed: () async {
                                  if (syncState.isConnected) {
                                    await syncNotifier.disconnect();
                                  } else {
                                    await syncNotifier.startDirectorServer(
                                      port: 0,
                                    );
                                  }
                                },
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(44, 44),
                                ),
                                icon: const Icon(
                                  Icons.notifications_active_outlined,
                                ),
                                label: Text(l10n?.triggerTestCue ?? 'Trigger Test Cue'),
                                onPressed: _triggerSampleCue,
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _hostController,
                                  decoration: InputDecoration(
                                    labelText: l10n?.directorHostIp ??
                                        'Director Host IP',
                                    hintText: '192.168.1.X',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _portController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: l10n?.portLabel ?? 'Port',
                                    hintText: '8080',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: syncState.isConnected
                                  ? AppTheme.stageRed
                                  : AppTheme.amberAccent,
                              foregroundColor: syncState.isConnected
                                  ? Colors.white
                                  : AppTheme.obsidianText,
                              minimumSize: const Size(44, 44),
                            ),
                            icon: Icon(
                              syncState.isConnected
                                  ? Icons.link_off
                                  : Icons.link,
                            ),
                            label: Text(
                              syncState.isConnected
                                  ? (l10n?.disconnect ?? 'Disconnect')
                                  : (l10n?.connectAsFollower ??
                                      'Connect as Follower'),
                            ),
                            onPressed: () async {
                              if (syncState.isConnected) {
                                await syncNotifier.disconnect();
                              } else {
                                final host = _hostController.text.trim();
                                final port =
                                    int.tryParse(_portController.text.trim()) ??
                                    8080;
                                try {
                                  await syncNotifier.connect(host, port);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n?.connectionFailed(
                                                  e.toString()) ??
                                              'Connection failed: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Pending Follower Override Requests (LeaderLock) ──
                  if (syncState.isDirector &&
                      syncState.pendingRequests.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.slateSurface
                            : AppTheme.pureWhiteSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.amberAccent,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.shield,
                                color: AppTheme.amberAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n?.leaderLockRequestsTitle ??
                                    'LeaderLock: Musician Transition Requests',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (final req in syncState.pendingRequests)
                            ListTile(
                              dense: true,
                              title: Text(
                                l10n?.requestPrefix(req.currentSectionId) ??
                                    'Request: ${req.currentSectionId}',
                              ),
                              subtitle: Text(
                                l10n?.followerRequestedChange ??
                                    'Follower requested section change',
                              ),
                              trailing: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.amberAccent,
                                  foregroundColor: AppTheme.obsidianText,
                                ),
                                onPressed: () {
                                  syncNotifier.jumpNowSection(
                                    req.currentSectionId,
                                  );
                                },
                                child: Text(l10n?.approveJump ?? 'Approve Jump'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Pinned Stage Director Control Bar ──
          DirectorControlBar(
            sections: activeSections,
            activeSectionId: syncState.activeSectionId,
            onQueueSection: (section) {
              syncNotifier.queueNextSection(section);
            },
            onJumpSection: (section) {
              syncNotifier.jumpNowSection(section);
            },
            onClearQueue: () {
              syncNotifier.queueNextSection('');
            },
          ),
        ],
      ),
    );
  }
}
