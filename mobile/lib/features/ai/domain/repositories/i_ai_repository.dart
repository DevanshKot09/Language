import '../models/ai_models.dart';

abstract class IAiRepository {
  Future<Map<String, dynamic>> getAiStatus();

  Future<List<AiRecommendationItemModel>> getRecommendations({
    required String track,
    required String ageBand,
    required List<String> candidateLessonIds,
    List<String> recentCompletedLessonIds = const [],
    List<String> currentGoals = const [],
  });

  Future<AiExplanationModel> getExplanation({
    required String lessonTitle,
    required String exercisePrompt,
    required String targetConcept,
    required String learnerQuestion,
    required String ageBand,
  });

  Future<AiFeedbackModel> getFeedback({
    required String activityType,
    required String prompt,
    required String learnerSubmission,
    required String ageBand,
    required String track,
  });

  Future<AiConversationReplyModel> getConversationReply({
    required String scenarioId,
    required String scenarioTitle,
    required String scenarioContext,
    required String ageBand,
    required List<Map<String, String>> history,
    required String userMessage,
  });

  Future<AiProgressInsightModel> getProgressInsight({
    required String ageBand,
    required String track,
    required int completedLessonCount,
    required int practiceAttemptCount,
    List<String> activeGoals = const [],
    List<String> recentSkills = const [],
  });
}
