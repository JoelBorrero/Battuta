/// Battuta — Service Event & Calendar Assignment Entities.
///
/// Models worship services, rehearsals, recurring calendar schedules,
/// and musician band assignments.
library;

import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Category of worship service or band event.
enum ServiceType {
  sundayService('Sunday Service', 'Sunday Worship', Icons.church_outlined),
  rehearsal('Band Rehearsal', 'Rehearsal', Icons.music_note_outlined),
  midweek('Midweek Gathering', 'Midweek', Icons.groups_outlined),
  youthService('Youth Service', 'Youth', Icons.local_fire_department_outlined),
  specialEvent('Special Event', 'Special', Icons.star_border_outlined);

  const ServiceType(this.displayName, this.shortName, this.icon);

  /// The type stored under [name] (`event_type`); unknown values are a
  /// Sunday service.
  static ServiceType parse(String? name) => values.firstWhere(
    (type) => type.name == name,
    orElse: () => ServiceType.sundayService,
  );

  final String displayName;
  final String shortName;
  final IconData icon;

  /// Localized full display name.
  String localizedName([BuildContext? context]) {
    final isEs = context != null
        ? Localizations.localeOf(context).languageCode == 'es'
        : (Intl.defaultLocale?.startsWith('es') ?? false);
    if (!isEs) return displayName;
    return switch (this) {
      ServiceType.sundayService => 'Servicio Dominical',
      ServiceType.rehearsal => 'Ensayo de Banda',
      ServiceType.midweek => 'Reunión Semanal',
      ServiceType.youthService => 'Servicio de Jóvenes',
      ServiceType.specialEvent => 'Evento Especial',
    };
  }

  /// Localized short name for compact badges.
  String localizedShortName([BuildContext? context]) {
    final isEs = context != null
        ? Localizations.localeOf(context).languageCode == 'es'
        : (Intl.defaultLocale?.startsWith('es') ?? false);
    if (!isEs) return shortName;
    return switch (this) {
      ServiceType.sundayService => 'Culto Dom',
      ServiceType.rehearsal => 'Ensayo',
      ServiceType.midweek => 'Semanal',
      ServiceType.youthService => 'Jóvenes',
      ServiceType.specialEvent => 'Especial',
    };
  }
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

  /// The cadence stored under [name] (`pattern`); unknown values are weekly.
  static EventRecurrence parse(String? name) => values.firstWhere(
    (recurrence) => recurrence.name == name,
    orElse: () => EventRecurrence.weekly,
  );

  /// Cadences whose dates do not depend on the day they are computed: the
  /// others (bi-weekly, monthly) have no anchor date in the schedule row.
  static const List<EventRecurrence> schedulable = [
    weekly,
    weeklyThursday,
    firstSundayOfMonth,
    secondSundayOfMonth,
    thirdSundayOfMonth,
    lastSundayOfMonth,
  ];

  final String displayName;
  final String shortName;

  /// Localized full display name.
  String localizedName([BuildContext? context]) {
    final isEs = context != null
        ? Localizations.localeOf(context).languageCode == 'es'
        : (Intl.defaultLocale?.startsWith('es') ?? false);
    if (!isEs) return displayName;
    return switch (this) {
      EventRecurrence.none => 'Evento Único',
      EventRecurrence.weekly => 'Cada Domingo (Semanal)',
      EventRecurrence.weeklyThursday => 'Cada Jueves (Ensayo Semanal)',
      EventRecurrence.biweekly => 'Quincenal (Cada 2 semanas)',
      EventRecurrence.firstSundayOfMonth =>
        '1.er Domingo del Mes (ej. Santa Cena)',
      EventRecurrence.secondSundayOfMonth => '2.º Domingo del Mes',
      EventRecurrence.thirdSundayOfMonth => '3.er Domingo del Mes',
      EventRecurrence.lastSundayOfMonth => 'Último Domingo del Mes',
      EventRecurrence.monthly => 'Mensual el mismo día',
    };
  }

