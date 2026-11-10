/// Battuta — Brand theme extension.
///
/// Exposes brightness-aware brand tokens (built exclusively from the existing
/// [AppTheme] palette) that Material's [ColorScheme] has no slot for: the
/// "stage light" glow, the readable amber ink for each mode, raised card
/// surfaces, and structural borders.
///
/// ```dart
/// final brand = BattutaBrand.of(context);
/// Container(decoration: brand.cardDecoration());
/// ```
library;

import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/app/theme/battuta_tokens.dart';
import 'package:flutter/material.dart';

/// Brand tokens registered on [ThemeData.extensions].
@immutable
class BattutaBrand extends ThemeExtension<BattutaBrand> {
  const BattutaBrand({
    required this.brightness,
    required this.canvas,
    required this.card,
    required this.cardRaised,
    required this.border,
    required this.borderSubtle,
    required this.ink,
    required this.inkMuted,
    required this.inkDim,
    required this.accent,
    required this.accentInk,
    required this.accentWash,
    required this.onAccent,
  });

  /// Brand tokens for dark (stage) mode.
  static const BattutaBrand dark = BattutaBrand(
    brightness: Brightness.dark,
    canvas: AppTheme.slateBackground,
    card: AppTheme.slateSurface,
    cardRaised: AppTheme.slateSurfaceLight,
    border: AppTheme.slateBorder,
    borderSubtle: AppTheme.slateBorderSubtle,
    ink: AppTheme.textOffWhite,
    inkMuted: AppTheme.textMuted,
    inkDim: AppTheme.textDim,
    accent: AppTheme.amberAccent,
    accentInk: AppTheme.amberAccent,
    accentWash: AppTheme.amberMuted,
    onAccent: AppTheme.obsidianText,
  );

  /// Brand tokens for light (rehearsal hall) mode.
  static const BattutaBrand light = BattutaBrand(
    brightness: Brightness.light,
    canvas: AppTheme.pearlBackground,
    card: AppTheme.pureWhiteSurface,
    cardRaised: AppTheme.pearlSurfaceLight,
    border: AppTheme.pearlBorder,
    borderSubtle: AppTheme.pearlBorderSubtle,
    ink: AppTheme.charcoalText,
    inkMuted: AppTheme.charcoalMuted,
    inkDim: AppTheme.charcoalDim,
    accent: AppTheme.amberAccent,
    accentInk: AppTheme.amberAccentLightText,
    accentWash: AppTheme.amberMuted,
    onAccent: AppTheme.obsidianText,
  );

  /// Resolves the brand tokens for [context], falling back to the palette
  /// matching the ambient brightness when the theme has no extension
  /// registered (e.g. bare `MaterialApp` in widget tests).
  static BattutaBrand of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<BattutaBrand>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  final Brightness brightness;

  /// Scaffold background.
  final Color canvas;

  /// Default card / sheet surface.
  final Color card;

  /// Nested or pressed surface.
  final Color cardRaised;

  /// 1px structural border.
  final Color border;

  /// Softer divider.
  final Color borderSubtle;

  /// Primary text / icons.
  final Color ink;

  /// Secondary text / icons.
  final Color inkMuted;

  /// Placeholder / tertiary text.
  final Color inkDim;

  /// Stage amber fill.
  final Color accent;

  /// Amber used for text and icons on [canvas]/[card] (darker in light mode
  /// for legibility).
  final Color accentInk;

  /// Translucent amber wash for selected states.
  final Color accentWash;

  /// Content placed on [accent].
  final Color onAccent;

  bool get isDark => brightness == Brightness.dark;

  /// A soft amber "stage light" glow used behind the brand mark and active
  /// cues. Flat (no blur shadow) to respect the anti-material invariant.
  RadialGradient get stageLight => RadialGradient(
    colors: [
      accent.withValues(alpha: isDark ? 0.22 : 0.16),
      accent.withValues(alpha: 0),
    ],
  );

  /// Flush, border-delineated card decoration.
  BoxDecoration cardDecoration({bool selected = false, bool pressed = false}) {
    return BoxDecoration(
      color: pressed ? cardRaised : card,
      borderRadius: BattutaRadius.mdAll,
      border: Border.all(
        color: selected ? accent : border,
        width: selected ? 1.5 : 1,
      ),
    );
  }

  @override
  BattutaBrand copyWith({
    Brightness? brightness,
    Color? canvas,
    Color? card,
    Color? cardRaised,
    Color? border,
    Color? borderSubtle,
    Color? ink,
    Color? inkMuted,
    Color? inkDim,
    Color? accent,
    Color? accentInk,
    Color? accentWash,
    Color? onAccent,
  }) {
    return BattutaBrand(
      brightness: brightness ?? this.brightness,
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      cardRaised: cardRaised ?? this.cardRaised,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkDim: inkDim ?? this.inkDim,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentWash: accentWash ?? this.accentWash,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  BattutaBrand lerp(ThemeExtension<BattutaBrand>? other, double t) {
    if (other is! BattutaBrand) return this;
    return BattutaBrand(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardRaised: Color.lerp(cardRaised, other.cardRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkDim: Color.lerp(inkDim, other.inkDim, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      accentWash: Color.lerp(accentWash, other.accentWash, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}
