/// Baseline activity model for deterministic, age-adapted baseline questions.
class BaselineActivityModel {
  final String id;
  final String skillId;
  final String track;
  final String domain;
  final String ageBand;
  final String activityType;
  final String instruction;
  final String prompt;
  final List<String> options;
  final String? hint;
  final String difficulty;

  const BaselineActivityModel({
    required this.id,
    required this.skillId,
    required this.track,
    required this.domain,
    required this.ageBand,
    required this.activityType,
    required this.instruction,
    required this.prompt,
    required this.options,
    this.hint,
    this.difficulty = 'medium',
  });

  factory BaselineActivityModel.fromJson(Map<String, dynamic> json) {
    return BaselineActivityModel(
      id: json['id']?.toString() ?? '',
      skillId: (json['skill_id'] ?? json['skillId'])?.toString() ?? '',
      track: json['track']?.toString() ?? 'foundation',
      domain: json['domain']?.toString() ?? 'General',
      ageBand: (json['age_band'] ?? json['ageBand'])?.toString() ?? 'all',
      activityType: (json['activity_type'] ?? json['activityType'])?.toString() ?? 'multiple_choice',
      instruction: json['instruction']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? '',
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      hint: json['hint']?.toString(),
      difficulty: json['difficulty']?.toString() ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skill_id': skillId,
      'track': track,
      'domain': domain,
      'age_band': ageBand,
      'activity_type': activityType,
      'instruction': instruction,
      'prompt': prompt,
      'options': options,
      'hint': hint,
      'difficulty': difficulty,
    };
  }
}
