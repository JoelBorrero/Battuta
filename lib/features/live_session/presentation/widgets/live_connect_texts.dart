/// Battuta — localized messages for hosting and joining a Live session.
library;

import 'package:battuta/features/sync/domain/models/live_join_address.dart';
import 'package:battuta/features/sync/presentation/providers/live_sync_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';

/// The message for [issue]. English fallbacks keep widgets usable in tests
/// that mount without localization delegates.
String liveIssueText(AppLocalizations? l10n, LiveConnectIssue issue) =>
    switch (issue) {
      LiveConnectIssue.noNetwork =>
        l10n?.liveNoNetwork ??
            'Connect to Wi-Fi or turn on your hotspot to host',
      LiveConnectIssue.timeout => l10n?.liveConnectTimeout ?? 'The host did not answer in 5 seconds. Check that you are on the same Wi-Fi.',
      LiveConnectIssue.unreachable => l10n?.liveConnectUnreachable ?? 'Could not reach the host. Check the address and that the session is running.',
      LiveConnectIssue.hostFailed =>
        l10n?.liveHostFailed ?? 'Could not start hosting. Try again.',
    };

/// The message for a rejected typed address.
String liveAddressErrorText(AppLocalizations? l10n, LiveJoinAddressError e) =>
    switch (e) {
      LiveJoinAddressError.empty =>
        l10n?.liveAddressErrorEmpty ??
            'Enter the address shown on the host device.',
      LiveJoinAddressError.invalidHost =>
        l10n?.liveAddressErrorHost ??
            'That address is not valid. Use something like 192.168.1.20.',
      LiveJoinAddressError.invalidPort =>
        l10n?.liveAddressErrorPort ??
            'The port must be a number between 1 and 65535.',
      LiveJoinAddressError.invalidLink =>
        l10n?.liveAddressErrorLink ?? 'That is not a Battuta Live link.',
    };
