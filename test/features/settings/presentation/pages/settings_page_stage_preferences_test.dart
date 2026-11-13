import 'dart:ui' show Tristate;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/theme/theme_provider.dart';
import 'package:battuta/core/services/device_preferences_storage.dart';
import 'package:battuta/features/settings/presentation/pages/settings_page.dart';
import 'package:battuta/features/settings/presentation/providers/stage_preferences_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/memory_storage.dart';

void main() {
  late MemoryStorage storage;
  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester, {
    double width = 390,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = Size(width, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    storage = MemoryStorage();
    container = ProviderContainer(
      overrides: [devicePreferencesStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the flats and awake rows toggle the saved preferences', (
    tester,
  ) async {
    await pump(tester);
    expect(container.read(stagePreferencesProvider).preferFlats, isFalse);
    expect(container.read(stagePreferencesProvider).keepScreenAwake, isTrue);

    await tester.tap(find.byKey(const ValueKey('prefer_flats_row')));
    await tester.pumpAndSettle();
    expect(container.read(stagePreferencesProvider).preferFlats, isTrue);
    expect(storage.values['battuta_prefer_flats'], 'true');

    await tester.tap(find.byKey(const ValueKey('keep_awake_row')));
    await tester.pumpAndSettle();
    expect(container.read(stagePreferencesProvider).keepScreenAwake, isFalse);
    expect(storage.values['battuta_keep_screen_awake'], 'false');
  });

  testWidgets('the rows are at least 44 pt tall and expose toggle state', (
    tester,
  ) async {
    await pump(tester);
    for (final key in ['prefer_flats_row', 'keep_awake_row']) {
      expect(
        tester.getSize(find.byKey(ValueKey(key))).height,
        greaterThanOrEqualTo(44),
      );
    }
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('keep_awake_row')),
    );
    expect(semantics.label, contains('Keep screen awake on stage'));
    expect(semantics.flagsCollection.isToggled, Tristate.isTrue);
  });

  testWidgets('the slider shows the percent and drives the scale', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('100%'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Chart text size')), findsWidgets);

    final slider = find.byKey(const ValueKey('chart_text_size_slider'));
    final rect = tester.getRect(slider);
    // Drag to the far right: 160%.
    await tester.dragFrom(
      Offset(rect.left + 24, rect.center.dy),
      Offset(rect.width, 0),
    );
    await tester.pumpAndSettle();
    expect(container.read(stagePreferencesProvider).chartTextScale, 1.6);
    expect(find.text('160%'), findsOneWidget);
    expect(storage.values['battuta_chart_text_scale'], '1.6');
  });

  testWidgets('the theme choice is saved', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Rehearsal'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(storage.values['battuta_theme_mode'], 'light');
  });

  for (final width in [320.0, 1180.0]) {
    testWidgets('new rows do not overflow at ${width.toInt()} wide', (
      tester,
    ) async {
      await pump(tester, width: width);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('keep_awake_row')), findsOneWidget);
    });
  }
}
