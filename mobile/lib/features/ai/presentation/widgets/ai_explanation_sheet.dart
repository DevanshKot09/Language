import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_card.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../domain/models/ai_models.dart';

/// Modal or bottom sheet component presenting an AI-assisted concept explanation.
/// Validated against curriculum content and grounded in non-diagnostic educational scaffolding.
class AiExplanationSheet extends StatelessWidget {
  final String conceptTitle;
  final AiExplanationModel explanation;
  final VoidCallback onClose;

  const AiExplanationSheet({
    super.key,
    required this.conceptTitle,
    required this.explanation,
    required this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required String conceptTitle,
    required AiExplanationModel explanation,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiExplanationSheet(
        conceptTitle: conceptTitle,
        explanation: explanation,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: LinguaTokens.surfaceCard,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LinguaTokens.radiusHero),
        ),
      ),
      padding: const EdgeInsets.all(LinguaTokens.space24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: LinguaTokens.borderSubtle,
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                ),
              ),
            ),
            const SizedBox(height: LinguaTokens.space16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(LinguaTokens.space8),
                  decoration: BoxDecoration(
                    color: LinguaTokens.primary100,
                    borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: LinguaTokens.primary700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: LinguaTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI-Assisted Explanation',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: LinguaTokens.primary700,
                        ),
                      ),
                      Text(
                        conceptTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: LinguaTokens.ink900,
                          fontFamily: LinguaTokens.fontPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: LinguaTokens.space16),
            LinguaCard(
              backgroundColor: LinguaTokens.paper50,
              padding: const EdgeInsets.all(LinguaTokens.space16),
              child: Text(
                explanation.explanation,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: LinguaTokens.ink900,
                  fontFamily: LinguaTokens.fontPrimary,
                ),
              ),
            ),
            if (explanation.clarityTip != null &&
                explanation.clarityTip!.isNotEmpty) ...[
              const SizedBox(height: LinguaTokens.space12),
              Container(
                padding: const EdgeInsets.all(LinguaTokens.space12),
                decoration: BoxDecoration(
                  color: LinguaTokens.accent50,
                  border: Border.all(
                    color: LinguaTokens.accent500.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: LinguaTokens.accent600,
                      size: 18,
                    ),
                    const SizedBox(width: LinguaTokens.space8),
                    Expanded(
                      child: Text(
                        explanation.clarityTip!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: LinguaTokens.ink700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: LinguaTokens.space16),
            const Text(
              'This explanation is generated for educational clarity based on your current activity. It is not clinical or diagnostic advice.',
              style: TextStyle(
                fontSize: 11,
                color: LinguaTokens.inkMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: LinguaTokens.space20),
            SizedBox(
              width: double.infinity,
              child: LinguaButton(
                label: 'Got it',
                onPressed: onClose,
                variant: LinguaButtonVariant.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
