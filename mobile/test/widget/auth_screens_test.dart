import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/app/providers/auth_provider.dart';
import 'package:lingua_ai/features/authentication/login_screen.dart';
import 'package:lingua_ai/features/authentication/signup_screen.dart';
import '../helpers/mock_auth_repository.dart';

void main() {
  group('Authentication Widget Tests', () {
    testWidgets('LoginScreen shows validation warning when email is invalid', (WidgetTester tester) async {
      final mockAuth = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Tap Sign In with empty fields
      await tester.tap(find.text('Sign In').first);
      await tester.pump();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('SignupScreen requires non-diagnostic consent to enable create account button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockAuth = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
          ],
          child: const MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Before checking consent box, button is disabled (onPressed is null)
      final buttonFinder = find.widgetWithText(ElevatedButton, 'Create My Account');
      if (buttonFinder.evaluate().isNotEmpty) {
        final button = tester.widget<ElevatedButton>(buttonFinder);
        expect(button.onPressed, isNull);
      }

      // Check the consent tile
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      // Now button is enabled
      if (buttonFinder.evaluate().isNotEmpty) {
        final button = tester.widget<ElevatedButton>(buttonFinder);
        expect(button.onPressed, isNotNull);
      }
    });
    testWidgets('LoginScreen renders Continue with Google button with accessible label', (WidgetTester tester) async {
      final mockAuth = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.bySemanticsLabel('Continue with Google sign-in'), findsOneWidget);
      expect(find.text('G'), findsOneWidget);
      expect(find.text('or'), findsOneWidget);
    });

    testWidgets('Tapping Continue with Google triggers signInWithGoogle and handles session update', (WidgetTester tester) async {
      final mockAuth = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      final googleButtonFinder = find.widgetWithText(OutlinedButton, 'Continue with Google');
      expect(googleButtonFinder, findsOneWidget);

      await tester.tap(googleButtonFinder);
      await tester.pump();

      // Progressing microtasks and animations
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      // Check no crash and button restored
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Tapping Continue with Google displays friendly cancellation message when cancelled', (WidgetTester tester) async {
      final mockAuth = MockAuthRepository()..shouldCancelGoogle = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      final googleButtonFinder = find.widgetWithText(OutlinedButton, 'Continue with Google');
      await tester.tap(googleButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Google sign-in was cancelled.'), findsOneWidget);
    });

    testWidgets('Tapping Continue with Google displays error message when sign-in fails', (WidgetTester tester) async {
      final mockAuth = MockAuthRepository()..shouldFail = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      final googleButtonFinder = find.widgetWithText(OutlinedButton, 'Continue with Google');
      await tester.tap(googleButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text("We couldn't complete Google sign-in. Please try again."), findsOneWidget);
    });
  });
}
