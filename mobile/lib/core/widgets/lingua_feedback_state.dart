import 'package:flutter/material.dart';
import '../../shared/design_tokens/tokens.dart';
import '../errors/app_failure.dart';
import 'lingua_button.dart';

/// Reusable feedback state widget for Loading, Error, Empty, and Success screens.
class LinguaFeedbackState extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LinguaFeedbackState({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  factory LinguaFeedbackState.fromFailure({
    required Failure failure,
    VoidCallback? onRetry,
  }) {
    return LinguaFeedbackState(
      icon: Icons.error_outline,
      iconColor: LinguaTokens.danger600,
      title: 'Action Needed',
      message: failure.userMessage,
      actionLabel: onRetry != null ? 'Try Again' : null,
      onAction: onRetry,
    );
  }

  factory LinguaFeedbackState.empty({
    String title = 'Nothing to show yet',
    String message = 'Activities and progress will appear here as you practice.',
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return LinguaFeedbackState(
      icon: Icons.inbox_outlined,
      iconColor: LinguaTokens.inkMuted,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LinguaTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (iconColor ?? LinguaTokens.primary600).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: iconColor ?? LinguaTokens.primary600),
            ),
            const SizedBox(height: LinguaTokens.space16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LinguaTokens.ink900,
              ),
            ),
            const SizedBox(height: LinguaTokens.space8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: LinguaTokens.ink700,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: LinguaTokens.space20),
              LinguaButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: LinguaButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
