import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/app/providers/auth_provider.dart';
import 'package:lingua_ai/features/authentication/forgot_password_screen.dart';
import '../helpers/mock_auth_repository.dart';

void main() {
  group('LINGUA AI ForgotPasswordScreen - Stitch Reference UI & Interaction Tests', () {
    Widget buildTestableForgotPasswordScreen({
      MockAuthRepository? authRepo,
      String? initialEmail,
    }) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo ?? MockAuthRepository()),
        ],
        child: MaterialApp(
          home: ForgotPasswordScreen(initialEmail: initialEmail),
        ),
      );
    }

    testWidgets('Renders complete Stitch reference visual hierarchy and elements',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableForgotPasswordScreen());
      await tester.pump();

      // Top Header: Back button + Lingua AI wordmark
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(
        find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('Lingua AI')),
        findsOneWidget,
      );

      // Recovery Orbit Visual: central lock icon & ambient sparkles
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

      // Card Content
      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text('Enter your email to reset it.'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);
      expect(find.text('you@example.com'), findsOneWidget);

      // Primary CTA
      expect(find.text('Send reset link'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      // Sub-card navigation & security badge
      expect(find.text('Remember your password? '), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
      expect(
        find.text('Protected by Lingua Child-Safe AI Security • 256-bit Encryption'),
        findsOneWidget,
      );
    });

    testWidgets('Empty or invalid email triggers inline validation error',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableForgotPasswordScreen());
      await tester.pump();

      // Tap Send reset link with empty email
      await tester.tap(find.text('Send reset link'));
      await tester.pump();

      expect(find.text('Please enter your email address.'), findsOneWidget);

      // Enter invalid email format
      final emailField = find.widgetWithText(TextField, 'you@example.com');
      await tester.enterText(emailField, 'notanemail');
      await tester.pump();

      await tester.tap(find.text('Send reset link'));
      await tester.pump();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
    });

    testWidgets('Valid email submission sends reset request and displays animated success state',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockAuth = MockAuthRepository();
      await tester.pumpWidget(
        buildTestableForgotPasswordScreen(
          authRepo: mockAuth,
          initialEmail: 'elena.speaks@linguakids.com',
        ),
      );
      await tester.pump();

      // Tap Send reset link
      await tester.tap(find.text('Send reset link'));
      await tester.pump(); // Start async submit

      // Verify repository method called with correct recipient email
      expect(mockAuth.lastResetEmailRequested, 'elena.speaks@linguakids.com');

      // Settle animations
      await tester.pumpAndSettle();

      // Success State verification
      expect(find.text('Check your email'), findsOneWidget);
      expect(find.text('We sent you a reset link.'), findsOneWidget);
      expect(find.text('elena.speaks@linguakids.com'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
    });

    testWidgets('Failure state displays user-friendly error message without crashing',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockAuth = MockAuthRepository()..shouldFailReset = true;
      await tester.pumpWidget(
        buildTestableForgotPasswordScreen(
          authRepo: mockAuth,
          initialEmail: 'elena.speaks@linguakids.com',
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
      expect(find.text('Send reset link'), findsOneWidget);
    });
  });
}
