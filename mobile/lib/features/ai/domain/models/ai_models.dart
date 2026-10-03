/// AI Recommendation Model
class AiRecommendationItemModel {
  final String lessonId;
  final String reasonCode;
  final String shortExplanation;
  final String confidenceLevel;

  const AiRecommendationItemModel({
    required this.lessonId,
    required this.reasonCode,
    required this.shortExplanation,
    this.confidenceLevel = 'medium',
  });

  factory AiRecommendationItemModel.fromJson(Map<String, dynamic> json) {
    return AiRecommendationItemModel(
      lessonId: json['lesson_id'] as String? ?? '',
      reasonCode: json['reason_code'] as String? ?? '',
      shortExplanation: json['short_explanation'] as String? ?? '',
      confidenceLevel: json['confidence_level'] as String? ?? 'medium',
    );
  }
}

/// Educational Explanation Model
class AiExplanationModel {
  final String explanation;
  final String? clarityTip;
  final bool fallbackUsed;

  const AiExplanationModel({
    required this.explanation,
    this.clarityTip,
    this.fallbackUsed = false,
  });

  factory AiExplanationModel.fromJson(Map<String, dynamic> json) {
    return AiExplanationModel(
      explanation: json['explanation'] as String? ?? '',
      clarityTip: json['clarity_tip'] as String?,
      fallbackUsed: json['fallback_used'] as bool? ?? false,
    );
  }
}

/// Educational Feedback Model
class AiFeedbackModel {
  final String clarityNote;
  final String learningTip;
  final String encouragement;
  final String? revisionSuggestion;
  final bool fallbackUsed;

  const AiFeedbackModel({
    required this.clarityNote,
    required this.learningTip,
    required this.encouragement,
    this.revisionSuggestion,
    this.fallbackUsed = false,
  });

  factory AiFeedbackModel.fromJson(Map<String, dynamic> json) {
    return AiFeedbackModel(
      clarityNote: json['clarity_note'] as String? ?? '',
      learningTip: json['learning_tip'] as String? ?? '',
      encouragement: json['encouragement'] as String? ?? '',
      revisionSuggestion: json['revision_suggestion'] as String?,
      fallbackUsed: json['fallback_used'] as bool? ?? false,
    );
  }
}

/// Conversational Partner Model
class AiConversationReplyModel {
  final String reply;
  final String? followupPrompt;
  final bool isScenarioComplete;
  final bool fallbackUsed;

  const AiConversationReplyModel({
    required this.reply,
    this.followupPrompt,
    this.isScenarioComplete = false,
    this.fallbackUsed = false,
  });

  factory AiConversationReplyModel.fromJson(Map<String, dynamic> json) {
    return AiConversationReplyModel(
      reply: json['reply'] as String? ?? '',
      followupPrompt: json['followup_prompt'] as String?,
      isScenarioComplete: json['is_scenario_complete'] as bool? ?? false,
      fallbackUsed: json['fallback_used'] as bool? ?? false,
    );
  }
}

/// Progress Insights Model
class AiProgressInsightModel {
  final String practiceSummary;
  final String whatWentWell;
  final String nextPracticeArea;
  final String encouragingNote;
  final bool fallbackUsed;

  const AiProgressInsightModel({
    required this.practiceSummary,
    required this.whatWentWell,
    required this.nextPracticeArea,
    required this.encouragingNote,
    this.fallbackUsed = false,
  });

  factory AiProgressInsightModel.fromJson(Map<String, dynamic> json) {
    return AiProgressInsightModel(
      practiceSummary: json['practice_summary'] as String? ?? '',
      whatWentWell: json['what_went_well'] as String? ?? '',
      nextPracticeArea: json['next_practice_area'] as String? ?? '',
      encouragingNote: json['encouraging_note'] as String? ?? '',
      fallbackUsed: json['fallback_used'] as bool? ?? false,
    );
  }
}
