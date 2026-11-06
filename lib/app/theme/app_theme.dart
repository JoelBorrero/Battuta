/// Battuta — Stage-Ready Design System & Theme.
///
/// Tailored for high-end, premium iPadOS and macOS stage environments.
/// Replaces standard Android Material elevations and ripples with a flush,
/// anti-material aesthetic inspired by pro audio and stage prompters (e.g. OnStage):
/// - Deep matte slate (`#1A1C20`) and obsidian backgrounds for zero glare.
/// - Flat surfaces (`#24272C`) with crisp 1px borders (`#3A3D44`) instead of drop shadows.
/// - Amber/Gold (`#E5A93C`) accents for stage cues, active states, and primary actions.
/// - Crisp off-white (`#F2F2F2`) and muted grey (`#9BA0A6`) typography powered by SF Pro Display.
/// - Complete disabling of ink ripples and elevation shadows.
library;

import 'package:flutter/material.dart';

/// Central theme provider and design system tokens for Battuta.
abstract final class AppTheme {
  const AppTheme._();

  // ── 1. Color Palette Tokens ──────────────────────────────────────────

  /// Deep matte slate canvas background for extreme low-light stage environments.
  static const Color slateBackground = Color(0xFF1A1C20);

  /// Obsidian black for ultra-dark backgrounds and contrast surfaces.
  static const Color obsidian = Color(0xFF121316);

  /// High-contrast dark ink on amber accents.
  static const Color obsidianText = Color(0xFF141619);

  /// Elevated slate surface for cards, dialogs, sheets, and bars.
  static const Color slateSurface = Color(0xFF24272C);

  /// Lighter surface variant for interactive states, chips, and nested panels.
  static const Color slateSurfaceLight = Color(0xFF2D3138);

  /// Subtle 1px structural border replacing drop shadows.
  static const Color slateBorder = Color(0xFF3A3D44);

  /// Subtle secondary divider / border color.
  static const Color slateBorderSubtle = Color(0xFF2E3137);

  /// Primary warm amber / gold for active states, playback, and stage cues.
  static const Color amberAccent = Color(0xFFE5A93C);

  /// Bright gold for urgent cues and live performance badges.
  static const Color goldAccent = Color(0xFFFFB800);

  /// Subtle amber tint for active pill indicators and selection highlights.
  static const Color amberMuted = Color(0x26E5A93C); // 15% opacity

  /// Crisp off-white for high-legibility primary text and icons.
  static const Color textOffWhite = Color(0xFFF2F2F2);

  /// Muted slate grey for secondary metadata, subtitles, and disabled states.
  static const Color textMuted = Color(0xFF9BA0A6);

  /// Tertiary grey for subtle placeholder hints.
  static const Color textDim = Color(0xFF6B7280);

  /// Stage alert / error red.
  static const Color stageRed = Color(0xFFEF5350);

  /// Stage green for connected / sync / in-time cues.
  static const Color stageGreen = Color(0xFF4CAF50);

  // ── 2. Typography Constants ──────────────────────────────────────────

  static const String primaryFontFamily = 'SF Pro Display';
  static const List<String> fontFamilyFallbacks = [
    'SF Pro Text',
    '-apple-system',
    'BlinkMacSystemFont',
    'Inter',
    'Roboto',
    'Helvetica Neue',
    'sans-serif',
  ];

  static const String monoFontFamily = 'JetBrains Mono';
  static const List<String> monoFontFallbacks = [
    'SF Mono',
    'Menlo',
    'Courier New',
    'monospace',
  ];

  // ── 3. Public Theme API ──────────────────────────────────────────────

  /// Primary stage-ready dark theme (Dark Mode Only design).
  static ThemeData get dark => _buildDarkTheme();

  /// Light mode fallback (redirects to the stage-ready dark theme).
  static ThemeData get light => _buildDarkTheme();

  // ── 4. ColorScheme Builder ───────────────────────────────────────────

