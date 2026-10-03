/// Node representing a step in the personalized learning path.
class LearningPathNodeModel {
  final int stepNumber;
  final String lessonId;
  final String title;
  final String track;
  final String skillName;
  final String status; // completed, active, unlocked, upcoming
  final bool isCompleted;
  final bool isActive;
  final int difficulty;

  const LearningPathNodeModel({
    required this.stepNumber,
    required this.lessonId,
    required this.title,
    required this.track,
    required this.skillName,
    required this.status,
    required this.isCompleted,
    required this.isActive,
    required this.difficulty,
  });

  factory LearningPathNodeModel.fromJson(Map<String, dynamic> json) {
    return LearningPathNodeModel(
      stepNumber: json['step_number'] as int? ?? 1,
      lessonId: json['lesson_id'] as String,
      title: json['title'] as String,
      track: json['track'] as String,
      skillName: json['skill_name'] as String,
      status: json['status'] as String? ?? 'upcoming',
      isCompleted: json['is_completed'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? false,
      difficulty: json['difficulty'] as int? ?? 1,
    );
  }
}

/// Model for the full personalized learning path.
class LearningPathModel {
  final String track;
  final List<LearningPathNodeModel> nodes;

  const LearningPathModel({
    required this.track,
    required this.nodes,
  });

  factory LearningPathModel.fromJson(Map<String, dynamic> json) {
    final nodesRaw = json['nodes'] as List<dynamic>? ?? [];
    return LearningPathModel(
      track: json['track'] as String? ?? 'both_track',
      nodes: nodesRaw
          .map((e) => LearningPathNodeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
