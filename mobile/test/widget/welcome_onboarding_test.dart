import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/features/welcome/welcome_screen.dart';

void main() {
  group('LINGUA AI 3-Screen Welcome / Onboarding Flow Tests', () {
    testWidgets('Screen 1 renders exact hierarchy, typography, and controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Top bar on Screen 1: Skip present, no back button
      expect(find.text('Skip'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      // Headline & Description for Screen 1
      expect(find.text('Language learning, made\npersonal.'), findsOneWidget);
      expect(
        find.text('Build communication skills through\nguided practice designed around you.'),
        findsOneWidget,
      );

      // Primary CTA on Screen 1 is "Next"
      expect(find.text('Next'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

      // Secondary action ("Sign in") should NOT be present on Screen 1
      expect(find.text('Sign in'), findsNothing);
    });

    testWidgets('Navigates smoothly from Screen 1 -> Screen 2 -> Screen 3 via Next button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Tap Next to advance to Screen 2
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Screen 2 assertions
      expect(find.text('Practice at your pace.'), findsOneWidget);
      expect(
        find.text('Follow focused activities that adapt to\nyour learning journey.'),
        findsOneWidget,
      );
      expect(find.text('Personalized'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Tap Next to advance to Screen 3
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Screen 3 assertions
      expect(find.text('Learn with the right support.'), findsOneWidget);
      expect(
        find.text('Track progress and stay connected with the\npeople who support your learning.'),
        findsOneWidget,
      );
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Circular Back button returns accurately from Screen 3 -> Screen 2 -> Screen 1', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Advance to Screen 2 then Screen 3
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Learn with the right support.'), findsOneWidget);

      // Tap Back to return to Screen 2
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Practice at your pace.'), findsOneWidget);

      // Tap Back to return to Screen 1
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Language learning, made\npersonal.'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('Responsive on compact viewport (320x640) without any overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('Language learning, made\npersonal.'), findsOneWidget);

      // Advance to Screen 2
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);

      // Advance to Screen 3
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Responsive on large modern viewport (412x915) without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('Language learning, made\npersonal.'), findsOneWidget);
    });
  });
}
