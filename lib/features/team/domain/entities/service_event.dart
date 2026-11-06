/// Battuta — Service Event & Calendar Assignment Entities.
///
/// Models worship services, rehearsals, recurring calendar schedules,
/// and musician band assignments.
library;

import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Category of worship service or band event.
enum ServiceType {
  sundayService('Sunday Service', 'Sunday Worship', Icons.church_outlined),
  rehearsal('Band Rehearsal', 'Rehearsal', Icons.music_note_outlined),
  midweek('Midweek Gathering', 'Midweek', Icons.groups_outlined),
  youthService('Youth Service', 'Youth', Icons.local_fire_department_outlined),
  specialEvent('Special Event', 'Special', Icons.star_border_outlined);

  const ServiceType(this.displayName, this.shortName, this.icon);
  final String displayName;
  final String shortName;
  final IconData icon;
}

/// Periodic recurrence rule for calendar services and band rehearsals.
enum EventRecurrence {
  none('One-time Event', 'None'),
  weekly('Every Sunday (Weekly)', 'Weekly Sun'),
  weeklyThursday('Every Thursday (Weekly Rehearsal)', 'Weekly Thu'),
  biweekly('Bi-weekly (Every 2 weeks)', 'Bi-weekly'),
  firstSundayOfMonth('1st Sunday of the Month (e.g. Communion)', '1st Sun'),
  secondSundayOfMonth('2nd Sunday of the Month', '2nd Sun'),
  thirdSundayOfMonth('3rd Sunday of the Month', '3rd Sun'),
  lastSundayOfMonth('Last Sunday of the Month', 'Last Sun'),
  monthly('Monthly on same day', 'Monthly');

  const EventRecurrence(this.displayName, this.shortName);
  final String displayName;
  final String shortName;

  /// Whether this rule is a repeating schedule.
  bool get isRepeating => this != EventRecurrence.none;
}

/// Computes recurrence occurrences mathematically across calendars.
extension EventRecurrenceCalculator on EventRecurrence {
  /// Computes the list of upcoming [DateTime] occurrences starting on or after [fromDateTime].
  List<DateTime> generateOccurrences({
    required DateTime fromDateTime,
    int count = 6,
  }) {
    if (this == EventRecurrence.none) {
      return [fromDateTime];
    }

    final results = <DateTime>[];
    final baseTime = TimeOfDay(
      hour: fromDateTime.hour,
      minute: fromDateTime.minute,
    );

    switch (this) {
      case EventRecurrence.none:
        results.add(fromDateTime);

      case EventRecurrence.weekly:
        var cursor = _nextWeekday(fromDateTime, DateTime.sunday);
        for (var i = 0; i < count; i++) {
          results.add(DateTime(
            cursor.year,
            cursor.month,
            cursor.day,
            baseTime.hour,
            baseTime.minute,
          ));
          cursor = cursor.add(const Duration(days: 7));
        }

      case EventRecurrence.weeklyThursday:
        var cursor = _nextWeekday(fromDateTime, DateTime.thursday);
        for (var i = 0; i < count; i++) {
          results.add(DateTime(
            cursor.year,
            cursor.month,
            cursor.day,
            baseTime.hour,
            baseTime.minute,
          ));
          cursor = cursor.add(const Duration(days: 7));
        }

      case EventRecurrence.biweekly:
        var cursor = fromDateTime;
        for (var i = 0; i < count; i++) {
          results.add(DateTime(
            cursor.year,
            cursor.month,
            cursor.day,
            baseTime.hour,
            baseTime.minute,
          ));
          cursor = cursor.add(const Duration(days: 14));
        }

      case EventRecurrence.firstSundayOfMonth:
        results.addAll(_generateNthWeekdayOfMonths(
          fromDateTime: fromDateTime,
          weekday: DateTime.sunday,
          ordinal: 1,
          count: count,
          baseTime: baseTime,
        ));

      case EventRecurrence.secondSundayOfMonth:
        results.addAll(_generateNthWeekdayOfMonths(
          fromDateTime: fromDateTime,
          weekday: DateTime.sunday,
          ordinal: 2,
          count: count,
          baseTime: baseTime,
        ));

      case EventRecurrence.thirdSundayOfMonth:
        results.addAll(_generateNthWeekdayOfMonths(
          fromDateTime: fromDateTime,
          weekday: DateTime.sunday,
          ordinal: 3,
          count: count,
          baseTime: baseTime,
        ));

      case EventRecurrence.lastSundayOfMonth:
        results.addAll(_generateNthWeekdayOfMonths(
          fromDateTime: fromDateTime,
          weekday: DateTime.sunday,
          ordinal: -1,
          count: count,
          baseTime: baseTime,
        ));

      case EventRecurrence.monthly:
        var cursor = fromDateTime;
        for (var i = 0; i < count; i++) {
          results.add(DateTime(
            cursor.year,
            cursor.month,
            cursor.day,
            baseTime.hour,
            baseTime.minute,
          ));
          final nextYear = cursor.year + (cursor.month == 12 ? 1 : 0);
          final nextMonth = cursor.month == 12 ? 1 : cursor.month + 1;
          final maxDays = DateTime(nextYear, nextMonth + 1, 0).day;
          final nextDay = cursor.day > maxDays ? maxDays : cursor.day;
          cursor = DateTime(nextYear, nextMonth, nextDay);
        }
    }

    return results;
  }

