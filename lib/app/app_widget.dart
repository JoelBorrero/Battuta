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
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
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
/// - Automated background Supabase connection & synchronization on app launch
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
      _autoConnectAndSync();
    });
  }

  Future<void> _autoConnectAndSync() async {
    try {
      final clientManager = ref.read(supabaseClientManagerProvider);
      if (!clientManager.isInitialized) {
        await clientManager.initialize();
      }
      await ref.read(cloudSyncProvider.notifier).triggerSync();
    } catch (_) {
      // Invariant: Offline-first resilience; network/credential issues never crash startup
    }
  }

  @override
  Widget build(BuildContext context) {
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
