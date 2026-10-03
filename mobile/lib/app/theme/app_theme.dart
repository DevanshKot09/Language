import 'package:flutter/material.dart';
import '../../shared/design_tokens/tokens.dart';
import '../../shared/models/age_profile.dart';

/// Central theme engine for LINGUA AI.
/// Produces an accessible, warm, non-clinical design that adapts dynamically
/// based on the active [AgeProfileConfig] and high contrast preferences.
class LinguaTheme {
  static ThemeData buildTheme(
    AgeProfileConfig ageProfile, {
    bool highContrast = false,
    String? fontFamily,
  }) {
    final effectiveFontFamily = fontFamily ?? LinguaTokens.fontPrimary;
    final Color scaffoldBg = highContrast ? Colors.white : LinguaTokens.paper50;
    final Color cardBg = LinguaTokens.surfaceCard;
    final Color primaryColor = LinguaTokens.primary600;
    final Color textColor = highContrast ? Colors.black : LinguaTokens.ink900;
    final Color secondaryTextColor = highContrast ? const Color(0xFF1E293B) : LinguaTokens.ink700;

    return ThemeData(
      useMaterial3: true,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: LinguaTokens.accent500,
        onSecondary: Colors.white,
        error: LinguaTokens.danger600,
        onError: Colors.white,
        surface: cardBg,
        onSurface: textColor,
      ),
      fontFamily: effectiveFontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: effectiveFontFamily,
          fontSize: ageProfile.baseFontSize + 4,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, ageProfile.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
          ),
          textStyle: TextStyle(
            fontFamily: effectiveFontFamily,
            fontSize: ageProfile.baseFontSize,
            fontWeight: FontWeight.w600,
          ),
          elevation: highContrast ? 0 : 1,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: Size(double.infinity, ageProfile.minTouchTarget),
          side: BorderSide(
            color: highContrast ? primaryColor : LinguaTokens.borderSubtle,
            width: highContrast ? 2.0 : 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
          ),
          textStyle: TextStyle(
            fontFamily: LinguaTokens.fontPrimary,
            fontSize: ageProfile.baseFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: highContrast ? 0 : 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
          side: BorderSide(
            color: highContrast ? Colors.black : LinguaTokens.borderSubtle,
            width: highContrast ? 2.0 : 1.0,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: LinguaTokens.space8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
          borderSide: BorderSide(color: LinguaTokens.borderSubtle, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
          borderSide: BorderSide(
            color: highContrast ? Colors.black : LinguaTokens.borderSubtle,
            width: highContrast ? 2.0 : 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
          borderSide: BorderSide(color: primaryColor, width: 3.0),
        ),
        hintStyle: TextStyle(
          color: LinguaTokens.inkMuted,
          fontSize: ageProfile.baseFontSize,
        ),
        labelStyle: TextStyle(
          color: secondaryTextColor,
          fontSize: ageProfile.baseFontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