  static DateTime _nextWeekday(DateTime from, int targetWeekday) {
    var cursor = DateTime(from.year, from.month, from.day);
    while (cursor.weekday != targetWeekday) {
      cursor = cursor.add(const Duration(days: 1));
    }
    return cursor;
  }

  static List<DateTime> _generateNthWeekdayOfMonths({
    required DateTime fromDateTime,
    required int weekday,
    required int ordinal,
    required int count,
    required TimeOfDay baseTime,
  }) {
    final list = <DateTime>[];
    var currentYear = fromDateTime.year;
    var currentMonth = fromDateTime.month;

    while (list.length < count) {
      final occurrence = _findNthWeekdayOfMonth(
        year: currentYear,
        month: currentMonth,
        weekday: weekday,
        ordinal: ordinal,
      );

      final fullDateTime = DateTime(
        occurrence.year,
        occurrence.month,
        occurrence.day,
        baseTime.hour,
        baseTime.minute,
      );

      final fromDayStart = DateTime(
        fromDateTime.year,
        fromDateTime.month,
        fromDateTime.day,
      );

      if (!occurrence.isBefore(fromDayStart)) {
        list.add(fullDateTime);
      }

      if (currentMonth == 12) {
        currentYear++;
        currentMonth = 1;
      } else {
        currentMonth++;
      }
    }

    return list;
  }

  static DateTime _findNthWeekdayOfMonth({
    required int year,
    required int month,
    required int weekday,
    required int ordinal,
  }) {
    if (ordinal > 0) {
      var date = DateTime(year, month, 1);
      while (date.weekday != weekday) {
        date = date.add(const Duration(days: 1));
      }
      date = date.add(Duration(days: 7 * (ordinal - 1)));
      return date;
    } else {
      final lastDay = DateTime(year, month + 1, 0).day;
      var date = DateTime(year, month, lastDay);
      while (date.weekday != weekday) {
        date = date.subtract(const Duration(days: 1));
      }
      return date;
    }
  }
}

/// Confirmation and attendance status for a team member on a specific service date.
enum AssignmentStatus {
  confirmed('Confirmed', Colors.green),
  scheduled('Scheduled', Colors.blue),
  declined('Unavailable', Colors.grey);

  const AssignmentStatus(this.displayName, this.color);
  final String displayName;
  final Color color;
}

/// A specific role assignment for a team member on a calendar service date.
class ServiceAssignment {
  const ServiceAssignment({
    required this.memberId,
    required this.role,
    this.status = AssignmentStatus.confirmed,
  });

  final String memberId;
  final TeamRole role;
  final AssignmentStatus status;

  ServiceAssignment copyWith({
    String? memberId,
    TeamRole? role,
    AssignmentStatus? status,
  }) {
    return ServiceAssignment(
      memberId: memberId ?? this.memberId,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceAssignment &&
          runtimeType == other.runtimeType &&
          memberId == other.memberId &&
          role == other.role &&
          status == other.status;

  @override
  int get hashCode => memberId.hashCode ^ role.hashCode ^ status.hashCode;
}

/// An immutable calendar event for the band (e.g. Sunday Service, Midweek Rehearsal).
class ServiceEvent {
  const ServiceEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    this.type = ServiceType.sundayService,
    this.recurrence = EventRecurrence.weekly,
    this.location = 'Main Sanctuary',
    this.assignments = const [],
    this.notes,
    this.setlistId,
  });

  final String id;
  final String title;
  final DateTime dateTime;
  final ServiceType type;
  final EventRecurrence recurrence;
  final String location;
  final List<ServiceAssignment> assignments;
  final String? notes;
  final String? setlistId;

  /// Whether this service event is scheduled for today or a future date.
  bool get isUpcoming {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return dateTime.isAfter(todayStart) || dateTime.isAtSameMomentAs(todayStart);
  }

  /// Formatted date string (e.g. "Sun, Nov 8").
  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[dateTime.weekday - 1];
    final month = months[dateTime.month - 1];
    return '$weekday, $month ${dateTime.day}';
  }

  /// Formatted time string (e.g. "9:00 AM").
  String get formattedTime {
    final hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  ServiceEvent copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    ServiceType? type,
    EventRecurrence? recurrence,
    String? location,
    List<ServiceAssignment>? assignments,
    String? notes,
    String? setlistId,
  }) {
    return ServiceEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      recurrence: recurrence ?? this.recurrence,
      location: location ?? this.location,
      assignments: assignments ?? this.assignments,
      notes: notes ?? this.notes,
      setlistId: setlistId ?? this.setlistId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          dateTime == other.dateTime &&
          type == other.type &&
          recurrence == other.recurrence &&
          location == other.location &&
          listEquals(assignments, other.assignments) &&
          notes == other.notes &&
          setlistId == other.setlistId;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      dateTime.hashCode ^
      type.hashCode ^
      recurrence.hashCode ^
      location.hashCode ^
      Object.hashAll(assignments) ^
      notes.hashCode ^
      setlistId.hashCode;
}
