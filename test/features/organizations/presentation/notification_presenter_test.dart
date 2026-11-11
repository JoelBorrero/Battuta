import 'package:battuta/features/organizations/domain/entities/notification.dart';
import 'package:battuta/features/organizations/presentation/notifications/notification_presenter.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

AppNotification note(
  NotificationType type, {
  Map<String, dynamic> payload = const {},
  String? orgId = 'org-1',
}) => AppNotification(
  id: 'n-${type.name}',
  recipientId: 'u-me',
  type: type,
  organizationId: orgId,
  payload: payload,
);

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    final l10n = lookupAppLocalizations(locale);

    test('every NotificationType has a sentence in ${locale.languageCode}', () {
      final sentences = <String>{};
      for (final type in NotificationType.values) {
        final sentence = notificationSentence(l10n, note(type));
        expect(sentence.trim(), isNotEmpty, reason: type.name);
        sentences.add(sentence);
      }
      // Distinct types do not collapse into one generic line.
      expect(sentences.length, greaterThan(NotificationType.values.length - 4));
    });
  }

  final en = lookupAppLocalizations(const Locale('en'));

  test('uses payload data and organization lookups', () {
    expect(
      notificationSentence(
        en,
        note(
          NotificationType.roleChanged,
          payload: {'organization_name': 'Grace', 'new_role': 'admin'},
        ),
      ),
      'Your role in Grace is now Admin',
    );
    expect(
      notificationSentence(
        en,
        note(NotificationType.archiveCompleted, payload: {}),
        organizationName: (id) => id == 'org-1' ? 'Grace' : null,
      ),
      'Grace was archived',
    );
    expect(
      notificationSentence(
        en,
        note(
          NotificationType.eventAssigned,
          payload: {'event_title': 'Sunday service'},
        ),
      ),
      'You were assigned to Sunday service',
    );
    expect(
      notificationSentence(
        en,
        note(
          NotificationType.memberProfileEdited,
          payload: {
            'organization_name': 'Grace',
            'changed_fields': ['instruments', 'min_pitch'],
          },
        ),
      ),
      'An admin updated your profile in Grace: instruments, lowest note',
    );
  });

  test('an unknown organization falls back to a capitalised phrase', () {
    expect(
      notificationSentence(en, note(NotificationType.archiveCompleted)),
      'Your organization was archived',
    );
  });

  test('unknown types get the generic line', () {
    final n = AppNotification.fromJson({
      'id': 'n1',
      'recipient_id': 'u',
      'type': 'something_new',
    });
    expect(n.type, NotificationType.unknown);
    expect(notificationSentence(en, n), 'You have a new notification');
  });

  group('notificationTarget', () {
    test('routes every type', () {
      NotificationDestination of(NotificationType t, [Map<String, dynamic>? p]) =>
          notificationTarget(note(t, payload: p ?? const {})).destination;
      expect(of(NotificationType.invitation), NotificationDestination.invitations);
      expect(of(NotificationType.roleChanged), NotificationDestination.roster);
      expect(of(NotificationType.removed), NotificationDestination.roster);
      expect(
        of(NotificationType.memberProfileEdited),
        NotificationDestination.roster,
      );
      expect(of(NotificationType.eventAssigned), NotificationDestination.calendar);
      expect(
        of(NotificationType.eventUnassigned),
        NotificationDestination.calendar,
      );
      expect(
        of(NotificationType.assignmentDeclined),
        NotificationDestination.calendar,
      );
      expect(
        of(NotificationType.archiveRequested),
        NotificationDestination.organization,
      );
      expect(
        of(NotificationType.songVersionForked, {'version_id': 'v1'}),
        NotificationDestination.song,
      );
      expect(
        of(NotificationType.songMergeRequested),
        NotificationDestination.repertoire,
      );
      expect(of(NotificationType.unknown), NotificationDestination.none);
    });

    test('a fork carries the version to open', () {
      final target = notificationTarget(
        note(NotificationType.songVersionForked, payload: {'version_id': 'v1'}),
      );
      expect(target.versionId, 'v1');
    });
  });

  test('relativeTime picks the unit', () {
    final now = DateTime(2026, 11, 11, 12);
    expect(relativeTime(en, now, now: now), 'Just now');
    expect(
      relativeTime(en, now.subtract(const Duration(minutes: 5)), now: now),
      '5 min ago',
    );
    expect(
      relativeTime(en, now.subtract(const Duration(hours: 3)), now: now),
      '3 h ago',
    );
    expect(
      relativeTime(en, now.subtract(const Duration(days: 2)), now: now),
      '2 d ago',
    );
    expect(relativeTime(en, null, now: now), '');
  });
}
