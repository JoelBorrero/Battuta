/// Battuta — perform a setlist (or one song) on this device: the chart in the
/// right key, sections in order with the next one always named, and lyrics
/// that scroll at the tempo of the song.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/core/platform/screen_wake_lock.dart';
import 'package:battuta/features/live_session/domain/performance_plan.dart';
import 'package:battuta/features/live_session/presentation/providers/performance_controller.dart';
import 'package:battuta/features/live_session/presentation/widgets/performance_chart.dart';
import 'package:battuta/features/live_session/presentation/widgets/performance_header.dart';
import 'package:battuta/features/live_session/presentation/widgets/performance_transport_bar.dart';
import 'package:battuta/features/live_session/presentation/widgets/section_cue_strip.dart';
import 'package:battuta/features/live_session/presentation/widgets/setlist_outline.dart';
import 'package:battuta/features/settings/presentation/providers/stage_preferences_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Width from which the setlist outline sits beside the chart.
const double _wideBreakpoint = 840;

class LivePerformancePage extends ConsumerStatefulWidget {
  /// Performs [setlistId] or, when it is null, the single song [songId].
  const LivePerformancePage({this.setlistId, this.songId, super.key});

  final String? setlistId;
  final String? songId;

  @override
  ConsumerState<LivePerformancePage> createState() =>
      _LivePerformancePageState();
}

class _LivePerformancePageState extends ConsumerState<LivePerformancePage> {
  late final ScreenWakeLock _wakeLock;
  // Wake lock calls run one after the other so a late enable can never
  // outlive a later disable.
  Future<void> _wakeLockCalls = Future<void>.value();
  bool _disposed = false;

  PerformanceTarget get _target =>
      (setlistId: widget.setlistId, songId: widget.songId);

  @override
  void initState() {
    super.initState();
    _wakeLock = ref.read(screenWakeLockProvider);
    _setWakeLock(ref.read(stagePreferencesProvider).keepScreenAwake);
    ref.listenManual(performancePlanProvider(_target), (_, next) {
      _apply(next);
    });
    // Provider state must not change while the tree is being built.
    Future<void>.microtask(() {
      if (mounted) _apply(ref.read(performancePlanProvider(_target)));
    });
  }

  void _apply(AsyncValue<PerformancePlan?> plan) {
    final value = plan.value;
    if (value != null && value.songs.isNotEmpty) {
      ref.read(performanceControllerProvider.notifier).setPlan(value);
    }
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
        // A missing plugin must not break the performance.
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _setWakeLock(false);
    super.dispose();
  }