  /// Localized short name for compact badges.
  String localizedShortName([BuildContext? context]) {
    final isEs = context != null
        ? Localizations.localeOf(context).languageCode == 'es'
        : (Intl.defaultLocale?.startsWith('es') ?? false);
    if (!isEs) return shortName;
    return switch (this) {
      EventRecurrence.none => 'Ninguno',
      EventRecurrence.weekly => 'Semanal Dom',
      EventRecurrence.weeklyThursday => 'Semanal Jue',
      EventRecurrence.biweekly => 'Quincenal',
      EventRecurrence.firstSundayOfMonth => '1.er Dom',
      EventRecurrence.secondSundayOfMonth => '2.º Dom',
      EventRecurrence.thirdSundayOfMonth => '3.er Dom',
      EventRecurrence.lastSundayOfMonth => 'Último Dom',
      EventRecurrence.monthly => 'Mensual',
    };
  }

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
          results.add(
            DateTime(
              cursor.year,
              cursor.month,
              cursor.day,
              baseTime.hour,
              baseTime.minute,
            ),
          );
          cursor = _addDays(cursor, 7);
        }

      case EventRecurrence.weeklyThursday:
        var cursor = _nextWeekday(fromDateTime, DateTime.thursday);
        for (var i = 0; i < count; i++) {
          results.add(
            DateTime(
              cursor.year,
              cursor.month,
              cursor.day,
              baseTime.hour,
              baseTime.minute,
            ),
          );
          cursor = _addDays(cursor, 7);
        }

      case EventRecurrence.biweekly:
        var cursor = fromDateTime;
        for (var i = 0; i < count; i++) {
          results.add(
            DateTime(
              cursor.year,
              cursor.month,
              cursor.day,
              baseTime.hour,
              baseTime.minute,
            ),
          );
          cursor = _addDays(cursor, 14);
        }

      case EventRecurrence.firstSundayOfMonth:
        results.addAll(
          _generateNthWeekdayOfMonths(
            fromDateTime: fromDateTime,
            weekday: DateTime.sunday,
            ordinal: 1,
            count: count,
            baseTime: baseTime,
          ),
        );

      case EventRecurrence.secondSundayOfMonth:
        results.addAll(
          _generateNthWeekdayOfMonths(
            fromDateTime: fromDateTime,
            weekday: DateTime.sunday,
            ordinal: 2,
            count: count,
            baseTime: baseTime,
          ),
        );

      case EventRecurrence.thirdSundayOfMonth:
        results.addAll(
          _generateNthWeekdayOfMonths(
            fromDateTime: fromDateTime,
            weekday: DateTime.sunday,
            ordinal: 3,
            count: count,
            baseTime: baseTime,
          ),
        );

      case EventRecurrence.lastSundayOfMonth:
        results.addAll(
          _generateNthWeekdayOfMonths(
            fromDateTime: fromDateTime,
            weekday: DateTime.sunday,
            ordinal: -1,
            count: count,
            baseTime: baseTime,
          ),
        );

      case EventRecurrence.monthly:
        var cursor = fromDateTime;
        for (var i = 0; i < count; i++) {
          results.add(
            DateTime(
              cursor.year,
              cursor.month,
              cursor.day,
              baseTime.hour,
              baseTime.minute,
            ),
          );
          final nextYear = cursor.year + (cursor.month == 12 ? 1 : 0);
          final nextMonth = cursor.month == 12 ? 1 : cursor.month + 1;
          final maxDays = DateTime(nextYear, nextMonth + 1, 0).day;
          final nextDay = cursor.day > maxDays ? maxDays : cursor.day;
          cursor = DateTime(nextYear, nextMonth, nextDay);
        }
    }

    return results;
  }

  /// Calendar-day arithmetic: adding 24 h multiples would land on the wrong
  /// day around a daylight saving change.
  static DateTime _addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  static DateTime _nextWeekday(DateTime from, int targetWeekday) {
    var cursor = DateTime(from.year, from.month, from.day);
    while (cursor.weekday != targetWeekday) {
      cursor = _addDays(cursor, 1);
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
        date = _addDays(date, 1);
      }
      date = _addDays(date, 7 * (ordinal - 1));
      return date;
    } else {
      final lastDay = DateTime(year, month + 1, 0).day;
      var date = DateTime(year, month, lastDay);
      while (date.weekday != weekday) {
        date = _addDays(date, -1);
      }
      return date;
    }
  }
}

