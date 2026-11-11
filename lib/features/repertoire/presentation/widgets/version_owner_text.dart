/// "Owned by ..." text for versions that belong to somebody else.
library;

import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';

/// "Owned by Grace", marking deactivated owners.
String ownedByText(AppLocalizations l10n, VersionOwnerLabel owner) {
  final name = owner.ownerName ?? l10n.ownerUnknown;
  return owner.ownerDeactivated
      ? l10n.ownedByDeactivated(name)
      : l10n.ownedByName(name);
}
