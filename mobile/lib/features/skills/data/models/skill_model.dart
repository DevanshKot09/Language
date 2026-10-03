/// Skill model representing an evidence-informed skill in the LINGUA AI taxonomy.
class SkillModel {
  final String id;
  final String code;
  final String name;
  final String description;
  final String track;
  final String domain;
  final String ageBandApplicability;
  final String priority;

  const SkillModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.track,
    required this.domain,
    this.ageBandApplicability = 'all',
    this.priority = 'ESSENTIAL',
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      track: json['track'] as String,
      domain: json['domain'] as String,
      ageBandApplicability: (json['age_band_applicability'] as String?) ?? 'all',
      priority: (json['priority'] as String?) ?? 'ESSENTIAL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'track': track,
      'domain': domain,
      'age_band_applicability': ageBandApplicability,
      'priority': priority,
    };
  }
}
