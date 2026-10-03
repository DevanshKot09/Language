import '../../../core/network/api_client.dart';
import '../domain/models/ai_models.dart';
import '../domain/repositories/i_ai_repository.dart';

class AiRepository implements IAiRepository {
  final IApiClient apiClient;

  AiRepository({required this.apiClient});

  @override
  Future<Map<String, dynamic>> getAiStatus() async {
    try {
      final res = await apiClient.get('/api/v1/ai/status');
      return Map<String, dynamic>.from(res as Map);
    } catch (_) {
      return {
        'ai_enabled': false,
        'provider': 'unavailable',
      };
    }
  }

  @override
  Future<List<AiRecommendationItemModel>> getRecommendations({
    required String track,
    required String ageBand,
    required List<String> candidateLessonIds,
    List<String> recentCompletedLessonIds = const [],
    List<String> currentGoals = const [],
  }) async {
    try {
      final body = {
        'user_id': '', // Evaluated from auth token on server
        'track': track,
        'age_band': ageBand,
        'candidate_lesson_ids': candidateLessonIds,
        'recent_completed_lesson_ids': recentCompletedLessonIds,
        'current_goals': currentGoals,
      };

      final res = await apiClient.post('/api/v1/ai/recommendations', body: body);
      if (res is Map && res['recommendations'] is List) {
        return (res['recommendations'] as List)
            .map((item) => AiRecommendationItemModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } catch (_) {
      // Deterministic client fallback
      if (candidateLessonIds.isNotEmpty) {
        return [
          AiRecommendationItemModel(
            lessonId: candidateLessonIds.first,
            reasonCode: 'curriculum_sequence',
            shortExplanation: 'Next suggested practice lesson in your learning sequence.',
            confidenceLevel: 'high',
          )
        ];
      }
      return [];
    }
  }

  @override
  Future<AiExplanationModel> getExplanation({
    required String lessonTitle,
    required String exercisePrompt,
    required String targetConcept,
    required String learnerQuestion,
    required String ageBand,
  }) async {
    try {
      final body = {
        'lesson_title': lessonTitle,
        'exercise_prompt': exercisePrompt,
        'target_concept': targetConcept,
        'learner_question': learnerQuestion,
        'age_band': ageBand,
      };

      final res = await apiClient.post('/api/v1/ai/explanations', body: body);
      return AiExplanationModel.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (_) {
      return const AiExplanationModel(
        explanation: 'This activity focuses on sentence clarity and vocabulary use.',
        clarityTip: 'Check the example clue provided in your exercise.',
        fallbackUsed: true,
      );
    }
  }

  @override
  Future<AiFeedbackModel> getFeedback({
    required String activityType,
    required String prompt,
    required String learnerSubmission,
    required String ageBand,
    required String track,
  }) async {
    try {
      final body = {
        'activity_type': activityType,
        'prompt': prompt,
        'learner_submission': learnerSubmission,
        'age_band': ageBand,
        'track': track,
      };

      final res = await apiClient.post('/api/v1/ai/feedback', body: body);
      return AiFeedbackModel.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (_) {
      return const AiFeedbackModel(
        clarityNote: 'Your response expresses your idea clearly.',
        learningTip: 'Complete sentences help convey your meaning with precision.',
        encouragement: 'Great effort practicing your language skills!',
        revisionSuggestion: null,
        fallbackUsed: true,
      );
    }
  }

  @override
  Future<AiConversationReplyModel> getConversationReply({
    required String scenarioId,
    required String scenarioTitle,
    required String scenarioContext,
    required String ageBand,
    required List<Map<String, String>> history,
    required String userMessage,
  }) async {
    try {
      final body = {
        'scenario_id': scenarioId,
        'scenario_title': scenarioTitle,
        'scenario_context': scenarioContext,
        'age_band': ageBand,
        'history': history.map((h) => {'role': h['role'], 'text': h['text']}).toList(),
        'user_message': userMessage,
      };

      final res = await apiClient.post('/api/v1/ai/conversation', body: body);
      return AiConversationReplyModel.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (_) {
      return const AiConversationReplyModel(
        reply: 'Thank you for sharing that. What would you like to add next?',
        followupPrompt: 'Tell me more about your thought.',
        isScenarioComplete: false,
        fallbackUsed: true,
      );
    }
  }

  @override
  Future<AiProgressInsightModel> getProgressInsight({
    required String ageBand,
    required String track,
    required int completedLessonCount,
    required int practiceAttemptCount,
    List<String> activeGoals = const [],
    List<String> recentSkills = const [],
  }) async {
    try {
      final body = {
        'age_band': ageBand,
        'track': track,
        'completed_lesson_count': completedLessonCount,
        'practice_attempt_count': practiceAttemptCount,
        'active_goals': activeGoals,
        'recent_skills': recentSkills,
      };

      final res = await apiClient.post('/api/v1/ai/progress-insight', body: body);
      return AiProgressInsightModel.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (_) {
      return AiProgressInsightModel(
        practiceSummary: 'You have completed $completedLessonCount lessons and $practiceAttemptCount practice activities.',
        whatWentWell: 'Consistent participation across your learning sessions.',
        nextPracticeArea: 'Continue with your recommended daily practice.',
        encouragingNote: 'Steady practice creates meaningful growth!',
        fallbackUsed: true,
      );
    }
  }
}
