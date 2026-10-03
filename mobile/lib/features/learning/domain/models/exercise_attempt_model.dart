/// Request payload for submitting an exercise attempt.
class ExerciseAttemptRequestModel {
  final dynamic response;
  final int attemptNumber;
  final int timeSpentMs;
  final bool hintUsed;

  const ExerciseAttemptRequestModel({
    required this.response,
    this.attemptNumber = 1,
    this.timeSpentMs = 0,
    this.hintUsed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'response': response,
      'attempt_number': attemptNumber,
      'time_spent_ms': timeSpentMs,
      'hint_used': hintUsed,
    };
  }
}

/// Evaluation result response model returned after attempt submission.
class ExerciseAttemptResponseModel {
  final String attemptId;
  final String status; // correct, partially_correct, incorrect
  final bool isCorrect;
  final double partialScore;
  final String feedbackMessage;
  final String? explanation;
  final int currentExerciseIndex;
  final int? nextExerciseIndex;
  final bool lessonCompleted;

  const ExerciseAttemptResponseModel({
    required this.attemptId,
    required this.status,
    required this.isCorrect,
    required this.partialScore,
    required this.feedbackMessage,
    this.explanation,
    required this.currentExerciseIndex,
    this.nextExerciseIndex,
    required this.lessonCompleted,
  });

  bool get isPartiallyCorrect => status == 'partially_correct';

  factory ExerciseAttemptResponseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseAttemptResponseModel(
      attemptId: json['attempt_id'] as String,
      status: json['status'] as String,
      isCorrect: json['is_correct'] as bool? ?? false,
      partialScore: (json['partial_score'] as num?)?.toDouble() ?? 0.0,
      feedbackMessage: json['feedback_message'] as String? ?? '',
      explanation: json['explanation'] as String?,
      currentExerciseIndex: json['current_exercise_index'] as int? ?? 0,
      nextExerciseIndex: json['next_exercise_index'] as int?,
      lessonCompleted: json['lesson_completed'] as bool? ?? false,
    );
  }
}
