import 'exercise_model.dart';

/// Summary model for a curriculum practice lesson.
class LessonSummaryModel {
  final String id;
  final String skillId;
  final String? skillName;
  final String title;
  final String description;
  final String track;
  final String ageBand;
  final int difficulty;
  final int sequenceOrder;
  final int estimatedEffortMinutes;
  final int totalExercises;
  final String userStatus; // not_started, in_progress, completed
  final int currentExerciseIndex;
  final int completedExercises;

  const LessonSummaryModel({
    required this.id,
    required this.skillId,
    this.skillName,
    required this.title,
    required this.description,
    required this.track,
    required this.ageBand,
    required this.difficulty,
    required this.sequenceOrder,
    required this.estimatedEffortMinutes,
    required this.totalExercises,
    required this.userStatus,
    required this.currentExerciseIndex,
    required this.completedExercises,
  });

  bool get isCompleted => userStatus == 'completed';
  bool get isInProgress => userStatus == 'in_progress';
  bool get isNotStarted => userStatus == 'not_started';

  double get progressFraction {
    if (totalExercises == 0) return 0.0;
    return (completedExercises / totalExercises).clamp(0.0, 1.0);
  }

  factory LessonSummaryModel.fromJson(Map<String, dynamic> json) {
    return LessonSummaryModel(
      id: json['id'] as String,
      skillId: json['skill_id'] as String,
      skillName: json['skill_name'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      track: json['track'] as String,
      ageBand: json['age_band'] as String,
      difficulty: json['difficulty'] as int? ?? 1,
      sequenceOrder: json['sequence_order'] as int? ?? 1,
      estimatedEffortMinutes: json['estimated_effort_minutes'] as int? ?? 5,
      totalExercises: json['total_exercises'] as int? ?? 0,
      userStatus: json['user_status'] as String? ?? 'not_started',
      currentExerciseIndex: json['current_exercise_index'] as int? ?? 0,
      completedExercises: json['completed_exercises'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skill_id': skillId,
      'skill_name': skillName,
      'title': title,
      'description': description,
      'track': track,
      'age_band': ageBand,
      'difficulty': difficulty,
      'sequence_order': sequenceOrder,
      'estimated_effort_minutes': estimatedEffortMinutes,
      'total_exercises': totalExercises,
      'user_status': userStatus,
      'current_exercise_index': currentExerciseIndex,
      'completed_exercises': completedExercises,
    };
  }
}

/// Detailed model for a lesson containing ordered exercises.
class LessonDetailModel extends LessonSummaryModel {
  final List<ExerciseModel> exercises;

  const LessonDetailModel({
    required super.id,
    required super.skillId,
    super.skillName,
    required super.title,
    required super.description,
    required super.track,
    required super.ageBand,
    required super.difficulty,
    required super.sequenceOrder,
    required super.estimatedEffortMinutes,
    required super.totalExercises,
    required super.userStatus,
    required super.currentExerciseIndex,
    required super.completedExercises,
    required this.exercises,
  });

  factory LessonDetailModel.fromJson(Map<String, dynamic> json) {
    final exercisesRaw = json['exercises'] as List<dynamic>? ?? [];
    return LessonDetailModel(
      id: json['id'] as String,
      skillId: json['skill_id'] as String,
      skillName: json['skill_name'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      track: json['track'] as String,
      ageBand: json['age_band'] as String,
      difficulty: json['difficulty'] as int? ?? 1,
      sequenceOrder: json['sequence_order'] as int? ?? 1,
      estimatedEffortMinutes: json['estimated_effort_minutes'] as int? ?? 5,
      totalExercises: json['total_exercises'] as int? ?? exercisesRaw.length,
      userStatus: json['user_status'] as String? ?? 'not_started',
      currentExerciseIndex: json['current_exercise_index'] as int? ?? 0,
      completedExercises: json['completed_exercises'] as int? ?? 0,
      exercises: exercisesRaw
          .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
