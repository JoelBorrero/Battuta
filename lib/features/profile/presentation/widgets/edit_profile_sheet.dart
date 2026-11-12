/// Bottom sheet that edits my display name and username. The username is
/// checked live (my current one counts as available); a failure keeps the
/// sheet open with the reason.
library;

import 'dart:async';

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the sheet; completes with `true` when the profile was saved.
Future<bool?> showEditProfileSheet(
  BuildContext context, {
  required UserProfile profile,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => EditProfileSheet(profile: profile),
);

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  static final _usernamePattern = RegExp(r'^[a-z0-9_.]{3,30}$');

  late final _name = TextEditingController(text: widget.profile.displayName);
  late final _username = TextEditingController(text: widget.profile.username);
  Timer? _debounce;
  bool _checking = false;
  bool? _usernameAvailable;
  bool _saving = false;
  String? _nameError;
  String? _error;

  String get _normalized => _username.text.trim().toLowerCase();
  bool get _wellFormed => _usernamePattern.hasMatch(_normalized);
  bool get _isCurrent => _normalized == widget.profile.username.toLowerCase();

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String _) {
    _debounce?.cancel();
    setState(() {
      _usernameAvailable = null;
      _checking = false;
      _error = null;
    });
    if (!_wellFormed) return;
    if (_isCurrent) {
      setState(() => _usernameAvailable = true);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), _check);
  }

  Future<void> _check() async {
    final username = _normalized;
    setState(() => _checking = true);
    final available = await ref
        .read(authControllerProvider.notifier)
        .isUsernameAvailable(username);
    if (!mounted || username != _normalized) return;
    setState(() {
      _checking = false;
      _usernameAvailable = available;
    });
  }

  String? _usernameHelper(AppLocalizations l10n) {
    if (_username.text.isEmpty) return l10n.usernameHintHelper;
    if (!_wellFormed) return l10n.usernameInvalidHelper;
    if (_checking) return l10n.usernameCheckingHelper;
    return switch (_usernameAvailable) {
      true => l10n.usernameAvailableHelper,
      false => l10n.usernameTakenHelper,
      null => null,
    };
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim();
    if (name.isEmpty || name.length > 80) {
      setState(() => _nameError = l10n.profileDisplayNameInvalid);
      return;
    }
    if (!_wellFormed) {
      setState(() => _error = l10n.usernameInvalidError);
      return;
    }
    setState(() {
      _saving = true;
      _nameError = null;
      _error = null;
    });
    final notifier = ref.read(authControllerProvider.notifier);
    if (!_isCurrent) {
      final available = await notifier.isUsernameAvailable(_normalized);
      if (!mounted) return;
      if (available == false) {
        setState(() {
          _saving = false;
          _usernameAvailable = false;
          _error = l10n.usernameTakenError;
        });
        return;
      }
    }
    final result = await notifier.updateMyProfile(
      displayName: name,
      username: _normalized,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = backendErrorMessage(l10n, failure);
        if (failure.errorCode == BackendErrorCode.usernameTaken) {
          _usernameAvailable = false;
        }
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final taken = _usernameAvailable == false;

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
              l10n.profileEditAction,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('profile_name_field'),
              controller: _name,
              maxLength: 80,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              decoration: InputDecoration(
                labelText: l10n.profileDisplayNameLabel,
                errorText: _nameError,
                counterText: '',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('profile_username_field'),
              controller: _username,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onChanged: _onUsernameChanged,
              onSubmitted: (_) => _saving ? null : _save(),
              decoration: InputDecoration(
                labelText: l10n.usernameLabel,
                prefixText: '@',
                helperText: _usernameHelper(l10n),
                helperMaxLines: 2,
                helperStyle: TextStyle(
                  color: taken ? theme.colorScheme.error : null,
                ),
                errorText: taken ? l10n.usernameTakenError : null,
                errorMaxLines: 2,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null && !taken) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const ValueKey('profile_edit_error'),
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
                  key: const ValueKey('profile_save_btn'),
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
