import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';

/// Non-coercive, clear explanation dialog before OS microphone prompt.
/// Designed for Child, Teen, and Adult readability without medical or clinical terms.
class MicrophonePermissionDialog extends StatelessWidget {
  final VoidCallback onGrant;
  final VoidCallback onCancel;
  final VoidCallback onTypeInstead;

  const MicrophonePermissionDialog({
    super.key,
    required this.onGrant,
    required this.onCancel,
    required this.onTypeInstead,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusCard)),
      title: Row(
        children: const [
          Icon(Icons.mic, color: LinguaTokens.primary600, size: 26),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Use Your Voice?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'To answer this activity with your voice, Lingua AI needs access to your microphone.',
            style: TextStyle(fontSize: 14, height: 1.4, color: LinguaTokens.ink700),
          ),
          const SizedBox(height: LinguaTokens.space12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LinguaTokens.paper100,
              borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
              border: Border.all(color: LinguaTokens.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '• We only listen when you tap Speak',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: LinguaTokens.ink700),
                ),
                SizedBox(height: 4),
                Text(
                  '• No permanent audio recordings are kept',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: LinguaTokens.ink700),
                ),
                SizedBox(height: 4),
                Text(
                  '• You can always choose to type instead',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: LinguaTokens.ink700),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onTypeInstead,
          child: const Text('Type Instead', style: TextStyle(color: LinguaTokens.inkMuted)),
        ),
        TextButton(
          onPressed: onCancel,
          child: const Text('Not Now', style: TextStyle(color: LinguaTokens.ink700)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: LinguaTokens.primary600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusPill)),
          ),
          onPressed: onGrant,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
