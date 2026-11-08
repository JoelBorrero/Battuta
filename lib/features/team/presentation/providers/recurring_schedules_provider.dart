/// Battuta — Recurring Schedules Provider.
///
/// Manages the single recurring definition/template per repetitive service
/// (e.g. Sunday Morning Worship, Thursday Band Rehearsal). Supports rolling X-event
/// projection lookaheads, active toggling, and disabling on/after a specific cutoff date.
library;

import 'package:battuta/core/services/demo_mode_provider.dart';
import 'package:battuta/features/team/domain/entities/recurring_schedule.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recurringSchedulesProvider =
    NotifierProvider<RecurringSchedulesNotifier, List<RecurringSchedule>>(
      RecurringSchedulesNotifier.new,
    );

class RecurringSchedulesNotifier extends Notifier<List<RecurringSchedule>> {
  final List<RecurringSchedule> _userSchedules = [];

  @override
  List<RecurringSchedule> build() {
    final isDemo = ref.watch(demoModeProvider);
    if (isDemo) {
      return [..._userSchedules, ..._initialSampleSchedules()];
    }
    return List.unmodifiable(_userSchedules);
  }

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

  static List<RecurringSchedule> _initialSampleSchedules() {
    return const [
      RecurringSchedule(
        id: 'series-sunday-morning',
        title: 'Sunday Morning Worship',
        type: ServiceType.sundayService,
        recurrence: EventRecurrence.weekly,
        time: TimeOfDay(hour: 9, minute: 0),
        location: 'Main Sanctuary',
        notes: 'Soundcheck at 7:45 AM. Lead sheet package in Battuta.',
        isActive: true,
        lookaheadCount: 4,
      ),
      RecurringSchedule(
        id: 'series-thursday-rehearsal',
        title: 'Midweek Band Rehearsal',
        type: ServiceType.rehearsal,
        recurrence: EventRecurrence.weeklyThursday,
        time: TimeOfDay(hour: 19, minute: 0),
        location: 'Music Suite & Rehearsal Room',
        notes: 'Vocal harmony blend and lead sheet transitions.',
        isActive: true,
        lookaheadCount: 4,
      ),
    ];
  }
}
