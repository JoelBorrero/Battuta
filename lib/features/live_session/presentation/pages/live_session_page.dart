/// Battuta — Live Stage Session & Real-Time Sync Page.
///
/// Provides stage synchronization controls for directors and band members:
/// - Director Mode: Local LAN WebSocket host, LeaderLock section broadcasting, and cue lookahead.
/// - Follower Mode: Real-time section following, upcoming cue banner, and request queuing.
/// - Integrated [StageCueBanner] and [DirectorControlBar].
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/core/platform/screen_wake_lock.dart';
import 'package:battuta/features/organizations/presentation/widgets/inbox_button.dart';
import 'package:battuta/features/profile/presentation/widgets/profile_avatar_button.dart';
import 'package:battuta/features/settings/presentation/providers/stage_preferences_provider.dart';
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
  /// End stops the band's session, so a stray tap mid-song must not do it.
  Future<void> _confirmEnd(
    BuildContext context,
    Future<void> Function() end,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.endSessionConfirmTitle ?? 'End the live session?'),
        content: Text(
          l10n?.endSessionConfirmBody ??
              'Everyone following this session will be disconnected.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('live_end_cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            key: const ValueKey('live_end_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.endSessionAction ?? 'End'),
          ),
        ],
      ),
    );
    if (confirmed == true) await end();
  }

  final _hostController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '8080');
  static const int _currentMeasure = 14;

  late final ScreenWakeLock _wakeLock;
  // Wake lock calls run one after the other so a late enable can never
  // outlive a later disable.
  Future<void> _wakeLockCalls = Future<void>.value();
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _wakeLock = ref.read(screenWakeLockProvider);
    _setWakeLock(ref.read(stagePreferencesProvider).keepScreenAwake);
  }

  void _setWakeLock(bool on) {
    _wakeLockCalls = _wakeLockCalls.then((_) async {
      try {
        // Disposed meanwhile: never take the lock, always release it.
        if (on && !_disposed) {
          await _wakeLock.enable();
        } else {
          await _wakeLock.disable();
        }
      } catch (_) {
        // A missing plugin must not break the Live page.
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _setWakeLock(false);
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
    ref.listen(
      stagePreferencesProvider.select((p) => p.keepScreenAwake),
      (_, on) => _setWakeLock(on),
    );
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
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

    final connectionLabel = syncState.isConnected
        ? (syncState.isDirector
              ? (l10n?.hostingStatus ?? 'HOSTING')
              : (l10n?.syncedStatus ?? 'SYNCED'))
        : (l10n?.standaloneStatus ?? 'STANDALONE');

    final stopStyle = FilledButton.styleFrom(
      backgroundColor: brand.wash(brand.danger),
      foregroundColor: brand.danger,
      minimumSize: const Size(44, 44),
      side: BorderSide(color: brand.danger.withValues(alpha: 0.6)),
    );
    final startStyle = FilledButton.styleFrom(
      backgroundColor: brand.accent,
      foregroundColor: brand.onAccent,
      minimumSize: const Size(44, 44),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.liveStageSync ?? 'Live Stage Sync'),
        actions: const [InboxButton(), ProfileAvatarButton()],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Session header: LIVE badge, connection, End ──
                  Row(
                    key: const ValueKey('live_session_header'),
                    children: [
                      StageStatusPill(
                        label: l10n?.liveBadge ?? 'LIVE',
                        active: syncState.isConnected,
                        tone: brand.accent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          connectionLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: syncState.isConnected
                                ? brand.success
                                : brand.inkMuted,
                          ),
                        ),
                      ),
                      if (syncState.isConnected) ...[
                        const SizedBox(width: 8),
                        BattutaPressable(
                          key: const ValueKey('live_end_button'),
                          onTap: () =>
                              _confirmEnd(context, syncNotifier.disconnect),
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 64,
                              minHeight: 44,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: brand.border),
                            ),
                            child: Text(
                              l10n?.endSessionAction ?? 'End',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: brand.ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Mode Switcher (Director vs Follower) ──
                  StageSegmentedControl<LiveSyncMode>(
                    selected: syncState.mode,
                    onChanged: syncNotifier.setSyncMode,
                    segments: [
                      StageSegment(
                        value: LiveSyncMode.director,
                        label: l10n?.directorHost ?? 'Director (Host)',
                        icon: Icons.cell_tower,
                      ),
                      StageSegment(
                        value: LiveSyncMode.follower,
                        label: l10n?.musicianFollower ?? 'Musician (Follower)',
                        icon: Icons.group,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Live Stage Cue Banner (If Active Cue Present) ──
                  if (syncState.activeCue != null) ...[
                    StageCueBanner(
                      key: ValueKey(syncState.activeCue!.sequenceNumber),
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
                  StageCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.onStageNow ?? 'ON STAGE NOW',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700,
                            color: brand.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: brand.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                syncState.activeSectionId ??
                                    (l10n?.introPreRoll ?? 'INTRO / PRE-ROLL'),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: brand.accentInk,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              l10n?.queuedNext ?? 'Queued Next:',
                              style: TextStyle(
                                fontSize: 13,
                                color: brand.inkMuted,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: brand.accentWash,
                                borderRadius: BorderRadius.circular(
                                  BattutaRadius.xs,
                                ),
                              ),
                              child: Text(
                                syncState.queuedSectionLabel ??
                                    (l10n?.waitingForCue ??
                                        'None (Waiting for cue)'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: brand.accentInk,
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
                  StageCard(
                    padding: const EdgeInsets.all(16),
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
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: brand.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (syncState.isDirector) ...[
                          Text(
                            syncState.isConnected
                                ? (l10n?.serverRunningOnPort(
                                        syncState.serverPort ?? 0,
                                      ) ??
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
                                style: syncState.isConnected
                                    ? stopStyle
                                    : startStyle,
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
                                label: Text(
                                  l10n?.triggerTestCue ?? 'Trigger Test Cue',
                                ),
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
                                    labelText:
                                        l10n?.directorHostIp ??
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
                            style: syncState.isConnected
                                ? stopStyle
                                : startStyle,
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
                                                e.toString(),
                                              ) ??
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
                    StageCard(
                      selected: true,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shield,
                                color: brand.accentInk,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n?.leaderLockRequestsTitle ?? 'LeaderLock: Musician Transition Requests',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (final req in syncState.pendingRequests)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                l10n?.requestPrefix(req.currentSectionId) ??
                                    'Request: ${req.currentSectionId}',
                              ),
                              subtitle: Text(
                                l10n?.followerRequestedChange ??
                                    'Follower requested section change',
                              ),
                              trailing: FilledButton(
                                style: startStyle,
                                onPressed: () {
                                  syncNotifier.jumpNowSection(
                                    req.currentSectionId,
                                  );
                                },
                                child: Text(
                                  l10n?.approveJump ?? 'Approve Jump',
                                ),
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
            queuedSectionId: syncState.queuedSectionLabel,
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
