/// Admin sheet to edit an organization's name and description.
library;

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the sheet; completes with `true` when the profile was saved.
Future<bool?> showEditOrganizationProfileSheet(
  BuildContext context, {
  required Organization organization,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => EditOrganizationProfileSheet(organization: organization),
);

class EditOrganizationProfileSheet extends ConsumerStatefulWidget {
  const EditOrganizationProfileSheet({required this.organization, super.key});

  final Organization organization;

  @override
  ConsumerState<EditOrganizationProfileSheet> createState() =>
      _EditOrganizationProfileSheetState();
}

class _EditOrganizationProfileSheetState
    extends ConsumerState<EditOrganizationProfileSheet> {
  static const int _maxName = 100;
  static const int _maxDescription = 280;

  late final _name = TextEditingController(text: widget.organization.name);
  late final _description = TextEditingController(
    text: widget.organization.description ?? '',
  );
  bool _saving = false;
  String? _nameError;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim();
    if (name.isEmpty || name.length > _maxName) {
      setState(() => _nameError = l10n.backendErrorInvalidName);
      return;
    }
    setState(() {
      _saving = true;
      _nameError = null;
      _error = null;
    });
    final result = await ref
        .read(organizationRepositoryProvider)
        .updateOrganizationProfile(
          widget.organization.id,
          name: name,
          description: _description.text,
        );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = backendErrorMessage(l10n, failure);
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.organizationEditTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('org_profile_name_field'),
              controller: _name,
              maxLength: _maxName,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              decoration: InputDecoration(
                labelText: l10n.organizationNameLabel,
                errorText: _nameError,
                counterText: '',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('org_profile_description_field'),
              controller: _description,
              maxLength: _maxDescription,
              minLines: 3,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: l10n.organizationDescriptionLabel,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const ValueKey('org_profile_error'),
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(44, 48)),
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  key: const ValueKey('org_profile_save_btn'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(44, 48),
                  ),
                  onPressed: _saving ? null : _save,
                  child: Text(l10n.saveChanges),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
