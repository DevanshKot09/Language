import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingua_ai/app/providers/session_provider.dart';
import 'package:lingua_ai/app/router/app_router.dart';
import 'package:lingua_ai/features/welcome/splash_screen.dart';
import 'package:lingua_ai/shared/models/auth_user.dart';
import 'package:lingua_ai/shared/models/user_role.dart';
import 'package:lingua_ai/shared/models/user_profile.dart';
import 'package:lingua_ai/shared/models/skill_track.dart';
import 'package:lingua_ai/shared/models/age_profile.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LINGUA AI Splash Screen Visual Hierarchy & Unit Tests', () {
    testWidgets('Renders all primary visual elements matching reference', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(autoInitialize: false),
          ),
        ),
      );

      // Advance entrance animation so all components are fully visible
      await tester.pump(const Duration(milliseconds: 600));

      // 1. App Icon with Semantics
      expect(find.bySemanticsLabel('LINGUA AI Official Brand Logo'), findsOneWidget);

      // 2. Brand Wordmark & AI Pill
      expect(find.text('LINGUA'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);

      // 3. Tagline
      expect(find.text('Learn. Practice. Communicate.'), findsOneWidget);

      // 4. Bottom Context Badge
      expect(find.text('SPEECH & LANGUAGE AI'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);

      // Verify no forbidden buttons exist on splash
      expect(find.text('Get Started'), findsNothing);
      expect(find.text('Sign In'), findsNothing);
      expect(find.text('Sign Up'), findsNothing);
    });

    testWidgets('Responsive across compact mobile viewport (320x640) without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(autoInitialize: false),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.text('LINGUA'), findsOneWidget);
      expect(find.text('Learn. Practice. Communicate.'), findsOneWidget);
    });

    testWidgets('Responsive across modern large mobile viewport (412x915) without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(autoInitialize: false),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.text('LINGUA'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
    });

    testWidgets('Navigates to home when authenticated as learner', (WidgetTester tester) async {
      const mockUser = AuthUser(
        id: 'user-001',
        email: 'learner@lingua.ai',
        role: UserRole.learner,
        status: 'active',
      );

      const mockProfile = UserProfile(
        id: 'prof-001',
        userId: 'user-001',
        displayName: 'Sammy',
        ageBand: AgeBand.child,
        supportFocus: SupportTrack.dldSpokenLanguage,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userSessionProvider.overrideWith(
              () => _MockUserSessionNotifier(
                const UserSessionState(
                  status: SessionStatus.authenticated,
                  currentUser: mockUser,
                  profile: mockProfile,
                  currentRole: UserRole.learner,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRouter.generateRoute,
          ),
        ),
      );

      expect(find.text('LINGUA'), findsOneWidget);

      // Advance past splash transition
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should have navigated away from splash
      expect(find.text('LINGUA'), findsNothing);
    });

    testWidgets('Navigates to specialist dashboard when authenticated as specialist', (WidgetTester tester) async {
      const mockUser = AuthUser(
        id: 'spec-001',
        email: 'specialist@lingua.ai',
        role: UserRole.specialist,
        status: 'active',
      );

      const mockProfile = UserProfile(
        id: 'prof-spec-001',
        userId: 'spec-001',
        displayName: 'Dr. Sarah Smith',
        ageBand: AgeBand.adult,
        supportFocus: SupportTrack.dldSpokenLanguage,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userSessionProvider.overrideWith(
              () => _MockUserSessionNotifier(
                const UserSessionState(
                  status: SessionStatus.authenticated,
                  currentUser: mockUser,
                  profile: mockProfile,
                  currentRole: UserRole.specialist,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRouter.generateRoute,
          ),
        ),
      );

      expect(find.text('LINGUA'), findsOneWidget);

      // Advance past splash transition
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should be on specialist dashboard
      expect(find.text('Specialist Caseload'), findsOneWidget);
    });
  });
}

class _MockUserSessionNotifier extends UserSessionNotifier {
  final UserSessionState _initialState;

  _MockUserSessionNotifier(this._initialState);

  @override
  UserSessionState build() => _initialState;

  @override
  Future<void> restoreSession() async {
    state = _initialState;
  }
}
