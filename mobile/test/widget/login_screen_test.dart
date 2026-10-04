import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/app/providers/auth_provider.dart';
import 'package:lingua_ai/features/authentication/login_screen.dart';
import '../helpers/mock_auth_repository.dart';

void main() {
  group('LINGUA AI LoginScreen - Stitch Reference UI & Interaction Tests', () {
    Widget buildTestableLoginScreen({MockAuthRepository? authRepo}) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo ?? MockAuthRepository()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      );
    }

    testWidgets('Renders complete Stitch visual hierarchy, branding, and inputs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableLoginScreen());
      await tester.pumpAndSettle();

      // Top App Bar
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(
        find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('LinguaAI')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      // Headline & Subtitle
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in to continue your personalized learning journey.'), findsOneWidget);

      // Email field with sub-label
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Parent or Clinician'), findsOneWidget);
      expect(find.text('sarah.jenkins@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);

      // Password field with sub-label
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Case-sensitive'), findsOneWidget);
      expect(find.text('••••••••••••••'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Forgot password
      expect(find.text('Forgot password?'), findsOneWidget);

      // Sign In CTA
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

      // OR Divider
      expect(find.text('OR'), findsOneWidget);

      // Continue with Google
      expect(find.text('Continue with Google'), findsOneWidget);

      // Bottom Sign up link
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().contains("Don't have an account?") &&
            w.text.toPlainText().contains('Create account ↗')),
        findsOneWidget,
      );
    });

    testWidgets('Password visibility toggle toggles obscure state and icon',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableLoginScreen());
      await tester.pumpAndSettle();

      // Initially visibility is off (icon is visibility_outlined)
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // Tap toggle
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      // Now visibility icon is visibility_off_outlined
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('Email input displays green checkmark badge when valid format entered',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableLoginScreen());
      await tester.pumpAndSettle();

      // Initially no checkmark badge
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      // Enter valid email
      final emailField = find.widgetWithText(TextField, 'sarah.jenkins@example.com');
      await tester.enterText(emailField, 'sarah.jenkins@example.com');
      await tester.pump();

      // Checkmark badge appears
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('Empty email submission triggers inline validation warning',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableLoginScreen());
      await tester.pumpAndSettle();

      // Tap Sign In with empty fields
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('Tapping Forgot password navigates to ForgotPasswordScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableLoginScreen());
      await tester.pumpAndSettle();

      // Tap Forgot password?
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text('Enter your email to reset it.'), findsOneWidget);
      expect(find.text('Send reset link'), findsOneWidget);
      expect(find.text('Remember your password? '), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });
  });
}
