import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/core/widgets/non_diagnostic_banner.dart';

void main() {
  group('NonDiagnosticBanner Safety Component Tests', () {
    testWidgets('Displays mandatory clinical safety disclaimer', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NonDiagnosticBanner(),
          ),
        ),
      );

      expect(
        find.text('Screening & Learning Support • Not a medical or clinical diagnosis substitute'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('Renders compact variant with smaller padding and icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NonDiagnosticBanner(compact: true),
          ),
        ),
      );

      expect(
        find.text('Screening & Learning Support • Not a medical or clinical diagnosis substitute'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });
  });
}
