/// Battuta — Non-color design tokens: motion, spacing, and radii.
///
/// Battuta's motion language is built around the conductor's **ictus**: the
/// precise instant a beat lands. Things in the interface move like a baton —
/// a quick, decisive approach that decelerates crisply onto its target, with
/// no floaty overshoot except for small, celebratory "rebounds".
///
/// Durations are named after musical units so designers and engineers share a
/// vocabulary (`tick` < `beat` < `bar` < `phrase`). Every animation in the app
/// should pick one of these instead of inventing a `Duration` literal.
library;

import 'package:flutter/widgets.dart';

/// Motion tokens (durations and curves).
abstract final class BattutaMotion {
  // ── Durations ─────────────────────────────────────────────────────────

  /// Micro-feedback: press states, icon swaps, color tints.
  static const Duration tick = Duration(milliseconds: 120);

  /// Small component transitions: indicators, toggles, chips.
  static const Duration beat = Duration(milliseconds: 220);

  /// Container / page level transitions.
  static const Duration bar = Duration(milliseconds: 360);

  /// Choreographed sequences (brand intro, empty-state reveals).
  static const Duration phrase = Duration(milliseconds: 720);

  /// Delay between consecutive items in a staggered list entrance.
  static const Duration stagger = Duration(milliseconds: 40);

  /// Upper bound on items that receive a stagger delay, so long lists never
  /// feel sluggish.
  static const int maxStaggeredItems = 8;

  // ── Curves ────────────────────────────────────────────────────────────

  /// The signature "ictus" curve: fast approach, decisive landing.
  /// Use for anything entering or moving to a resting position.
  static const Curve downbeat = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Accelerating exit — the baton lifting off before the next beat.
  static const Curve upbeat = Cubic(0.3, 0.0, 1.0, 1.0);

  /// A small, confident overshoot for selection and success moments.
  static const Curve rebound = Cubic(0.34, 1.36, 0.64, 1.0);

  /// Symmetric ease for position changes that are neither enter nor exit.
  static const Curve legato = Cubic(0.4, 0.0, 0.2, 1.0);

  /// Returns [duration], or [Duration.zero] when the platform requests
  /// reduced motion (accessibility setting).
  static Duration resolve(BuildContext context, Duration duration) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return reduce ? Duration.zero : duration;
  }

  /// Whether the user has requested reduced motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Spacing scale (4pt base grid).
abstract final class BattutaSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Minimum interactive target (Apple HIG).
  static const double minTouchTarget = 44;
}

/// Corner radius scale.
abstract final class BattutaRadius {
  /// Badges, tags, tiny pills.
  static const double xs = 6;

  /// Buttons, inputs, menus.
  static const double sm = 10;

  /// Cards and list tiles.
  static const double md = 14;

  /// Sheets, dialogs, large panels.
  static const double lg = 20;

  /// Fully rounded pill.
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
}

/// Responsive breakpoints.
abstract final class BattutaBreakpoints {
  /// Width at and above which the app switches to a side navigation rail
  /// (iPad landscape, macOS windows).
  static const double rail = 840;
}
