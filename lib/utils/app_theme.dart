import 'package:flutter/material.dart';

class AppTheme {
  static const brandPrimary = Color(0xFF12113C);
  static const brandSurface = Color(0xFFF5F1FC);
  static const brandWhite = Colors.white;
  static const brandInk = Color(0xFF12113C);
  static const brandMuted = Color(0xFF615C7D);
  static const brandBorder = Color(0xFFD8D0EA);
  static const brandTint = Color(0xFFE7E1F4);
  static const brandTintStrong = Color(0xFFD4CCEA);
  static const _darkSurface = Color(0xFF0D0C26);
  static const _darkCard = Color(0xFF161436);
  static const _darkBorder = Color(0xFF47436A);

  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: brandPrimary,
      brightness: Brightness.light,
      surface: brandSurface,
    );
    final scheme = base.copyWith(
      primary: brandPrimary,
      onPrimary: brandWhite,
      secondary: brandTintStrong,
      onSecondary: brandPrimary,
      tertiary: brandTint,
      onTertiary: brandPrimary,
      surface: brandSurface,
      onSurface: brandInk,
      onSurfaceVariant: brandMuted,
      outline: brandMuted,
      outlineVariant: brandBorder,
      surfaceContainerLowest: brandWhite,
      surfaceContainerLow: const Color(0xFFF0EBF9),
      surfaceContainerHighest: const Color(0xFFECE5F7),
      primaryContainer: brandTint,
      onPrimaryContainer: brandPrimary,
    );
    return _base(
      scheme,
      ThemeData.light().textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }

  static ThemeData get dark {
    final base = ColorScheme.fromSeed(
      seedColor: brandPrimary,
      brightness: Brightness.dark,
      surface: _darkSurface,
    );
    final scheme = base.copyWith(
      primary: brandSurface,
      onPrimary: brandPrimary,
      secondary: const Color(0xFFBFB5DD),
      onSecondary: brandPrimary,
      tertiary: const Color(0xFF9D93C7),
      onTertiary: brandPrimary,
      surface: _darkSurface,
      onSurface: brandSurface,
      onSurfaceVariant: const Color(0xFFC7C1DE),
      outline: const Color(0xFF8E88AC),
      outlineVariant: _darkBorder,
      surfaceContainerLowest: _darkCard,
      surfaceContainerLow: const Color(0xFF1D1A42),
      surfaceContainerHighest: const Color(0xFF282454),
      primaryContainer: const Color(0xFF2A2758),
      onPrimaryContainer: brandSurface,
    );
    return _base(
      scheme,
      ThemeData.dark().textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme, TextTheme textTheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        shadowColor: scheme.shadow.withValues(alpha: .06),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .3)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: .45),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 4,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
