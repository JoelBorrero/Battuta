/// Battuta App — Root [MaterialApp.router] widget.
///
/// Configures theming, routing (via GoRouter), and any top-level
/// app observers. This widget sits directly below [ProviderScope]
/// in the widget tree.
library;

import 'package:battuta/app/account_lifecycle.dart';
import 'package:battuta/app/config/app_constants.dart';
import 'package:battuta/app/design_system/brand/brand_intro.dart';
import 'package:battuta/app/localization/locale_provider.dart';
import 'package:battuta/app/routes/app_router.dart';
import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/app/theme/theme_provider.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
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
/// - A one-shot brand intro (the "downbeat") over the first frame
/// - Supabase connection on launch; the data layer starts on sign-in
///   (see `accountLifecycleProvider`)
class BattutaApp extends ConsumerStatefulWidget {
  const BattutaApp({super.key});

  @override
  ConsumerState<BattutaApp> createState() => _BattutaAppState();
}

class _BattutaAppState extends ConsumerState<BattutaApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connect();
    });
  }

  Future<void> _connect() async {
    try {
      final clientManager = ref.read(supabaseClientManagerProvider);
      if (!clientManager.isInitialized) {
        await clientManager.initialize();
      }
    } catch (_) {
      // Invariant: Offline-first resilience; network/credential issues never crash startup
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(accountLifecycleProvider);
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

      // Brand intro plays once over the first route.
      builder: (context, child) => BrandIntro(child: child ?? const SizedBox()),
    );
  }
}
