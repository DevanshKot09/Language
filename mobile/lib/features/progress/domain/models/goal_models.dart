class LearnerGoal {
  final String id;
  final String userId;
  final String? skillId;
  final String title;
  final String? description;
  final String goalType; // complete_lessons, practice_sessions, practice_skill, milestone
  final int targetCount;
  final int currentCount;
  final String targetFrequency;
  final String? targetBehavior;
  final String status; // active, completed, achieved, paused
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const LearnerGoal({
    required this.id,
    required this.userId,
    this.skillId,
    required this.title,
    this.description,
    this.goalType = 'complete_lessons',
    this.targetCount = 3,
    this.currentCount = 0,
    this.targetFrequency = 'weekly',
    this.targetBehavior,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  bool get isCompleted => status == 'completed' || status == 'achieved';

  double get progressRatio {
    if (targetCount <= 0) return 0.0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }

  factory LearnerGoal.fromJson(Map<String, dynamic> json) {
    return LearnerGoal(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      skillId: json['skill_id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      goalType: json['goal_type'] as String? ?? 'complete_lessons',
      targetCount: json['target_count'] as int? ?? 3,
      currentCount: json['current_count'] as int? ?? 0,
      targetFrequency: json['target_frequency'] as String? ?? 'weekly',
      targetBehavior: json['target_behavior'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'skill_id': skillId,
      'title': title,
      'description': description,
      'goal_type': goalType,
      'target_count': targetCount,
      'current_count': currentCount,
      'target_frequency': targetFrequency,
      'target_behavior': targetBehavior,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}

class GoalCreateDto {
  final String title;
  final String? description;
  final String? skillId;
  final String goalType;
  final int targetCount;
  final String targetFrequency;
  final String? targetBehavior;

  const GoalCreateDto({
    required this.title,
    this.description,
    this.skillId,
    this.goalType = 'complete_lessons',
    this.targetCount = 3,
    this.targetFrequency = 'weekly',
    this.targetBehavior,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'skill_id': skillId,
      'goal_type': goalType,
      'target_count': targetCount,
      'target_frequency': targetFrequency,
      'target_behavior': targetBehavior,
    };
  }
}

class GoalUpdateDto {
  final String? title;
  final String? description;
  final int? targetCount;
  final String? targetFrequency;
  final String? targetBehavior;
  final String? status;

  const GoalUpdateDto({
    this.title,
    this.description,
    this.targetCount,
    this.targetFrequency,
    this.targetBehavior,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (targetCount != null) map['target_count'] = targetCount;
    if (targetFrequency != null) map['target_frequency'] = targetFrequency;
    if (targetBehavior != null) map['target_behavior'] = targetBehavior;
    if (status != null) map['status'] = status;
    return map;
  }
}
