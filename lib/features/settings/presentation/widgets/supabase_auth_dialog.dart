/// Battuta — Supabase Authentication Dialog.
///
/// Stage-ready modal for Email/Password sign-in, account registration,
/// and passwordless Magic Link dispatch.
library;

import 'dart:async';

import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SupabaseAuthDialog extends ConsumerStatefulWidget {
  const SupabaseAuthDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const SupabaseAuthDialog(),
    );
  }

  @override
  ConsumerState<SupabaseAuthDialog> createState() => _SupabaseAuthDialogState();
}

class _SupabaseAuthDialogState extends ConsumerState<SupabaseAuthDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  Timer? _usernameDebounce;
  bool? _usernameAvailable;
  bool _checkingUsername = false;

  bool _isSignUp = false;
  bool _useMagicLink = false;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  static final _usernamePattern = RegExp(r'^[a-z0-9_.]{3,30}$');

  bool get _usernameWellFormed =>
      _usernamePattern.hasMatch(_usernameController.text.trim().toLowerCase());

  void _onUsernameChanged(String _) {
    _usernameDebounce?.cancel();
    setState(() => _usernameAvailable = null);
    if (!_usernameWellFormed) return;
    _usernameDebounce = Timer(
      const Duration(milliseconds: 400),
      _checkUsername,
    );
  }

  Future<void> _checkUsername() async {
    final username = _usernameController.text.trim().toLowerCase();
    setState(() => _checkingUsername = true);
    final available = await ref
        .read(authControllerProvider.notifier)
        .isUsernameAvailable(username);
    if (!mounted || username != _usernameController.text.trim().toLowerCase()) {
      return;
    }
    setState(() {
      _checkingUsername = false;
      _usernameAvailable = available;
    });
  }

  String? _usernameHelper(AppLocalizations? l10n) {
    if (_usernameController.text.isEmpty) {
      return l10n?.usernameHintHelper ??
          '3-30 characters: letters, numbers, _ or .';
    }
    if (!_usernameWellFormed) {
      return l10n?.usernameInvalidHelper ??
          'Use 3-30 characters: letters, numbers, _ or .';
    }
    if (_checkingUsername) return l10n?.usernameCheckingHelper ?? 'Checking...';
    return switch (_usernameAvailable) {
      true => l10n?.usernameAvailableHelper ?? 'Username is available',
      false => l10n?.usernameTakenHelper ?? 'Username is already taken',
      null => null,
    };
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();
    final l10n = AppLocalizations.of(context);

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    if (!_useMagicLink && password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    if (_isSignUp && !_useMagicLink) {
      if (!_usernameWellFormed) {
        setState(
          () => _errorMessage =
              l10n?.usernameInvalidError ??
              'Username must be 3-30 characters: letters, numbers, _ or .',
        );
        return;
      }
      final available = await ref
          .read(authControllerProvider.notifier)
          .isUsernameAvailable(_usernameController.text.trim().toLowerCase());
      if (!mounted) return;
      if (available == false) {
        setState(() {
          _usernameAvailable = false;
          _errorMessage =
              l10n?.usernameTakenError ?? 'That username is already taken.';
        });
        return;
      }
    }

    setState(() {
      _errorMessage = null;
      _statusMessage = null;
    });

    final notifier = ref.read(authControllerProvider.notifier);

    if (_useMagicLink) {
      final success = await notifier.sendMagicLink(email: email);
      if (mounted) {
        if (success) {
          setState(() {
            _statusMessage = 'Magic link sent! Check your inbox to sign in.';
          });
        } else {
          final err = ref.read(authControllerProvider).error;
          setState(
            () =>
                _errorMessage = err?.toString() ?? 'Failed to send magic link.',
          );
        }
      }
      return;
    }

    if (_isSignUp) {
      final success = await notifier.signUpWithEmailPassword(
        email: email,
        password: password,
        username: _usernameController.text.trim().toLowerCase(),
        displayName: name.isNotEmpty ? name : null,
      );
      if (mounted) {
        if (success) {
          final currentUser = ref.read(currentUserProvider);
          if (currentUser == null) {
            setState(() {
              _statusMessage = 'Account created! Please check your email to confirm your account.';
            });
          } else {
            Navigator.of(context).pop();
          }
        } else {
          final err = ref.read(authControllerProvider).error;
          setState(() => _errorMessage = err?.toString() ?? 'Sign up failed.');
        }
      }
    } else {
      final success = await notifier.signInWithEmailPassword(
        email: email,
        password: password,
      );
      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
        } else {
          final err = ref.read(authControllerProvider).error;
          setState(() => _errorMessage = err?.toString() ?? 'Sign in failed.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(
        _useMagicLink
            ? (l10n?.magicLinkSignInTitle ?? 'Magic Link Sign In')
            : _isSignUp
            ? (l10n?.createAccountTitle ?? 'Create Supabase Account')
            : (l10n?.signInTitle ?? 'Sign In to Supabase'),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (_statusMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _statusMessage!,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (_isSignUp && !_useMagicLink) ...[
                TextField(
                  key: const ValueKey('supabase_auth_name_field'),
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n?.fullNameLabel ?? 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
              ],
              if (_isSignUp && !_useMagicLink) ...[
                TextField(
                  key: const ValueKey('supabase_auth_username_field'),
                  controller: _usernameController,
                  onChanged: _onUsernameChanged,
                  decoration: InputDecoration(
                    labelText: l10n?.usernameLabel ?? 'Username',
                    helperText: _usernameHelper(l10n),
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
                key: const ValueKey('supabase_auth_email_field'),
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n?.emailAddressLabel ?? 'Email Address',
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
                  key: const ValueKey('supabase_auth_password_field'),
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n?.passwordLabel ?? 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleSubmit(),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _useMagicLink = !_useMagicLink;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _useMagicLink
                          ? (l10n?.usePasswordAction ?? 'Use Password')
                          : (l10n?.sendMagicLinkAction ?? 'Send Magic Link'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (!_useMagicLink)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                          _errorMessage = null;
                        });
                      },
                      child: Text(
                        _isSignUp
                            ? (l10n?.haveAccountSignInAction ??
                                  'Have an account? Sign In')
                            : (l10n?.newRegisterAction ?? 'New? Register'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          key: const ValueKey('supabase_auth_submit_btn'),
          onPressed: isLoading ? null : _handleSubmit,
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _useMagicLink
                      ? (l10n?.sendLinkAction ?? 'Send Link')
                      : _isSignUp
                      ? (l10n?.registerAction ?? 'Register')
                      : (l10n?.signInAction ?? 'Sign In'),
                ),
        ),
      ],
    );
  }
}
