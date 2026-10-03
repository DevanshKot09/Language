import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../domain/models/exercise_attempt_model.dart';

class ExerciseFeedbackBanner extends StatelessWidget {
  final ExerciseAttemptResponseModel evaluation;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  const ExerciseFeedbackBanner({
    super.key,
    required this.evaluation,
    required this.onContinue,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = evaluation.isCorrect;
    final isPartial = evaluation.isPartiallyCorrect;

    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final IconData iconData;
    final String statusHeader;

    if (isCorrect) {
      bgColor = LinguaTokens.successLight;
      borderColor = LinguaTokens.success600;
      iconColor = LinguaTokens.success600;
      iconData = Icons.check_circle;
      statusHeader = '✓ Correct';
    } else if (isPartial) {
      bgColor = LinguaTokens.accent100;
      borderColor = LinguaTokens.accent500;
      iconColor = LinguaTokens.accent600;
      iconData = Icons.info_outline;
      statusHeader = 'Partially Correct';
    } else {
      bgColor = LinguaTokens.paper100;
      borderColor = LinguaTokens.borderSubtle;
      iconColor = LinguaTokens.primary600;
      iconData = Icons.replay;
      statusHeader = 'Take Another Look';
    }

    return Container(
      margin: const EdgeInsets.only(top: LinguaTokens.space20),
      padding: const EdgeInsets.all(LinguaTokens.space16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(iconData, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Text(
                statusHeader,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? LinguaTokens.success600 : LinguaTokens.ink900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            evaluation.feedbackMessage,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: LinguaTokens.ink900,
            ),
          ),

          if (evaluation.explanation != null && evaluation.explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                evaluation.explanation!,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: LinguaTokens.ink700,
                  height: 1.3,
                ),
              ),
            ),
          ],

          const SizedBox(height: LinguaTokens.space16),

          if (isCorrect)
            LinguaButton(
              label: evaluation.lessonCompleted ? 'Finish Lesson' : 'Continue',
              icon: Icons.arrow_forward,
              onPressed: onContinue,
            )
          else
            Row(
              children: [
                Expanded(
                  child: LinguaButton(
                    label: 'Retry Activity',
                    icon: Icons.refresh,
                    variant: LinguaButtonVariant.secondary,
                    onPressed: onRetry,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LinguaButton(
                    label: 'Next Activity',
                    icon: Icons.skip_next,
                    variant: LinguaButtonVariant.secondary,
                    onPressed: onContinue,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
