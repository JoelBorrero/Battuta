/// Battuta App — Root [MaterialApp.router] widget.
///
/// Configures theming, routing (via GoRouter), and any top-level
/// app observers. This widget sits directly below [ProviderScope]
/// in the widget tree.
library;

import 'package:battuta/app/config/app_constants.dart';
import 'package:battuta/app/localization/locale_provider.dart';
import 'package:battuta/app/routes/app_router.dart';
import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/app/theme/theme_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The root widget of the Battuta application.
///
/// Sets up [MaterialApp.router] with:
/// - GoRouter for declarative navigation
/// - Light and dark [ThemeData] from [AppTheme]
/// - System-default theme mode (respects OS setting)
/// - Internationalization (English & Spanish, default system language)
class BattutaApp extends ConsumerWidget {
  const BattutaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theming
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      // Localization
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // Routing
      routerConfig: router,
    );
  }
}
