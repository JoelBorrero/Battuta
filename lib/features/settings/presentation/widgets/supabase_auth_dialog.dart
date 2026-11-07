/// Battuta — Supabase Authentication Dialog.
///
/// Stage-ready modal for Email/Password sign-in, account registration,
/// and passwordless Magic Link dispatch.
library;

import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
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

  bool _isSignUp = false;
  bool _useMagicLink = false;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    if (!_useMagicLink && password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
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
          setState(() => _errorMessage = err?.toString() ?? 'Failed to send magic link.');
        }
      }
      return;
    }

    if (_isSignUp) {
      final success = await notifier.signUpWithEmailPassword(
        email: email,
        password: password,
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

    return AlertDialog(
      title: Text(_useMagicLink
          ? 'Magic Link Sign In'
          : _isSignUp
              ? 'Create Supabase Account'
              : 'Sign In to Supabase'),
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
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                key: const ValueKey('supabase_auth_email_field'),
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
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
                      _useMagicLink ? 'Use Password' : 'Send Magic Link',
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
                        _isSignUp ? 'Have an account? Sign In' : 'New? Register',
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
          child: const Text('Cancel'),
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
              : Text(_useMagicLink
                  ? 'Send Link'
                  : _isSignUp
                      ? 'Register'
                      : 'Sign In'),
        ),
      ],
    );
  }
}
