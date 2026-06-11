import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // ── Brand palette ─────────────────────────────────────────────────────

  // Light mode
  static const _lightPrimary = Color(0xFFC2410C); // Terracotta/rust
  static const _lightPrimaryContainer = Color(0xFFFFEDD5);
  static const _lightOnPrimaryContainer = Color(0xFF431407);
  static const _lightSecondary = Color(0xFF6B21A8); // Warm violet
  static const _lightSecondaryContainer = Color(0xFFF3E8FF);
  static const _lightSurface = Color(0xFFF8F6F3); // Warm cream
  static const _lightSurfaceContainerLow = Color(0xFFFFFFFF);
  static const _lightSurfaceContainerHighest = Color(0xFFEFEBE4);
  static const _lightOnSurface = Color(0xFF1C1816);
  static const _lightOnSurfaceVariant = Color(0xFF6B6058);
  static const _lightOutline = Color(0xFFD0C4B8);
  static const _lightOutlineVariant = Color(0xFFE6E0D8);
  static const _lightError = Color(0xFF991B1B);

  // Dark mode
  static const _darkPrimary = Color(0xFFF97316); // Bright terracotta
  static const _darkPrimaryContainer = Color(0xFF431407);
  static const _darkOnPrimaryContainer = Color(0xFFFFEDD5);
  static const _darkSecondary = Color(0xFFA855F7);
  static const _darkSecondaryContainer = Color(0xFF2E1065);
  static const _darkSurface = Color(0xFF141210); // Deeper warm dark
  static const _darkSurfaceContainerLow = Color(0xFF1E1B19); // Cards
  static const _darkSurfaceContainerHighest = Color(0xFF2A2622);
  static const _darkOnSurface = Color(0xFFF5F1EC);
  static const _darkOnSurfaceVariant = Color(0xFFB0A49B);
  static const _darkOutline = Color(0xFF524843);
  static const _darkOutlineVariant = Color(0xFF3A3330);
  static const _darkError = Color(0xFFEF4444);

  // ── Public theme factories ────────────────────────────────────────────

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: _lightPrimary,
      primaryContainer: _lightPrimaryContainer,
      onPrimaryContainer: _lightOnPrimaryContainer,
      secondary: _lightSecondary,
      secondaryContainer: _lightSecondaryContainer,
      surface: _lightSurface,
      onSurface: _lightOnSurface,
      onSurfaceVariant: _lightOnSurfaceVariant,
      surfaceContainerLow: _lightSurfaceContainerLow,
      surfaceContainerHighest: _lightSurfaceContainerHighest,
      outline: _lightOutline,
      outlineVariant: _lightOutlineVariant,
      error: _lightError,
    );
    return _theme(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: _darkPrimary,
      primaryContainer: _darkPrimaryContainer,
      onPrimaryContainer: _darkOnPrimaryContainer,
      secondary: _darkSecondary,
      secondaryContainer: _darkSecondaryContainer,
      surface: _darkSurface,
      onSurface: _darkOnSurface,
      onSurfaceVariant: _darkOnSurfaceVariant,
      surfaceContainerLow: _darkSurfaceContainerLow,
      surfaceContainerHighest: _darkSurfaceContainerHighest,
      outline: _darkOutline,
      outlineVariant: _darkOutlineVariant,
      error: _darkError,
    );
    return _theme(colorScheme);
  }

  // ── Internal builder ──────────────────────────────────────────────────

  static ThemeData _theme(ColorScheme colorScheme) {
    final textTheme = const TextTheme(
      // Display
      displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -1.5),
      displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.5),
      // Headlines
      headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5),
      headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3),
      headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2),
      // Titles
      titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2),
      titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1),
      titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600),
      // Body
      bodyLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5),
      bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400),
      // Labels
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500),
    ).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // ── AppBar ─────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      // ── Card ───────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Input ──────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          color: colorScheme.onSurfaceVariant,
        ),
        helperStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),

      // ── Buttons ────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // ── Dialog ─────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        backgroundColor: colorScheme.surfaceContainerLow,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
          letterSpacing: -0.2,
        ),
      ),

      // ── DataTable ──────────────────────────────────────────────────
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerHighest,
        ),
        dataRowMinHeight: 52,
        dataRowMaxHeight: 68,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: colorScheme.onSurface,
        ),
      ),

      // ── Divider ────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ── Tooltip ────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(
          fontSize: 12,
          color: colorScheme.onInverseSurface,
        ),
        waitDuration: const Duration(milliseconds: 600),
        showDuration: const Duration(seconds: 3),
      ),

      // ── Chip ───────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),

      // ── ListTile ───────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        minLeadingWidth: 20,
      ),

      // ── Switch / Checkbox / Radio ───────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return null;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── ExpansionTile ───────────────────────────────────────────────
      expansionTileTheme: ExpansionTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        iconColor: colorScheme.onSurfaceVariant,
        collapsedIconColor: colorScheme.onSurfaceVariant,
      ),

      // ── Scrollbar ──────────────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(4),
        thumbVisibility: const WidgetStatePropertyAll(false),
      ),

      // ── ProgressIndicator ──────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primaryContainer,
        circularTrackColor: colorScheme.primaryContainer,
      ),

      // ── DropdownMenu ───────────────────────────────────────────────
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
      ),
    );
  }
}

const fontFamily = 'Inter';
