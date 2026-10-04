import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/learner_report_screen.dart';
import 'package:lingua_ai/features/collaboration/application/collaboration_providers.dart';

void main() {
  group('Specialist Learner Report (Stitch Reference) Widget & Responsive Tests', () {
    Widget buildTestWidget({
      String learnerId = 'lr-1',
      ReportViewMode? initialMode,
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
          'total_practice_time_minutes': 260,
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
          specialistLearnerDetailProvider('lr-3').overrideWith((ref) async {
            return {
              'learner_id': 'lr-3',
              'display_name': 'Liam K.',
              'age_band': 'teen',
              'support_focus': 'general',
              'baseline_status': 'pending',
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
            child: SizedBox(
              width: surfaceSize.width,
              height: surfaceSize.height,
              child: LearnerReportScreen(
                learnerId: learnerId,
                initialMode: initialMode,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Renders complete Learner Report Stitch visual hierarchy', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 1. Top App Bar
      expect(find.text('Learner Report'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

      // 2. Mode Switcher
      expect(find.text('Child (Aarav)'), findsOneWidget);
      expect(find.text('Adult (Maya)'), findsOneWidget);
      expect(find.text('No Activity'), findsOneWidget);
      expect(find.text('Skeleton'), findsOneWidget);

      // 3. Learner Identity / Context Card
      expect(find.text('Aarav Mehta'), findsOneWidget);
      expect(find.text('Child • 10 years old'), findsOneWidget);
      expect(find.text('Parent connected: Priya M.'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      // 4. Time Range Filter
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('3 Months'), findsOneWidget);

      // 5. 3 Summary Metrics
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('4h 20m'), findsOneWidget);
      expect(find.text('Audio Time'), findsOneWidget);
      expect(find.text('3 Active'), findsOneWidget);
      expect(find.text('Skills'), findsOneWidget);

      // 6. Practice Activity Card
      expect(find.text('Practice Activity'), findsOneWidget);
      expect(find.text('+18%'), findsOneWidget);
      expect(find.text('W1'), findsOneWidget);
      expect(find.text('W2'), findsOneWidget);
      expect(find.text('W3'), findsOneWidget);
      expect(find.text('W4 (Now)'), findsOneWidget);
      expect(find.text('Weekly Rhythm:'), findsOneWidget);

      // 7. Skill Progress Section
      expect(find.text('Skill Progress'), findsOneWidget);
      expect(find.text('Phonological Awareness'), findsOneWidget);
      expect(find.text('Level 4'), findsOneWidget);
      expect(find.text('78%'), findsOneWidget);
      expect(find.text('Reading Fluency & Pacing'), findsOneWidget);
      expect(find.text('Level 3'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('Syllable Segmentation'), findsOneWidget);
      expect(find.text('Level 2'), findsOneWidget);
      expect(find.text('52%'), findsOneWidget);
      expect(find.textContaining('Steady Improvement:'), findsOneWidget);

      // 8. Recent Sessions
      expect(find.text('Recent Sessions'), findsOneWidget);
      expect(find.text('Live Support Session'), findsOneWidget);
      expect(find.text('Practice Review'), findsOneWidget);
      expect(find.text('Completed'), findsNWidgets(2));

      // 9. Specialist Reflection
      expect(find.text('Dr. Maya Lin, CCC-SLP'), findsOneWidget);
      expect(find.text('Latest Reflection • Oct 16'), findsOneWidget);
      expect(find.text('View Full Reflection'), findsOneWidget);

      // 10. Action Buttons & Security Footnote
      expect(find.text('Share Report with Circle'), findsOneWidget);
      expect(find.text('Download PDF Summary'), findsOneWidget);
      expect(
        find.text('Protected by Lingua AI Security • Shared only with approved support circle'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping switcher updates view to Adult (Maya S.)', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Adult (Maya)
      await tester.tap(find.text('Adult (Maya)'));
      await tester.pumpAndSettle();

      expect(find.text('Maya S.'), findsOneWidget);
      expect(find.text('Adult • Self-connected learner'), findsOneWidget);
      expect(find.text('Self-managed practice'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('6h 40m'), findsOneWidget);
      expect(find.text('4 Active'), findsOneWidget);
      expect(find.text('+24%'), findsOneWidget);
      expect(find.text('Presentation Pacing & Cadence'), findsOneWidget);
    });

    testWidgets('Tapping switcher updates view to No Activity (Empty State)', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll and tap No Activity
      await tester.ensureVisible(find.text('No Activity'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No Activity'));
      await tester.pumpAndSettle();

      expect(find.text('Liam K.'), findsOneWidget);
      expect(find.text('Teen • 14 years old'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('0m'), findsOneWidget);
      expect(find.text('0 Active'), findsOneWidget);
      expect(find.text('No practice sessions logged yet'), findsOneWidget);
      expect(find.text('No completed sessions in this period.'), findsOneWidget);
    });

    testWidgets('Tapping switcher updates view to Skeleton loading state', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll and tap Skeleton
      await tester.ensureVisible(find.text('Skeleton'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skeleton'));
      await tester.pumpAndSettle();

      // Header remains interactive, body switches to shimmer containers
      expect(find.text('Learner Report'), findsOneWidget);
      expect(find.text('Child (Aarav)'), findsOneWidget);
      expect(find.text('Aarav Mehta'), findsNothing);
    });

    testWidgets('Tapping View Full Reflection opens modal', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('View Full Reflection'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View Full Reflection'));
      await tester.pumpAndSettle();

      expect(find.text('Specialist Reflection • Oct 16, 2024'), findsOneWidget);
      expect(find.text('Close Reflection'), findsOneWidget);
    });

    testWidgets('Tapping More options opens report options modal', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Report Options'), findsOneWidget);
      expect(find.text('Refresh Data'), findsOneWidget);
      expect(find.text('Export Summary PDF'), findsOneWidget);
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
        expect(find.text('Learner Report'), findsOneWidget);
        expect(find.text('Practice Activity'), findsOneWidget);
        expect(find.text('Skill Progress'), findsOneWidget);
        expect(find.text('Share Report with Circle'), findsOneWidget);
      });
    }
  });
}
