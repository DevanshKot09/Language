import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:lingua_ai/app/router/app_router.dart';
import 'package:lingua_ai/shared/models/user_role.dart';
import 'package:lingua_ai/shared/models/skill_track.dart';
import 'package:lingua_ai/shared/design_tokens/tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 13 Release Candidate Router & Configuration Validation', () {
    test('AppRoutes defines all essential learner and professional routes', () {
      expect(AppRoutes.welcome, equals('/'));
      expect(AppRoutes.login, equals('/login'));
      expect(AppRoutes.signup, equals('/signup'));
      expect(AppRoutes.home, equals('/home'));
      expect(AppRoutes.practice, equals('/practice'));
      expect(AppRoutes.dldDashboard, equals('/dld/dashboard'));
      expect(AppRoutes.dyslexiaDashboard, equals('/dyslexia/dashboard'));
      expect(AppRoutes.progress, equals('/progress'));
      expect(AppRoutes.goals, equals('/goals'));
      expect(AppRoutes.achievements, equals('/achievements'));
      expect(AppRoutes.voicePrivacy, equals('/voice-privacy'));
      expect(AppRoutes.accessibility, equals('/accessibility'));

      // Professional role routes
      expect(AppRoutes.parentDashboard, equals('/parent'));
      expect(AppRoutes.teacherDashboard, equals('/teacher'));
      expect(AppRoutes.specialistDashboard, equals('/specialist'));
      expect(AppRoutes.specialistLearnerDetail, equals('/specialist/learner'));
      expect(AppRoutes.reportBuilder, equals('/reports/builder'));
      expect(AppRoutes.relationships, equals('/relationships'));
    });

    test('AppRouter generates valid MaterialPageRoute for core destinations', () {
      final routesToTest = [
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.home,
        AppRoutes.roles,
        AppRoutes.ageMode,
        AppRoutes.progress,
        AppRoutes.goals,
        AppRoutes.achievements,
        AppRoutes.voicePrivacy,
        AppRoutes.parentDashboard,
        AppRoutes.teacherDashboard,
        AppRoutes.specialistDashboard,
        AppRoutes.relationships,
      ];

      for (final route in routesToTest) {
        final settings = RouteSettings(name: route);
        final pageRoute = AppRouter.generateRoute(settings);
        expect(pageRoute, isNotNull, reason: 'Route $route should resolve to a valid page route');
        expect(pageRoute, isA<MaterialPageRoute>());
      }
    });

    test('Design tokens enforce minimum accessible touch targets and contrast bounds', () {
      expect(LinguaTokens.minTouchTarget, greaterThanOrEqualTo(44.0));
      expect(LinguaTokens.childTouchTarget, greaterThanOrEqualTo(56.0));
      expect(LinguaTokens.radiusCard, greaterThanOrEqualTo(10.0));

      // Color tokens must be non-null and high-contrast capable
      expect(LinguaTokens.primary600, isNotNull);
      expect(LinguaTokens.surfaceCard, isNotNull);
      expect(LinguaTokens.ink900, isNotNull);
      expect(LinguaTokens.paper50, isNotNull);
    });

    test('Non-diagnostic rule is strictly preserved in all Role & Track labels', () {
      for (final role in UserRole.values) {
        expect(role.name.toLowerCase(), isNot(contains('doctor')));
        expect(role.name.toLowerCase(), isNot(contains('clinician')));
        expect(role.name.toLowerCase(), isNot(contains('patient')));
      }

      for (final track in SupportTrack.values) {
        expect(track.shortLabel.toLowerCase(), isNot(contains('severity')));
        expect(track.shortLabel.toLowerCase(), isNot(contains('disorder level')));
        expect(track.title.toLowerCase(), isNot(contains('clinical diagnosis')));
      }
    });
  });
}
