import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/features/skills/data/models/skill_model.dart';
import 'package:lingua_ai/features/baseline/data/models/baseline_activity_model.dart';
import 'package:lingua_ai/features/baseline/data/models/baseline_session_model.dart';
import 'package:lingua_ai/features/baseline/data/models/skill_snapshot_model.dart';
import 'package:lingua_ai/features/baseline/data/models/learner_goal_model.dart';

void main() {
  group('Skill & Baseline Domain Models Tests', () {
    test('SkillModel correctly deserializes and identifies tracks', () {
      final json = {
        'id': 'skill-1',
        'code': 'dld_vocab',
        'name': 'Vocabulary Breadth',
        'description': 'Targeted word learning with cues.',
        'track': 'dld_track',
        'domain': 'vocabulary',
        'age_band_applicability': 'all',
        'priority': 'ESSENTIAL',
      };

      final model = SkillModel.fromJson(json);
      expect(model.id, 'skill-1');
      expect(model.track, 'dld_track');
      expect(model.domain, 'vocabulary');
      expect(model.priority, 'ESSENTIAL');
    });

    test('BaselineActivityModel correctly parses prompt and options', () {
      final json = {
        'id': 'act-1',
        'skill_id': 'skill-1',
        'track': 'dld_track',
        'domain': 'vocabulary',
        'age_band': 'teen',
        'activity_type': 'multiple_choice',
        'instruction': 'Choose the best meaning.',
        'prompt': 'What does "vivid" mean?',
        'options': ['Bright and clear', 'Quiet and slow', 'Heavy and dark'],
        'hint': 'Think about bright colors.',
        'difficulty': 'medium',
      };

      final activity = BaselineActivityModel.fromJson(json);
      expect(activity.id, 'act-1');
      expect(activity.options.length, 3);
      expect(activity.hint, 'Think about bright colors.');
    });

    test('BaselineSessionModel parses session status and activities list', () {
      final json = {
        'id': 'sess-1',
        'user_id': 'user-1',
        'track': 'dld_track',
        'status': 'in_progress',
        'total_activities': 6,
        'completed_activities': 2,
        'activities': [],
      };

      final session = BaselineSessionModel.fromJson(json);
      expect(session.id, 'sess-1');
      expect(session.status, 'in_progress');
      expect(session.totalActivities, 6);
      expect(session.completedActivities, 2);
      expect(session.isCompleted, isFalse);
    });

    test('SkillSnapshotModel cleanly separates DLD and Dyslexia skills', () {
      final json = {
        'user_id': 'user-123',
        'baseline_status': 'completed',
        'completed_at': '2026-09-30T12:00:00Z',
        'skills': [
          {
            'skill_id': 's1',
            'skill_code': 'dld_vocab',
            'skill_name': 'Vocabulary',
            'track': 'dld_track',
            'domain': 'vocabulary',
            'band': 'Consistent',
            'score': 0.9,
            'accuracy': 0.9,
            'description': 'Strong independent skill.',
          },
          {
            'skill_id': 's2',
            'skill_code': 'dys_phon',
            'skill_name': 'Phonological Awareness',
            'track': 'dyslexia_track',
            'domain': 'phonology',
            'band': 'Developing',
            'score': 0.5,
            'accuracy': 0.5,
            'description': 'Emerging ability.',
          },
        ],
        'strength_areas': ['Vocabulary'],
        'priority_practice_areas': ['Phonological Awareness'],
      };

      final snapshot = SkillSnapshotModel.fromJson(json);
      expect(snapshot.isCompleted, isTrue);
      expect(snapshot.dldSkills.length, 1);
      expect(snapshot.dyslexiaSkills.length, 1);
      expect(snapshot.dldSkills.first.skillName, 'Vocabulary');
      expect(snapshot.dyslexiaSkills.first.skillName, 'Phonological Awareness');
      expect(snapshot.dldSkills.first.band, 'Consistent');
      expect(snapshot.dyslexiaSkills.first.band, 'Developing');
    });

    test('LearnerGoalModel parses correctly', () {
      final json = {
        'id': 'goal-1',
        'user_id': 'user-123',
        'skill_id': 's1',
        'title': 'Practice word meanings',
        'target_frequency': 'weekly',
        'target_behavior': 'Do 1 vocabulary session on Mon and Wed',
        'status': 'active',
      };

      final goal = LearnerGoalModel.fromJson(json);
      expect(goal.title, 'Practice word meanings');
      expect(goal.targetFrequency, 'weekly');
      expect(goal.status, 'active');
    });
  });
}
