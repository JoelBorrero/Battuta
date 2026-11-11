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
    this.eventType = defaultEventType,
    this.setlistId,
    this.seriesId,
    this.occurrenceDate,
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
    eventType: json['event_type'] as String? ?? defaultEventType,
    setlistId: json['setlist_id'] as String?,
    seriesId: json['series_id'] as String?,
    occurrenceDate: json['occurrence_date'] == null
        ? null
        : parseDateOnly(json['occurrence_date']),
  );

  /// The `event_type` of rows that do not say (the first service type).
  static const defaultEventType = 'sundayService';

  final String id;
  final String organizationId;
  final String title;

  /// The instant of the event (UTC). Convert with `toLocal()` for display.
  final DateTime dateTime;
  final String? bandId;
  final String? createdBy;
  final String? location;
  final String? notes;

  /// Kind of service (the app's `ServiceType` name).
  final String eventType;

  /// A setlist of the same organization, if one is linked.
  final String? setlistId;

  /// The recurring schedule this event is an occurrence of, if any.
  final String? seriesId;

  /// The calendar day of the schedule occurrence this event materializes.
  final DateTime? occurrenceDate;

  CalendarEvent copyWith({
    String? title,
    DateTime? dateTime,
    String? bandId,
    bool clearBand = false,
    String? location,
    String? notes,
    String? eventType,
    String? setlistId,
    bool clearSetlist = false,
    bool clearLocation = false,
    bool clearNotes = false,
  }) => CalendarEvent(
    id: id,
    organizationId: organizationId,
    title: title ?? this.title,
    dateTime: dateTime ?? this.dateTime,
    bandId: clearBand ? null : (bandId ?? this.bandId),
    createdBy: createdBy,
    location: clearLocation ? null : (location ?? this.location),
    notes: clearNotes ? null : (notes ?? this.notes),
    eventType: eventType ?? this.eventType,
    setlistId: clearSetlist ? null : (setlistId ?? this.setlistId),
    seriesId: seriesId,
    occurrenceDate: occurrenceDate,
  );

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
    'event_type': eventType,
    'setlist_id': setlistId,
    'series_id': seriesId,
    'occurrence_date': occurrenceDate == null
        ? null
        : formatDateOnly(occurrenceDate!),
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
    eventType,
    setlistId,
    seriesId,
    occurrenceDate,
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
    this.minuteOfDay = defaultMinuteOfDay,
    this.location,
    this.eventType = CalendarEvent.defaultEventType,
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
        minuteOfDay: parseTimeOfDay(json['time_of_day']),
        location: json['location'] as String?,
        eventType:
            json['event_type'] as String? ?? CalendarEvent.defaultEventType,
      );

  /// 09:00, the column default.
  static const defaultMinuteOfDay = 9 * 60;

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

  /// Local start time as minutes after midnight (0-1439).
  final int minuteOfDay;
  final String? location;
  final String eventType;

  RecurringSchedule copyWith({
    String? title,
    String? bandId,
    bool clearBand = false,
    int? dayOfWeek,
    String? pattern,
    int? lookaheadCount,
    bool? isActive,
    DateTime? disabledAfter,
    bool clearDisabledAfter = false,
    int? minuteOfDay,
    String? location,
    bool clearLocation = false,
    String? eventType,
  }) => RecurringSchedule(
    id: id,
    organizationId: organizationId,
    title: title ?? this.title,
    bandId: clearBand ? null : (bandId ?? this.bandId),
    createdBy: createdBy,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    pattern: pattern ?? this.pattern,
    lookaheadCount: lookaheadCount ?? this.lookaheadCount,
    isActive: isActive ?? this.isActive,
    disabledAfter: clearDisabledAfter
        ? null
        : (disabledAfter ?? this.disabledAfter),
    minuteOfDay: minuteOfDay ?? this.minuteOfDay,
    location: clearLocation ? null : (location ?? this.location),
    eventType: eventType ?? this.eventType,
  );

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
    'time_of_day': formatTimeOfDay(minuteOfDay),
    'location': location,
    'event_type': eventType,
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
    minuteOfDay,
    location,
    eventType,
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
