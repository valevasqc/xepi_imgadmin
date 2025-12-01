import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide theme configuration with modern, minimal design
class AppTheme {
  // Brand Colors (used as accents)
  static const orange = Color(0xFFDB6A19);
  static const yellow = Color(0xFFFEC800);
  static const blue = Color(0xFF00ACC0);

  // Neutral Colors (primary palette)
  static const darkGray = Color(0xFF2B2B2B);
  static const mediumGray = Color(0xFF6B6B6B);
  static const lightGray = Color(0xFFE5E5E5);
  static const backgroundGray = Color(0xFFF8F8F8);
  static const white = Color(0xFFFFFFFF);

  // Status Colors
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  // Text Styles
  static TextStyle get heading1 => GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: darkGray,
        letterSpacing: -0.5,
      );

  static TextStyle get heading2 => GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: darkGray,
        letterSpacing: -0.3,
      );

  static TextStyle get heading3 => GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkGray,
      );

  static TextStyle get heading4 => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkGray,
      );

  static TextStyle get bodyLarge => GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: darkGray,
      );

  static TextStyle get bodyMedium => GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: darkGray,
      );

  static TextStyle get bodySmall => GoogleFonts.quicksand(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: mediumGray,
      );

  static TextStyle get caption => GoogleFonts.quicksand(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: mediumGray,
      );

  static TextStyle get buttonText => GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: white,
      );

  // Shadows
  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get hoverShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  // Border Radius
  static BorderRadius get borderRadiusSmall => BorderRadius.circular(8);
  static BorderRadius get borderRadiusMedium => BorderRadius.circular(12);
  static BorderRadius get borderRadiusLarge => BorderRadius.circular(16);

  // Spacing
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundGray,
      colorScheme: const ColorScheme.light(
        primary: blue,
        secondary: orange,
        tertiary: yellow,
        surface: white,
        error: danger,
      ),
      textTheme: TextTheme(
        displayLarge: heading1,
        displayMedium: heading2,
        displaySmall: heading3,
        headlineMedium: heading4,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelSmall: caption,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: heading3,
        iconTheme: const IconThemeData(color: darkGray),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMedium,
        ),
        shadowColor: Colors.black.withValues(alpha: 0.06),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusSmall,
          ),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkGray,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: lightGray),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusSmall,
          ),
          textStyle: buttonText.copyWith(color: darkGray),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: borderRadiusSmall,
          borderSide: const BorderSide(color: lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusSmall,
          borderSide: const BorderSide(color: lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusSmall,
          borderSide: const BorderSide(color: blue, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: bodyMedium.copyWith(color: mediumGray),
      ),
    );
  }
}
