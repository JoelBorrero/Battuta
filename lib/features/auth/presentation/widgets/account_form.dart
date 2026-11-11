/// Email / password form shared by the sign-in and create-account pages.
///
/// Sign in also offers a magic link and a password reset email. Create
/// account asks for a username and checks its availability while typing.
library;

import 'dart:async';

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/auth/presentation/providers/account_notice_provider.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum AccountFormMode { signIn, createAccount }

class AccountForm extends ConsumerStatefulWidget {
  const AccountForm({
    required this.mode,
    this.initialEmail,
    this.initialStatus,
    this.onCreatedPendingConfirmation,
    super.key,
  });

  final AccountFormMode mode;

  /// Pre-fills the email field (e.g. right after creating the account).
  final String? initialEmail;

  /// A status message shown above the fields when the form opens.
  final String? initialStatus;

  /// Called with the email when an account was created but needs its email
  /// confirmed before signing in. Without it the form shows a message.
  final ValueChanged<String>? onCreatedPendingConfirmation;

  @override
  ConsumerState<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<AccountForm> {
  static final _usernamePattern = RegExp(r'^[a-z0-9_.]{3,30}$');

  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _username = TextEditingController();
  Timer? _debounce;
  bool? _usernameAvailable;
  bool _checkingUsername = false;
  bool _useMagicLink = false;
  String? _error;
  late String? _status = widget.initialStatus;

  bool get _isCreate => widget.mode == AccountFormMode.createAccount;

  String get _normalizedUsername => _username.text.trim().toLowerCase();
  bool get _usernameWellFormed =>
      _usernamePattern.hasMatch(_normalizedUsername);

  @override
  void dispose() {
    _debounce?.cancel();
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String _) {
    _debounce?.cancel();
    setState(() {
      _usernameAvailable = null;
      _checkingUsername = false;
    });
    if (!_usernameWellFormed) return;
    _debounce = Timer(const Duration(milliseconds: 400), _checkUsername);
  }

  Future<void> _checkUsername() async {
    final username = _normalizedUsername;
    setState(() => _checkingUsername = true);
    final available = await ref
        .read(authControllerProvider.notifier)
        .isUsernameAvailable(username);
    if (!mounted || username != _normalizedUsername) return;
    setState(() {
      _checkingUsername = false;
      _usernameAvailable = available;
    });
  }

  String? _usernameHelper(AppLocalizations l10n) {
    if (_username.text.isEmpty) return l10n.usernameHintHelper;
    if (!_usernameWellFormed) return l10n.usernameInvalidHelper;
    if (_checkingUsername) return l10n.usernameCheckingHelper;
    return switch (_usernameAvailable) {
      true => l10n.usernameAvailableHelper,
      false => l10n.usernameTakenHelper,
      null => null,
    };
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = l10n.authInvalidEmail);
      return;
    }
    if (!_useMagicLink && password.length < 6) {
      setState(() => _error = l10n.authPasswordTooShort);
      return;
    }

    final notifier = ref.read(authControllerProvider.notifier);
    setState(() {
      _error = null;
      _status = null;
    });

    if (_useMagicLink) {
      final sent = await notifier.sendMagicLink(email: email);
      if (!mounted) return;
      setState(() {
        if (sent) {
          _status = l10n.authMagicLinkSent;
        } else {
          _error = backendErrorMessage(
            l10n,
            ref.read(authControllerProvider).error ?? '',
          );
        }
      });
      return;
    }

    if (_isCreate) {
      if (!_usernameWellFormed) {
        setState(() => _error = l10n.usernameInvalidError);
        return;
      }
      final available = await notifier.isUsernameAvailable(_normalizedUsername);
      if (!mounted) return;
      if (available == false) {
        setState(() {
          _usernameAvailable = false;
          _error = l10n.usernameTakenError;
        });
        return;
      }
      final name = _name.text.trim();
      final created = await notifier.signUpWithEmailPassword(
        email: email,
        password: password,
        username: _normalizedUsername,
        displayName: name.isEmpty ? null : name,
      );
      if (!mounted) return;
      if (!created) {
        _showFailure(l10n);
      } else if (ref.read(authRepositoryProvider).currentUser == null) {
        // No session: the server wants the email confirmed first.
        final onPending = widget.onCreatedPendingConfirmation;
        if (onPending != null) {
          onPending(email);
        } else {
          setState(() => _status = l10n.authAccountCreatedCheckEmail);
        }
      } else {
        _enterApp();
      }
      return;
    }

