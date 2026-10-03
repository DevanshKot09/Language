import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_card.dart';

/// Reusable status notice when AI services are disabled, offline, or rate-limited.
/// Assures the learner that all standard, curated curriculum activities remain fully functional.
class AiStatusNotice extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AiStatusNotice({
    super.key,
    this.message =
        "AI support isn't available right now. Your regular learning activities are still available.",
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return LinguaCard(
      backgroundColor: LinguaTokens.paper100,
      borderColor: LinguaTokens.borderSubtle,
      padding: const EdgeInsets.all(LinguaTokens.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: LinguaTokens.inkMuted,
            size: 20,
          ),
          const SizedBox(width: LinguaTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assistive Feature Notice',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: LinguaTokens.ink700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: LinguaTokens.ink700,
                    height: 1.4,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Try Again'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
