import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/features/progress/domain/models/progress_models.dart';
import 'package:lingua_ai/features/progress/domain/models/goal_models.dart';
import 'package:lingua_ai/features/progress/domain/models/achievement_models.dart';
import 'package:lingua_ai/features/progress/presentation/widgets/progress_summary_card.dart';
import 'package:lingua_ai/features/progress/presentation/widgets/skill_progress_card.dart';
import 'package:lingua_ai/features/progress/presentation/widgets/goal_card.dart';
import 'package:lingua_ai/features/progress/presentation/widgets/achievement_card.dart';
import 'package:lingua_ai/features/progress/presentation/widgets/progress_chart_card.dart';
import 'package:lingua_ai/features/progress/presentation/widgets/ai_progress_insight_card.dart';
import 'package:lingua_ai/features/progress/presentation/widgets/timeline_item_tile.dart';
import 'package:lingua_ai/features/progress/presentation/screens/progress_screen.dart';
import 'package:lingua_ai/features/progress/presentation/screens/skill_progress_detail_screen.dart';
import 'package:lingua_ai/features/progress/presentation/screens/goals_dashboard_screen.dart';
import 'package:lingua_ai/features/progress/presentation/screens/create_goal_screen.dart';
import 'package:lingua_ai/features/progress/presentation/screens/achievement_center_screen.dart';
import 'package:lingua_ai/features/progress/application/progress_providers.dart';

