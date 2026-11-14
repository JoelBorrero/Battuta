/// Battuta — the state of a performance: which song and section is on, whether
/// the chart is scrolling and how fast.
library;

import 'package:battuta/features/live_session/domain/performance_plan.dart';
import 'package:battuta/features/live_session/domain/scroll_pace.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/settings/presentation/providers/stage_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What to perform: a setlist, or a single song. Exactly one is set.
typedef PerformanceTarget = ({String? setlistId, String? songId});

/// The plan for [PerformanceTarget]: `null` data when it does not exist.
///
/// Rebuilds when the setlist or the songs change, so edits show up mid-session.
final performancePlanProvider = Provider.autoDispose
    .family<AsyncValue<PerformancePlan?>, PerformanceTarget>((ref, target) {
      final setlistId = target.setlistId;
      if (setlistId != null) {
        final setlist = ref.watch(setlistByIdProvider(setlistId));
        final songs = ref.watch(repertoireProvider);
        if (setlist.hasError) {
          return AsyncError(setlist.error!, setlist.stackTrace!);
        }
        if (songs.hasError) return AsyncError(songs.error!, songs.stackTrace!);
        if (!setlist.hasValue || !songs.hasValue) return const AsyncLoading();
        final found = setlist.value;
        if (found == null) return const AsyncData(null);
        return AsyncData(
          PerformancePlan.fromSetlist(found, {
            for (final song in songs.value!) song.id: song,
          }),
        );
      }
      final songId = target.songId;
      if (songId == null) return const AsyncData(null);
      final song = ref.watch(songByIdProvider(songId));
      if (song.hasError) return AsyncError(song.error!, song.stackTrace!);
      if (!song.hasValue) return const AsyncLoading();
      final Song? found = song.value;
      return AsyncData(found == null ? null : PerformancePlan.fromSong(found));
    });

/// Immutable state of a performance.
class PerformanceState {
  const PerformanceState({
    this.plan,
    this.songIndex = 0,
    this.cueIndex = 0,
    this.isScrolling = false,
    this.speed = ScrollPace.defaultAdjustment,
    this.atEnd = false,
    this.finished = false,
    this.navSerial = 0,
  });

  /// What is being performed; `null` until it is loaded.
  final PerformancePlan? plan;

  final int songIndex;

  /// Section within the current song.
  final int cueIndex;

  /// Whether the chart auto-scrolls.
  final bool isScrolling;

  /// The player's speed adjustment (0.5 to 2.0) for the current song.
  final double speed;

  /// Whether the last section of the current song is fully on screen.
  final bool atEnd;

  /// Whether the whole set has been played.
  final bool finished;

  /// Counts moves the player asked for (next, previous, a chip, restart), so
  /// the chart scrolls to them; scrolling that moves the cue does not count.
  final int navSerial;

  PerformanceSong? get currentSong {
    final p = plan;
    if (p == null || songIndex < 0 || songIndex >= p.songs.length) return null;
    return p.songs[songIndex];
  }

  bool get isLastSong => plan != null && songIndex >= plan!.songs.length - 1;

  bool get isLastStep {
    final s = currentSong;
    return s != null && isLastSong && cueIndex >= s.stepCount - 1;
  }

  PerformanceState copyWith({
    PerformancePlan? plan,
    int? songIndex,
    int? cueIndex,
    bool? isScrolling,
    double? speed,
    bool? atEnd,
    bool? finished,
    int? navSerial,
  }) => PerformanceState(
    plan: plan ?? this.plan,
    songIndex: songIndex ?? this.songIndex,
    cueIndex: cueIndex ?? this.cueIndex,
    isScrolling: isScrolling ?? this.isScrolling,
    speed: speed ?? this.speed,
    atEnd: atEnd ?? this.atEnd,
    finished: finished ?? this.finished,
    navSerial: navSerial ?? this.navSerial,
  );
}

/// Drives a performance. Lives while the performance page is open.
class PerformanceController extends Notifier<PerformanceState> {
  @override
  PerformanceState build() => const PerformanceState();

  /// Loads or reloads the plan. When the setlist was edited mid-session the
  /// current song stays (found by its item id) if it still exists.
  void setPlan(PerformancePlan plan) {
    if (state.plan == plan) return;
    var songIndex = 0;
    var cueIndex = 0;
    final current = state.currentSong;
    if (current != null) {
      final kept = plan.indexOfItem(current.itemId);
      if (kept >= 0) {
        songIndex = kept;
        cueIndex = state.cueIndex.clamp(0, plan.songs[kept].stepCount - 1);
      }
    }
    final placeChanged =
        state.plan == null ||
        songIndex != state.songIndex ||
        cueIndex != state.cueIndex;
    state = PerformanceState(
      plan: plan,
      songIndex: songIndex,
      cueIndex: cueIndex,
      isScrolling: state.isScrolling,
      speed: _savedSpeed(plan, songIndex),
      atEnd: state.atEnd,
      finished: state.finished,
      // The chart only moves when the place in the set changed (the song was
      // removed or shifted); an unrelated edit keeps the scroll as it is.
      navSerial: placeChanged ? state.navSerial + 1 : state.navSerial,
    );
  }

