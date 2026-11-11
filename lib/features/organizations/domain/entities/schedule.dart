/// Events, recurring schedules, assignments and absences of an organization.
library;

import 'package:battuta/features/organizations/domain/entities/json_helpers.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Generates the UUID v4 used for every client-created row.
String newEntityId() => const Uuid().v4();

class CalendarEvent extends Equatable {
  const CalendarEvent({
    required this.id,
    required this.organizationId,
    required this.title,
    required this.dateTime,
    this.bandId,
    this.createdBy,
    this.location,
    this.notes,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
    id: json['id'] as String,
    organizationId: json['organization_id'] as String,
    title: json['title'] as String,
    dateTime: parseTimestamp(json['date_time'])!,
    bandId: json['band_id'] as String?,
    createdBy: json['created_by'] as String?,
    location: json['location'] as String?,
    notes: json['notes'] as String?,
  );

  final String id;
  final String organizationId;
  final String title;

  /// The instant of the event (UTC). Convert with `toLocal()` for display.
  final DateTime dateTime;
  final String? bandId;
  final String? createdBy;
  final String? location;
  final String? notes;

  /// The calendar day of the event in the device time zone.
  DateTime get localDay {
    final local = dateTime.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Columns a client may write (server-managed ones are left out).
  Map<String, dynamic> toWriteJson() => {
    'id': id,
    'organization_id': organizationId,
    'band_id': bandId,
    'title': title,
    'date_time': formatTimestamp(dateTime),
    'location': location,
    'notes': notes,
  };

  Map<String, dynamic> toJson() => {...toWriteJson(), 'created_by': createdBy};

  @override
  List<Object?> get props => [
    id,
    organizationId,
    title,
    dateTime,
    bandId,
    createdBy,
    location,
    notes,
  ];
}

class RecurringSchedule extends Equatable {
  const RecurringSchedule({
    required this.id,
    required this.organizationId,
    required this.title,
    this.bandId,
    this.createdBy,
    this.dayOfWeek = 7,
    this.pattern = 'weekly',
    this.lookaheadCount = 4,
    this.isActive = true,
    this.disabledAfter,
  });

  factory RecurringSchedule.fromJson(Map<String, dynamic> json) =>
      RecurringSchedule(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        title: json['title'] as String,
        bandId: json['band_id'] as String?,
        createdBy: json['created_by'] as String?,
        dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 7,
        pattern: json['pattern'] as String? ?? 'weekly',
        lookaheadCount: (json['lookahead_count'] as num?)?.toInt() ?? 4,
        isActive: json['is_active'] as bool? ?? true,
        disabledAfter: parseTimestamp(json['disabled_after']),
      );

  final String id;
  final String organizationId;
  final String title;
  final String? bandId;
  final String? createdBy;

  /// 1 = Monday ... 7 = Sunday.
  final int dayOfWeek;
  final String pattern;
  final int lookaheadCount;
  final bool isActive;
  final DateTime? disabledAfter;

  Map<String, dynamic> toWriteJson() => {
    'id': id,
    'organization_id': organizationId,
    'band_id': bandId,
    'title': title,
    'day_of_week': dayOfWeek,
    'pattern': pattern,
    'lookahead_count': lookaheadCount,
    'is_active': isActive,
    'disabled_after': formatTimestamp(disabledAfter),
  };

  Map<String, dynamic> toJson() => {...toWriteJson(), 'created_by': createdBy};

  @override
  List<Object?> get props => [
    id,
    organizationId,
    title,
    bandId,
    createdBy,
    dayOfWeek,
    pattern,
    lookaheadCount,
    isActive,
    disabledAfter,
  ];
}

enum AssignmentResponse {
  pending,
  accepted,
  declined;

  static AssignmentResponse parse(Object? value) =>
      values.firstWhere((r) => r.name == value, orElse: () => pending);
}

class EventAssignment extends Equatable {
  const EventAssignment({
    required this.id,
    required this.organizationId,
    required this.eventId,
    required this.instrument,
    this.memberId,
    this.response = AssignmentResponse.pending,
    this.respondedAt,
    this.declineReason,
  });

  factory EventAssignment.fromJson(Map<String, dynamic> json) =>
      EventAssignment(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        eventId: json['event_id'] as String,
        instrument: json['instrument'] as String,
        memberId: json['member_id'] as String?,
        response: AssignmentResponse.parse(json['response']),
        respondedAt: parseTimestamp(json['responded_at']),
        declineReason: json['decline_reason'] as String?,
      );

  final String id;
  final String organizationId;
  final String eventId;
  final String instrument;

  /// Null for past assignments of a member who left.
  final String? memberId;
  final AssignmentResponse response;
  final DateTime? respondedAt;
  final String? declineReason;

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'event_id': eventId,
    'instrument': instrument,
    'member_id': memberId,
    'response': response.name,
    'responded_at': formatTimestamp(respondedAt),
    'decline_reason': declineReason,
  };

  @override
  List<Object?> get props => [
    id,
    organizationId,
    eventId,
    instrument,
    memberId,
    response,
    respondedAt,
    declineReason,
  ];
}

/// Days a member is away. [startsOn] / [endsOn] are calendar days (inclusive).
class MemberAbsence extends Equatable {
  const MemberAbsence({
    required this.id,
    required this.organizationId,
    required this.memberId,
    required this.startsOn,
    required this.endsOn,
    this.note,
  });

  factory MemberAbsence.fromJson(Map<String, dynamic> json) => MemberAbsence(
    id: json['id'] as String,
    organizationId: json['organization_id'] as String,
    memberId: json['member_id'] as String,
    startsOn: parseDateOnly(json['starts_on']),
    endsOn: parseDateOnly(json['ends_on']),
    note: json['note'] as String?,
  );

  final String id;
  final String organizationId;
  final String memberId;
  final DateTime startsOn;
  final DateTime endsOn;
  final String? note;

  /// Whether the calendar [day] (time of day ignored) falls in the absence.
  bool covers(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(DateTime(startsOn.year, startsOn.month, startsOn.day)) &&
        !d.isAfter(DateTime(endsOn.year, endsOn.month, endsOn.day));
  }

  /// Whether the member is away on the day of [event] in the device time zone.
  bool coversEvent(CalendarEvent event) => covers(event.localDay);

  Map<String, dynamic> toWriteJson() => {
    'id': id,
    'organization_id': organizationId,
    'member_id': memberId,
    'starts_on': formatDateOnly(startsOn),
    'ends_on': formatDateOnly(endsOn),
    'note': note,
  };

  Map<String, dynamic> toJson() => toWriteJson();

  @override
  List<Object?> get props => [
    id,
    organizationId,
    memberId,
    startsOn,
    endsOn,
    note,
  ];
}

/// A row of `members_available_on`.
class AvailableMember extends Equatable {
  const AvailableMember({
    required this.memberId,
    required this.userId,
    required this.username,
    required this.displayName,
  });

  factory AvailableMember.fromJson(Map<String, dynamic> json) =>
      AvailableMember(
        memberId: json['member_id'] as String,
        userId: json['user_id'] as String,
        username: json['username'] as String,
        displayName: json['display_name'] as String,
      );

  final String memberId;
  final String userId;
  final String username;
  final String displayName;

  @override
  List<Object?> get props => [memberId, userId, username, displayName];
}
