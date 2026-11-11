/// Create an account: name, username (checked live), email and password.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/auth/presentation/pages/sign_in_page.dart';
import 'package:battuta/features/auth/presentation/widgets/account_form.dart';
import 'package:battuta/features/auth/presentation/widgets/pending_invite_note.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateAccountPage extends StatelessWidget {
  const CreateAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createAccountPageTitle)),
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
                    mode: AccountFormMode.createAccount,
                    // Email confirmation pending: continue on the sign-in
                    // page with the email filled in.
                    onCreatedPendingConfirmation: (email) =>
                        context.pushReplacement(
                          AppRoutes.signIn,
                          extra: SignInPrefill(
                            email: email,
                            accountCreated: true,
                          ),
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const ValueKey('auth_switch_to_sign_in_btn'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: () => context.pushReplacement(AppRoutes.signIn),
                    child: Text(l10n.haveAccountSignInAction),
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
