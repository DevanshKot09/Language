class AchievementItem {
  final String id;
  final String code;
  final String title;
  final String description;
  final String category;
  final String iconName;
  final int threshold;
  final String badgeTier; // bronze, silver, gold, milestone
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progressValue;

  const AchievementItem({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.category,
    required this.iconName,
    required this.threshold,
    required this.badgeTier,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progressValue = 0,
  });

  double get progressRatio {
    if (threshold <= 0) return 1.0;
    return (progressValue / threshold).clamp(0.0, 1.0);
  }

  factory AchievementItem.fromJson(Map<String, dynamic> json) {
    return AchievementItem(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'learning',
      iconName: json['icon_name'] as String? ?? 'emoji_events',
      threshold: json['threshold'] as int? ?? 1,
      badgeTier: json['badge_tier'] as String? ?? 'bronze',
      isUnlocked: json['is_unlocked'] as bool? ?? false,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.tryParse(json['unlocked_at'] as String)
          : null,
      progressValue: json['progress_value'] as int? ?? 0,
    );
  }
}
