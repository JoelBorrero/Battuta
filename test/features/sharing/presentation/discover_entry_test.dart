import 'package:battuta/features/repertoire/presentation/widgets/repertoire_scope_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sharing_harness.dart';

void main() {
  testWidgets('signed in without an organization: Discover only', (
    tester,
  ) async {
    final h = SharingHarness(organizations: const []);
    await h.pump(tester, const Scaffold(body: RepertoireScopeBar()));

    expect(find.byKey(const ValueKey('discover_chip')), findsOneWidget);
    expect(find.byKey(const ValueKey('scope_mine')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('discover_chip')));
    await tester.pumpAndSettle();
    expect(h.location, 'discover');
  });

  testWidgets('with organizations it sits next to the scopes', (tester) async {
    final h = SharingHarness();
    await h.pump(tester, const Scaffold(body: RepertoireScopeBar()));

    expect(find.byKey(const ValueKey('scope_mine')), findsOneWidget);
    expect(find.byKey(const ValueKey('discover_chip')), findsOneWidget);
  });

  testWidgets('signed out there is nothing to discover', (tester) async {
    final h = SharingHarness(signedIn: false);
    await h.pump(tester, const Scaffold(body: RepertoireScopeBar()));
    expect(find.byKey(const ValueKey('discover_chip')), findsNothing);
  });

  for (final width in [320.0, 375.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${width.toInt()} px', (tester) async {
      final h = SharingHarness();
      await h.pump(
        tester,
        const Scaffold(body: RepertoireScopeBar()),
        width: width,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
