import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_card.dart';
import '../../domain/models/ai_models.dart';

/// Card rendering AI-assisted educational feedback for writing or transcript-based speaking.
/// Adheres strictly to non-diagnostic boundaries: provides scaffolding and clarity notes,
/// without clinical disorder scores, pronunciation diagnoses, or fluency ratings.
class AiFeedbackCard extends StatelessWidget {
  final AiFeedbackModel feedback;
  final String activityTitle;

  const AiFeedbackCard({
    super.key,
    required this.feedback,
    this.activityTitle = 'Your Practice Feedback',
  });

  @override
  Widget build(BuildContext context) {
    return LinguaCard(
      borderColor: LinguaTokens.borderSubtle,
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
                  color: LinguaTokens.successLight,
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: LinguaTokens.success600,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'AI-Assisted Educational Feedback',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: LinguaTokens.success600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (feedback.fallbackUsed)
                const Tooltip(
                  message: 'Curated standard educational rule applied',
                  child: Icon(
                    Icons.rule_outlined,
                    size: 16,
                    color: LinguaTokens.inkMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: LinguaTokens.space12),
          Text(
            activityTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: LinguaTokens.ink900,
              fontFamily: LinguaTokens.fontPrimary,
            ),
          ),
          const SizedBox(height: LinguaTokens.space12),
          // Clarity Note
          _buildFeedbackSection(
            icon: Icons.check_circle_outline,
            iconColor: LinguaTokens.success600,
            title: 'Clarity & Organization',
            content: feedback.clarityNote,
          ),
          const SizedBox(height: LinguaTokens.space12),
          // Learning Tip
          _buildFeedbackSection(
            icon: Icons.lightbulb_outline,
            iconColor: LinguaTokens.accent600,
            title: 'Learning Tip',
            content: feedback.learningTip,
          ),
          // Revision Suggestion (Optional)
          if (feedback.revisionSuggestion != null &&
              feedback.revisionSuggestion!.isNotEmpty) ...[
            const SizedBox(height: LinguaTokens.space12),
            _buildFeedbackSection(
              icon: Icons.edit_note,
              iconColor: LinguaTokens.primary600,
              title: 'One Revision Idea',
              content: feedback.revisionSuggestion!,
            ),
          ],
          const SizedBox(height: LinguaTokens.space12),
          // Encouragement
          Container(
            padding: const EdgeInsets.all(LinguaTokens.space12),
            decoration: BoxDecoration(
              color: LinguaTokens.primary50,
              borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 16,
                  color: LinguaTokens.primary600,
                ),
                const SizedBox(width: LinguaTokens.space8),
                Expanded(
                  child: Text(
                    feedback.encouragement,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: LinguaTokens.primary900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: LinguaTokens.space12),
          const Text(
            'This feedback focuses on educational practice and clarity. It is not clinical speech scoring or diagnostic evaluation.',
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

  Widget _buildFeedbackSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: LinguaTokens.space8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LinguaTokens.ink700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: LinguaTokens.ink900,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
