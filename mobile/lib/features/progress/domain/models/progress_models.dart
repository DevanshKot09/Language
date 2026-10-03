import 'goal_models.dart';
import 'achievement_models.dart';

/// Educational descriptive readiness bands.
/// Strict non-diagnostic levels.
enum DescriptiveSkillBand {
  starting,
  developing,
  practicing,
  consistent;

  static DescriptiveSkillBand fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'consistent':
        return DescriptiveSkillBand.consistent;
      case 'practicing':
        return DescriptiveSkillBand.practicing;
      case 'developing':
        return DescriptiveSkillBand.developing;
      default:
        return DescriptiveSkillBand.starting;
    }
  }

  String get displayName {
    switch (this) {
      case DescriptiveSkillBand.consistent:
        return 'Consistent';
      case DescriptiveSkillBand.practicing:
        return 'Practicing';
      case DescriptiveSkillBand.developing:
        return 'Developing';
      case DescriptiveSkillBand.starting:
        return 'Starting';
    }
  }
}

class SkillProgressItem {
  final String skillId;
  final String skillCode;
  final String name;
  final String domain;
  final String track;
  final String? baselineBand;
  final String currentBand;
  final int attemptCount;
  final int lessonCompletedCount;
  final double accuracy;
  final DateTime? lastPracticedAt;
  final String priority;

  const SkillProgressItem({
    required this.skillId,
    required this.skillCode,
    required this.name,
    required this.domain,
    required this.track,
    this.baselineBand,
    required this.currentBand,
    required this.attemptCount,
    required this.lessonCompletedCount,
    required this.accuracy,
    this.lastPracticedAt,
    this.priority = 'ESSENTIAL',
  });

  factory SkillProgressItem.fromJson(Map<String, dynamic> json) {
    return SkillProgressItem(
      skillId: json['skill_id'] as String? ?? '',
      skillCode: json['skill_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      domain: json['domain'] as String? ?? '',
      track: json['track'] as String? ?? 'dld_track',
      baselineBand: json['baseline_band'] as String?,
      currentBand: json['current_band'] as String? ?? 'starting',
      attemptCount: json['attempt_count'] as int? ?? 0,
      lessonCompletedCount: json['lesson_completed_count'] as int? ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      lastPracticedAt: json['last_practiced_at'] != null
          ? DateTime.tryParse(json['last_practiced_at'] as String)
          : null,
      priority: json['priority'] as String? ?? 'ESSENTIAL',
    );
  }
}

class ActivityTimelineItem {
  final String id;
  final String eventType;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? track;
  final String? badgeIcon;

  const ActivityTimelineItem({
    required this.id,
    required this.eventType,
    required this.title,
    required this.description,
    required this.timestamp,
    this.track,
    this.badgeIcon,
  });

  factory ActivityTimelineItem.fromJson(Map<String, dynamic> json) {
    return ActivityTimelineItem(
      id: json['id'] as String? ?? '',
      eventType: json['event_type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      track: json['track'] as String?,
      badgeIcon: json['badge_icon'] as String?,
    );
  }
}

class WeeklyActivityDay {
  final String dayName;
  final String date;
  final int activityCount;
  final int practiceMinutes;

  const WeeklyActivityDay({
    required this.dayName,
    required this.date,
    required this.activityCount,
    required this.practiceMinutes,
  });

  factory WeeklyActivityDay.fromJson(Map<String, dynamic> json) {
    return WeeklyActivityDay(
      dayName: json['day_name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      activityCount: json['activity_count'] as int? ?? 0,
      practiceMinutes: json['practice_minutes'] as int? ?? 0,
    );
  }
}

class ProgressTrend {
  final List<WeeklyActivityDay> days;
  final String accessibleDescription;

  const ProgressTrend({
    required this.days,
    required this.accessibleDescription,
  });

  factory ProgressTrend.fromJson(Map<String, dynamic> json) {
    final list = json['days'] as List<dynamic>? ?? [];
    return ProgressTrend(
      days: list.map((e) => WeeklyActivityDay.fromJson(e as Map<String, dynamic>)).toList(),
      accessibleDescription: json['accessible_description'] as String? ?? '',
    );
  }
}

class TrackProgressSummary {
  final String track;
  final String trackName;
  final int completedLessons;
  final int totalLessons;
  final int practicedSkills;
  final int totalSkills;
  final double averageAccuracy;

  const TrackProgressSummary({
    required this.track,
    required this.trackName,
    required this.completedLessons,
    required this.totalLessons,
    required this.practicedSkills,
    required this.totalSkills,
    required this.averageAccuracy,
  });