    final signedIn = await notifier.signInWithEmailPassword(
      email: email,
      password: password,
    );
    if (!mounted) return;
    if (signedIn) {
      _enterApp();
    } else {
      _showFailure(l10n);
    }
  }

  /// Signed in: leave the account pages for the app. The cached user is
  /// refreshed first (the auth stream may not have emitted yet), and `go`
  /// replaces the whole stack, so a sign-in opened from Settings does not
  /// stay on top or leave a back arrow behind. The router redirect still
  /// sends a pending invite to its join page.
  void _enterApp() {
    ref.read(accountNoticeProvider.notifier).clear();
    ref.invalidate(currentUserProvider);
    GoRouter.maybeOf(context)?.go(AppRoutes.initial);
  }

  /// Shows the failure of the last auth call; a taken username (race between
  /// the check and the submit) is marked on the field.
  void _showFailure(AppLocalizations l10n) {
    final error = ref.read(authControllerProvider).error ?? '';
    setState(() {
      _error = backendErrorMessage(l10n, error);
      if (error is Failure &&
          error.errorCode == BackendErrorCode.usernameTaken) {
        _usernameAvailable = false;
      }
    });
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = l10n.authInvalidEmail);
      return;
    }
    final sent = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(email: email);
    if (!mounted) return;
    setState(() {
      _error = sent
          ? null
          : backendErrorMessage(
              l10n,
              ref.read(authControllerProvider).error ?? '',
            );
      if (sent) _status = l10n.authPasswordResetSent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final loading = ref.watch(authControllerProvider).isLoading;
    final notice = ref.watch(accountNoticeProvider);

    final submitLabel = _useMagicLink
        ? l10n.sendLinkAction
        : _isCreate
        ? l10n.createAccountPageTitle
        : l10n.signInAction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (notice == AccountNotice.deactivated)
          _Message(
            key: const ValueKey('auth_deactivated_message'),
            text: l10n.accountDeactivatedNotice,
            color: theme.colorScheme.error,
          ),
        if (_error != null)
          _Message(
            key: const ValueKey('auth_error_message'),
            text: _error!,
            color: theme.colorScheme.error,
          ),
        if (_status != null)
          _Message(
            key: const ValueKey('auth_status_message'),
            text: _status!,
            color: theme.colorScheme.primary,
          ),
        if (_isCreate) ...[
          TextField(
            key: const ValueKey('auth_name_field'),
            controller: _name,
            decoration: InputDecoration(
              labelText: l10n.fullNameLabel,
              prefixIcon: const Icon(Icons.person_outline),
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('auth_username_field'),
            controller: _username,
            onChanged: _onUsernameChanged,
            decoration: InputDecoration(
              labelText: l10n.usernameLabel,
              helperText: _usernameHelper(l10n),
              helperMaxLines: 2,
              helperStyle: TextStyle(
                color: _usernameAvailable == false
                    ? theme.colorScheme.error
                    : null,
              ),
              prefixIcon: const Icon(Icons.alternate_email),
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          key: const ValueKey('auth_email_field'),
          controller: _email,
          decoration: InputDecoration(
            labelText: l10n.emailAddressLabel,
            prefixIcon: const Icon(Icons.email_outlined),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: _useMagicLink
              ? TextInputAction.done
              : TextInputAction.next,
        ),
        if (!_useMagicLink) ...[
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('auth_password_field'),
            controller: _password,
            decoration: InputDecoration(
              labelText: l10n.passwordLabel,
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
            ),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          key: const ValueKey('auth_submit_btn'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: loading ? null : _submit,
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(submitLabel),
        ),
        if (!_isCreate) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 4,
            children: [
              TextButton(
                key: const ValueKey('auth_magic_link_toggle'),
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                onPressed: () => setState(() {
                  _useMagicLink = !_useMagicLink;
                  _error = null;
                }),
                child: Text(
                  _useMagicLink
                      ? l10n.usePasswordAction
                      : l10n.sendMagicLinkAction,
                ),
              ),
              if (!_useMagicLink)
                TextButton(
                  key: const ValueKey('auth_forgot_password_btn'),
                  style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                  onPressed: loading ? null : _resetPassword,
                  child: Text(l10n.forgotPasswordAction),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.color, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
    ),
  );
}
