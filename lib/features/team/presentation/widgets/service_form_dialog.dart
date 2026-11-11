/// Create or edit a service, or edit a recurring schedule.
library;

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/features/organizations/domain/entities/schedule.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/services/service_calendar_builder.dart';
import 'package:battuta/features/team/presentation/providers/calendar_actions.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the form. With [event] it edits that service (a projected
/// occurrence becomes a real event on save); with [schedule] it edits the
/// recurring schedule; with neither it creates a service, optionally
/// repeating.
Future<void> showServiceFormDialog(
  BuildContext context, {
  ServiceEvent? event,
  RecurringSchedule? schedule,
}) => showDialog<void>(
  context: context,
  builder: (_) => _ServiceFormDialog(event: event, schedule: schedule),
);

const _lookaheadChoices = [4, 6, 12, 24];

class _ServiceFormDialog extends ConsumerStatefulWidget {
  const _ServiceFormDialog({this.event, this.schedule});

  final ServiceEvent? event;
  final RecurringSchedule? schedule;

  @override
  ConsumerState<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends ConsumerState<_ServiceFormDialog> {
  late final TextEditingController _title = TextEditingController(
    text: widget.event?.title ?? widget.schedule?.title ?? '',
  );
  late final TextEditingController _location = TextEditingController(
    text: widget.event?.location ?? widget.schedule?.location ?? '',
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.event?.notes ?? '',
  );

  late ServiceType _type =
      widget.event?.type ??
      (widget.schedule == null
          ? ServiceType.sundayService
          : widget.schedule!.serviceType);
  late EventRecurrence _recurrence =
      widget.schedule?.recurrence ?? EventRecurrence.none;
  late int _lookahead = widget.schedule?.lookaheadCount ?? 4;
  late DateTime _date = _initialDate();
  late TimeOfDay _time = _initialTime();
  String? _setlistId;
  bool _saving = false;
  String? _error;

  bool get _editsEvent => widget.event != null;
  bool get _editsSchedule => widget.schedule != null;
  bool get _repeating => _recurrence != EventRecurrence.none;
  bool get _showsDate => !_editsSchedule && !_repeating;

  DateTime _initialDate() {
    final event = widget.event;
    if (event != null) {
      return DateTime(
        event.dateTime.year,
        event.dateTime.month,
        event.dateTime.day,
      );
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  TimeOfDay _initialTime() {
    final event = widget.event;
    if (event != null) {
      return TimeOfDay(
        hour: event.dateTime.hour,
        minute: event.dateTime.minute,
      );
    }
    final minutes =
        widget.schedule?.minuteOfDay ?? RecurringSchedule.defaultMinuteOfDay;
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  @override
  void initState() {
    super.initState();
    _setlistId = widget.event?.setlistId;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = l10n.backendErrorInvalidName);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final actions = ref.read(calendarActionsProvider);
    final minuteOfDay = _time.hour * 60 + _time.minute;
    var success = '';
    final result = await () {
      if (_editsSchedule) {
        success = l10n.updatedServiceSuccess(title);
        return actions.updateSchedule(
          widget.schedule!,
          ScheduleDraft(
            title: title,
            recurrence: _recurrence,
            minuteOfDay: minuteOfDay,
            type: _type,
            lookaheadCount: _lookahead,
            location: _location.text,
          ),
        );
      }
      if (_repeating) {
        success = l10n.recurringScheduleSuccess(title, _lookahead);
        return actions.createSchedule(
          ScheduleDraft(
            title: title,
            recurrence: _recurrence,
            minuteOfDay: minuteOfDay,
            type: _type,
            lookaheadCount: _lookahead,
            location: _location.text,
          ),
        );
      }
      final draft = EventDraft(
        title: title,
        dateTime: DateTime(
          _date.year,
          _date.month,
          _date.day,
          _time.hour,
          _time.minute,
        ),
        type: _type,
        location: _location.text,
        notes: _notes.text,
        setlistId: _setlistId,
      );
      if (_editsEvent) {
        success = l10n.updatedServiceSuccess(title);
        return actions.updateEvent(widget.event!, draft);
      }
      success = l10n.scheduledServiceSuccess(title);
      return actions.createEvent(draft);
    }();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = backendErrorMessage(l10n, failure);
      }),
      (_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final organizationId = ref.watch(activeOrganizationIdProvider);
    final setlists = [
      for (final s in ref.watch(setlistsProvider).value ?? const [])
        if (s.organizationId != null && s.organizationId == organizationId) s,
    ];
    final linked = setlists.any((s) => s.id == _setlistId);

    return AlertDialog(
      title: Text(
        _editsSchedule
            ? l10n.editScheduleTitle
            : _editsEvent
            ? l10n.editServiceEvent
            : l10n.addServiceRehearsal,
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.event?.isProjected ?? false) ...[
                Text(
                  l10n.repeatingServiceNote,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                key: const ValueKey('service_title_field'),
                controller: _title,
                decoration: InputDecoration(
                  labelText: l10n.serviceTitleRequired,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ServiceType>(
                key: const ValueKey('service_type_field'),
                isExpanded: true,
                initialValue: _type,
                decoration: InputDecoration(
                  labelText: l10n.serviceTypeLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final type in ServiceType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.localizedName(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              if (!_editsEvent) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<EventRecurrence>(
                  key: const ValueKey('service_repeat_field'),
                  isExpanded: true,
                  initialValue: _recurrence,
                  decoration: InputDecoration(
                    labelText: l10n.repeatsLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final value in [
                      if (!_editsSchedule) EventRecurrence.none,
                      ...EventRecurrence.schedulable,
                      // A schedule created earlier with another cadence.
                      if (_editsSchedule &&
                          !EventRecurrence.schedulable.contains(_recurrence))
                        _recurrence,
                    ])
                      DropdownMenuItem(
                        value: value,
                        child: Text(
                          value == EventRecurrence.none
                              ? l10n.repeatNever
                              : value.localizedName(context),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _recurrence = value);
                  },
                ),
              ],
              if (_repeating && !_editsEvent) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: const ValueKey('service_lookahead_field'),
                  isExpanded: true,
                  initialValue: _lookahead,
                  items: [
                    for (final count in {..._lookaheadChoices, _lookahead})
                      DropdownMenuItem(
                        value: count,
                        child: Text(l10n.lookaheadOption(count)),
                      ),
                  ],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    if (value != null) setState(() => _lookahead = value);
                  },
                ),
              ],
              const SizedBox(height: 12),
              if (_showsDate) ...[
                OutlinedButton.icon(
                  key: const ValueKey('service_date_btn'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(44, 48),
                  ),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    MaterialLocalizations.of(context).formatMediumDate(_date),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: _pickDate,
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                key: const ValueKey('service_time_btn'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 48),
                ),
                icon: const Icon(Icons.access_time, size: 16),
                label: Text(_time.format(context)),
                onPressed: _pickTime,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('service_location_field'),
                controller: _location,
                decoration: InputDecoration(
                  labelText: l10n.locationVenueLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (!_editsSchedule && !_repeating) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('service_notes_field'),
                  controller: _notes,
                  decoration: InputDecoration(
                    labelText: l10n.callTimeInstructionsLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (setlists.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    key: const ValueKey('service_setlist_field'),
                    isExpanded: true,
                    initialValue: linked ? _setlistId : null,
                    decoration: InputDecoration(
                      labelText: l10n.setlistLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        child: Text(l10n.noSetlistOption),
                      ),
                      for (final s in setlists)
                        DropdownMenuItem<String?>(
                          value: s.id,
                          child: Text(s.title, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (value) => setState(() => _setlistId = value),
                  ),
                ],
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  key: const ValueKey('service_form_error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('service_save_btn'),
          onPressed: _saving ? null : _save,
          child: Text(
            _editsEvent || _editsSchedule
                ? l10n.saveChanges
                : l10n.createService,
          ),
        ),
      ],
    );
  }
}
