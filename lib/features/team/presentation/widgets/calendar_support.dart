/// Small helpers shared by the Calendar widgets.
library;

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide Band;

/// The short localized name of a stored instrument string.
String instrumentLabel(BuildContext context, String instrument) =>
    TeamRole.fromInstrument(instrument)?.localizedShortName(context) ??
    instrument;

String statusLabel(AppLocalizations l10n, AssignmentStatus status) =>
    switch (status) {
      AssignmentStatus.confirmed => l10n.assignmentStatusAccepted,
      AssignmentStatus.scheduled => l10n.assignmentStatusPending,
      AssignmentStatus.declined => l10n.assignmentStatusDeclined,
      AssignmentStatus.away => l10n.assignmentStatusAway,
    };

IconData statusIcon(AssignmentStatus status) => switch (status) {
  AssignmentStatus.confirmed => Icons.check_circle_outline,
  AssignmentStatus.scheduled => Icons.schedule,
  AssignmentStatus.declined => Icons.person_off_outlined,
  AssignmentStatus.away => Icons.flight_takeoff_outlined,
};

Color statusColor(BuildContext context, AssignmentStatus status) {
  final brand = BattutaBrand.of(context);
  return switch (status) {
    AssignmentStatus.confirmed => AppTheme.stageGreen,
    AssignmentStatus.scheduled => brand.inkMuted,
    AssignmentStatus.declined => Theme.of(context).colorScheme.error,
    AssignmentStatus.away => brand.accentInk,
  };
}

/// Shows the failure of [result] (localized) or, on success, [success].
void reportResult(
  BuildContext context,
  Either<Failure, Unit> result, {
  String? success,
}) {
  final l10n = AppLocalizations.of(context)!;
  final message = result.fold(
    (failure) => backendErrorMessage(l10n, failure),
    (_) => success,
  );
  if (message == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Day and month of [date] as the stamp of a card (localized, upper case).
({String weekday, String month}) stampNames(BuildContext context, DateTime d) {
  final es = Localizations.localeOf(context).languageCode == 'es';
  const monthsEn = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC', //
  ];
  const monthsEs = [
    'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
    'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC', //
  ];
  const daysEn = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  const daysEs = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
  return (
    weekday: (es ? daysEs : daysEn)[d.weekday - 1],
    month: (es ? monthsEs : monthsEn)[d.month - 1],
  );
}

/// A flush, bordered pill used for statuses and tags.
class StatusTag extends StatelessWidget {
  const StatusTag({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.6)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ),
  );
}
