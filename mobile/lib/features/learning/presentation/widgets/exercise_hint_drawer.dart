import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_button.dart';

class ExerciseHintModal extends StatelessWidget {
  final List<String> hints;
  final VoidCallback onDismiss;

  const ExerciseHintModal({
    super.key,
    required this.hints,
    required this.onDismiss,
  });

  static Future<void> show(BuildContext context, List<String> hints, {VoidCallback? onHintUsed}) {
    if (onHintUsed != null) {
      onHintUsed();
    }
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ExerciseHintModal(
        hints: hints,
        onDismiss: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(LinguaTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: LinguaTokens.accent100,
                    borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                  ),
                  child: const Icon(Icons.lightbulb, color: LinguaTokens.accent600, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Helpful Learning Clue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: LinguaTokens.ink900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                  tooltip: 'Close hint',
                ),
              ],
            ),
            const SizedBox(height: LinguaTokens.space16),

            if (hints.isEmpty)
              const Text(
                'Read the prompt carefully and look for key words that connect the ideas.',
                style: TextStyle(fontSize: 15, height: 1.4, color: LinguaTokens.ink700),
              )
            else
              ...hints.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            h,
                            style: const TextStyle(fontSize: 15, height: 1.4, color: LinguaTokens.ink700),
                          ),
                        ),
                      ],
                    ),
                  )),

            const SizedBox(height: LinguaTokens.space20),

            LinguaButton(
              label: 'Got it, let me try!',
              onPressed: onDismiss,
              variant: LinguaButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
