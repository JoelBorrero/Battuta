/// Complete Material 3 [ThemeData] factory for the Battuta app.
///
/// Provides both light and dark variants with the brand color palette
/// and custom typography wired in. The themes are consumed by the
/// top-level [MaterialApp.router] widget.
///
/// ```dart
/// MaterialApp.router(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
///   themeMode: ThemeMode.system,
///   …
/// );
/// ```
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Factory for the app's light and dark [ThemeData].
final class AppTheme {
  const AppTheme._();

  // ── Public API ────────────────────────────────────────────────────────

  /// Light-mode [ThemeData].
  static ThemeData get light => _build(Brightness.light);

  /// Dark-mode [ThemeData].
  static ThemeData get dark => _build(Brightness.dark);

  // ── Builder ───────────────────────────────────────────────────────────

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
      primary: colors.primary,
      secondary: colors.secondary,
      surface: colors.surface,
      error: colors.error,
      onPrimary: colors.onPrimary,
      onSurface: colors.onSurface,
      onError: colors.onError,
    );

    final textTheme = AppTypography.textTheme.apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colors.background,

      // ── AppBar ──────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        backgroundColor: colors.background,
        foregroundColor: colors.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.onSurface,
        ),
      ),

      // ── Bottom Navigation ───────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        backgroundColor: isDark
            ? colors.surfaceVariant
            : colors.surface,
        indicatorColor: colors.primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(
            color: colors.onSurface,
          ),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: colors.onSurfaceVariant),
        ),
      ),

      // ── Cards ───────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: isDark ? 1 : 0.5,
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // ── Elevated Buttons ────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colors.onPrimary,
          backgroundColor: colors.primary,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── Outlined Buttons ────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── Text Buttons ────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── FAB ─────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandAmber,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Input Decoration ────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),

      // ── Divider ─────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colors.onSurface.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),

      // ── Chips ───────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceVariant,
        selectedColor: colors.primary.withValues(alpha: 0.2),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      ),

      // ── SnackBar ────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: isDark
            ? const Color(0xFF2A2A3C)
            : const Color(0xFF323232),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
      ),

      // ── Dialog ──────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colors.onSurface,
        ),
      ),

      // ── Bottom Sheet ────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: colors.onSurface.withValues(alpha: 0.2),
      ),
    );
  }
}
