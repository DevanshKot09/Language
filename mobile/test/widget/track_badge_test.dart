import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/core/widgets/track_badge.dart';
import 'package:lingua_ai/shared/models/skill_track.dart';

void main() {
  group('TrackBadge Distinct Track Indicator Tests', () {
    testWidgets('Renders DLD badge with proper label and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrackBadge(track: SupportTrack.dldSpokenLanguage),
          ),
        ),
      );

      expect(find.text('Spoken Language Support (DLD Focus)'), findsOneWidget);
    });

    testWidgets('Renders Dyslexia badge with distinct color and label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrackBadge(track: SupportTrack.dyslexiaLiteracy),
          ),
        ),
      );

      expect(find.text('Literacy & Reading Support (Dyslexia Focus)'), findsOneWidget);
    });

    testWidgets('Renders compact track badge with short label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrackBadge(track: SupportTrack.dldSpokenLanguage, compact: true),
          ),
        ),
      );

      expect(find.text('DLD Spoken Track'), findsOneWidget);
    });
  });
}
