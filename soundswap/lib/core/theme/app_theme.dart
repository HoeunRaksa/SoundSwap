import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: const Color(0xFFC2410C), // Deep terracotta/rust
      primaryContainer: const Color(0xFFFFEDD5),
      onPrimaryContainer: const Color(0xFF431407),
      secondary: const Color(0xFF6B21A8), // Warm violet/plum
      secondaryContainer: const Color(0xFFF3E8FF),
      surface: const Color(0xFFFAF8F5), // Soft Claude cream background
      onSurface: const Color(0xFF1E1A18), // Muted dark text
      onSurfaceVariant: const Color(0xFF6B6058), // Muted dark variant text
      surfaceContainerLow: const Color(0xFFFFFFFF), // Pure white cards
      surfaceContainerHighest: const Color(
        0xFFF3EFE9,
      ), // Soft warm grey for headers
      outline: const Color(0xFFD6CBC0), // Muted outline
      outlineVariant: const Color(0xFFE8E2D9), // Very soft card border
      error: const Color(0xFF991B1B),
    );
    return _theme(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: const Color(0xFFF97316), // Bright terracotta
      primaryContainer: const Color(0xFF431407),
      onPrimaryContainer: const Color(0xFFFFEDD5),
      secondary: const Color(0xFFA855F7), // Muted violet
      secondaryContainer: const Color(0xFF2E1065),
      surface: const Color(0xFF171412), // Very soft warm dark background
      onSurface: const Color(0xFFF3EFEA), // Soft warm text
      onSurfaceVariant: const Color(0xFFB5A9A0),
      surfaceContainerLow: const Color(0xFF24201E), // Soft dark card
      surfaceContainerHighest: const Color(0xFF2D2926), // Dark header row
      outline: const Color(0xFF5C524B),
      outlineVariant: const Color(0xFF3D3733),
      error: const Color(0xFFEF4444),
    );
    return _theme(colorScheme);
  }

  static ThemeData _theme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          side: BorderSide(color: colorScheme.primary),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerHighest,
        ),
        dataRowMinHeight: 56,
        dataRowMaxHeight: 72,
      ),
    );
  }
}
