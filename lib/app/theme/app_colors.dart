/// Color palette for the Battuta music app.
///
/// Designed around two moods:
/// - **Dark theme** — a concert-hall aesthetic with deep indigo surfaces
///   and warm amber/gold accents, evoking brass instruments under stage light.
/// - **Light theme** — a parchment-and-ink aesthetic reminiscent of printed
///   sheet music, with soft cream backgrounds and rich navy notation.
///
/// Music-notation-specific colors (staff lines, note heads, bar lines) are
/// included so that custom score-rendering widgets can stay in sync with the
/// overall theme.
library;

import 'dart:ui' show Color;

/// App-wide color tokens.
///
/// Access through [AppColors.light] or [AppColors.dark] to obtain the
/// palette for the corresponding brightness.
sealed class AppColors {
  const AppColors._();

  // ── Palette instances ─────────────────────────────────────────────────

  /// Light-mode palette.
  static const LightAppColors light = LightAppColors._();

  /// Dark-mode palette.
  static const DarkAppColors dark = DarkAppColors._();

  // ── Shared brand colors (brightness-agnostic) ─────────────────────────

  /// The seed color used by [ColorScheme.fromSeed].
  static const Color seed = Color(0xFF3949AB); // Indigo 600

  /// Deep indigo — the brand's primary hue.
  static const Color brandIndigo = Color(0xFF283593); // Indigo 800

  /// Warm amber/gold — the brand's accent hue.
  static const Color brandAmber = Color(0xFFFFAB00); // Amber A700

  /// Pure gold for premium / "live session" accents.
  static const Color gold = Color(0xFFFFD600);

  /// Subtle red for errors, keeping the warm tone.
  static const Color errorRed = Color(0xFFD32F2F);

  /// Success green.
  static const Color successGreen = Color(0xFF388E3C);

  // ── Abstract theme tokens implemented by light and dark palettes ─────
  Color get primary;
  Color get secondary;
  Color get background;
  Color get surface;
  Color get surfaceVariant;
  Color get error;
  Color get onPrimary;
  Color get onSurface;
  Color get onSurfaceVariant;
  Color get onError;
  Color get staffLines;
  Color get noteHeads;
  Color get barLines;
  Color get selectionHighlight;
  Color get chordSymbol;
}

/// Light-mode color tokens.
final class LightAppColors extends AppColors {
  const LightAppColors._() : super._();

  // ── Core surfaces ─────────────────────────────────────────────────────

  /// Primary brand color.
  @override
  Color get primary => const Color(0xFF3949AB);

  /// Secondary / complementary color.
  @override
  Color get secondary => const Color(0xFF5C6BC0);

  /// Main background (parchment cream).
  @override
  Color get background => const Color(0xFFFAF8F5);

  /// Card / elevated surface color.
  @override
  Color get surface => const Color(0xFFFFFFFF);

  /// Surface variant for slight contrast.
  @override
  Color get surfaceVariant => const Color(0xFFF0EDE8);

  /// Error color.
  @override
  Color get error => AppColors.errorRed;

  // ── On-colors (content on top of surfaces) ────────────────────────────

  /// Content on [primary].
  @override
  Color get onPrimary => const Color(0xFFFFFFFF);

  /// Content on [background] and [surface].
  @override
  Color get onSurface => const Color(0xFF1C1B1F);

  /// De-emphasised content on [surface].
  @override
  Color get onSurfaceVariant => const Color(0xFF49454F);

  /// Content on [error].
  @override
  Color get onError => const Color(0xFFFFFFFF);

  // ── Music-notation tokens ─────────────────────────────────────────────

  /// Staff lines (five horizontal lines of the musical staff).
  @override
  Color get staffLines => const Color(0xFF9E9E9E);

  /// Note heads and stems.
  @override
  Color get noteHeads => const Color(0xFF212121);

  /// Bar lines / measure separators.
  @override
  Color get barLines => const Color(0xFF616161);

  /// Selection / highlight overlay (semi-transparent amber).
  @override
  Color get selectionHighlight => const Color(0x40FFAB00);

  /// Chord symbol text color.
  @override
  Color get chordSymbol => const Color(0xFF283593);
}

/// Dark-mode color tokens.
final class DarkAppColors extends AppColors {
  const DarkAppColors._() : super._();

  // ── Core surfaces ─────────────────────────────────────────────────────

  /// Primary brand color (lighter for dark backgrounds).
  @override
  Color get primary => const Color(0xFF7986CB);

  /// Secondary color.
  @override
  Color get secondary => const Color(0xFF9FA8DA);

  /// Main background (deep charcoal with a blue undertone).
  @override
  Color get background => const Color(0xFF121218);

  /// Card / elevated surface color.
  @override
  Color get surface => const Color(0xFF1E1E2A);

  /// Surface variant for slight contrast.
  @override
  Color get surfaceVariant => const Color(0xFF2A2A3C);

  /// Error color (slightly lighter for readability on dark).
  @override
  Color get error => const Color(0xFFEF5350);

  // ── On-colors ─────────────────────────────────────────────────────────

  /// Content on [primary].
  @override
  Color get onPrimary => const Color(0xFF1A1A2E);

  /// Content on [background] and [surface].
  @override
  Color get onSurface => const Color(0xFFE6E1E5);

  /// De-emphasised content on [surface].
  @override
  Color get onSurfaceVariant => const Color(0xFFCAC4D0);

  /// Content on [error].
  @override
  Color get onError => const Color(0xFF1A1A2E);

  // ── Music-notation tokens ─────────────────────────────────────────────

  /// Staff lines.
  @override
  Color get staffLines => const Color(0xFF616161);

  /// Note heads and stems.
  @override
  Color get noteHeads => const Color(0xFFE0E0E0);

  /// Bar lines / measure separators.
  @override
  Color get barLines => const Color(0xFF9E9E9E);

  /// Selection / highlight overlay (semi-transparent gold).
  @override
  Color get selectionHighlight => const Color(0x40FFD600);

  /// Chord symbol text color.
  @override
  Color get chordSymbol => const Color(0xFFFFAB00);
}
