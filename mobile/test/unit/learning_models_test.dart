import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/features/learning/domain/models/lesson_model.dart';
import 'package:lingua_ai/features/learning/domain/models/exercise_model.dart';
import 'package:lingua_ai/features/learning/domain/models/exercise_attempt_model.dart';
import 'package:lingua_ai/features/learning/domain/models/practice_hub_model.dart';
import 'package:lingua_ai/features/learning/domain/models/learning_path_model.dart';

void main() {
  group('Learning Domain Models Tests', () {
    test('LessonSummaryModel correctly deserializes and calculates progress fraction', () {
      final json = {
        'id': 'lesson-1',
        'skill_id': 'skill-vocab',
        'skill_name': 'Everyday Vocabulary',
        'title': 'Action Verbs',
        'description': 'Practice core verbs.',
        'track': 'dld_track',
        'age_band': 'child',
        'difficulty': 1,
        'sequence_order': 1,
        'estimated_effort_minutes': 5,
        'total_exercises': 4,
        'user_status': 'in_progress',
        'current_exercise_index': 2,
        'completed_exercises': 2,
      };

      final lesson = LessonSummaryModel.fromJson(json);
      expect(lesson.id, 'lesson-1');
      expect(lesson.skillName, 'Everyday Vocabulary');
      expect(lesson.isInProgress, isTrue);
      expect(lesson.isCompleted, isFalse);
      expect(lesson.progressFraction, 0.5);
    });

    test('LessonDetailModel parses exercises array cleanly', () {
      final json = {
        'id': 'lesson-1',
        'skill_id': 'skill-vocab',
        'title': 'Action Verbs',
        'description': 'Practice core verbs.',
        'track': 'dld_track',
        'age_band': 'child',
        'difficulty': 1,
        'sequence_order': 1,
        'estimated_effort_minutes': 5,
        'total_exercises': 1,
        'user_status': 'not_started',
        'current_exercise_index': 0,
        'completed_exercises': 0,
        'exercises': [
          {
            'id': 'ex-1',
            'lesson_id': 'lesson-1',
            'skill_id': 'skill-vocab',
            'exercise_type': 'multiple_choice',
            'prompt': 'What does "explore" mean?',
            'instruction': 'Choose the meaning.',
            'content': {
              'options': ['Discover new things', 'Sleep']
            },
            'difficulty': 1,
            'age_band': 'child',
            'track': 'dld_track',
            'sequence_order': 1,
            'hints': ['Think about explorers.'],
            'explanation': 'Explore means discovering.',
          }
        ],
      };

      final detail = LessonDetailModel.fromJson(json);
      expect(detail.exercises.length, 1);
      final ex = detail.exercises.first;
      expect(ex.exerciseType, 'multiple_choice');
      expect(ex.options, ['Discover new things', 'Sleep']);
      expect(ex.hints.first, 'Think about explorers.');
    });

    test('ExerciseModel extracts tokens for word_order and pairs for matching', () {
      final wordOrderJson = {
        'id': 'ex-wo',
        'lesson_id': 'lesson-1',
        'skill_id': 'skill-syntax',
        'exercise_type': 'word_order',
        'prompt': 'Build sentence.',
        'instruction': 'Arrange words.',
        'content': {
          'tokens': ['The', 'children', 'played.']
        },
        'difficulty': 1,
        'age_band': 'child',
        'track': 'dld_track',
        'sequence_order': 1,
      };

      final woEx = ExerciseModel.fromJson(wordOrderJson);
      expect(woEx.tokens, ['The', 'children', 'played.']);

      final matchingJson = {
        'id': 'ex-match',
        'lesson_id': 'lesson-1',
        'skill_id': 'skill-phonics',
        'exercise_type': 'matching',
        'prompt': 'Match sounds.',
        'instruction': 'Connect pairs.',
        'content': {
          'pairs': [
            {'key': 'sh', 'value': 'ship'},
            {'key': 'ch', 'value': 'chip'},
          ]
        },
        'difficulty': 1,
        'age_band': 'child',
        'track': 'dyslexia_track',
        'sequence_order': 2,
      };

      final matchEx = ExerciseModel.fromJson(matchingJson);
      expect(matchEx.matchingPairs.length, 2);
      expect(matchEx.matchingPairs[0]['key'], 'sh');
      expect(matchEx.matchingPairs[0]['value'], 'ship');
    });

    test('ExerciseAttemptResponseModel correctly deserializes evaluation and status', () {
      final json = {
        'attempt_id': 'att-1',
        'status': 'partially_correct',
        'is_correct': false,
        'partial_score': 0.67,
        'feedback_message': 'Good progress! Check the last word.',
        'explanation': 'Sentences connect subject and predicate.',
        'current_exercise_index': 1,
        'next_exercise_index': null,
        'lesson_completed': false,
      };

      final attempt = ExerciseAttemptResponseModel.fromJson(json);
      expect(attempt.attemptId, 'att-1');
      expect(attempt.isPartiallyCorrect, isTrue);
      expect(attempt.partialScore, 0.67);
      expect(attempt.lessonCompleted, isFalse);
    });

    test('PracticeHubModel parses recommended, in-progress, and skill summaries', () {
      final json = {
        'recommended_lessons': [
          {
            'id': 'l-rec',
            'skill_id': 's-1',
            'title': 'Recommended Lesson',
            'description': 'Desc',
            'track': 'dld_track',
            'age_band': 'child',
            'difficulty': 1,
            'sequence_order': 1,
            'estimated_effort_minutes': 5,
            'total_exercises': 3,
            'user_status': 'not_started',
            'current_exercise_index': 0,
            'completed_exercises': 0,
          }
        ],
        'in_progress_lessons': [],
        'completed_lessons': [],
        'skills_summary': [
          {
            'skill_id': 's-1',
            'skill_code': 'dld_vocab',
            'skill_name': 'Vocabulary',
            'track': 'dld_track',
            'completed_lessons': 1,
            'total_lessons': 2,
            'mastery_status': 'Practicing',
          }
        ],
      };

      final hub = PracticeHubModel.fromJson(json);
      expect(hub.recommendedLessons.length, 1);
      expect(hub.skillsSummary.first.masteryStatus, 'Practicing');
    });

    test('LearningPathModel correctly parses sequence nodes', () {
      final json = {
        'track': 'dld_track',
        'nodes': [
          {
            'step_number': 1,
            'lesson_id': 'l-1',
            'title': 'Action Words',
            'track': 'dld_track',
            'skill_name': 'Vocabulary',
            'status': 'completed',
            'is_completed': true,
            'is_active': false,
            'difficulty': 1,
          },
          {
            'step_number': 2,
            'lesson_id': 'l-2',
            'title': 'Sentence Building',
            'track': 'dld_track',
            'skill_name': 'Syntax',
            'status': 'active',
            'is_completed': false,
            'is_active': true,
            'difficulty': 1,
          },
        ],
      };

      final path = LearningPathModel.fromJson(json);
      expect(path.nodes.length, 2);
      expect(path.nodes[0].isCompleted, isTrue);
      expect(path.nodes[1].isActive, isTrue);
    });
  });
}
