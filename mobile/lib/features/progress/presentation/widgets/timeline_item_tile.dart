import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../domain/models/progress_models.dart';

class TimelineItemTile extends StatelessWidget {
  final ActivityTimelineItem item;

  const TimelineItemTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _getEventIcon(item.eventType);
    final iconColor = _getEventColor(item.eventType);

    return Padding(
      padding: const EdgeInsets.only(bottom: LinguaTokens.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: iconColor.withValues(alpha: 0.12),
            child: Icon(iconData, size: 18, color: iconColor),
          ),
          const SizedBox(width: LinguaTokens.space12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(LinguaTokens.space12),
              decoration: BoxDecoration(
                color: LinguaTokens.surfaceCard,
                borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                border: Border.all(color: LinguaTokens.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: LinguaTokens.ink900,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(item.timestamp),
                        style: const TextStyle(
                          fontSize: 11,
                          color: LinguaTokens.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: LinguaTokens.ink700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'lesson_completed':
        return Icons.check_circle_outlined;
      case 'lesson_started':
        return Icons.play_circle_outlined;
      case 'goal_completed':
        return Icons.flag;
      case 'goal_created':
        return Icons.outlined_flag;
      case 'achievement_earned':
        return Icons.emoji_events_outlined;
      case 'baseline_completed':
        return Icons.explore_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'lesson_completed':
      case 'goal_completed':
        return LinguaTokens.success600;
      case 'achievement_earned':
        return const Color(0xFFD97706);
      case 'baseline_completed':
        return LinguaTokens.accent600;
      default:
        return LinguaTokens.primary600;
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
