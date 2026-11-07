/// Battuta — Recurring Schedule Entity.
///
/// Models a single recurring template/rule for repetitive events (e.g. Sunday Morning Worship,
/// Midweek Band Rehearsal). Dynamically projects a rolling window of X upcoming events
/// in the calendar list, and supports disabling generation on/after a specific cutoff date.
library;

import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class RecurringSchedule extends Equatable {
  const RecurringSchedule({
    required this.id,
    required this.title,
    this.type = ServiceType.sundayService,
    this.recurrence = EventRecurrence.weekly,
    this.time = const TimeOfDay(hour: 9, minute: 0),
    this.location = 'Main Sanctuary',
    this.notes,
    this.isActive = true,
    this.disabledAfter,
    this.lookaheadCount = 4,
    this.defaultAssignments = const [],
  });

  /// Unique identifier for this recurring series (e.g. "series-sunday-morning").
  final String id;

  /// Display title for projected occurrences.
  final String title;

  /// Service category (e.g. Sunday Service, Rehearsal, Youth).
  final ServiceType type;

  /// Recurrence cadence (e.g. Weekly Sunday, Weekly Thursday, 1st Sunday).
  final EventRecurrence recurrence;

  /// Event start time.
  final TimeOfDay time;

  /// Venue / sanctuary location.
  final String location;

  /// Default notes or call-time indications.
  final String? notes;

  /// Whether this recurring rule is active. When false, no events are projected.
  final bool isActive;

  /// If specified, no occurrences will be projected on or after this date.
  final DateTime? disabledAfter;

  /// The rolling count (X) of upcoming events ahead to display in the calendar list.
  final int lookaheadCount;

  /// Optional default assignments to apply to projected occurrences.
  final List<ServiceAssignment> defaultAssignments;

  RecurringSchedule copyWith({
    String? id,
    String? title,
    ServiceType? type,
    EventRecurrence? recurrence,
    TimeOfDay? time,
    String? location,
    String? notes,
    bool? isActive,
    DateTime? disabledAfter,
    bool clearDisabledAfter = false,
    int? lookaheadCount,
    List<ServiceAssignment>? defaultAssignments,
  }) {
    return RecurringSchedule(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      recurrence: recurrence ?? this.recurrence,
      time: time ?? this.time,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      disabledAfter: clearDisabledAfter ? null : (disabledAfter ?? this.disabledAfter),
      lookaheadCount: lookaheadCount ?? this.lookaheadCount,
      defaultAssignments: defaultAssignments ?? this.defaultAssignments,
    );
  }

  /// Calculates the projected upcoming dates for this recurring schedule
  /// starting on or after [fromDateTime], respecting [lookaheadCount] and [disabledAfter].
  List<DateTime> generateOccurrences({required DateTime fromDateTime}) {
    if (!isActive || lookaheadCount <= 0) return [];

    final startAnchor = DateTime(
      fromDateTime.year,
      fromDateTime.month,
      fromDateTime.day,
      time.hour,
      time.minute,
    );

    final rawOccurrences = recurrence.generateOccurrences(
      fromDateTime: startAnchor,
      count: lookaheadCount,
    );

    if (disabledAfter == null) {
      return rawOccurrences;
    }

    final cutoffDayStart = DateTime(
      disabledAfter!.year,
      disabledAfter!.month,
      disabledAfter!.day,
    );

    return rawOccurrences.where((dt) {
      final occurrenceDayStart = DateTime(dt.year, dt.month, dt.day);
      return occurrenceDayStart.isBefore(cutoffDayStart);
    }).toList();
  }

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        recurrence,
        time,
        location,
        notes,
        isActive,
        disabledAfter,
        lookaheadCount,
        defaultAssignments,
      ];
}
