import 'lesson_model.dart';

/// Progress item for a specific skill within the practice hub.
class SkillProgressItemModel {
  final String skillId;
  final String skillCode;
  final String skillName;
  final String track;
  final int completedLessons;
  final int totalLessons;
  final String masteryStatus; // Starting, Developing, Practicing, Consistent

  const SkillProgressItemModel({
    required this.skillId,
    required this.skillCode,
    required this.skillName,
    required this.track,
    required this.completedLessons,
    required this.totalLessons,
    required this.masteryStatus,
  });

  factory SkillProgressItemModel.fromJson(Map<String, dynamic> json) {
    return SkillProgressItemModel(
      skillId: json['skill_id'] as String,
      skillCode: json['skill_code'] as String,
      skillName: json['skill_name'] as String,
      track: json['track'] as String,
      completedLessons: json['completed_lessons'] as int? ?? 0,
      totalLessons: json['total_lessons'] as int? ?? 0,
      masteryStatus: json['mastery_status'] as String? ?? 'Starting',
    );
  }
}

/// Aggregated data model for the Practice Hub screen.
class PracticeHubModel {
  final List<LessonSummaryModel> recommendedLessons;
  final List<LessonSummaryModel> inProgressLessons;
  final List<LessonSummaryModel> completedLessons;
  final List<SkillProgressItemModel> skillsSummary;

  const PracticeHubModel({
    required this.recommendedLessons,
    required this.inProgressLessons,
    required this.completedLessons,
    required this.skillsSummary,
  });

  factory PracticeHubModel.fromJson(Map<String, dynamic> json) {
    final rec = json['recommended_lessons'] as List<dynamic>? ?? [];
    final inProg = json['in_progress_lessons'] as List<dynamic>? ?? [];
    final comp = json['completed_lessons'] as List<dynamic>? ?? [];
    final skills = json['skills_summary'] as List<dynamic>? ?? [];

    return PracticeHubModel(
      recommendedLessons: rec
          .map((e) => LessonSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      inProgressLessons: inProg
          .map((e) => LessonSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      completedLessons: comp
          .map((e) => LessonSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      skillsSummary: skills
          .map((e) => SkillProgressItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
