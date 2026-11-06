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

/// Periodic recurrence rule for calendar services.
enum EventRecurrence {
  none('One-time Event', 'None'),
  weekly('Weekly (Every Sunday)', 'Weekly'),
  biweekly('Bi-weekly (Every 2 weeks)', 'Bi-weekly'),
  monthly('Monthly', 'Monthly');

  const EventRecurrence(this.displayName, this.shortName);
  final String displayName;
  final String shortName;
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

