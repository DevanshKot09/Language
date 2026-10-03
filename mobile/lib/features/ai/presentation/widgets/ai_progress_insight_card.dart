import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_card.dart';
import '../../domain/models/ai_models.dart';

/// Card presenting AI-assisted educational progress summaries.
/// Grounded strictly in validated deterministic learner metrics, using learning-language
/// exclusively (no disorder scoring, no clinical trajectory claims).
class AiProgressInsightCard extends StatelessWidget {
  final AiProgressInsightModel insight;

  const AiProgressInsightCard({
    super.key,
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    return LinguaCard(
      borderColor: LinguaTokens.primary500.withValues(alpha: 0.25),
      backgroundColor: LinguaTokens.surfaceCard,
      padding: const EdgeInsets.all(LinguaTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LinguaTokens.space8,
                  vertical: LinguaTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: LinguaTokens.primary100,
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: LinguaTokens.primary700,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'AI Learning Summary',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: LinguaTokens.primary700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (insight.fallbackUsed)
                const Tooltip(
                  message: 'Curated curriculum metrics applied',
                  child: Icon(
                    Icons.rule_outlined,
                    size: 16,
                    color: LinguaTokens.inkMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: LinguaTokens.space12),
          // Practice Summary
          Text(
            insight.practiceSummary,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: LinguaTokens.ink900,
              height: 1.4,
            ),
          ),
          const SizedBox(height: LinguaTokens.space12),
          // What went well
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: LinguaTokens.success600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What is going well',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: LinguaTokens.ink700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      insight.whatWentWell,
                      style: const TextStyle(
                        fontSize: 13,
                        color: LinguaTokens.ink900,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LinguaTokens.space12),
          // Next practice area
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.trending_up,
                size: 18,
                color: LinguaTokens.primary600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What to practice next',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: LinguaTokens.ink700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      insight.nextPracticeArea,
                      style: const TextStyle(
                        fontSize: 13,
                        color: LinguaTokens.ink900,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LinguaTokens.space12),
          // Encouraging note
          Container(
            padding: const EdgeInsets.all(LinguaTokens.space12),
            decoration: BoxDecoration(
              color: LinguaTokens.paper50,
              borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sentiment_satisfied_alt,
                  size: 18,
                  color: LinguaTokens.accent600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight.encouragingNote,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: LinguaTokens.ink700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: LinguaTokens.space12),
          const Text(
            'Summarizes educational practice metrics only. Not a medical evaluation or clinical outcome score.',
            style: TextStyle(
              fontSize: 11,
              color: LinguaTokens.inkMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
