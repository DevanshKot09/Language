import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/app/providers/auth_provider.dart';
import 'package:lingua_ai/features/authentication/signup_screen.dart';
import '../helpers/mock_auth_repository.dart';

void main() {
  group('LINGUA AI SignupScreen - Reference UI & Interaction Tests', () {
    Widget buildTestableSignupScreen({MockAuthRepository? authRepo}) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo ?? MockAuthRepository()),
        ],
        child: const MaterialApp(
          home: SignupScreen(),
        ),
      );
    }

    testWidgets('STATE 1: Initial form has Adult selected, title, subtitle, and all fields',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableSignupScreen());
      await tester.pumpAndSettle();

      // Header & Title
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Start your personalized language learning journey.'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('LinguaAI')),
        findsOneWidget,
      );

      // Fields
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
      expect(find.text('Enter your full name'), findsOneWidget);

      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Verification required'), findsOneWidget);
      expect(find.text('Send OTP'), findsOneWidget);

      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Create a password'), findsOneWidget);
      expect(find.text('8+ characters'), findsOneWidget);

      // Role Selection Grid
      expect(find.text('How will you use LINGUA AI?'), findsOneWidget);
      expect(find.text('Adult'), findsOneWidget);
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Teacher'), findsOneWidget);
      expect(find.text('Specialist'), findsOneWidget);

      // Child age group should NOT be visible when Adult is selected
      expect(find.text('Child age group'), findsNothing);

      // Consent & Buttons
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText && w.text.toPlainText().contains('Terms & Privacy Policy')),
        findsOneWidget,
      );
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText && w.text.toPlainText().contains('Already have an account?')),
        findsOneWidget,
      );
    });

    testWidgets('STATE 2: Selecting Parent reveals Child age group (5–11 and 11–18)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableSignupScreen());
      await tester.pumpAndSettle();

      // Initially hidden
      expect(find.text('Child age group'), findsNothing);

      // Tap Parent
      await tester.ensureVisible(find.text('Parent'));
      await tester.tap(find.text('Parent'));
      await tester.pumpAndSettle();

      // Revealed
      expect(find.text('Child age group'), findsOneWidget);
      expect(find.text('5–11 years'), findsOneWidget);
      expect(find.text('11–18 years'), findsOneWidget);

      // Tap 11–18 years
      await tester.tap(find.text('11–18 years'));
      await tester.pumpAndSettle();
      expect(find.text('11–18 years'), findsOneWidget);
    });

    testWidgets('STATE 3 & 4: Switching to Teacher or Specialist collapses Child age group',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableSignupScreen());
      await tester.pumpAndSettle();

      // Tap Parent -> shows
      await tester.ensureVisible(find.text('Parent'));
      await tester.tap(find.text('Parent'));
      await tester.pumpAndSettle();
      expect(find.text('Child age group'), findsOneWidget);

      // Tap Teacher -> hides
      await tester.tap(find.text('Teacher'));
      await tester.pumpAndSettle();
      expect(find.text('Child age group'), findsNothing);

      // Tap Specialist -> still hidden
      await tester.tap(find.text('Specialist'));
      await tester.pumpAndSettle();
      expect(find.text('Child age group'), findsNothing);
    });

    testWidgets('STATE 5, 6, 7: Email Send OTP shows verification boxes and countdown',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableSignupScreen());
      await tester.pumpAndSettle();

      // Enter email
      final emailFinder = find.widgetWithText(TextField, 'you@example.com');
      await tester.enterText(emailFinder, 'sarah.jenkins@example.com');
      await tester.pump();

      // Tap Send OTP
      await tester.tap(find.text('Send OTP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // OTP section appears
      expect(find.text('Verification code'), findsOneWidget);
      expect(find.textContaining('Resend in'), findsOneWidget);

      // Enter 6 digits
      final otpBoxes = find.byWidgetPredicate((w) => w is TextField && w.maxLength == 1);
      expect(otpBoxes, findsNWidgets(6));
      for (int i = 0; i < 6; i++) {
        await tester.enterText(otpBoxes.at(i), '1');
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Shows Verified badge
      expect(find.text('Verified'), findsWidgets);
    });

    testWidgets('STATE 8 & 9: Password strength updates correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableSignupScreen());
      await tester.pumpAndSettle();

      final passwordFinder = find.widgetWithText(TextField, 'Create a password');

      // Weak: < 8 chars
      await tester.enterText(passwordFinder, 'abc');
      await tester.pump();
      expect(find.text('Weak'), findsOneWidget);

      // Medium: 8+ chars letters + numbers
      await tester.enterText(passwordFinder, 'password123');
      await tester.pump();
      expect(find.text('Medium'), findsOneWidget);

      // Strong: 8+ chars letters + numbers + special chars
      await tester.enterText(passwordFinder, 'Password123!');
      await tester.pump();
      expect(find.text('Strong'), findsOneWidget);
    });

    testWidgets('STATE 10: Validation errors show if submitting empty fields',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableSignupScreen());
      await tester.pumpAndSettle();

      // Tap Create Account with empty fields
      await tester.ensureVisible(find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Should display validation error
      expect(find.text('Please enter your full name.'), findsOneWidget);
    });
  });
}
