/// The month grid of the Calendar tab: a bordered card with the month
/// navigation, the weekday initials and one 44 pt cell per day.
library;

import 'package:battuta/app/design_system/motion/pressable.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/app/theme/battuta_tokens.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// The date-only (local) form of [d].
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Day cells of [month] laid out in whole weeks that start on
/// [firstDayOfWeek] (0 = Sunday ... 6 = Saturday, as in
/// `MaterialLocalizations.firstDayOfWeekIndex`). Cells outside the month
/// are `null`.
List<DateTime?> monthCells(DateTime month, int firstDayOfWeek) {
  final first = DateTime(month.year, month.month);
  final days = DateTime(month.year, month.month + 1, 0).day;
  final leading = (first.weekday % 7 - firstDayOfWeek + 7) % 7;
  final total = ((leading + days) / 7).ceil() * 7;
  return [
    for (var i = 0; i < total; i++)
      if (i >= leading && i < leading + days)
        DateTime(month.year, month.month, i - leading + 1)
      else
        null,
  ];
}

class MonthGrid extends StatelessWidget {
  const MonthGrid({
    required this.month,
    required this.today,
    required this.selected,
    required this.markedDays,
    required this.onSelect,
    required this.onPreviousMonth,
    required this.onNextMonth,
    super.key,
  });

  /// Any day of the month shown.
  final DateTime month;
  final DateTime today;
  final DateTime selected;

  /// Date-only days that carry a dot (they have services).
  final Set<DateTime> markedDays;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  /// Height of a day cell (the touch target).
  static const double cellHeight = 44;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brand = BattutaBrand.of(context);
    final material = MaterialLocalizations.of(context);
    final first = material.firstDayOfWeekIndex;
    final cells = monthCells(month, first);
    final todayDate = dateOnly(today);
    final selectedDate = dateOnly(selected);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  key: const ValueKey('month_prev_btn'),
                  constraints: const BoxConstraints(
                    minWidth: BattutaSpace.minTouchTarget,
                    minHeight: BattutaSpace.minTouchTarget,
                  ),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: l10n.previousMonthTooltip,
                  onPressed: onPreviousMonth,
                ),
                Expanded(
                  child: Text(
                    material.formatMonthYear(month),
                    key: const ValueKey('month_title'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: brand.ink,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('month_next_btn'),
                  constraints: const BoxConstraints(
                    minWidth: BattutaSpace.minTouchTarget,
                    minHeight: BattutaSpace.minTouchTarget,
                  ),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: l10n.nextMonthTooltip,
                  onPressed: onNextMonth,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Text(
                        material.narrowWeekdays[(first + i) % 7],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: brand.inkMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            for (var week = 0; week < cells.length ~/ 7; week++) ...[
              if (week > 0) const SizedBox(height: 2),
              SizedBox(
                height: cellHeight,
                child: Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: switch (cells[week * 7 + i]) {
                          final day? => _DayCell(
                            day: day,
                            isToday: day == todayDate,
                            isSelected: day == selectedDate,
                            isPast: day.isBefore(todayDate),
                            hasServices: markedDays.contains(day),
                            onTap: () => onSelect(day),
                          ),
                          null => const SizedBox.shrink(),
                        },
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isPast,
    required this.hasServices,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool isPast;
  final bool hasServices;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final material = MaterialLocalizations.of(context);
    final foreground = isSelected
        ? brand.onAccent
        : (isPast ? brand.inkMuted : brand.ink);
    final emphasized = isSelected || isToday;
    final stamp =
        '${day.year}-${day.month.toString().padLeft(2, '0')}'
        '-${day.day.toString().padLeft(2, '0')}';

    return Semantics(
      selected: isSelected,
      child: BattutaPressable(
        key: ValueKey('month_day_$stamp'),
        onTap: onTap,
        pressedScale: 0.92,
        semanticLabel: material.formatFullDate(day),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? brand.accent : Colors.transparent,
                  border: isToday
                      ? Border.all(color: brand.accent, width: 1.5)
                      : null,
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                key: hasServices ? ValueKey('month_dot_$stamp') : null,
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasServices
                      ? (isSelected ? brand.ink : brand.accent)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