  factory TrackProgressSummary.fromJson(Map<String, dynamic> json) {
    return TrackProgressSummary(
      track: json['track'] as String? ?? '',
      trackName: json['track_name'] as String? ?? '',
      completedLessons: json['completed_lessons'] as int? ?? 0,
      totalLessons: json['total_lessons'] as int? ?? 0,
      practicedSkills: json['practiced_skills'] as int? ?? 0,
      totalSkills: json['total_skills'] as int? ?? 0,
      averageAccuracy: (json['average_accuracy'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProgressSummary {
  final int totalLessonsCompleted;
  final int totalLessonsInProgress;
  final int totalExercisesAttempted;
  final int totalPracticeTimeMinutes;
  final double independentRate;
  final int consistencyStreakDays;
  final int activeGoalsCount;
  final int completedGoalsCount;
  final int achievementsCount;

  const ProgressSummary({
    required this.totalLessonsCompleted,
    required this.totalLessonsInProgress,
    required this.totalExercisesAttempted,
    required this.totalPracticeTimeMinutes,
    required this.independentRate,
    required this.consistencyStreakDays,
    required this.activeGoalsCount,
    required this.completedGoalsCount,
    required this.achievementsCount,
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    return ProgressSummary(
      totalLessonsCompleted: json['total_lessons_completed'] as int? ?? 0,
      totalLessonsInProgress: json['total_lessons_in_progress'] as int? ?? 0,
      totalExercisesAttempted: json['total_exercises_attempted'] as int? ?? 0,
      totalPracticeTimeMinutes: json['total_practice_time_minutes'] as int? ?? 0,
      independentRate: (json['independent_rate'] as num?)?.toDouble() ?? 100.0,
      consistencyStreakDays: json['consistency_streak_days'] as int? ?? 0,
      activeGoalsCount: json['active_goals_count'] as int? ?? 0,
      completedGoalsCount: json['completed_goals_count'] as int? ?? 0,
      achievementsCount: json['achievements_count'] as int? ?? 0,
    );
  }
}

class ProgressDashboardData {
  final ProgressSummary summary;
  final String activeTrack;
  final TrackProgressSummary? dldTrackSummary;
  final TrackProgressSummary? dyslexiaTrackSummary;
  final List<SkillProgressItem> skills;
  final List<SkillProgressItem> dldSkills;
  final List<SkillProgressItem> dyslexiaSkills;
  final List<LearnerGoal> activeGoals;
  final List<AchievementItem> recentAchievements;
  final List<ActivityTimelineItem> timeline;
  final ProgressTrend trend;
  final String? aiInsightSummary;
  final List<String>? aiInsightDetails;
  final bool aiFallbackUsed;

  const ProgressDashboardData({
    required this.summary,
    required this.activeTrack,
    this.dldTrackSummary,
    this.dyslexiaTrackSummary,
    required this.skills,
    required this.dldSkills,
    required this.dyslexiaSkills,
    required this.activeGoals,
    required this.recentAchievements,
    required this.timeline,
    required this.trend,
    this.aiInsightSummary,
    this.aiInsightDetails,
    this.aiFallbackUsed = false,
  });

  factory ProgressDashboardData.fromJson(Map<String, dynamic> json) {
    return ProgressDashboardData(
      summary: ProgressSummary.fromJson(json['summary'] as Map<String, dynamic>? ?? {}),
      activeTrack: json['active_track'] as String? ?? 'both_track',
      dldTrackSummary: json['dld_track_summary'] != null
          ? TrackProgressSummary.fromJson(json['dld_track_summary'] as Map<String, dynamic>)
          : null,
      dyslexiaTrackSummary: json['dyslexia_track_summary'] != null
          ? TrackProgressSummary.fromJson(json['dyslexia_track_summary'] as Map<String, dynamic>)
          : null,
      skills: (json['skills'] as List<dynamic>? ?? [])
          .map((e) => SkillProgressItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      dldSkills: (json['dld_skills'] as List<dynamic>? ?? [])
          .map((e) => SkillProgressItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      dyslexiaSkills: (json['dyslexia_skills'] as List<dynamic>? ?? [])
          .map((e) => SkillProgressItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeGoals: (json['active_goals'] as List<dynamic>? ?? [])
          .map((e) => LearnerGoal.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentAchievements: (json['recent_achievements'] as List<dynamic>? ?? [])
          .map((e) => AchievementItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeline: (json['timeline'] as List<dynamic>? ?? [])
          .map((e) => ActivityTimelineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      trend: ProgressTrend.fromJson(json['trend'] as Map<String, dynamic>? ?? {}),
      aiInsightSummary: json['ai_insight_summary'] as String?,
      aiInsightDetails: (json['ai_insight_details'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      aiFallbackUsed: json['ai_fallback_used'] as bool? ?? false,
    );
  }
}
