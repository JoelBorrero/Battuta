/// Battuta — Recurring Schedules Provider.
///
/// Manages the single recurring definition/template per repetitive service
/// (e.g. Sunday Morning Worship, Thursday Band Rehearsal). Supports rolling X-event
/// projection lookaheads, active toggling, and disabling on/after a specific cutoff date.
library;

import 'package:battuta/features/team/domain/entities/recurring_schedule.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recurringSchedulesProvider =
    NotifierProvider<RecurringSchedulesNotifier, List<RecurringSchedule>>(
      RecurringSchedulesNotifier.new,
    );

class RecurringSchedulesNotifier extends Notifier<List<RecurringSchedule>> {
  final List<RecurringSchedule> _userSchedules = [];

  @override
  List<RecurringSchedule> build() => List.unmodifiable(_userSchedules);

  /// Adds a new repetitive schedule pattern.
  void addSchedule(RecurringSchedule schedule) {
    _userSchedules.add(schedule);
    ref.invalidateSelf();
  }

  /// Updates an existing recurring schedule definition.
  void updateSchedule(RecurringSchedule updated) {
    state = [
      for (final s in state)
        if (s.id == updated.id) updated else s,
    ];
  }

  /// Toggles whether a recurring schedule is active or paused.
  void toggleActive(String id) {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(isActive: !s.isActive) else s,
    ];
  }

  /// Sets or clears the cutoff date after which no occurrences will be generated.
  void setDisabledDate(String id, DateTime? disabledAfter) {
    state = [
      for (final s in state)
        if (s.id == id)
          s.copyWith(
            disabledAfter: disabledAfter,
            clearDisabledAfter: disabledAfter == null,
          )
        else
          s,
    ];
  }

  /// Changes the rolling number of upcoming events (X) to show ahead in the calendar.
  void setLookaheadCount(String id, int count) {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(lookaheadCount: count) else s,
    ];
  }

  /// Removes a recurring schedule definition.
  void removeSchedule(String id) {
    state = state.where((s) => s.id != id).toList();
  }
}