  static ColorScheme get colorScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: amberAccent,
        onPrimary: obsidianText,
        primaryContainer: Color(0xFF2E291B),
        onPrimaryContainer: Color(0xFFFFD580),
        secondary: textMuted,
        onSecondary: slateBackground,
        secondaryContainer: slateSurfaceLight,
        onSecondaryContainer: textOffWhite,
        tertiary: goldAccent,
        onTertiary: obsidianText,
        tertiaryContainer: Color(0xFF332710),
        onTertiaryContainer: Color(0xFFFFE082),
        surface: slateSurface,
        onSurface: textOffWhite,
        surfaceContainerLow: obsidian,
        surfaceContainer: slateSurface,
        surfaceContainerHigh: slateSurfaceLight,
        surfaceContainerHighest: Color(0xFF33373E),
        onSurfaceVariant: textMuted,
        outline: slateBorder,
        outlineVariant: slateBorderSubtle,
        error: stageRed,
        onError: obsidianText,
        errorContainer: Color(0xFF3E1E1E),
        onErrorContainer: Color(0xFFFFB4AB),
        shadow: Colors.transparent, // Anti-Material: No drop shadows
        scrim: Color(0xCC0E1013),
      );

  // ── 5. TextTheme Builder ─────────────────────────────────────────────

  static TextTheme get textTheme => _buildTextTheme();

  static TextTheme _buildTextTheme() {
    TextStyle style({
      required double fontSize,
      required FontWeight fontWeight,
      required Color color,
      double? letterSpacing,
      double? height,
    }) {
      return TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fontFamilyFallbacks,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }

    return TextTheme(
      // Display — sleek, restrained, never bulky
      displayLarge: style(
        fontSize: 34,
        fontWeight: FontWeight.w500,
        color: textOffWhite,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      displayMedium: style(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: textOffWhite,
        letterSpacing: -0.3,
        height: 1.25,
      ),
      displaySmall: style(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: textOffWhite,
        letterSpacing: -0.2,
        height: 1.3,
      ),

      // Headline — medium weights for section titles
      headlineLarge: style(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: textOffWhite,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      headlineMedium: style(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: textOffWhite,
        letterSpacing: -0.1,
        height: 1.35,
      ),
      headlineSmall: style(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textOffWhite,
        letterSpacing: 0,
        height: 1.4,
      ),

      // Title — card and bar headers
      titleLarge: style(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: textOffWhite,
        letterSpacing: -0.1,
        height: 1.4,
      ),
      titleMedium: style(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: textOffWhite,
        letterSpacing: 0,
        height: 1.4,
      ),
      titleSmall: style(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textMuted,
        letterSpacing: 0.1,
        height: 1.4,
      ),

      // Body — regular weight for effortless readability at distance
      bodyLarge: style(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textOffWhite,
        letterSpacing: -0.1,
        height: 1.5,
      ),
      bodyMedium: style(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textOffWhite,
        letterSpacing: 0,
        height: 1.45,
      ),
      bodySmall: style(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textMuted,
        letterSpacing: 0.2,
        height: 1.4,
      ),

      // Label — buttons, chips, and stage cues
      labelLarge: style(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textOffWhite,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      labelMedium: style(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMuted,
        letterSpacing: 0.2,
        height: 1.35,
      ),
      labelSmall: style(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textMuted,
        letterSpacing: 0.5,
        height: 1.3,
      ),
    );
  }

  // ── 6. Anti-Material Container Helpers ────────────────────────────────

  /// Reusable [BoxDecoration] for flush, border-delineated stage cards.
  ///
  /// Use this on custom [Container] widgets instead of Flutter's default [Card].
  static BoxDecoration cardDecoration({
    BorderRadius? borderRadius,
    Color? color,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? slateSurface,
      borderRadius: borderRadius ?? BorderRadius.circular(10),
      border: border ?? Border.all(color: slateBorder, width: 1),
    );
  }

  /// Reusable [BoxDecoration] for high-contrast stage cues (e.g. "NEXT: CORO").
  static BoxDecoration stageCueDecoration({bool isActive = false}) {
    return BoxDecoration(
      color: isActive ? amberMuted : slateSurface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isActive ? amberAccent : slateBorder,
        width: 1.5,
      ),
    );
  }

  // ── 7. ThemeData Builder ─────────────────────────────────────────────

  static ThemeData _buildDarkTheme() {
    final scheme = colorScheme;
    final typography = textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      textTheme: typography,
      scaffoldBackgroundColor: slateBackground,
      canvasColor: slateBackground,

      // Anti-Material: Completely disable ripple and ink splash effects
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: const Color(0x0DE5A93C),
      splashFactory: NoSplash.splashFactory,

      // ── Card Theme ───────────────────────────────────────────────────
      // Overridden to be flush, shadow-free, with a subtle 1px border.
      cardTheme: CardThemeData(
        elevation: 0,
        color: slateSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: slateBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Elevated Button Theme ────────────────────────────────────────
      // Overridden to flat, rounded rectangles with amber accent and no elevation.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: amberAccent,
          foregroundColor: obsidianText,
          disabledBackgroundColor: slateSurfaceLight,
          disabledForegroundColor: textDim,
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: primaryFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // ── Filled Button Theme ──────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: amberAccent,
          foregroundColor: obsidianText,
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: primaryFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Outlined Button Theme ────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: textOffWhite,
          side: const BorderSide(color: slateBorder, width: 1),
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: primaryFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Text Button Theme ────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: amberAccent,
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontFamily: primaryFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Divider Theme ────────────────────────────────────────────────
      // Overridden to subtle 1px border.
      dividerTheme: const DividerThemeData(
        color: slateBorder,
        thickness: 1,
        space: 1,
      ),

      // ── Bottom Navigation Bar Theme (Standard) ───────────────────────
      // Overridden for flush slate background with amber active items.
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: slateBackground,
        selectedItemColor: amberAccent,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // ── Navigation Bar Theme (Material 3 Shell) ──────────────────────
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: slateBackground,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: amberMuted,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: primaryFontFamily,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            color: isSelected ? amberAccent : textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? amberAccent : textMuted,
            size: 22,
          );
        }),
      ),

      // ── AppBar Theme ─────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: slateBackground,
        foregroundColor: textOffWhite,
        surfaceTintColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: slateBorder, width: 1),
        ),
        titleTextStyle: typography.titleLarge?.copyWith(
          color: textOffWhite,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: const IconThemeData(color: textOffWhite, size: 22),
      ),

      // ── Slider Theme (Cupertino-Style Sleek Stage Slider) ────────────
      sliderTheme: const SliderThemeData(
        trackHeight: 3.0,
        activeTrackColor: amberAccent,
        inactiveTrackColor: slateBorder,
        thumbColor: textOffWhite,
        overlayColor: Colors.transparent,
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: 7,
          elevation: 0,
          pressedElevation: 0,
        ),
        trackShape: RoundedRectSliderTrackShape(),
      ),

      // ── Switch Theme (Cupertino-Style Sleek Toggle) ──────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textOffWhite;
          }
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return amberAccent;
          }
          return slateSurfaceLight;
        }),
        trackOutlineColor: WidgetStateProperty.all(slateBorder),
        trackOutlineWidth: WidgetStateProperty.all(1.0),
        splashRadius: 0,
      ),

      // ── Bottom Sheet Theme ───────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        modalElevation: 0,
        backgroundColor: slateSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          side: BorderSide(color: slateBorder, width: 1),
        ),
        showDragHandle: true,
        dragHandleColor: slateBorder,
        dragHandleSize: Size(36, 4),
      ),

      // ── Dialog Theme ─────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: slateSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: slateBorder, width: 1),
        ),
        titleTextStyle: typography.titleLarge?.copyWith(
          color: textOffWhite,
        ),
      ),

      // ── Input Decoration Theme ───────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slateSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: slateBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: slateBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: amberAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: stageRed, width: 1),
        ),
        hintStyle: typography.bodyMedium?.copyWith(
          color: textDim,
        ),
      ),

      // ── Segmented Button Theme ───────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          splashFactory: NoSplash.splashFactory,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return slateBorder;
            }
            return slateSurface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return textOffWhite;
            }
            return textMuted;
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: slateBorder, width: 1),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // ── Chip Theme ───────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 0,
        backgroundColor: slateSurface,
        selectedColor: amberMuted,
        labelStyle: typography.labelMedium?.copyWith(
          color: textOffWhite,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(color: slateBorder, width: 1),
      ),

      // ── Popup Menu Theme ─────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        elevation: 0,
        color: slateSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: slateBorder, width: 1),
        ),
        textStyle: typography.bodyMedium?.copyWith(
          color: textOffWhite,
        ),
      ),

      // ── SnackBar Theme ───────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: slateSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: slateBorder, width: 1),
        ),
        contentTextStyle: typography.bodyMedium?.copyWith(
          color: textOffWhite,
        ),
      ),

      // ── Floating Action Button Theme ─────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: amberAccent,
        foregroundColor: obsidianText,
        splashColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
