/// Turns a backend [AppNotification] into a localized sentence, a relative
/// time and the place a tap leads to. Pure functions, no widgets.
library;

import 'package:battuta/features/organizations/domain/entities/notification.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// Where tapping a notification leads.
enum NotificationDestination {
  /// The invitation cards at the top of the inbox.
  invitations,

  /// The Roster of the notification's organization.
  roster,

  /// The Calendar of the notification's organization.
  calendar,

  /// The organization's settings page (where an archive request is answered).
  organization,

  /// A song version of mine.
  song,

  /// A song (the work) with all its versions; [songId] names it.
  songPage,

  /// A merge request I have to answer; [requestId] names it.
  mergeRequest,

  /// The repertoire (no version is known).
  repertoire,

  /// Nothing to open: the notification is only marked as read.
  none,
}

/// Where a tap leads and the ids needed to get there.
typedef NotificationTarget = ({
  NotificationDestination destination,
  String? versionId,
  String? songId,
  String? requestId,
});

NotificationTarget _target(
  NotificationDestination destination, {
  String? versionId,
  String? songId,
  String? requestId,
}) => (
  destination: destination,
  versionId: versionId,
  songId: songId,
  requestId: requestId,
);

/// Where [notification] leads, with the ids needed to get there.
NotificationTarget notificationTarget(AppNotification notification) {
  final payload = notification.payload;
  String? id(String key) =>
      payload[key] is String ? payload[key] as String : null;
  return switch (notification.type) {
    NotificationType.invitation => _target(NotificationDestination.invitations),
    NotificationType.roleChanged ||
    NotificationType.removed ||
    NotificationType.memberProfileEdited => _target(
      NotificationDestination.roster,
    ),
    NotificationType.eventAssigned ||
    NotificationType.eventUnassigned ||
    NotificationType.assignmentDeclined => _target(
      NotificationDestination.calendar,
    ),
    NotificationType.archiveRequested ||
    NotificationType.archiveCancelled ||
    NotificationType.archiveCompleted => _target(
      NotificationDestination.organization,
    ),
    // Somebody copied my version: the song shows it next to the copy.
    NotificationType.songVersionForked =>
      id('song_id') != null
          ? _target(NotificationDestination.songPage, songId: id('song_id'))
          : id('version_id') != null
          ? _target(NotificationDestination.song, versionId: id('version_id'))
          : _target(NotificationDestination.repertoire),
    // A merge request to answer.
    NotificationType.songMergeRequested =>
      id('request_id') != null
          ? _target(
              NotificationDestination.mergeRequest,
              requestId: id('request_id'),
            )
          : _target(NotificationDestination.repertoire),
    // The result: the surviving song (the target; the page follows merges).
    NotificationType.songMergeAccepted =>
      id('target_song_id') != null
          ? _target(
              NotificationDestination.songPage,
              songId: id('target_song_id'),
            )
          : _target(NotificationDestination.repertoire),
    NotificationType.songMergeDeclined => _target(
      NotificationDestination.repertoire,
    ),
    NotificationType.unknown => _target(NotificationDestination.none),
  };
}

/// Whether opening [destination] needs the notification's organization to
/// be one of mine.
bool destinationNeedsOrganization(NotificationDestination destination) =>
    switch (destination) {
      NotificationDestination.roster ||
      NotificationDestination.calendar ||
      NotificationDestination.organization => true,
      _ => false,
    };

String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// The sentence for [notification]. [organizationName] resolves an
/// organization id the payload does not name.
String notificationSentence(
  AppLocalizations l10n,
  AppNotification notification, {
  String? Function(String organizationId)? organizationName,
}) {
  final payload = notification.payload;
  final orgId = notification.organizationId;
  final organization =
      _text(payload['organization_name']) ??
      (orgId == null ? null : organizationName?.call(orgId)) ??
      l10n.notifOrganizationFallback;
  final event = _text(payload['event_title']) ?? l10n.notifEventFallback;

  final sentence = switch (notification.type) {
    NotificationType.invitation => l10n.notifInvitation(organization),
    NotificationType.roleChanged => l10n.notifRoleChanged(
      organization,
      OrganizationRole.parse(payload['new_role']) == OrganizationRole.admin
          ? l10n.adminRole
          : l10n.memberRoleLabel,
    ),
    NotificationType.removed => l10n.notifRemoved(organization),
    NotificationType.memberProfileEdited => l10n.notifMemberProfileEdited(
      organization,
      _changedFields(l10n, payload['changed_fields']),
    ),
    NotificationType.eventAssigned => l10n.notifEventAssigned(event),
    NotificationType.eventUnassigned => l10n.notifEventUnassigned(event),
    NotificationType.assignmentDeclined => l10n.notifAssignmentDeclined(event),
    NotificationType.archiveRequested => l10n.notifArchiveRequested(
      organization,
    ),
    NotificationType.archiveCancelled => l10n.notifArchiveCancelled(
      organization,
    ),
    NotificationType.archiveCompleted => l10n.notifArchiveCompleted(
      organization,
    ),
    NotificationType.songVersionForked => l10n.notifSongVersionForked,
    NotificationType.songMergeRequested => l10n.notifSongMergeRequested(
      _text(payload['source_title']) ?? '?',
      _text(payload['target_title']) ?? '?',
    ),
    NotificationType.songMergeAccepted => l10n.notifSongMergeAccepted,
    NotificationType.songMergeDeclined => l10n.notifSongMergeDeclined,
    NotificationType.unknown => l10n.notifUnknown,
  };
  // A fallback name ("your organization") can start the sentence.
  return toBeginningOfSentenceCase(sentence, l10n.localeName) ?? sentence;
}

String _changedFields(AppLocalizations l10n, Object? fields) {
  if (fields is! List) return l10n.notifFieldsFallback;
  final names = <String>[
    for (final field in fields)
      if (field is String)
        switch (field) {
          'instruments' => l10n.notifFieldInstruments,
          'min_pitch' => l10n.notifFieldMinPitch,
          'max_pitch' => l10n.notifFieldMaxPitch,
          'notes' => l10n.notifFieldNotes,
          _ => field,
        },
  ];
  return names.isEmpty ? l10n.notifFieldsFallback : names.join(', ');
}

/// "Just now", "5 min ago", "3 h ago", "2 d ago", then the date.
String relativeTime(
  AppLocalizations l10n,
  DateTime? at, {
  required DateTime now,
}) {
  if (at == null) return '';
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
  return DateFormat.yMMMd(l10n.localeName).format(at.toLocal());
}
