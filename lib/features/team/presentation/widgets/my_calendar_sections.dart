/// What the signed-in member does in the Calendar tab: answer their
/// assignments ("My services") and manage their absences ("My absences").
library;

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/presentation/providers/calendar_actions.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:battuta/features/team/presentation/widgets/calendar_support.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyServicesSection extends ConsumerWidget {
  const MyServicesSection({super.key});

  Future<void> _decline(
    BuildContext context,
    WidgetRef ref,
    MyService service,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _DeclineDialog(),
    );
    if (reason == null || !context.mounted) return;
    final result = await ref
        .read(calendarActionsProvider)
        .respond(
          service.assignment.id,
          AssignmentResponse.declined,
          declineReason: reason,
        );
    if (context.mounted) reportResult(context, result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final services = ref.watch(myServicesProvider);
    if (services.isEmpty) return const SizedBox.shrink();
    final materialLocalizations = MaterialLocalizations.of(context);

    return Container(
      key: const ValueKey('my_services_section'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: brand.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.myServicesTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          for (final service in services)
            Padding(
              key: ValueKey('my_service_${service.assignment.id}'),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.event.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${materialLocalizations.formatMediumDate(service.event.dateTime)}'
                    ' · ${materialLocalizations.formatTimeOfDay(TimeOfDay.fromDateTime(service.event.dateTime))}'
                    ' · ${instrumentLabel(context, service.assignment.instrument)}',
                    style: TextStyle(fontSize: 12, color: brand.inkMuted),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusTag(
                        label: statusLabel(l10n, service.assignment.status),
                        color: statusColor(context, service.assignment.status),
                      ),
                      if (service.assignment.status !=
                          AssignmentStatus.confirmed)
                        FilledButton(
                          key: ValueKey('accept_btn_${service.assignment.id}'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(44, 44),
                          ),
                          onPressed: () async {
                            final result = await ref
                                .read(calendarActionsProvider)
                                .respond(
                                  service.assignment.id,
                                  AssignmentResponse.accepted,
                                );
                            if (context.mounted) reportResult(context, result);
                          },
                          child: Text(l10n.acceptAssignmentAction),
                        ),
                      if (service.assignment.status !=
                          AssignmentStatus.declined)
                        OutlinedButton(
                          key: ValueKey('decline_btn_${service.assignment.id}'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(44, 44),
                          ),
                          onPressed: () => _decline(context, ref, service),
                          child: Text(l10n.declineAssignmentAction),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Asks for an optional reason; pops it (possibly empty), or nothing on cancel.
class _DeclineDialog extends StatefulWidget {
  const _DeclineDialog();

  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.declineAssignmentTitle),
      content: TextField(
        key: const ValueKey('decline_reason_field'),
        controller: _reason,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.declineReasonLabel,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('confirm_decline_btn'),
          onPressed: () => Navigator.of(context).pop(_reason.text),
          child: Text(l10n.declineAssignmentAction),
        ),
      ],
    );
  }
}

class MyAbsencesSection extends ConsumerWidget {
  const MyAbsencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final me = ref.watch(currentMemberProvider);
    if (me == null) return const SizedBox.shrink();
    final absences = ref.watch(myAbsencesProvider);
    final materialLocalizations = MaterialLocalizations.of(context);

    return Container(
      key: const ValueKey('my_absences_section'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: brand.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.myAbsencesTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                key: const ValueKey('add_absence_btn'),
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addAbsenceAction),
                onPressed: () => showAbsenceDialog(context),
              ),
            ],
          ),
          if (absences.isEmpty)
            Text(
              l10n.noAbsencesYet,
              style: TextStyle(fontSize: 12, color: brand.inkMuted),
            ),
          for (final absence in absences)
            Container(
              key: ValueKey('absence_${absence.id}'),
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.absenceRangeLabel(
                            materialLocalizations.formatMediumDate(
                              absence.startsOn,
                            ),
                            materialLocalizations.formatMediumDate(
                              absence.endsOn,
                            ),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (absence.note != null)
                          Text(
                            absence.note!,
                            style: TextStyle(
                              fontSize: 12,
                              color: brand.inkMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: ValueKey('absence_edit_${absence.id}'),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: l10n.editAbsenceAction,
                    onPressed: () =>
                        showAbsenceDialog(context, existing: absence),
                  ),
                  IconButton(
                    key: ValueKey('absence_delete_${absence.id}'),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    tooltip: l10n.deleteAbsenceAction,
                    onPressed: () async {
                      final result = await ref
                          .read(calendarActionsProvider)
                          .deleteAbsence(absence);
                      if (context.mounted) reportResult(context, result);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Adds an absence, or edits [existing].
Future<void> showAbsenceDialog(
  BuildContext context, {
  MemberAbsence? existing,
}) => showDialog<void>(
  context: context,
  builder: (_) => _AbsenceDialog(existing: existing),
);

class _AbsenceDialog extends ConsumerStatefulWidget {
  const _AbsenceDialog({this.existing});

  final MemberAbsence? existing;

  @override
  ConsumerState<_AbsenceDialog> createState() => _AbsenceDialogState();
}

class _AbsenceDialogState extends ConsumerState<_AbsenceDialog> {
  late DateTime _start =
      widget.existing?.startsOn ??
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  late DateTime _end = widget.existing?.endsOn ?? _start;
  late final TextEditingController _note = TextEditingController(
    text: widget.existing?.note ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime.now().subtract(const Duration(days: 365)),
    lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
  );

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_end.isBefore(_start)) {
      setState(() => _error = l10n.absenceEndBeforeStart);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(calendarActionsProvider)
        .saveAbsence(
          existing: widget.existing,
          startsOn: _start,
          endsOn: _end,
          note: _note.text,
        );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = backendErrorMessage(l10n, failure);
      }),
      (_) => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialLocalizations = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? l10n.addAbsenceAction
            : l10n.editAbsenceAction,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton(
              key: const ValueKey('absence_start_btn'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48)),
              onPressed: () async {
                final picked = await _pick(_start);
                if (picked == null) return;
                setState(() {
                  _start = picked;
                  if (_end.isBefore(_start)) _end = _start;
                });
              },
              child: Text(
                '${l10n.absenceFromLabel}: ${materialLocalizations.formatMediumDate(_start)}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('absence_end_btn'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48)),
              onPressed: () async {
                final picked = await _pick(_end);
                if (picked != null) setState(() => _end = picked);
              },
              child: Text(
                '${l10n.absenceToLabel}: ${materialLocalizations.formatMediumDate(_end)}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('absence_note_field'),
              controller: _note,
              decoration: InputDecoration(
                labelText: l10n.absenceNoteLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const ValueKey('absence_error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('absence_save_btn'),
          onPressed: _saving ? null : _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
