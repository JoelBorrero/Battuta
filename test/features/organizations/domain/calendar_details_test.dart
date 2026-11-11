import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/organizations/domain/entities/json_helpers.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calendar detail columns', () {
    test('CalendarEvent reads and writes type, setlist and occurrence', () {
      final event = CalendarEvent.fromJson({
        'id': 'e1',
        'organization_id': 'o1',
        'title': 'Sunday',
        'date_time': '2026-11-15T14:30:00Z',
        'event_type': 'rehearsal',
        'setlist_id': 'set-1',
        'series_id': 's1',
        'occurrence_date': '2026-11-15',
      });
      expect(event.eventType, 'rehearsal');
      expect(event.setlistId, 'set-1');
      expect(event.seriesId, 's1');
      expect(event.occurrenceDate, DateTime(2026, 11, 15));
      final json = event.toWriteJson();
      expect(json['event_type'], 'rehearsal');
      expect(json['setlist_id'], 'set-1');
      expect(json['series_id'], 's1');
      expect(json['occurrence_date'], '2026-11-15');
      expect(CalendarEvent.fromJson(event.toJson()), event);
    });

    test('rows cached before the columns existed read with defaults', () {
      final event = CalendarEvent.fromJson({
        'id': 'e1',
        'organization_id': 'o1',
        'title': 'Old',
        'date_time': '2026-11-15T14:30:00Z',
      });
      expect(event.eventType, CalendarEvent.defaultEventType);
      expect(event.setlistId, isNull);
      expect(event.seriesId, isNull);
      expect(event.occurrenceDate, isNull);
      expect(event.toWriteJson()['occurrence_date'], isNull);
    });

    test('copyWith clears optional values explicitly', () {
      final event = CalendarEvent(
        id: 'e1',
        organizationId: 'o1',
        title: 'T',
        dateTime: DateTime.utc(2026, 11, 15),
        location: 'Hall',
        notes: 'n',
        setlistId: 'set-1',
        seriesId: 's1',
        occurrenceDate: DateTime(2026, 11, 15),
      );
      final cleared = event.copyWith(
        clearLocation: true,
        clearNotes: true,
        clearSetlist: true,
      );
      expect(cleared.location, isNull);
      expect(cleared.notes, isNull);
      expect(cleared.setlistId, isNull);
      expect(cleared.seriesId, 's1');
      expect(cleared.occurrenceDate, DateTime(2026, 11, 15));
    });

    test('RecurringSchedule reads and writes time, place and type', () {
      final schedule = RecurringSchedule.fromJson({
        'id': 's1',
        'organization_id': 'o1',
        'title': 'Sunday',
        'time_of_day': '10:30:00',
        'location': 'Main hall',
        'event_type': 'midweek',
      });
      expect(schedule.minuteOfDay, 10 * 60 + 30);
      expect(schedule.location, 'Main hall');
      expect(schedule.eventType, 'midweek');
      final json = schedule.toWriteJson();
      expect(json['time_of_day'], '10:30:00');
      expect(json['location'], 'Main hall');
      expect(json['event_type'], 'midweek');
      expect(RecurringSchedule.fromJson(schedule.toJson()), schedule);
    });

    test('RecurringSchedule defaults match the column defaults', () {
      final schedule = RecurringSchedule.fromJson({
        'id': 's1',
        'organization_id': 'o1',
        'title': 'Sunday',
      });
      expect(schedule.minuteOfDay, 9 * 60);
      expect(schedule.eventType, 'sundayService');
      expect(schedule.location, isNull);
    });

    test('time of day parsing and formatting', () {
      expect(parseTimeOfDay('09:05'), 545);
      expect(parseTimeOfDay('23:59:59'), 23 * 60 + 59);
      expect(parseTimeOfDay(null), 540);
      expect(parseTimeOfDay('nonsense'), 540);
      expect(formatTimeOfDay(0), '00:00:00');
      expect(formatTimeOfDay(23 * 60 + 59), '23:59:00');
    });
  });

  group('unique violations', () {
    test('23505 without a documented code is a conflict', () {
      final code = BackendErrorCode.fromMessage(
        'duplicate key value violates unique constraint "calendar_events_occurrence_key"',
        sqlState: '23505',
      );
      expect(code, BackendErrorCode.conflict);
      expect(code.failure().errorCode, BackendErrorCode.conflict);
    });

    test('a documented code wins over the SQLSTATE', () {
      expect(
        BackendErrorCode.fromMessage('username_taken', sqlState: '23505'),
        BackendErrorCode.usernameTaken,
      );
    });
  });
}
