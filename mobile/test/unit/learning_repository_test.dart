import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/features/learning/data/learning_repository.dart';
import 'package:lingua_ai/features/learning/domain/models/exercise_attempt_model.dart';
import '../helpers/mock_api_client.dart';

void main() {
  group('LearningRepository Unit Tests', () {
    late MockApiClient mockClient;
    late LearningRepository repository;

    setUp(() {
      mockClient = MockApiClient();
      repository = LearningRepository(mockClient);
    });

    test('getLessons returns list of LessonSummaryModel', () async {
      mockClient.mockResponse = [
        {
          'id': 'lesson-1',
          'skill_id': 'skill-1',
          'title': 'Vocabulary Practice',
          'description': 'Description',
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
      ];

      final lessons = await repository.getLessons(track: 'dld_track');
      expect(lessons.length, 1);
      expect(lessons.first.title, 'Vocabulary Practice');
      expect(lessons.first.track, 'dld_track');
    });

    test('getLessonDetail returns LessonDetailModel with exercises', () async {
      mockClient.mockResponse = {
        'id': 'lesson-1',
        'skill_id': 'skill-1',
        'title': 'Action Words',
        'description': 'Description',
        'track': 'dld_track',
        'age_band': 'child',
        'difficulty': 1,
        'sequence_order': 1,
        'estimated_effort_minutes': 5,
        'total_exercises': 1,
        'user_status': 'in_progress',
        'current_exercise_index': 0,
        'completed_exercises': 0,
        'exercises': [
          {
            'id': 'ex-1',
            'lesson_id': 'lesson-1',
            'skill_id': 'skill-1',
            'exercise_type': 'multiple_choice',
            'prompt': 'Prompt text',
            'instruction': 'Instruction text',
            'content': {
              'options': ['A', 'B']
            },
            'difficulty': 1,
            'age_band': 'child',
            'track': 'dld_track',
            'sequence_order': 1,
            'hints': ['Hint 1'],
          }
        ],
      };

      final detail = await repository.getLessonDetail('lesson-1');
      expect(detail.id, 'lesson-1');
      expect(detail.exercises.length, 1);
      expect(detail.exercises.first.prompt, 'Prompt text');
    });

    test('submitExerciseAttempt successfully submits and returns Evaluation result', () async {
      mockClient.mockResponse = {
        'attempt_id': 'att-123',
        'status': 'correct',
        'is_correct': true,
        'partial_score': 1.0,
        'feedback_message': 'Wonderful job!',
        'explanation': 'Explanation text',
        'current_exercise_index': 0,
        'next_exercise_index': 1,
        'lesson_completed': false,
      };

      final result = await repository.submitExerciseAttempt(
        exerciseId: 'ex-1',
        request: const ExerciseAttemptRequestModel(
          response: 'Option A',
          attemptNumber: 1,
          hintUsed: false,
        ),
      );

      expect(result.attemptId, 'att-123');
      expect(result.isCorrect, isTrue);
      expect(result.status, 'correct');
      expect(result.feedbackMessage, 'Wonderful job!');
    });

    test('getPracticeHub returns PracticeHubModel', () async {
      mockClient.mockResponse = {
        'recommended_lessons': [],
        'in_progress_lessons': [],
        'completed_lessons': [],
        'skills_summary': [],
      };

      final hub = await repository.getPracticeHub();
      expect(hub.recommendedLessons, isEmpty);
      expect(hub.skillsSummary, isEmpty);
    });

    test('getLearningPath returns LearningPathModel', () async {
      mockClient.mockResponse = {
        'track': 'both_track',
        'nodes': [
          {
            'step_number': 1,
            'lesson_id': 'l-1',
            'title': 'Node 1',
            'track': 'dld_track',
            'skill_name': 'Vocab',
            'status': 'active',
            'is_completed': false,
            'is_active': true,
            'difficulty': 1,
          }
        ],
      };

      final path = await repository.getLearningPath();
      expect(path.track, 'both_track');
      expect(path.nodes.length, 1);
      expect(path.nodes.first.isActive, isTrue);
    });
  });
}
