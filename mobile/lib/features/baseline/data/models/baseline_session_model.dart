import 'baseline_activity_model.dart';

/// Baseline session model tracking an in-progress or completed baseline.
class BaselineSessionModel {
  final String id;
  final String userId;
  final String track;
  final String status;
  final int totalActivities;
  final int completedActivities;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<BaselineActivityModel> activities;

  const BaselineSessionModel({
    required this.id,
    required this.userId,
    required this.track,
    required this.status,
    required this.totalActivities,
    required this.completedActivities,
    this.startedAt,
    this.completedAt,
    required this.activities,
  });

  bool get isCompleted => status == 'completed';

  factory BaselineSessionModel.fromJson(Map<String, dynamic> json) {
    return BaselineSessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      track: json['track'] as String,
      status: json['status'] as String,
      totalActivities: (json['total_activities'] as int?) ?? 0,
      completedActivities: (json['completed_activities'] as int?) ?? 0,
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'].toString()) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
      activities: (json['activities'] as List<dynamic>?)
              ?.map((e) => BaselineActivityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  BaselineSessionModel copyWith({
    String? status,
    int? completedActivities,
    DateTime? completedAt,
  }) {
    return BaselineSessionModel(
      id: id,
      userId: userId,
      track: track,
      status: status ?? this.status,
      totalActivities: totalActivities,
      completedActivities: completedActivities ?? this.completedActivities,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      activities: activities,
    );
  }
}

/// Baseline response result returned upon submitting an answer.
class BaselineResponseResultModel {
  final String activityId;
  final bool isCorrect;
  final String correctAnswer;
  final int completedActivities;
  final int totalActivities;
  final bool isSessionComplete;

  const BaselineResponseResultModel({
    required this.activityId,
    required this.isCorrect,
    required this.correctAnswer,
    required this.completedActivities,
    required this.totalActivities,
    required this.isSessionComplete,
  });

  factory BaselineResponseResultModel.fromJson(Map<String, dynamic> json) {
    return BaselineResponseResultModel(
      activityId: json['activity_id'] as String,
      isCorrect: json['is_correct'] as bool,
      correctAnswer: json['correct_answer'] as String,
      completedActivities: json['completed_activities'] as int,
      totalActivities: json['total_activities'] as int,
      isSessionComplete: json['is_session_complete'] as bool,
    );
  }
}
