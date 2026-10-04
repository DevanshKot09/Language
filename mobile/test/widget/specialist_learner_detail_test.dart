import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/specialist_learner_detail_screen.dart';
import 'package:lingua_ai/features/collaboration/application/collaboration_providers.dart';

void main() {
  group('Specialist Learner Profile (Stitch Reference) Widget & Responsive Tests', () {
    Widget buildTestWidget({
      String learnerId = 'lr-1',
      Size surfaceSize = const Size(390, 844),
      Map<String, dynamic>? mockData,
    }) {
      final overrideData = mockData ?? {
        'learner_id': 'lr-1',
        'display_name': 'Aarav Mehta',
        'age_band': 'child',
        'support_focus': 'dld_track',
        'baseline_status': 'in_progress',
        'progress_summary': {
          'total_lessons_completed': 12,
          'total_exercises_attempted': 45,
          'total_practice_time_minutes': 78,
          'independent_rate': 82.5,
        },
        'skills': [],
        'goals': [],
        'ai_recommendations': [],
      };

      return ProviderScope(
        overrides: [
          specialistLearnerDetailProvider(learnerId).overrideWith((ref) async {
            return overrideData;
          }),
          specialistLearnerDetailProvider('lr-2').overrideWith((ref) async {
            return {
              'learner_id': 'lr-2',
              'display_name': 'Maya S.',
              'age_band': 'adult',
              'support_focus': 'articulation',
              'baseline_status': 'verified',
              'progress_summary': {},
              'skills': [],
              'goals': [],
              'ai_recommendations': [],
            };
          }),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: surfaceSize),
            child: SpecialistLearnerDetailScreen(learnerId: learnerId),
          ),
        ),
      );
    }

    testWidgets('Renders complete Learner Profile Stitch visual hierarchy', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Top App Bar
      expect(find.text('Learner Profile'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

      // Switcher
      expect(find.text('Aarav M. (Child)'), findsOneWidget);
      expect(find.text('Maya S. (Adult)'), findsOneWidget);

      // Identity Card
      expect(find.text('Aarav Mehta'), findsOneWidget);
      expect(find.text('Child • 10 years old'), findsOneWidget);
      expect(find.text('Parent connected: Priya M.'), findsOneWidget);
      expect(find.text('14-Day Practice Streak'), findsOneWidget);
      expect(find.text('Top 5% Engaged'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      // Action Grid
      expect(find.text('Start Session'), findsOneWidget);
      expect(find.text('Live 1-on-1 Practice'), findsOneWidget);
      expect(find.text('View Reports'), findsOneWidget);
      expect(find.text('Schedule'), findsNWidgets(2)); // Grid + Bottom nav
      expect(find.text('Guidance Chat'), findsOneWidget);

      // Support Consent Card
      expect(find.text('Support Consent Confirmed'), findsOneWidget);
      expect(find.text('Simulate'), findsOneWidget);

      // Next Session Card
      expect(find.text('NEXT SESSION'), findsOneWidget);
      expect(find.text('Live Support Session'), findsOneWidget);
      expect(find.text('Join Session'), findsOneWidget);

      // Learning Focus
      expect(find.text('Learning Focus'), findsOneWidget);
      expect(find.text('CURRENT FOCUS AREA'), findsOneWidget);
      expect(find.text('Phonological Awareness (/r/ blends)'), findsOneWidget);
      expect(find.text('Practice Frequency'), findsOneWidget);
      expect(find.text('3 Sessions'), findsOneWidget);
      expect(find.text('Last Check-In'), findsOneWidget);

      // Milestone Progress
      expect(find.text('Milestone Progress'), findsOneWidget);
      expect(find.text('Month 3'), findsOneWidget);
      expect(find.text('Phonemic Awareness'), findsOneWidget);
      expect(find.text('Reading Fluency & Pacing'), findsOneWidget);
      expect(find.text('Syllable Segmentation'), findsOneWidget);

      // Latest Reflection
      expect(find.text('LATEST REFLECTION'), findsOneWidget);
      expect(find.text('Weekly Speech Pacing & Blends'), findsOneWidget);
      expect(find.text('View Full Report'), findsOneWidget);

      // Support Team
      expect(find.text('Support Team'), findsOneWidget);
      expect(find.text('Open Chat'), findsOneWidget);
      expect(find.text('Priya Mehta'), findsOneWidget);
      expect(find.text('Dr. Maya Lin'), findsOneWidget);
      expect(find.text('Mrs. Eleanor Davies'), findsOneWidget);

      // Bottom Navigation
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Caseload'), findsOneWidget);
      expect(find.text('Schedule'), findsNWidgets(2)); // Card + Bottom Nav
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Profile'), findsNothing);
    });

    testWidgets('Tapping switcher updates view to Adult (Maya S.)', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Maya S.
      await tester.tap(find.text('Maya S. (Adult)'));
      await tester.pumpAndSettle();

      expect(find.text('Maya S.'), findsNWidgets(2)); // Identity card + Support team
      expect(find.text('Adult • Self-connected learner'), findsOneWidget);
      expect(find.text('Workplace Presentation Pacing (88 WPM)'), findsOneWidget);
      expect(find.text('21-Day Practice Streak'), findsOneWidget);
    });

    testWidgets('Tapping Simulate toggles consent state', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Support Consent Confirmed'), findsOneWidget);

      await tester.tap(find.text('Simulate'));
      await tester.pumpAndSettle();

      expect(find.text('Consent Pending Verification'), findsOneWidget);

      await tester.tap(find.text('Simulate'));
      await tester.pumpAndSettle();

      expect(find.text('Support Consent Confirmed'), findsOneWidget);
    });

    testWidgets('Tapping Start Session opens session modal', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Session'));
      await tester.pumpAndSettle();

      expect(find.text('Connect Now'), findsOneWidget);
    });

    testWidgets('Tapping Schedule opens slot booking modal', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Schedule').first);
      await tester.pumpAndSettle();

      expect(find.text('Upcoming Schedule Slots'), findsOneWidget);
    });

    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      testWidgets('Responsive Layout: No overflow on ${width}px width', (tester) async {
        tester.view.physicalSize = Size(width * 2.0, 844 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget(surfaceSize: Size(width, 844)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Check key elements are present and not overflowing
        expect(find.text('Learner Profile'), findsOneWidget);
        expect(find.text('Start Session'), findsOneWidget);
        expect(find.text('Support Consent Confirmed'), findsOneWidget);
      });
    }
  });
}