  void _leave() {
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      Navigator.of(context).pop();
    } else if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRoutes.live);
    }
  }

  Future<void> _confirmEnd() async {
    final l10n = AppLocalizations.of(context);
    final end = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.livePerfEndTitle ?? 'End this live session?'),
        content: Text(
          l10n?.livePerfEndBody ?? 'You can start it again from the Live tab.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('perf_end_cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            key: const ValueKey('perf_end_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.endSessionAction ?? 'End'),
          ),
        ],
      ),
    );
    if (end == true && mounted) _leave();
  }

  String _cueLabel(AppLocalizations? l10n, PerformanceSong song, int index) {
    final cue = song.cues[index];
    return cue.isWholeSong
        ? (l10n?.livePerfWholeSong ?? 'Whole song')
        : cue.label;
  }

  /// "Next: Chorus", or what follows the last section of the song.
  String _nextText(AppLocalizations? l10n, PerformanceState state) {
    final song = state.currentSong!;
    final plan = state.plan!;
    if (state.cueIndex < song.cues.length - 1) {
      final label = _cueLabel(l10n, song, state.cueIndex + 1);
      return l10n?.livePerfNextCue(label) ?? 'Next: $label';
    }
    if (!state.isLastSong) {
      final title = plan.songs[state.songIndex + 1].title;
      return l10n?.livePerfNextSongCue(title) ?? 'Next song: $title';
    }
    return l10n?.livePerfLastSection ?? 'Last section of the set';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      stagePreferencesProvider.select((p) => p.keepScreenAwake),
      (_, on) => _setWakeLock(on),
    );
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);
    final planAsync = ref.watch(performancePlanProvider(_target));
    final state = ref.watch(performanceControllerProvider);
    final notifier = ref.read(performanceControllerProvider.notifier);

    Widget body;
    final plan = planAsync.value;
    if (planAsync.isLoading && plan == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (plan == null || plan.songs.isEmpty) {
      body = _Message(
        icon: Icons.queue_music,
        title: l10n?.livePerfNotFound ?? 'Nothing to play here',
        message:
            l10n?.livePerfNotFoundBody ??
            'The setlist or song is not on this device.',
        actions: [
          OutlinedButton(
            key: const ValueKey('perf_close_empty'),
            onPressed: _leave,
            child: Text(l10n?.livePerfClose ?? 'Close'),
          ),
        ],
      );
    } else if (state.plan == null || state.currentSong == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.finished) {
      body = _Message(
        icon: Icons.check_circle_outline,
        title: l10n?.livePerfSetComplete ?? 'Set complete',
        actions: [
          FilledButton(
            key: const ValueKey('perf_restart'),
            style: FilledButton.styleFrom(
              backgroundColor: brand.accent,
              foregroundColor: brand.onAccent,
              minimumSize: const Size(44, 48),
            ),
            onPressed: notifier.restart,
            child: Text(l10n?.livePerfRestart ?? 'Restart'),
          ),
          OutlinedButton(
            key: const ValueKey('perf_done_close'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48)),
            onPressed: _leave,
            child: Text(l10n?.livePerfClose ?? 'Close'),
          ),
        ],
      );
    } else {
      body = _stage(context, l10n, state, notifier);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (state.finished || state.plan == null) {
          _leave();
        } else {
          _confirmEnd();
        }
      },
      child: Scaffold(
        backgroundColor: brand.canvas,
        body: SafeArea(bottom: false, child: body),
      ),
    );
  }

  Widget _stage(
    BuildContext context,
    AppLocalizations? l10n,
    PerformanceState state,
    PerformanceController notifier,
  ) {
    final plan = state.plan!;
    final song = state.currentSong!;
    final canGoBack = state.songIndex > 0 || state.cueIndex > 0;
    final onLastCue = state.cueIndex >= song.stepCount - 1;
    final nextIsPrimary = state.atEnd && onLastCue;
    final nextLabel = state.isLastStep
        ? (l10n?.livePerfFinish ?? 'Finish')
        : (l10n?.livePerfNext ?? 'Next');

    final chart = song.isMissing
        ? _Message(
            icon: Icons.cloud_off_outlined,
            title: l10n?.livePerfMissingSong ?? 'Not on this device',
            message:
                '${song.title}\n'
                '${l10n?.livePerfMissingBody ?? 'This song is not available here. Go to the next one.'}',
          )
        : PerformanceChart(key: ValueKey(song.itemId), song: song);

    final main = Column(
      children: [
        PerformanceHeader(
          song: song,
          songNumber: state.songIndex + 1,
          songCount: plan.length,
          nextText: _nextText(l10n, state),
          onClose: _confirmEnd,
        ),
        if (song.cues.isNotEmpty) ...[
          SectionCueStrip(
            song: song,
            cueIndex: state.cueIndex,
            onSelect: (i) => notifier.jumpToCue(i),
          ),
          const SizedBox(height: 8),
        ],
        Expanded(child: chart),
      ],
    );

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _wideBreakpoint) return main;
              return Row(
                children: [
                  Expanded(child: main),
                  SizedBox(
                    width: 300,
                    child: SetlistOutline(
                      plan: plan,
                      songIndex: state.songIndex,
                      onSelect: (i) => notifier.jumpToCue(0, songIndex: i),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        PerformanceTransportBar(
          playing: state.isScrolling,
          speed: state.speed,
          bpm: song.bpm,
          nextLabel: nextLabel,
          nextIsPrimary: nextIsPrimary,
          canGoBack: canGoBack,
          onPrevious: notifier.prevCue,
          onNext: notifier.nextCue,
          onTogglePlay: notifier.toggleScroll,
          onSlower: () => notifier.stepSpeed(-1),
          onFaster: () => notifier.stepSpeed(1),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.message,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String? message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: StageEmptyState(
        icon: icon,
        title: title,
        message: message,
        actions: actions,
      ),
    ),
  );
}