  double _savedSpeed(PerformancePlan plan, int songIndex) {
    if (songIndex < 0 || songIndex >= plan.songs.length) {
      return ScrollPace.defaultAdjustment;
    }
    final saved = ref
        .read(stagePreferencesProvider)
        .songSpeeds[plan.songs[songIndex].songId];
    return ScrollPace.normalizeAdjustment(
      saved ?? ScrollPace.defaultAdjustment,
    );
  }

  void _goTo(int songIndex, int cueIndex) {
    final plan = state.plan;
    if (plan == null) return;
    final sameSong = songIndex == state.songIndex;
    state = state.copyWith(
      songIndex: songIndex,
      cueIndex: cueIndex,
      speed: sameSong ? state.speed : _savedSpeed(plan, songIndex),
      atEnd: sameSong ? state.atEnd : false,
      finished: false,
      navSerial: state.navSerial + 1,
    );
  }

  /// The next section; past the last one, the next song's first. After the
  /// last section of the set the performance is finished.
  void nextCue() {
    final song = state.currentSong;
    if (song == null || state.finished) return;
    if (state.cueIndex < song.stepCount - 1) {
      _goTo(state.songIndex, state.cueIndex + 1);
    } else {
      nextSong();
    }
  }

  /// The previous section; before the first one, the previous song's last.
  void prevCue() {
    final plan = state.plan;
    if (plan == null) return;
    if (state.finished) {
      _goTo(state.songIndex, state.cueIndex);
      return;
    }
    if (state.cueIndex > 0) {
      _goTo(state.songIndex, state.cueIndex - 1);
    } else if (state.songIndex > 0) {
      final previous = plan.songs[state.songIndex - 1];
      _goTo(state.songIndex - 1, previous.stepCount - 1);
    }
  }

  /// The next song from its first section; after the last song the set is
  /// finished.
  void nextSong() {
    final plan = state.plan;
    if (plan == null || state.finished) return;
    if (state.songIndex < plan.songs.length - 1) {
      _goTo(state.songIndex + 1, 0);
    } else {
      state = state.copyWith(finished: true, isScrolling: false);
    }
  }

  /// The previous song from its first section.
  void prevSong() {
    if (state.plan == null || state.songIndex == 0) return;
    _goTo(state.songIndex - 1, 0);
  }

  /// Goes to section [cueIndex] of song [songIndex] (the current one by
  /// default). Out-of-range values are ignored.
  void jumpToCue(int cueIndex, {int? songIndex}) {
    final plan = state.plan;
    if (plan == null) return;
    final song = songIndex ?? state.songIndex;
    if (song < 0 || song >= plan.songs.length) return;
    if (cueIndex < 0 || cueIndex >= plan.songs[song].stepCount) return;
    _goTo(song, cueIndex);
  }

  /// The chart scrolled to section [index]: follows it without moving the
  /// chart again.
  void followScroll(int index) {
    final song = state.currentSong;
    if (song == null || index == state.cueIndex) return;
    if (index < 0 || index >= song.stepCount) return;
    state = state.copyWith(cueIndex: index);
  }

  /// Whether the last section of the current song is fully on screen.
  void setAtEnd(bool value) {
    if (value == state.atEnd) return;
    state = state.copyWith(atEnd: value);
  }

  void toggleScroll() {
    if (state.finished) return;
    state = state.copyWith(isScrolling: !state.isScrolling);
  }

  void pause() {
    if (!state.isScrolling) return;
    state = state.copyWith(isScrolling: false);
  }

  /// Sets the speed adjustment (snapped to 0.1 inside 0.5 to 2.0) and keeps it
  /// for this song on this device.
  void setSpeed(double value) {
    final song = state.currentSong;
    final speed = ScrollPace.normalizeAdjustment(value);
    state = state.copyWith(speed: speed);
    if (song != null && song.songId.isNotEmpty) {
      ref
          .read(stagePreferencesProvider.notifier)
          .setSongSpeed(song.songId, speed);
    }
  }

  /// One step faster (`1`) or slower (`-1`).
  void stepSpeed(int direction) =>
      setSpeed(state.speed + direction * ScrollPace.adjustmentStep);

  /// Starts the set again from the first song.
  void restart() {
    final plan = state.plan;
    if (plan == null) return;
    state = PerformanceState(
      plan: plan,
      speed: _savedSpeed(plan, 0),
      navSerial: state.navSerial + 1,
    );
  }
}

final performanceControllerProvider =
    NotifierProvider.autoDispose<PerformanceController, PerformanceState>(
      PerformanceController.new,
    );
