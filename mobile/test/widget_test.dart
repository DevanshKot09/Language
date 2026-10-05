import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingua_ai/app/router/app_router.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LINGUA AI smoke test loads Splash screen and transitions to Welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRouter.generateRoute,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    // Verify initial launch displays LINGUA AI Splash branding
    expect(find.text('LINGUA'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Learn. Practice. Communicate.'), findsOneWidget);
    expect(find.text('SPEECH & LANGUAGE AI'), findsOneWidget);

    // Advance clock past splash initialization, exit transition, and route transition
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify smooth transition to WelcomeScreen
    expect(find.text('Language learning, made\npersonal.'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
