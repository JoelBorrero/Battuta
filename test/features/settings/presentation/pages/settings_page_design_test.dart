import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/settings/presentation/pages/settings_page.dart';
import 'package:battuta/features/workspace/domain/entities/workspace_usage.dart';
import 'package:battuta/features/workspace/presentation/providers/workspace_usage_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _usage = WorkspaceUsage(
  workspaceId: 'w',
  workspaceName: 'A Rather Long Workspace Name For Layout',
  tier: 'Pro',
  billingPeriod: '2026-11',
  geminiCreditsUsed: 1450,
  geminiCreditsLimit: 5000,
  geminiScansCount: 12,
  storageUsedBytes: 42 * 1024 * 1024,
  storageLimitBytes: 1024 * 1024 * 1024,
  filesUploadedCount: 30,
);

class _FixedUsage extends WorkspaceUsageNotifier {
  @override
  Future<WorkspaceUsage> build() async => _usage;
}

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required double width,
    double height = 900,
    ThemeMode mode = ThemeMode.dark,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isCurrentUserAdminProvider.overrideWithValue(true),
          workspaceUsageProvider.overrideWith(_FixedUsage.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 1180.0]) {
    testWidgets('lays out without overflow at ${width.toInt()} wide', (
      tester,
    ) async {
      await pump(tester, width: width);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('licenses_tile')),
        300,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('settings_version')), findsOneWidget);
    });
  }

  testWidgets('the usage card takes its colours from the brand in light', (
    tester,
  ) async {
    await pump(tester, width: 390, mode: ThemeMode.light);
    await tester.scrollUntilVisible(find.text('Gemini AI Credits'), 200);
    final brand = BattutaBrand.of(
      tester.element(find.byKey(const ValueKey('workspace_usage_card'))),
    );
    expect(brand.card, isNot(const Color(0xFF1E2024)));

    Color? colorOf(String text) =>
        tester.widget<Text>(find.text(text).first).style?.color;

    expect(colorOf('Gemini AI Credits'), brand.ink);
    expect(colorOf('ACTIVE WORKSPACE POOL'), brand.inkMuted);
    expect(colorOf('1450 / 5000 Credits'), brand.inkMuted);

    final bars = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .toList();
    expect(bars, hasLength(2));
    for (final bar in bars) {
      expect(bar.backgroundColor, brand.cardRaised);
    }
    expect(
      (bars.first.valueColor! as AlwaysStoppedAnimation<Color>).value,
      brand.accent,
    );
    expect(
      (bars.last.valueColor! as AlwaysStoppedAnimation<Color>).value,
      brand.info,
    );
  });

  testWidgets('the language row opens a picker and keeps the choice', (
    tester,
  ) async {
    await pump(tester, width: 390);
    expect(find.text('System'), findsNWidgets(2)); // theme + language value

    await tester.tap(find.byKey(const ValueKey('language_tile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('language_option_system')), findsOne);
    expect(find.byKey(const ValueKey('language_option_english')), findsOne);
    expect(find.byKey(const ValueKey('language_option_spanish')), findsOne);

    await tester.tap(find.byKey(const ValueKey('language_option_english')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('language_option_system')), findsNothing);
    expect(find.text('English'), findsOneWidget); // row value
  });
}