void main() {
  final sampleSummary = ProgressSummary(
    totalLessonsCompleted: 8,
    totalLessonsInProgress: 2,
    totalExercisesAttempted: 24,
    totalPracticeTimeMinutes: 42,
    independentRate: 85.0,
    consistencyStreakDays: 3,
    activeGoalsCount: 2,
    completedGoalsCount: 1,
    achievementsCount: 4,
  );

  final sampleSkill = SkillProgressItem(
    skillId: 's-1',
    skillCode: 'dld_vocab',
    name: 'Vocabulary Depth',
    domain: 'vocabulary',
    track: 'dld_track',
    currentBand: 'practicing',
    attemptCount: 10,
    lessonCompletedCount: 2,
    accuracy: 0.88,
  );

  final sampleGoal = LearnerGoal(
    id: 'g-1',
    userId: 'u-1',
    title: 'Complete 3 Reading Activities',
    description: 'Build confidence with short stories',
    targetCount: 3,
    currentCount: 2,
    status: 'active',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final sampleAchievement = AchievementItem(
    id: 'a-1',
    code: 'first_lesson',
    title: 'First Practice Step',
    description: 'Completed your first practice lesson.',
    category: 'learning',
    iconName: 'school',
    threshold: 1,
    badgeTier: 'bronze',
    isUnlocked: true,
    progressValue: 1,
  );

  final sampleTrend = ProgressTrend(
    days: [
      WeeklyActivityDay(dayName: 'Mon', date: '2026-09-28', activityCount: 3, practiceMinutes: 6),
      WeeklyActivityDay(dayName: 'Tue', date: '2026-09-29', activityCount: 0, practiceMinutes: 0),
      WeeklyActivityDay(dayName: 'Wed', date: '2026-09-30', activityCount: 4, practiceMinutes: 8),
      WeeklyActivityDay(dayName: 'Thu', date: '2026-10-01', activityCount: 2, practiceMinutes: 4),
    ],
    accessibleDescription: 'Over the past 7 days you completed 9 learning activities across 3 active days.',
  );

  final sampleDashboard = ProgressDashboardData(
    summary: sampleSummary,
    activeTrack: 'both_track',
    skills: [sampleSkill],
    dldSkills: [sampleSkill],
    dyslexiaSkills: [],
    activeGoals: [sampleGoal],
    recentAchievements: [sampleAchievement],
    timeline: [
      ActivityTimelineItem(
        id: 't-1',
        eventType: 'lesson_completed',
        title: 'Lesson Completed',
        description: 'Completed Everyday Words',
        timestamp: DateTime.now(),
      )
    ],
    trend: sampleTrend,
    aiInsightSummary: 'You completed 8 lessons with steady focus and high independence!',
    aiInsightDetails: ['Active across 3 practice days this week'],
    aiFallbackUsed: false,
  );

  group('Phase 10 Progress Reusable Widgets Tests', () {
    testWidgets('ProgressSummaryCard renders metrics and labels accurately', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressSummaryCard(summary: sampleSummary, showStreaks: true),
          ),
        ),
      );

      expect(find.text('Lessons Completed'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Practice Time'), findsOneWidget);
      expect(find.text('42 min'), findsOneWidget);
      expect(find.text('Independent Rate'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Active Days'), findsOneWidget);
      expect(find.text('3 days'), findsOneWidget);
    });

    testWidgets('SkillProgressCard renders non-diagnostic band badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillProgressCard(skill: sampleSkill),
          ),
        ),
      );

      expect(find.text('Vocabulary Depth'), findsOneWidget);
      expect(find.text('VOCABULARY'), findsOneWidget);
      expect(find.text('Practicing'), findsOneWidget);
      expect(find.text('10 activities • 88% practice accuracy'), findsOneWidget);
    });

    testWidgets('GoalCard renders goal title, description and progress ratio', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalCard(goal: sampleGoal),
          ),
        ),
      );

      expect(find.text('Complete 3 Reading Activities'), findsOneWidget);
      expect(find.text('Build confidence with short stories'), findsOneWidget);
      expect(find.text('2 of 3 completed'), findsOneWidget);
      expect(find.text('WEEKLY TARGET'), findsOneWidget);
    });

    testWidgets('AchievementCard renders unlocked milestone badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 150,
              width: 180,
              child: AchievementCard(achievement: sampleAchievement),
            ),
          ),
        ),
      );

      expect(find.text('First Practice Step'), findsOneWidget);
      expect(find.text('Completed your first practice lesson.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('ProgressChartCard renders trend and accessible text alternative', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressChartCard(trend: sampleTrend),
          ),
        ),
      );

      expect(find.text('Weekly Practice Activity'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(
        find.text('Over the past 7 days you completed 9 learning activities across 3 active days.'),
        findsOneWidget,
      );
    });

    testWidgets('AiProgressInsightCard renders disclosure and summary copy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiProgressInsightCard(
              summary: 'You completed 8 lessons with steady focus!',
              details: const ['Practiced across 3 days'],
              fallbackUsed: false,
            ),
          ),
        ),
      );

      expect(find.text('AI-Assisted Practice Summary'), findsOneWidget);
      expect(find.text('ASSISTIVE'), findsOneWidget);
      expect(find.text('You completed 8 lessons with steady focus!'), findsOneWidget);
      expect(find.text('Practiced across 3 days'), findsOneWidget);
      expect(find.textContaining('Non-diagnostic.'), findsOneWidget);
    });

    testWidgets('TimelineItemTile renders observable learning event tile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimelineItemTile(
              item: ActivityTimelineItem(
                id: 'item-1',
                eventType: 'goal_completed',
                title: 'Goal Achieved',
                description: 'Reached your practice goal.',
                timestamp: DateTime(2026, 10, 1, 14, 30),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Goal Achieved'), findsOneWidget);
      expect(find.text('Reached your practice goal.'), findsOneWidget);
    });
  });

  group('Phase 10 Screen Integration Tests', () {
    testWidgets('ProgressScreen renders full dashboard with overridden provider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressDashboardProvider.overrideWith((ref) => Future.value(sampleDashboard)),
          ],
          child: const MaterialApp(
            home: ProgressScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Your Learning Progress'), findsOneWidget);
      expect(find.text('Your Practice & Growth Journey'), findsOneWidget);
      expect(find.text('Lessons Completed'), findsOneWidget);
      expect(find.text('Weekly Practice Activity'), findsOneWidget);
      expect(find.text('Skill Readiness & Practice'), findsOneWidget);
      expect(find.text('Learning Goals'), findsOneWidget);
      expect(find.text('Milestones & Achievements'), findsOneWidget);
    });

    testWidgets('SkillProgressDetailScreen renders all tabs and skill items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressDashboardProvider.overrideWith((ref) => Future.value(sampleDashboard)),
          ],
          child: const MaterialApp(
            home: SkillProgressDetailScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Skill Growth & Readiness'), findsOneWidget);
      expect(find.text('All Skills'), findsOneWidget);
      expect(find.text('Spoken Language'), findsOneWidget);
      expect(find.text('Literacy & Reading'), findsOneWidget);
      expect(find.text('Vocabulary Depth'), findsOneWidget);
    });

    testWidgets('GoalsDashboardScreen renders active and completed tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalsNotifierProvider.overrideWith(() => MockGoalsNotifier([sampleGoal])),
          ],
          child: const MaterialApp(
            home: GoalsDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Learning Goals'), findsOneWidget);
      expect(find.text('Active Goals'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Complete 3 Reading Activities'), findsOneWidget);
      expect(find.text('+ Set a New Goal'), findsOneWidget);
    });

    testWidgets('CreateGoalScreen renders presets and target count selector', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateGoalScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Set a Practice Goal'), findsOneWidget);
      expect(find.text('Goal Title'), findsOneWidget);
      expect(find.text('Target Count'), findsOneWidget);
      expect(find.text('Save Learning Goal'), findsOneWidget);
    });

    testWidgets('AchievementCenterScreen renders milestone grid and encouragement', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            achievementsProvider.overrideWith((ref) => Future.value([sampleAchievement])),
          ],
          child: const MaterialApp(
            home: AchievementCenterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Milestone Center'), findsOneWidget);
      expect(find.textContaining('Milestones Celebrated'), findsOneWidget);
      expect(find.text('First Practice Step'), findsOneWidget);
    });
  });
}

class MockGoalsNotifier extends GoalsNotifier {
  final List<LearnerGoal> initialGoals;
  MockGoalsNotifier(this.initialGoals);

  @override
  Future<List<LearnerGoal>> build() async {
    return initialGoals;
  }
}
