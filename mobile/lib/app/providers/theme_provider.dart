import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'accessibility_provider.dart';
import 'age_profile_provider.dart';

/// Computes the active application theme dynamically based on both
/// the developmental AgeProfileConfig and the WCAG 2.2 AA accessibility state.
final themeDataProvider = Provider<ThemeData>((ref) {
  final ageProfile = ref.watch(ageProfileProvider);
  final accessibility = ref.watch(accessibilityProvider);

  return LinguaTheme.buildTheme(
    ageProfile,
    highContrast: accessibility.highContrast,
    fontFamily: accessibility.fontFamily,
  );
});
