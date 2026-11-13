/// Month-over-day stamp of a setlist's event date, shared by the Setlists
/// list and the setlist detail header.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Month over day, the way a calendar page shows the service date.
///
/// A setlist's `eventDate` is an instant (a `timestamptz` on the backend, a
/// local `DateTime` once read back). The stamp always shows its calendar day
/// in the device's time zone ([calendarDay]), so a value flagged as UTC
/// (e.g. `2026-11-08T02:00Z`) never shows the UTC day to someone west of UTC.
class SetlistDateStamp extends StatelessWidget {
  const SetlistDateStamp({required this.date, super.key, this.large = false});

  final DateTime date;

  /// Taller variant for the detail header (60 x 64 instead of 52 x 52).
  final bool large;

  /// The device-local calendar day of [date] (at midnight, local).
  static DateTime calendarDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final locale = Localizations.localeOf(context).toString();
    final day = calendarDay(date);
    final month = DateFormat.MMM(locale).format(day).toUpperCase();

    return Container(
      width: large ? 60 : 52,
      height: large ? 64 : 52,
      padding: const EdgeInsets.all(BattutaSpace.xs),
      decoration: BoxDecoration(
        color: brand.accentWash,
        borderRadius: large ? BorderRadius.circular(14) : BattutaRadius.smAll,
        border: Border.all(color: brand.accent.withValues(alpha: 0.35)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              month,
              style: theme.textTheme.labelSmall?.copyWith(
                color: brand.accentInk,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                height: 1.1,
              ),
            ),
            Text(
              '${day.day}',
              style:
                  (large
                          ? theme.textTheme.headlineSmall
                          : theme.textTheme.titleMedium)
                      ?.copyWith(
                        color: brand.accentInk,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
