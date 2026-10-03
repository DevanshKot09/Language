import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../domain/models/goal_models.dart';

class GoalCard extends StatelessWidget {
  final LearnerGoal goal;
  final VoidCallback? onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = goal.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
      padding: const EdgeInsets.all(LinguaTokens.space16),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF3F9F4) : LinguaTokens.surfaceCard,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        border: Border.all(
          color: isDone ? LinguaTokens.success600.withValues(alpha: 0.3) : LinguaTokens.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isDone ? Icons.check_circle : Icons.flag_outlined,
                color: isDone ? LinguaTokens.success600 : LinguaTokens.primary600,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: LinguaTokens.ink900,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (goal.description != null && goal.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        goal.description!,
                        style: const TextStyle(fontSize: 12, color: LinguaTokens.ink700),
                      ),
                    ],
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: LinguaTokens.inkMuted),
                  tooltip: 'Remove goal',
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDone
                    ? 'Goal Achieved!'
                    : '${goal.currentCount} of ${goal.targetCount} completed',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDone ? LinguaTokens.success600 : LinguaTokens.ink700,
                ),
              ),
              Text(
                '${goal.targetFrequency.toUpperCase()} TARGET',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: LinguaTokens.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: goal.progressRatio,
            backgroundColor: LinguaTokens.paper100,
            color: isDone ? LinguaTokens.success600 : LinguaTokens.primary600,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}
