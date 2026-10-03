import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../domain/models/progress_models.dart';

class ProgressSummaryCard extends StatelessWidget {
  final ProgressSummary summary;
  final bool showStreaks;

  const ProgressSummaryCard({
    super.key,
    required this.summary,
    this.showStreaks = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                label: 'Lessons Completed',
                value: '${summary.totalLessonsCompleted}',
                subtitle: '${summary.totalLessonsInProgress} in progress',
                icon: Icons.check_circle_outline,
                color: LinguaTokens.success600,
              ),
            ),
            const SizedBox(width: LinguaTokens.space12),
            Expanded(
              child: _buildMetricTile(
                label: 'Practice Time',
                value: '${summary.totalPracticeTimeMinutes} min',
                subtitle: '${summary.totalExercisesAttempted} activities',
                icon: Icons.timer_outlined,
                color: LinguaTokens.primary600,
              ),
            ),
          ],
        ),
        const SizedBox(height: LinguaTokens.space12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                label: 'Independent Rate',
                value: '${summary.independentRate.toInt()}%',
                subtitle: 'Without hint usage',
                icon: Icons.verified_outlined,
                color: LinguaTokens.accent600,
              ),
            ),
            const SizedBox(width: LinguaTokens.space12),
            Expanded(
              child: _buildMetricTile(
                label: showStreaks ? 'Active Days' : 'Milestones',
                value: showStreaks
                    ? '${summary.consistencyStreakDays} days'
                    : '${summary.achievementsCount}',
                subtitle: showStreaks ? 'This week' : 'Unlocked so far',
                icon: showStreaks ? Icons.today_outlined : Icons.emoji_events_outlined,
                color: LinguaTokens.dldTrack,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(LinguaTokens.space16),
      decoration: BoxDecoration(
        color: LinguaTokens.surfaceCard,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        border: Border.all(color: LinguaTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: LinguaTokens.ink700,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: LinguaTokens.ink900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: LinguaTokens.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
