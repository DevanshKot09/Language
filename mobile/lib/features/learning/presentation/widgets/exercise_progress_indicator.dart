import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';

class ExerciseProgressIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final Color trackColor;

  const ExerciseProgressIndicator({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    this.trackColor = LinguaTokens.primary600,
  });

  @override
  Widget build(BuildContext context) {
    final double fraction = totalCount > 0 ? ((currentIndex + 1) / totalCount).clamp(0.0, 1.0) : 0.0;

    return Semantics(
      label: 'Activity ${currentIndex + 1} of $totalCount',
      value: '${(fraction * 100).toInt()}% completed',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity ${currentIndex + 1} of $totalCount',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LinguaTokens.ink700,
                ),
              ),
              Text(
                '${(fraction * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: trackColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: LinguaTokens.paper100,
              valueColor: AlwaysStoppedAnimation<Color>(trackColor),
            ),
          ),
        ],
      ),
    );
  }
}
