import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF003B43); // Deep Teal
  static const Color primaryContainer = Color(0xFF1A535C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF90C5CF);
  static const Color surfaceTint = Color(0xFF30666F);

  // Secondary & Accent Colors
  static const Color secondary = Color(0xFFAE2F34); // Coral
  static const Color secondaryContainer = Color(0xFFFF6B6B);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF6D0010);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF4FAFD);
  static const Color surface = Color(0xFFF4FAFD);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEEF5F7);
  static const Color surfaceContainer = Color(0xFFE8EFF1);
  static const Color surfaceContainerHigh = Color(0xFFE2E9EC);
  static const Color surfaceContainerHighest = Color(0xFFDDE4E6);

  // Content & Typography Colors
  static const Color onSurface = Color(0xFF161D1F);
  static const Color onSurfaceVariant = Color(0xFF40484A);
  static const Color outline = Color(0xFF70797A);
  static const Color outlineVariant = Color(0xFFC0C8CA);
  static const Color cardBorder = Color(0xFFDFE6E9);

  // Semantic Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFBA1A1A);

  // Ambient Shadow: 0px 4px 20px rgba(26, 83, 92, 0.08)
  static const BoxShadow ambientShadow = BoxShadow(
    color: Color(0x141A535C),
    blurRadius: 20,
    offset: Offset(0, 4),
  );

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    final manropeTheme = GoogleFonts.manropeTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        error: error,
      ),
      textTheme: manropeTheme.copyWith(
        headlineLarge: manropeTheme.headlineLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.02 * 32,
        ),
        headlineMedium: manropeTheme.headlineMedium?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: manropeTheme.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: onSurface,
          height: 1.5,
        ),
        bodyMedium: manropeTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onSurfaceVariant,
          height: 1.4,
        ),
        labelLarge: manropeTheme.labelLarge?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05 * 12,
        ),
        bodySmall: manropeTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: outline, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceContainerLowest,
        selectedItemColor: primary,
        unselectedItemColor: outline,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
