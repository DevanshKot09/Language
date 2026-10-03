/// Learner Goal Model representing user practice goals.
class LearnerGoalModel {
  final String id;
  final String userId;
  final String? skillId;
  final String title;
  final String targetFrequency;
  final String? targetBehavior;
  final String status;
  final DateTime? createdAt;

  const LearnerGoalModel({
    required this.id,
    required this.userId,
    this.skillId,
    required this.title,
    this.targetFrequency = 'weekly',
    this.targetBehavior,
    this.status = 'active',
    this.createdAt,
  });

  factory LearnerGoalModel.fromJson(Map<String, dynamic> json) {
    return LearnerGoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      skillId: json['skill_id'] as String?,
      title: json['title'] as String,
      targetFrequency: (json['target_frequency'] as String?) ?? 'weekly',
      targetBehavior: json['target_behavior'] as String?,
      status: (json['status'] as String?) ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'skill_id': skillId,
      'title': title,
      'target_frequency': targetFrequency,
      'target_behavior': targetBehavior,
      'status': status,
    };
  }
}
