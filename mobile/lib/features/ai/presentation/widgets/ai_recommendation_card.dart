import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_card.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../domain/models/ai_models.dart';

/// Card displaying an AI-assisted lesson recommendation.
/// Includes transparent disclosure that recommendations are assistive suggestions,
/// not clinical or diagnostic prescriptions.
class AiRecommendationCard extends StatelessWidget {
  final AiRecommendationItemModel recommendation;
  final String? lessonTitle;
  final VoidCallback onStart;
  final VoidCallback? onDismiss;

  const AiRecommendationCard({
    super.key,
    required this.recommendation,
    this.lessonTitle,
    required this.onStart,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'AI-assisted lesson suggestion: ${lessonTitle ?? recommendation.lessonId}',
      child: LinguaCard(
        borderColor: LinguaTokens.primary500.withValues(alpha: 0.3),
        backgroundColor: LinguaTokens.primary50,
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
                        'AI-Assisted Suggestion',
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
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Dismiss suggestion',
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: LinguaTokens.space12),
            Text(
              lessonTitle ?? 'Recommended Practice Activity',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LinguaTokens.ink900,
                fontFamily: LinguaTokens.fontPrimary,
              ),
            ),
            const SizedBox(height: LinguaTokens.space8),
            Text(
              recommendation.shortExplanation,
              style: const TextStyle(
                fontSize: 14,
                color: LinguaTokens.ink700,
                fontFamily: LinguaTokens.fontPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: LinguaTokens.space12),
            const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 13,
                  color: LinguaTokens.inkMuted,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Educational suggestion to guide practice. Not a clinical prescription.',
                    style: TextStyle(
                      fontSize: 11,
                      color: LinguaTokens.inkMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: LinguaTokens.space16),
            Row(
              children: [
                Expanded(
                  child: LinguaButton(
                    label: 'Start Suggested Activity',
                    onPressed: onStart,
                    variant: LinguaButtonVariant.primary,
                  ),
                ),
                if (onDismiss != null) ...[
                  const SizedBox(width: LinguaTokens.space8),
                  LinguaButton(
                    label: 'Maybe Later',
                    onPressed: onDismiss,
                    variant: LinguaButtonVariant.secondary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
