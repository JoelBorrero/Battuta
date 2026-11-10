/// Battuta — Page transitions.
///
/// - [BattutaPageTransitionsBuilder]: pushed routes on Android / desktop
///   slide in a short distance and fade on the downbeat curve while the
///   outgoing page recedes slightly. iOS and macOS keep the native Cupertino
///   transition so the edge-swipe-back gesture keeps working.
/// - [battutaTabPage]: a fade-through used when switching top-level tabs.
library;

import 'package:battuta/app/theme/battuta_tokens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BattutaPageTransitionsBuilder extends PageTransitionsBuilder {
  const BattutaPageTransitionsBuilder();

  @override
  Duration get transitionDuration => BattutaMotion.bar;

  @override
  Duration get reverseTransitionDuration =>
      BattutaMotion.beat + BattutaMotion.tick;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: BattutaMotion.downbeat,
      reverseCurve: BattutaMotion.upbeat.flipped,
    );
    final recede = CurvedAnimation(
      parent: secondaryAnimation,
      curve: BattutaMotion.legato,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.6).animate(recede),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.98).animate(recede),
        child: FadeTransition(
          opacity: enter,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(enter),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Theme-wide transitions: Battuta motion everywhere except Apple platforms.
const PageTransitionsTheme battutaPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: BattutaPageTransitionsBuilder(),
    TargetPlatform.fuchsia: BattutaPageTransitionsBuilder(),
    TargetPlatform.linux: BattutaPageTransitionsBuilder(),
    TargetPlatform.windows: BattutaPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
  },
);

/// Fade-through page for switching between top-level tabs.
Page<void> battutaTabPage({required LocalKey key, required Widget child}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: BattutaMotion.bar,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final t = CurvedAnimation(
        parent: animation,
        curve: BattutaMotion.downbeat,
      );
      return FadeTransition(
        opacity: t,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(t),
          child: child,
        ),
      );
    },
  );
}
