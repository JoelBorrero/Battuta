/// Sign in with email + password (or a magic link).
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/auth/presentation/widgets/account_form.dart';
import 'package:battuta/features/auth/presentation/widgets/pending_invite_note.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// What the sign-in page opens with after an account was just created.
class SignInPrefill {
  const SignInPrefill({required this.email, this.accountCreated = false});

  final String email;

  /// The account was created and its email must be confirmed first.
  final bool accountCreated;
}

class SignInPage extends StatelessWidget {
  const SignInPage({this.prefill, super.key});

  final SignInPrefill? prefill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signInPageTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BattutaWordmark(height: 36)),
                  const SizedBox(height: 24),
                  const PendingInviteNote(),
                  AccountForm(
                    mode: AccountFormMode.signIn,
                    initialEmail: prefill?.email,
                    initialStatus: prefill?.accountCreated ?? false
                        ? l10n.authAccountCreatedConfirmThenSignIn
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const ValueKey('auth_switch_to_create_btn'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: () =>
                        context.pushReplacement(AppRoutes.createAccount),
                    child: Text(l10n.newRegisterAction),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
