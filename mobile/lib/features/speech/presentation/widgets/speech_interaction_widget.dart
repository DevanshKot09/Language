import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../../../app/providers/audio_provider.dart';
import 'microphone_permission_dialog.dart';

/// Reusable speech interaction component supporting:
/// - Idle & Permission explanation
/// - Ready state ("Speak your answer")
/// - Listening state with visual waveform indicator & stop button
/// - Processing state ("Converting your speech to text...")
/// - Transcript review with Edit, Try Again, and Use This Answer
/// - Compassionate non-shaming error states
/// - Always available "Type instead" accessibility alternative
class SpeechInteractionWidget extends ConsumerStatefulWidget {
  final String prompt;
  final ValueChanged<String> onAnswerConfirmed;
  final VoidCallback onTypeInstead;

  const SpeechInteractionWidget({
    super.key,
    required this.prompt,
    required this.onAnswerConfirmed,
    required this.onTypeInstead,
  });

  @override
  ConsumerState<SpeechInteractionWidget> createState() => _SpeechInteractionWidgetState();
}

class _SpeechInteractionWidgetState extends ConsumerState<SpeechInteractionWidget> {
  final TextEditingController _editController = TextEditingController();
  bool _isEditingTranscript = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sttControllerProvider.notifier).prepareVoiceInteraction();
    });
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _showPermissionModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MicrophonePermissionDialog(
        onGrant: () async {
          Navigator.of(ctx).pop();
          await ref.read(sttControllerProvider.notifier).requestMicrophoneAccess();
        },
        onCancel: () {
          Navigator.of(ctx).pop();
          ref.read(sttControllerProvider.notifier).reset();
        },
        onTypeInstead: () {
          Navigator.of(ctx).pop();
          widget.onTypeInstead();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sttState = ref.watch(sttControllerProvider);
    final sttNotifier = ref.read(sttControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(LinguaTokens.space20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        border: Border.all(color: LinguaTokens.borderSubtle),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Activity Prompt
          Text(
            widget.prompt,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: LinguaTokens.ink900,
            ),
          ),
          const SizedBox(height: LinguaTokens.space16),

          // State-specific presentation
          if (sttState.step == SpeechInteractionStep.permissionRequired) ...[
            _buildPermissionPrompt(),
          ] else if (sttState.step == SpeechInteractionStep.ready || sttState.step == SpeechInteractionStep.idle) ...[
            _buildReadyState(sttNotifier),
          ] else if (sttState.step == SpeechInteractionStep.listening) ...[
            _buildListeningState(sttState, sttNotifier),
          ] else if (sttState.step == SpeechInteractionStep.processing) ...[
            _buildProcessingState(),
          ] else if (sttState.step == SpeechInteractionStep.review) ...[
            _buildReviewState(sttState, sttNotifier),
          ] else if (sttState.step == SpeechInteractionStep.error) ...[
            _buildErrorState(sttState, sttNotifier),
          ],

          const SizedBox(height: LinguaTokens.space12),

          // Always-accessible fallback button: Type instead
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.keyboard_outlined, size: 18, color: LinguaTokens.ink700),
              label: const Text(
                'Type your answer instead',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LinguaTokens.ink700,
                ),
              ),
              onPressed: widget.onTypeInstead,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionPrompt() {
    return Container(
      padding: const EdgeInsets.all(LinguaTokens.space16),
      decoration: BoxDecoration(
        color: LinguaTokens.primary50,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
      ),
      child: Column(
        children: [
          const Icon(Icons.mic_none, size: 36, color: LinguaTokens.primary600),
          const SizedBox(height: 8),
          const Text(
            'Ready to use your voice?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: LinguaTokens.primary900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap below to allow microphone access for speaking activities.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: LinguaTokens.ink700),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: LinguaTokens.primary600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusPill)),
            ),
            icon: const Icon(Icons.lock_open, size: 16),
            label: const Text('Enable Microphone'),
            onPressed: _showPermissionModal,
          ),
        ],
      ),
    );
  }

  Widget _buildReadyState(SttController sttNotifier) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: LinguaTokens.primary100,
                child: IconButton(
                  icon: const Icon(Icons.mic, size: 34, color: LinguaTokens.primary600),
                  tooltip: 'Tap to speak',
                  onPressed: () => sttNotifier.startListening(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tap to speak your answer',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Speak clearly at your own pace',
                style: TextStyle(fontSize: 12, color: LinguaTokens.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListeningState(SpeechInteractionUiState state, SttController sttNotifier) {
    return Container(
      padding: const EdgeInsets.all(LinguaTokens.space20),
      decoration: BoxDecoration(
        color: LinguaTokens.primary50,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        border: Border.all(color: LinguaTokens.primary600, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Listening...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LinguaTokens.primary900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Live audio sound level visualizer
          SizedBox(
            height: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(12, (index) {
                final barHeight = ((state.soundLevel * 10) + (index % 3) * 4).clamp(4.0, 24.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 4,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: LinguaTokens.primary600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          if (state.recognizedTranscript.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
              ),
              child: Text(
                '"${state.recognizedTranscript}"',
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: LinguaTokens.ink900),
              ),
            ),
            const SizedBox(height: 12),
          ],

          const Text(
            'Tap Stop when you are finished speaking.',
            style: TextStyle(fontSize: 12, color: LinguaTokens.inkMuted),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusPill)),
                ),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Cancel'),
                onPressed: () => sttNotifier.cancelListening(),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: LinguaTokens.primary600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusPill)),
                ),
                icon: const Icon(Icons.stop, size: 16),
                label: const Text('Done Speaking'),
                onPressed: () => sttNotifier.stopListening(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    return Container(
      padding: const EdgeInsets.all(LinguaTokens.space20),
      child: Column(
        children: const [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Converting your speech to text...',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: LinguaTokens.ink700),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewState(SpeechInteractionUiState state, SttController sttNotifier) {
    final transcript = _isEditingTranscript ? _editController.text : state.editedTranscript;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'We heard:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: LinguaTokens.ink700),
            ),
            TextButton.icon(
              icon: Icon(_isEditingTranscript ? Icons.check : Icons.edit_outlined, size: 16),
              label: Text(_isEditingTranscript ? 'Done Editing' : 'Edit Text'),
              onPressed: () {
                setState(() {
                  if (_isEditingTranscript) {
                    sttNotifier.updateEditedTranscript(_editController.text);
                    _isEditingTranscript = false;
                  } else {
                    _editController.text = state.editedTranscript;
                    _isEditingTranscript = true;
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 4),

        if (_isEditingTranscript) ...[
          TextField(
            controller: _editController,
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
              hintText: 'Edit your spoken response',
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(LinguaTokens.space16),
            decoration: BoxDecoration(
              color: LinguaTokens.paper100,
              borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
              border: Border.all(color: LinguaTokens.borderSubtle),
            ),
            child: Text(
              transcript.isEmpty ? '(No words detected)' : '"$transcript"',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: LinguaTokens.ink900,
                height: 1.4,
              ),
            ),
          ),
        ],
        const SizedBox(height: LinguaTokens.space16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try Again'),
                onPressed: () {
                  setState(() {
                    _isEditingTranscript = false;
                  });
                  sttNotifier.startListening();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: LinguaButton(
                label: 'Use This Answer',
                onPressed: transcript.trim().isNotEmpty
                    ? () => widget.onAnswerConfirmed(transcript.trim())
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState(SpeechInteractionUiState state, SttController sttNotifier) {
    return Container(
      padding: const EdgeInsets.all(LinguaTokens.space16),
      decoration: BoxDecoration(
        color: LinguaTokens.warningLight,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        border: Border.all(color: LinguaTokens.warning600.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: LinguaTokens.warning600, size: 28),
          const SizedBox(height: 8),
          Text(
            state.errorMessage ?? "We couldn't turn that recording into text. Your recording was not used to judge your ability.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.4, color: LinguaTokens.ink900),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: LinguaTokens.primary600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusPill)),
            ),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try Again'),
            onPressed: () => sttNotifier.startListening(),
          ),
        ],
      ),
    );
  }
}
