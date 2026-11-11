/// Sign in with email + password (or a magic link).
library;

import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/auth/presentation/widgets/account_form.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

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
                  const AccountForm(mode: AccountFormMode.signIn),
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
