import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/core/widgets/lingua_button.dart';

void main() {
  group('LinguaButton Reusable Component Tests', () {
    testWidgets('Renders label and responds to tap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinguaButton(
              label: 'Continue',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      expect(tapped, isTrue);
    });

    testWidgets('Shows CircularProgressIndicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinguaButton(
              label: 'Submit',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('Meets minimum touch target size for accessibility (>= 48px)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinguaButton(
              label: 'Accessible Target',
              onPressed: () {},
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(LinguaButton);
      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('Renders long labels at narrow widths without RenderFlex overflow', (WidgetTester tester) async {
      final testLabels = [
        ('Continue with Google', const Icon(Icons.g_mobiledata), null),
        ('Download PDF Report', null, Icons.picture_as_pdf),
        ('Create Assignment', null, Icons.add_task),
        ('View Learning Progress', null, Icons.trending_up),
        ('Spoken Language (DLD)', null, null),
        ('Sign In with Magic Link (Passwordless)', null, Icons.mail_outline),
      ];

      for (final (label, leading, icon) in testLabels) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 280, // Narrow Android mobile viewport constraint
                  child: LinguaButton(
                    label: label,
                    leading: leading,
                    icon: icon,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        // Verify button rendered and label text exists
        expect(find.text(label), findsOneWidget);

        // Verify no Flutter error / RenderFlex overflow was caught
        expect(tester.takeException(), isNull);
      }
    });
  });
}
