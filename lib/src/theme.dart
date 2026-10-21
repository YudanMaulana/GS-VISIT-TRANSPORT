import 'package:flutter/material.dart';

// Brand colors matching Garuda Shield FaceID Windows Desktop App
const brandBlue = Color(0xFF0F3D91);
const brandBlueStrong = Color(0xFF1249AB);
const brandBlueDeep = Color(0xFF0A2558);
const brandBlueSoft = Color(0xFFEAF2FF);
const brandYellow = Color(0xFFF4C300);
const brandMint = Color(0xFF5BDFC1);
const brandCoral = Color(0xFFFF8C6B);
const appBackground = Color(0xFFF3F7FF);
const surfaceColor = Colors.white;
const panelColor = Color(0xFFF6FAFF);
const previewColor = Color(0xFF112B57);
const panelAccent = Color(0xFFE1ECFF);
const overlaySurface = Color(0xFF091B3E);
const textPrimary = Color(0xFF10233F);
const textMuted = Color(0xFF5B7290);
const borderColor = Color(0xFFC7D7F0);
const successColor = Color(0xFF0F7A5C);
const warningColor = Color(0xFFC98B00);
const shadowColor = Color(0x1F143B7A);

class AppTheme {
  // Brand
  static const brandBlue = Color(0xFF0F3D91);
  static const brandBlueBright = Color(0xFF1249AB);
  static const brandBlueDeep = Color(0xFF0A2558);
  static const brandGold = Color(0xFFF4C300);
  static const brandGoldDeep = Color(0xFFC29200);
  static const brandTint = Color(0xFFEAF2FF);
  static const brandBlueSoft = Color(0xFFEAF2FF);

  // Surfaces
  static const bg = Color(0xFFF3F7FF);
  static const panel = Colors.white;
  static const panelAlt = Color(0xFFF6FAFF);
  static const panelRaised = Colors.white;
  static const panelSoft = Color(0xFFEAF2FF);
  static const outline = Color(0xFFC7D7F0);

  // Text
  static const fg = Color(0xFF10233F);
  static const muted = Color(0xFF5B7290);
  static const mutedStrong = Color(0xFF10233F);

  // Status
  static const okGreen = Color(0xFF0F7A5C);
  static const badRed = Color(0xFFD64045);
  static const warnAmber = Color(0xFFC98B00);
  static const accent = Color(0xFF0F3D91);

  static List<BoxShadow> softShadow([double alpha = 0.08]) => [
        BoxShadow(
          color: shadowColor.withValues(alpha: alpha),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandBlue,
        primary: brandBlue,
        secondary: brandYellow,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: appBackground,
      useMaterial3: true,
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: textPrimary,
            displayColor: textPrimary,
          ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderColor),
        ),
        elevation: 0,
        shadowColor: shadowColor,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: brandBlueStrong, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: const BorderSide(color: borderColor),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brandBlueDeep,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
