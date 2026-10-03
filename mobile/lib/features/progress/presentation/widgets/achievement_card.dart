import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../domain/models/achievement_models.dart';

class AchievementCard extends StatelessWidget {
  final AchievementItem achievement;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final (tierColor, tierBg) = _getTierColors(achievement.badgeTier);

    return Container(
      decoration: BoxDecoration(
        color: unlocked ? LinguaTokens.surfaceCard : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        border: Border.all(
          color: unlocked ? tierColor.withValues(alpha: 0.3) : LinguaTokens.borderSubtle,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(LinguaTokens.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: unlocked ? tierBg : LinguaTokens.paper100,
                      child: Icon(
                        _getIconData(achievement.iconName),
                        size: 20,
                        color: unlocked ? tierColor : LinguaTokens.inkMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: unlocked ? LinguaTokens.ink900 : LinguaTokens.inkMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unlocked)
                      Icon(Icons.check_circle, size: 16, color: LinguaTokens.success600),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: unlocked ? LinguaTokens.ink700 : LinguaTokens.inkMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                if (!unlocked) ...[
                  LinearProgressIndicator(
                    value: achievement.progressRatio,
                    backgroundColor: LinguaTokens.paper100,
                    color: tierColor,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${achievement.progressValue} of ${achievement.threshold}',
                    style: const TextStyle(fontSize: 10, color: LinguaTokens.inkMuted),
                  ),
                ] else if (achievement.unlockedAt != null) ...[
                  Text(
                    'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tierColor),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color) _getTierColors(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return (const Color(0xFFD97706), const Color(0xFFFEF3C7));
      case 'silver':
        return (const Color(0xFF4B5563), const Color(0xFFF3F4F6));
      case 'bronze':
      default:
        return (const Color(0xFF92400E), const Color(0xFFFDE68A));
    }
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'school':
        return Icons.school_outlined;
      case 'military_tech':
        return Icons.military_tech_outlined;
      case 'workspace_premium':
        return Icons.workspace_premium_outlined;
      case 'stars':
        return Icons.stars_outlined;
      case 'explore':
        return Icons.explore_outlined;
      case 'flag':
        return Icons.flag_outlined;
      case 'today':
        return Icons.today_outlined;
      case 'emoji_events':
      default:
        return Icons.emoji_events_outlined;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
