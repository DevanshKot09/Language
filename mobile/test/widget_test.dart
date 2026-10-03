import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/main.dart';

void main() {
  testWidgets('LINGUA AI smoke test loads Welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LinguaApp());
    expect(find.text('LINGUA AI'), findsWidgets);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
