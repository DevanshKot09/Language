/// Skill Snapshot Item representing non-diagnostic readiness in a specific skill.
class SkillSnapshotItemModel {
  final String skillId;
  final String skillCode;
  final String skillName;
  final String track;
  final String domain;
  final String band; // Starting, Developing, Practicing, Consistent
  final double score;
  final double accuracy;
  final String description;

  const SkillSnapshotItemModel({
    required this.skillId,
    required this.skillCode,
    required this.skillName,
    required this.track,
    required this.domain,
    required this.band,
    required this.score,
    required this.accuracy,
    required this.description,
  });

  factory SkillSnapshotItemModel.fromJson(Map<String, dynamic> json) {
    return SkillSnapshotItemModel(
      skillId: json['skill_id'] as String,
      skillCode: json['skill_code'] as String,
      skillName: json['skill_name'] as String,
      track: json['track'] as String,
      domain: json['domain'] as String,
      band: json['band'] as String,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      description: (json['description'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skill_id': skillId,
      'skill_code': skillCode,
      'skill_name': skillName,
      'track': track,
      'domain': domain,
      'band': band,
      'score': score,
      'accuracy': accuracy,
      'description': description,
    };
  }
}

/// Skill Snapshot Model representing the learner's overall non-diagnostic profile.
class SkillSnapshotModel {
  final String userId;
  final String baselineStatus; // not_started, in_progress, completed
  final DateTime? completedAt;
  final List<SkillSnapshotItemModel> skills;
  final List<String> strengthAreas;
  final List<String> priorityPracticeAreas;

  const SkillSnapshotModel({
    required this.userId,
    required this.baselineStatus,
    this.completedAt,
    required this.skills,
    required this.strengthAreas,
    required this.priorityPracticeAreas,
  });

  bool get isCompleted => baselineStatus == 'completed';

  List<SkillSnapshotItemModel> get dldSkills =>
      skills.where((s) => s.track == 'dld_track').toList();

  List<SkillSnapshotItemModel> get dyslexiaSkills =>
      skills.where((s) => s.track == 'dyslexia_track').toList();

  factory SkillSnapshotModel.fromJson(Map<String, dynamic> json) {
    return SkillSnapshotModel(
      userId: json['user_id'] as String,
      baselineStatus: (json['baseline_status'] as String?) ?? 'not_started',
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => SkillSnapshotItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      strengthAreas: (json['strength_areas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      priorityPracticeAreas: (json['priority_practice_areas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