/// Where an assignment stands, as the calendar shows it.
enum AssignmentStatus {
  /// The member accepted.
  confirmed,

  /// Waiting for the member to answer.
  scheduled,

  /// The member declined.
  declined,

  /// The member has an absence on the day of the service.
  away,
}

/// A role assignment of a member on a service (one `event_assignments` row).
class ServiceAssignment extends Equatable {
  const ServiceAssignment({
    required this.id,
    required this.memberId,
    required this.instrument,
    this.status = AssignmentStatus.scheduled,
    this.declineReason,
  });

  /// The assignment id.
  final String id;

  /// The organization member id.
  final String memberId;

  /// The stored instrument string (a [TeamRole] name for known roles).
  final String instrument;
  final AssignmentStatus status;
  final String? declineReason;

  /// The known role of [instrument], `null` for any other instrument.
  TeamRole? get role => TeamRole.fromInstrument(instrument);

  @override
  List<Object?> get props => [id, memberId, instrument, status, declineReason];
}

/// A service of the calendar: a real `calendar_events` row, or an occurrence
/// of a recurring schedule that has not been materialized yet
/// ([isProjected]).
class ServiceEvent extends Equatable {
  const ServiceEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    this.type = ServiceType.sundayService,
    this.recurrence = EventRecurrence.none,
    this.location,
    this.assignments = const [],
    this.notes,
    this.setlistId,
    this.seriesId,
    this.occurrenceDate,
    this.bandId,
    this.isProjected = false,
  });

  /// The event id; a synthetic one for projected occurrences.
  final String id;
  final String title;

  /// Local date and time.
  final DateTime dateTime;
  final ServiceType type;

  /// The cadence of the schedule this belongs to (`none` for one-off events).
  final EventRecurrence recurrence;
  final String? location;
  final List<ServiceAssignment> assignments;
  final String? notes;
  final String? setlistId;

  /// Identifier of the parent recurring schedule, if any.
  final String? seriesId;

  /// Calendar day of the schedule occurrence this service stands for.
  final DateTime? occurrenceDate;
  final String? bandId;

  /// True for an occurrence that is not a `calendar_events` row yet.
  final bool isProjected;

  /// Whether this service is today or later (by calendar day).
  bool get isUpcoming {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return !dateTime.isBefore(todayStart);
  }

  /// Formatted date string (e.g. "Sun, Nov 8" or "Dom, 8 nov").
  String get formattedDate {
    final isSpanish = Intl.defaultLocale?.startsWith('es') ?? false;
    if (isSpanish) {
      const monthsEs = [
        'ene',
        'feb',
        'mar',
        'abr',
        'may',
        'jun',
        'jul',
        'ago',
        'sep',
        'oct',
        'nov',
        'dic',
      ];
      const weekdaysEs = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      final weekday = weekdaysEs[dateTime.weekday - 1];
      final month = monthsEs[dateTime.month - 1];
      return '$weekday, ${dateTime.day} $month';
    }
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
      'Dec',
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

  @override
  List<Object?> get props => [
    id,
    title,
    dateTime,
    type,
    recurrence,
    location,
    assignments,
    notes,
    setlistId,
    seriesId,
    occurrenceDate,
    bandId,
    isProjected,
  ];
}
