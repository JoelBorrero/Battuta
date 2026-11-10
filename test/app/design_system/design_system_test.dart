import 'package:battuta/app/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {ThemeData? theme, bool reduceMotion = false}) {
  return MaterialApp(
    theme: theme,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('BattutaBrand', () {
    test('themes register the brand extension with the preserved palette', () {
      final dark = AppTheme.dark.extension<BattutaBrand>()!;
      final light = AppTheme.light.extension<BattutaBrand>()!;

      expect(dark.accent, AppTheme.amberAccent);
      expect(dark.canvas, AppTheme.slateBackground);
      expect(dark.card, AppTheme.slateSurface);
      expect(light.accent, AppTheme.amberAccent);
      expect(light.canvas, AppTheme.pearlBackground);
      expect(light.card, AppTheme.pureWhiteSurface);
      expect(light.border, AppTheme.pearlBorder);
      expect(light.ink, AppTheme.charcoalText);
    });

    testWidgets('of() falls back to brightness palette without extension', (
      tester,
    ) async {
      late BattutaBrand resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              resolved = BattutaBrand.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(resolved, same(BattutaBrand.dark));
    });

    test('lerp interpolates colors and copyWith overrides', () {
      final mid = BattutaBrand.dark.lerp(BattutaBrand.light, 0.5);
      expect(mid.canvas, isNot(BattutaBrand.dark.canvas));
      expect(mid.canvas, isNot(BattutaBrand.light.canvas));
      expect(BattutaBrand.dark.copyWith(accent: Colors.red).accent, Colors.red);
    });
  });

  group('BattutaMotion', () {
    testWidgets('resolve() collapses durations under reduced motion', (
      tester,
    ) async {
      late Duration resolved;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              resolved = BattutaMotion.resolve(context, BattutaMotion.bar);
              return const SizedBox();
            },
          ),
          reduceMotion: true,
        ),
      );
      expect(resolved, Duration.zero);
    });

    test('signature curves start at 0 and land at 1', () {
      for (final curve in [
        BattutaMotion.downbeat,
        BattutaMotion.upbeat,
        BattutaMotion.rebound,
        BattutaMotion.legato,
      ]) {
        expect(curve.transform(0), closeTo(0, 1e-6));
        expect(curve.transform(1), closeTo(1, 1e-6));
      }
    });
  });

  group('BattutaMark', () {
    testWidgets('renders static and mid-animation states', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              BattutaMark(size: 40),
              BattutaMark(size: 40, progress: 0.3),
              BattutaWordmark(progress: 0.7),
            ],
          ),
        ),
      );
      expect(find.byType(BattutaMark), findsNWidgets(3));
      expect(find.text('battuta'), findsOneWidget);
      expect(find.bySemanticsLabel('Battuta'), findsWidgets);
    });
  });

  group('BattutaEntrance', () {
    testWidgets('fades content in and settles fully visible', (tester) async {
      await tester.pumpWidget(
        _host(const BattutaEntrance(index: 3, child: Text('Hello'))),
      );
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('Hello'), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, lessThan(1));

      await tester.pumpAndSettle();
      final settled = tester.widget<Opacity>(
        find.ancestor(of: find.text('Hello'), matching: find.byType(Opacity)),
      );
      expect(settled.opacity, 1);
    });

    testWidgets('is immediately visible under reduced motion', (tester) async {
      await tester.pumpWidget(
        _host(const BattutaEntrance(child: Text('Now')), reduceMotion: true),
      );
      await tester.pump();
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('Now'), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 1);
    });
  });

  group('BattutaPressable', () {
    testWidgets('invokes onTap and scales while pressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Center(
            child: BattutaPressable(
              onTap: () => taps++,
              child: const SizedBox(width: 100, height: 50, child: Text('Go')),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Go')),
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        lessThan(1),
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    });

    testWidgets('does nothing when disabled', (tester) async {
      await tester.pumpWidget(
        _host(const BattutaPressable(onTap: null, child: Text('Off'))),
      );
      await tester.tap(find.text('Off'));
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    });
  });

  group('StageNavigation', () {
    const destinations = [
      StageDestination(
        icon: Icons.library_music_outlined,
        selectedIcon: Icons.library_music,
        label: 'Repertoire',
      ),
      StageDestination(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: 'Settings',
      ),
    ];

    testWidgets(
      'bar shows labels, filled icon for selection, and reports taps',
      (tester) async {
        int? tapped;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              bottomNavigationBar: StageNavigationBar(
                destinations: destinations,
                selectedIndex: 0,
                onSelected: (i) => tapped = i,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Repertoire'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.byIcon(Icons.library_music), findsOneWidget);
        expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        expect(tapped, 1);
      },
    );

    testWidgets('bar items meet the 44pt minimum touch target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StageNavigationBar(
              destinations: destinations,
              selectedIndex: 1,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byType(BattutaPressable).first);
      expect(size.height, greaterThanOrEqualTo(BattutaSpace.minTouchTarget));
      expect(size.width, greaterThanOrEqualTo(BattutaSpace.minTouchTarget));
    });

    testWidgets('rail shows brand mark and moves selection', (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Row(
                children: [
                  StageNavigationRail(
                    destinations: destinations,
                    selectedIndex: selected,
                    onSelected: (i) => setState(() => selected = i),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byType(BattutaMark), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(selected, 1);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });

  group('StageEmptyState', () {
    testWidgets('renders title, message and actions', (tester) async {
      await tester.pumpWidget(
        _host(
          StageEmptyState(
            icon: Icons.inbox,
            title: 'Nothing here',
            message: 'Add something',
            actions: [FilledButton(onPressed: () {}, child: const Text('Add'))],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Add something'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });
  });

  group('BrandIntro', () {
    testWidgets('plays once then reveals the app', (tester) async {
      await tester.pumpWidget(_host(const BrandIntro(child: Text('App'))));
      expect(find.byType(BattutaWordmark), findsOneWidget);
      expect(find.text('App'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(BattutaWordmark), findsNothing);
      expect(find.text('App'), findsOneWidget);
    });

    testWidgets('is skipped under reduced motion or when disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const BrandIntro(child: Text('App')), reduceMotion: true),
      );
      expect(find.byType(BattutaWordmark), findsNothing);

      await tester.pumpWidget(
        _host(const BrandIntro(enabled: false, child: Text('App 2'))),
      );
      expect(find.byType(BattutaWordmark), findsNothing);
    });
  });
}
