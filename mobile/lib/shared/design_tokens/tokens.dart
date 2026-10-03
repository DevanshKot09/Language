import 'package:flutter/material.dart';

/// LINGUA AI Design Tokens
/// Evidence-informed, accessible color palette, typography scales,
/// spacing, and corner radius tokens for DLD & Dyslexia support.
class LinguaTokens {
  // Brand Colors
  static const Color primary50 = Color(0xFFF4F4FD);
  static const Color primary100 = Color(0xFFE9E9FF);
  static const Color primary500 = Color(0xFF6B6BE2);
  static const Color primary600 = Color(0xFF5B5BD6);
  static const Color primary700 = Color(0xFF4A4ABF);
  static const Color primary900 = Color(0xFF2C2C7A);

  static const Color accent50 = Color(0xFFFEF7F4);
  static const Color accent100 = Color(0xFFFDEEE8);
  static const Color accent500 = Color(0xFFF59E7A);
  static const Color accent600 = Color(0xFFE27F57);

  // Surface & Paper Colors (Warm & Non-Clinical)
  static const Color paper50 = Color(0xFFF8FAFC);
  static const Color paper100 = Color(0xFFF1F5F9);
  static const Color surfaceCard = Colors.white;
  static const Color borderSubtle = Color(0xFFE2E8F0);

  // Text Colors
  static const Color ink900 = Color(0xFF18202A);
  static const Color ink700 = Color(0xFF45515E);
  static const Color inkMuted = Color(0xFF64748B);

  // Semantic Status Colors
  static const Color success600 = Color(0xFF2F8F6B);
  static const Color successLight = Color(0xFFEBF7F2);
  static const Color warning600 = Color(0xFFB7791F);
  static const Color warningLight = Color(0xFFFDF8ED);
  static const Color danger600 = Color(0xFFB94A59);
  static const Color dangerLight = Color(0xFFFDF2F4);

  // Distinct Clinical Support Tracks
  static const Color dldTrack = Color(0xFF5B5BD6); // Spoken Language
  static const Color dldTrackBg = Color(0xFFE9E9FF);
  static const Color dyslexiaTrack = Color(0xFF2F8F6B); // Literacy & Reading
  static const Color dyslexiaTrackBg = Color(0xFFEBF7F2);

  // Spacing Scale (4px base)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Radius Tokens
  static const double radiusSmall = 10.0;
  static const double radiusCard = 14.0;
  static const double radiusHero = 20.0;
  static const double radiusPill = 999.0;

  // Touch Target Minimums
  static const double minTouchTarget = 44.0;
  static const double childTouchTarget = 56.0;

  // Typography Families
  static const String fontPrimary = 'Atkinson Hyperlegible';
}
