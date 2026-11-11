/// Localized names and icons of a version's visibility.
library;

import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// "Private", "Organizations" or "Public".
String visibilityBadgeText(AppLocalizations l10n, SongVisibility visibility) =>
    switch (visibility) {
      SongVisibility.private => l10n.visibilityPrivate,
      SongVisibility.organizations => l10n.visibilityOrganizations,
      SongVisibility.public => l10n.visibilityPublic,
    };

IconData visibilityIcon(SongVisibility visibility) => switch (visibility) {
  SongVisibility.private => Icons.lock_outline,
  SongVisibility.organizations => Icons.groups_outlined,
  SongVisibility.public => Icons.public,
};
