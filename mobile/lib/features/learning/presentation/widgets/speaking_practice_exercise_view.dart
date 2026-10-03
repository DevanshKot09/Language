import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../domain/models/exercise_model.dart';
import '../../../speech/presentation/widgets/speech_interaction_widget.dart';

/// Interactive Speaking Practice Activity View for DLD & Oral Language support.
/// Learner receives a scaffolded oral prompt, taps Speak to record a short response,
/// reviews/edits the transcript, and submits their selected response.
/// Includes an immediate "Type instead" mode to ensure full accessibility.
class SpeakingPracticeExerciseView extends StatefulWidget {
  final ExerciseModel exercise;
  final String? currentAnswer;
  final ValueChanged<String> onAnswerChanged;
  final bool isLocked;

  const SpeakingPracticeExerciseView({
    super.key,
    required this.exercise,
    required this.currentAnswer,
    required this.onAnswerChanged,
    this.isLocked = false,
  });

  @override
  State<SpeakingPracticeExerciseView> createState() => _SpeakingPracticeExerciseViewState();
}

class _SpeakingPracticeExerciseViewState extends State<SpeakingPracticeExerciseView> {
  bool _useTypeMode = false;
  late final TextEditingController _typeController;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: widget.currentAnswer ?? '');
  }

  @override
  void didUpdateWidget(covariant SpeakingPracticeExerciseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentAnswer != oldWidget.currentAnswer && widget.currentAnswer != null) {
      if (_typeController.text != widget.currentAnswer) {
        _typeController.text = widget.currentAnswer!;
      }
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = widget.exercise.prompt;
    final instruction = widget.exercise.instruction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instruction Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: LinguaTokens.dldTrackBg,
            borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
            border: Border.all(color: LinguaTokens.dldTrack.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.record_voice_over_outlined, size: 18, color: LinguaTokens.dldTrack),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  instruction,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: LinguaTokens.dldTrack,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LinguaTokens.space16),

        if (_useTypeMode) ...[
          // Accessible Type Mode Card
          Container(
            padding: const EdgeInsets.all(LinguaTokens.space20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
              border: Border.all(color: LinguaTokens.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prompt,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
                ),
                const SizedBox(height: LinguaTokens.space16),
                TextField(
                  controller: _typeController,
                  enabled: !widget.isLocked,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Type your answer here...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
                  ),
                  onChanged: (val) => widget.onAnswerChanged(val.trim()),
                ),
                const SizedBox(height: LinguaTokens.space12),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.mic, size: 18, color: LinguaTokens.primary600),
                    label: const Text('Switch back to voice input'),
                    onPressed: () {
                      setState(() {
                        _useTypeMode = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Voice Interaction Component
          SpeechInteractionWidget(
            prompt: prompt,
            onAnswerConfirmed: (confirmedTranscript) {
              widget.onAnswerChanged(confirmedTranscript);
            },
            onTypeInstead: () {
              setState(() {
                _useTypeMode = true;
              });
            },
          ),
        ],

        if (widget.currentAnswer != null && widget.currentAnswer!.isNotEmpty) ...[
          const SizedBox(height: LinguaTokens.space16),
          Container(
            padding: const EdgeInsets.all(LinguaTokens.space16),
            decoration: BoxDecoration(
              color: LinguaTokens.paper100,
              borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
              border: Border.all(color: LinguaTokens.primary600.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: LinguaTokens.primary600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected response: "${widget.currentAnswer}"',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: LinguaTokens.primary900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
