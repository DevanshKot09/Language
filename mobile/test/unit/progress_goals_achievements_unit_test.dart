import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/features/progress/domain/models/progress_models.dart';
import 'package:lingua_ai/features/progress/domain/models/goal_models.dart';
import 'package:lingua_ai/features/progress/domain/models/achievement_models.dart';
import 'package:lingua_ai/features/progress/data/progress_repository.dart';
import 'package:lingua_ai/features/progress/data/goal_repository.dart';
import 'package:lingua_ai/features/progress/data/achievement_repository.dart';
import '../helpers/mock_api_client.dart';

void main() {
  group('Phase 10 Progress Domain Models Tests', () {
    test('ProgressSummary fromJson parses numeric fields reliably', () {
      final json = {
        'total_lessons_completed': 8,
        'total_lessons_in_progress': 2,
        'total_exercises_attempted': 24,
        'total_practice_time_minutes': 45,
        'independent_rate': 87.5,
        'consistency_streak_days': 4,
        'active_goals_count': 2,
        'completed_goals_count': 3,
        'achievements_count': 5,
      };

      final summary = ProgressSummary.fromJson(json);

      expect(summary.totalLessonsCompleted, equals(8));
      expect(summary.totalLessonsInProgress, equals(2));
      expect(summary.totalExercisesAttempted, equals(24));
      expect(summary.totalPracticeTimeMinutes, equals(45));
      expect(summary.independentRate, equals(87.5));
      expect(summary.consistencyStreakDays, equals(4));
      expect(summary.activeGoalsCount, equals(2));
      expect(summary.completedGoalsCount, equals(3));
      expect(summary.achievementsCount, equals(5));
    });

    test('SkillProgressItem parses descriptive bands and track isolation', () {
      final dldJson = {
        'skill_id': 'skill-dld-001',
        'skill_code': 'dld_vocab',
        'name': 'Vocabulary Depth',
        'domain': 'vocabulary',
        'track': 'dld_track',
        'baseline_band': 'developing',
        'current_band': 'practicing',
        'attempt_count': 12,
        'lesson_completed_count': 3,
        'accuracy': 0.85,
        'priority': 'ESSENTIAL',
      };

      final dldSkill = SkillProgressItem.fromJson(dldJson);
      expect(dldSkill.track, equals('dld_track'));
      expect(dldSkill.currentBand, equals('practicing'));
      expect(dldSkill.accuracy, equals(0.85));

      final dyslexiaJson = {
        'skill_id': 'skill-dys-001',
        'skill_code': 'dys_phonics',
        'name': 'Phonics & Decoding',
        'domain': 'decoding',
        'track': 'dyslexia_track',
        'baseline_band': 'starting',
        'current_band': 'developing',
        'attempt_count': 6,
        'lesson_completed_count': 1,
        'accuracy': 0.72,
        'priority': 'ESSENTIAL',
      };

      final dyslexiaSkill = SkillProgressItem.fromJson(dyslexiaJson);
      expect(dyslexiaSkill.track, equals('dyslexia_track'));
      expect(dyslexiaSkill.currentBand, equals('developing'));
      expect(dyslexiaSkill.accuracy, equals(0.72));
    });

    test('LearnerGoal progressRatio and completion state calculation', () {
      final goal = LearnerGoal(
        id: 'goal-001',
        userId: 'user-001',
        title: 'Complete 4 Reading Activities',
        targetCount: 4,
        currentCount: 2,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.progressRatio, equals(0.5));
      expect(goal.isCompleted, isFalse);

      final completedGoal = LearnerGoal(
        id: 'goal-002',
        userId: 'user-001',
        title: 'Practice Vocabulary',
        targetCount: 3,
        currentCount: 3,
        status: 'completed',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(completedGoal.progressRatio, equals(1.0));
      expect(completedGoal.isCompleted, isTrue);
    });

    test('AchievementItem progressRatio and tier parsing', () {
      final ach = AchievementItem(
        id: 'ach-001',
        code: 'five_lessons',
        title: 'Practice Momentum',
        description: 'Completed 5 learning lessons.',
        category: 'learning',
        iconName: 'military_tech',
        threshold: 5,
        badgeTier: 'silver',
        isUnlocked: false,
        progressValue: 3,
      );

      expect(ach.progressRatio, equals(0.6));
      expect(ach.isUnlocked, isFalse);
    });

    test('ActivityTimelineItem parses event metadata reliably', () {
      final item = ActivityTimelineItem.fromJson({
        'id': 'timeline-001',
        'event_type': 'lesson_completed',
        'title': 'Lesson Completed',
        'description': 'Completed practice lesson: Everyday Words.',
        'timestamp': '2026-10-01T12:00:00Z',
        'track': 'dld_track',
      });

      expect(item.eventType, equals('lesson_completed'));
      expect(item.title, equals('Lesson Completed'));
      expect(item.track, equals('dld_track'));
    });
  });

  group('Phase 10 Repositories Tests with MockApiClient', () {
    late MockApiClient mockClient;
    late ProgressRepository progressRepo;
    late GoalRepository goalRepo;
    late AchievementRepository achievementRepo;

    setUp(() {
      mockClient = MockApiClient();
      progressRepo = ProgressRepository(mockClient);
      goalRepo = GoalRepository(mockClient);
      achievementRepo = AchievementRepository(mockClient);
    });

    test('ProgressRepository getProgressDashboard parses full payload', () async {
      mockClient.mockResponse = {
        'summary': {
          'total_lessons_completed': 5,
          'total_lessons_in_progress': 1,
          'total_exercises_attempted': 15,
          'total_practice_time_minutes': 30,
          'independent_rate': 90.0,
          'consistency_streak_days': 3,
          'active_goals_count': 1,
          'completed_goals_count': 2,
          'achievements_count': 3,
        },
        'active_track': 'both_track',
        'skills': [],
        'dld_skills': [],
        'dyslexia_skills': [],
        'active_goals': [],
        'recent_achievements': [],
        'timeline': [],
        'trend': {
          'days': [
            {'day_name': 'Mon', 'date': '2026-09-28', 'activity_count': 2, 'practice_minutes': 4}
          ],
          'accessible_description': 'Over the past 7 days you completed 2 activities.',
        },
        'ai_insight_summary': 'Great effort on your practice journey!',
        'ai_fallback_used': false,
      };

      final data = await progressRepo.getProgressDashboard();
      expect(data.summary.totalLessonsCompleted, equals(5));
      expect(data.activeTrack, equals('both_track'));
      expect(data.aiInsightSummary, equals('Great effort on your practice journey!'));
      expect(data.trend.days.length, equals(1));
    });

    test('GoalRepository createGoal dispatches and parses created goal', () async {
      mockClient.mockResponse = {
        'id': 'new-goal-123',
        'user_id': 'user-123',
        'title': 'Read 3 Passages',
        'target_count': 3,
        'current_count': 0,
        'target_frequency': 'weekly',
        'status': 'active',
        'created_at': '2026-10-01T12:00:00Z',
        'updated_at': '2026-10-01T12:00:00Z',
      };

      final created = await goalRepo.createGoal(const GoalCreateDto(
        title: 'Read 3 Passages',
        targetCount: 3,
      ));

      expect(created.id, equals('new-goal-123'));
      expect(created.title, equals('Read 3 Passages'));
      expect(created.targetCount, equals(3));
      expect(created.currentCount, equals(0));
    });

    test('AchievementRepository getAchievements parses list of achievements', () async {
      mockClient.mockResponse = [
        {
          'id': 'ach-1',
          'code': 'first_lesson',
          'title': 'First Practice Step',
          'description': 'Completed your first practice lesson.',
          'category': 'learning',
          'icon_name': 'school',
          'threshold': 1,
          'badge_tier': 'bronze',
          'is_unlocked': true,
          'progress_value': 1,
        }
      ];

      final achs = await achievementRepo.getAchievements();
      expect(achs.length, equals(1));
      expect(achs.first.code, equals('first_lesson'));
      expect(achs.first.isUnlocked, isTrue);
    });
  });
}
