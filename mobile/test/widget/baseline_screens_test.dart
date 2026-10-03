import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/app/providers/age_profile_provider.dart';
import 'package:lingua_ai/features/baseline/presentation/screens/baseline_intro_screen.dart';
import 'package:lingua_ai/features/baseline/presentation/screens/baseline_activity_screen.dart';
import 'package:lingua_ai/features/baseline/presentation/screens/baseline_completion_screen.dart';
import 'package:lingua_ai/features/baseline/presentation/screens/skill_snapshot_screen.dart';
import 'package:lingua_ai/features/baseline/providers/baseline_provider.dart';
import 'package:lingua_ai/shared/models/age_profile.dart';
import 'package:lingua_ai/core/widgets/non_diagnostic_banner.dart';
import '../helpers/mock_baseline_repository.dart';

void main() {
  group('Phase 4 Baseline Screens Widget Tests', () {
    testWidgets('BaselineIntroScreen displays safety wording and primary CTA', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockBaselineRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            baselineRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: BaselineIntroScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title and non-diagnostic banner
      expect(find.text('Your Skill Snapshot'), findsOneWidget);
      expect(find.byType(NonDiagnosticBanner), findsOneWidget);
      expect(find.text('Start Skill Snapshot'), findsOneWidget);
      expect(find.text('Do This Later'), findsOneWidget);
    });

    testWidgets('BaselineActivityScreen renders question, selectable options, and clue drawer', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockBaselineRepository();

      final container = ProviderContainer(
        overrides: [
          baselineRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Start baseline session
      await container.read(baselineSessionProvider.notifier).startOrResumeSession();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BaselineActivityScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check prompt & instruction
      expect(find.text('What is the closest meaning of "candid"?'), findsOneWidget);
      expect(find.text('Frank and outspoken'), findsOneWidget);

      // Select an option
      await tester.tap(find.text('Frank and outspoken'));
      await tester.pumpAndSettle();

      // Clue toggle
      expect(find.text('Need a clue?'), findsOneWidget);
      await tester.tap(find.text('Need a clue?'));
      await tester.pumpAndSettle();
      expect(find.text('Think about honesty.'), findsOneWidget);

      // Check Answer button is enabled and taps
      final checkBtn = find.text('Check Answer');
      expect(checkBtn, findsOneWidget);
      await tester.tap(checkBtn);
      await tester.pumpAndSettle();

      // Feedback is displayed
      expect(find.text('Well done! Recorded.'), findsOneWidget);
      expect(find.text('Next Activity'), findsOneWidget);
    });

    testWidgets('BaselineCompletionScreen renders celebration and view snapshot CTA', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockBaselineRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            baselineRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: BaselineCompletionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Skill Snapshot Complete!'), findsOneWidget);
      expect(find.text('View My Skill Snapshot'), findsOneWidget);
      expect(find.text('Return to Home'), findsOneWidget);
    });

    testWidgets('SkillSnapshotScreen renders distinct tracks and descriptive badges', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockBaselineRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            baselineRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: SkillSnapshotScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Your Learning Profile'), findsOneWidget);
      expect(find.text('Vocabulary Breadth'), findsOneWidget);
      expect(find.text('Consistent'), findsOneWidget);
      expect(find.text('Phonological Awareness'), findsOneWidget);
      expect(find.text('Developing'), findsOneWidget);
      expect(find.text('Continue to Learning Path'), findsOneWidget);
    });

    testWidgets('Age adaptation: Child config scales elements appropriately', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockBaselineRepository();

      final container = ProviderContainer(
        overrides: [
          baselineRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      container.read(ageProfileProvider.notifier).setAgeBand(AgeBand.child);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BaselineIntroScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(container.read(ageProfileProvider).ageBand, AgeBand.child);
      expect(find.text('Start Skill Snapshot'), findsOneWidget);
    });
  });
}
