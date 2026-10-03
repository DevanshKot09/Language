import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../domain/models/progress_models.dart';

class ProgressChartCard extends StatelessWidget {
  final ProgressTrend trend;

  const ProgressChartCard({
    super.key,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final maxActivities = trend.days.map((d) => d.activityCount).fold<int>(1, max);

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
              const Text(
                'Weekly Practice Activity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: LinguaTokens.ink900,
                ),
              ),
              Semantics(
                label: 'Chart Information',
                child: const Icon(Icons.bar_chart, color: LinguaTokens.primary600, size: 20),
              ),
            ],
          ),
          const SizedBox(height: LinguaTokens.space16),

          // 7-day accessible bar visualization
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trend.days.map((day) {
                final heightFactor = maxActivities > 0 ? (day.activityCount / maxActivities).clamp(0.08, 1.0) : 0.08;
                final isZero = day.activityCount == 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${day.activityCount}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isZero ? LinguaTokens.inkMuted : LinguaTokens.ink900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 70 * heightFactor,
                          decoration: BoxDecoration(
                            color: isZero ? LinguaTokens.paper100 : LinguaTokens.primary600,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          day.dayName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: LinguaTokens.ink700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: LinguaTokens.space16),

          // Accessibility Text Alternative (Step 32)
          Container(
            padding: const EdgeInsets.all(LinguaTokens.space12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
              border: Border.all(color: LinguaTokens.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.accessibility_new, size: 16, color: LinguaTokens.primary600),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    readOnly: true,
                    label: 'Text alternative for weekly practice chart: ${trend.accessibleDescription}',
                    child: Text(
                      trend.accessibleDescription,
                      style: const TextStyle(
                        fontSize: 12,
                        color: LinguaTokens.ink700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
