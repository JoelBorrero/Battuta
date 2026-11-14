/// Battuta — Live Stage Session & Real-Time Sync Page.
///
/// Provides stage synchronization controls for directors and band members:
/// - Start a session: perform a setlist on this device (see the performance page).
/// - Director Mode: Local LAN WebSocket host and LeaderLock section requests.
/// - Follower Mode: Real-time section following, upcoming cue banner, and request queuing.
/// - Integrated [StageCueBanner].
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/core/platform/screen_wake_lock.dart';
import 'package:battuta/features/live_session/presentation/widgets/director_host_card.dart';
import 'package:battuta/features/live_session/presentation/widgets/join_by_address_sheet.dart';
import 'package:battuta/features/live_session/presentation/widgets/live_connect_texts.dart';
import 'package:battuta/features/live_session/presentation/widgets/nearby_sessions_list.dart';
import 'package:battuta/features/live_session/presentation/widgets/performance_start_card.dart';
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

class _LiveSessionPageState extends ConsumerState<LiveSessionPage>
    with WidgetsBindingObserver {
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

  /// Asks before a `battuta-live://` link replaces the running session.
  Future<void> _confirmSwitch() async {
    if (_switchPromptOpen || !mounted) return;
    final address = ref.read(liveSyncControllerProvider).pendingJoin;
    if (address == null) return;
    _switchPromptOpen = true;
    final l10n = AppLocalizations.of(context);
    final join = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.liveSwitchTitle ?? 'Leave the current session?'),
        content: Text(
          l10n?.liveSwitchBody(address.display) ??
              'Leave the current session and join ${address.display}?',
        ),
        actions: [
          TextButton(
            key: const ValueKey('live_switch_cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            key: const ValueKey('live_switch_join'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.liveSwitchJoin ?? 'Join'),
          ),
        ],
      ),
    );
    _switchPromptOpen = false;
    if (!mounted) return;
    if (join == true) {
      await _syncNotifier.confirmPendingJoin();
    } else {
      _syncNotifier.cancelPendingJoin();
    }
  }

  bool _switchPromptOpen = false;

  final _nameController = TextEditingController();
  bool _nameInitialized = false;

  late final LiveSyncNotifier _syncNotifier;

  late final ScreenWakeLock _wakeLock;
  // Wake lock calls run one after the other so a late enable can never
  // outlive a later disable.
  Future<void> _wakeLockCalls = Future<void>.value();
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncNotifier = ref.read(liveSyncControllerProvider.notifier);
    _wakeLock = ref.read(screenWakeLockProvider);
    _setWakeLock(ref.read(stagePreferencesProvider).keepScreenAwake);
    // Browsing changes provider state, which must not happen mid-build.
    Future<void>.microtask(_syncBrowsing);
    // A link that opened this page may already be waiting for an answer.
    WidgetsBinding.instance.addPostFrameCallback((_) => _confirmSwitch());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_nameInitialized) {
      _nameInitialized = true;
      _nameController.text =
          AppLocalizations.of(context)?.liveDefaultSessionName ??
          'Live session';
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // iOS may have closed the host's server while the app was suspended.
    if (state == AppLifecycleState.resumed) _syncNotifier.ensureHosting();
  }

  /// Followers that are not in a session list the sessions nearby.
  void _syncBrowsing() {
    if (!mounted) return;
    final s = ref.read(liveSyncControllerProvider);
    final browse =
        !s.isDirector &&
        (s.status == LiveSyncStatus.disconnected ||
            s.status == LiveSyncStatus.error);
    if (browse) {
      _syncNotifier.startBrowsing();
    } else {
      _syncNotifier.stopBrowsing();
    }
  }

  Future<void> _joinByAddress() async {
    final address = await showJoinByAddressSheet(context);
    if (address != null) await _syncNotifier.joinAddress(address);
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
    WidgetsBinding.instance.removeObserver(this);
    _setWakeLock(false);
    // Deferred: provider state must not change while the tree is torn down.
    Future<void>.microtask(_syncNotifier.stopBrowsing);
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      stagePreferencesProvider.select((p) => p.keepScreenAwake),
      (_, on) => _setWakeLock(on),
    );
    ref.listen(
      liveSyncControllerProvider.select((s) => (s.isDirector, s.status)),
      (_, _) => _syncBrowsing(),
    );
    ref.listen(liveSyncControllerProvider.select((s) => s.pendingJoin), (
      _,
      pending,
    ) {
      if (pending != null) _confirmSwitch();
    });
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
    final deviceName = ref.watch(liveDeviceNameProvider);
    final syncState = ref.watch(liveSyncControllerProvider);
    final syncNotifier = ref.read(liveSyncControllerProvider.notifier);

    final connectionLabel = switch (syncState.status) {
      LiveSyncStatus.connected =>
        syncState.isDirector
            ? (l10n?.hostingStatus ?? 'HOSTING')
            : (l10n?.syncedStatus ?? 'SYNCED'),
      LiveSyncStatus.connecting => l10n?.liveConnectingStatus ?? 'CONNECTING',
      LiveSyncStatus.reconnecting =>
        l10n?.liveReconnectingStatus ?? 'RECONNECTING',
      _ => l10n?.standaloneStatus ?? 'STANDALONE',
    };
    // Leave must stay available while the follower is trying to come back.
    final inSession = syncState.isConnected || syncState.isReconnecting;

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
                                : (syncState.isReconnecting
                                      ? brand.accentInk
                                      : brand.inkMuted),
                          ),
                        ),
                      ),
                      if (inSession) ...[
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

                  // ── Start a performance on this device ──
                  const PerformanceStartCard(),

                  const SizedBox(height: 14),

                  // ── Mode Switcher (Director vs Follower) ──
                  StageSegmentedControl<LiveSyncMode>(
                    selected: syncState.mode,
                    // A running session is ended first, so the card below
                    // never disagrees with what the device is doing.
                    onChanged: (mode) {
                      if (!inSession) syncNotifier.setSyncMode(mode);
                    },
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

                  // ── What the director has on stage (in a session) ──
                  if (inSession) ...[
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
                                      (l10n?.introPreRoll ??
                                          'INTRO / PRE-ROLL'),
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
                  ],

                  // ── Host (director) or find a session (follower) ──
                  if (syncState.isDirector)
                    DirectorHostCard(
                      nameController: _nameController,
                      hosting: syncState.isConnected,
                      deviceName: deviceName,
                      joinAddress: syncState.joinAddress,
                      followers: syncState.followers,
                      issue: syncState.issue,
                      onHost: () => syncNotifier.startHosting(
                        sessionName: _nameController.text.trim().isEmpty
                            ? (l10n?.liveDefaultSessionName ?? 'Live session')
                            : _nameController.text.trim(),
                      ),
                      onStop: syncNotifier.disconnect,
                    )
                  else ...[
                    if (!inSession &&
                        syncState.status != LiveSyncStatus.connecting)
                      NearbySessionsList(
                        sessions: syncState.sessions,
                        searching: syncState.searching,
                        timedOut: syncState.searchTimedOut,
                        onJoin: syncNotifier.joinSession,
                        onJoinByAddress: _joinByAddress,
                      ),
                    if (syncState.issue != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        liveIssueText(l10n, syncState.issue!),
                        key: const ValueKey('live_issue'),
                        style: TextStyle(fontSize: 13, color: brand.danger),
                      ),
                    ],
                  ],

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
        ],
      ),
    );
  }
}
