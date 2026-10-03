import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../domain/models/exercise_model.dart';
import '../../../../app/providers/audio_provider.dart';

class ListeningExerciseView extends ConsumerStatefulWidget {
  final ExerciseModel exercise;
  final String? selectedOption;
  final ValueChanged<String> onSelectOption;
  final bool isLocked;

  const ListeningExerciseView({
    super.key,
    required this.exercise,
    required this.selectedOption,
    required this.onSelectOption,
    this.isLocked = false,
  });

  @override
  ConsumerState<ListeningExerciseView> createState() => _ListeningExerciseViewState();
}

class _ListeningExerciseViewState extends ConsumerState<ListeningExerciseView> {
  bool _showTranscript = false;

  void _togglePlayback(String text) {
    final ttsState = ref.read(ttsControllerProvider);
    final ttsNotifier = ref.read(ttsControllerProvider.notifier);

    if (ttsState.isPlaying) {
      ttsNotifier.pause();
    } else if (ttsState.isPaused) {
      ttsNotifier.resume();
    } else {
      ttsNotifier.speak(text);
    }
  }

  void _replayAudio(String text) {
    final ttsNotifier = ref.read(ttsControllerProvider.notifier);
    ttsNotifier.stop().then((_) => ttsNotifier.speak(text));
  }

  @override
  Widget build(BuildContext context) {
    final transcript = widget.exercise.transcript ?? widget.exercise.prompt;
    final questionText = widget.exercise.question ?? widget.exercise.prompt;
    final options = widget.exercise.options;
    final ttsState = ref.watch(ttsControllerProvider);
    final isPlaying = ttsState.isPlaying;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instruction Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: LinguaTokens.primary50,
            borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
            border: Border.all(color: LinguaTokens.primary100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.headphones, size: 18, color: LinguaTokens.primary600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.exercise.instruction,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: LinguaTokens.primary700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LinguaTokens.space16),

        // Audio Player Card
        Container(
          padding: const EdgeInsets.all(LinguaTokens.space16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
            border: Border.all(color: LinguaTokens.borderSubtle),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isPlaying ? LinguaTokens.primary600 : LinguaTokens.primary100,
                    child: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: isPlaying ? Colors.white : LinguaTokens.primary700,
                        size: 24,
                      ),
                      tooltip: isPlaying ? 'Pause audio' : 'Play spoken prompt',
                      onPressed: () => _togglePlayback(transcript),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPlaying ? 'Playing spoken direction...' : 'Spoken Audio Direction',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: LinguaTokens.ink900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Listen carefully or view transcript below',
                          style: TextStyle(fontSize: 12, color: LinguaTokens.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.replay, color: LinguaTokens.ink700),
                    tooltip: 'Replay audio direction',
                    onPressed: () => _replayAudio(transcript),
                  ),
                ],
              ),
              const SizedBox(height: LinguaTokens.space12),

              // Transcript Access Toggle (Essential Accessibility Support)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showTranscript = !_showTranscript;
                    });
                  },
                  icon: Icon(
                    _showTranscript ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                    color: LinguaTokens.primary600,
                  ),
                  label: Text(
                    _showTranscript ? 'Hide Spoken Transcript' : 'Show Spoken Transcript',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: LinguaTokens.primary600,
                    ),
                  ),
                ),
              ),

              if (_showTranscript) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(LinguaTokens.space12),
                  decoration: BoxDecoration(
                    color: LinguaTokens.paper100,
                    borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                    border: Border.all(color: LinguaTokens.borderSubtle),
                  ),
                  child: Text(
                    '"$transcript"',
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                      color: LinguaTokens.ink700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: LinguaTokens.space20),

        // Comprehension Question Prompt
        Text(
          questionText,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: LinguaTokens.ink900,
            height: 1.3,
          ),
        ),
        const SizedBox(height: LinguaTokens.space16),

        // Selectable Options
        ...options.map((option) {
          final isSelected = widget.selectedOption == option;
          return Container(
            margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
            decoration: BoxDecoration(
              color: isSelected ? LinguaTokens.primary50 : Colors.white,
              borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
              border: Border.all(
                color: isSelected ? LinguaTokens.primary600 : LinguaTokens.borderSubtle,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
              child: InkWell(
                borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                onTap: widget.isLocked ? null : () => widget.onSelectOption(option),
                child: Padding(
                  padding: const EdgeInsets.all(LinguaTokens.space16),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? LinguaTokens.primary600 : LinguaTokens.inkMuted,
                            width: 2,
                          ),
                          color: isSelected ? LinguaTokens.primary600 : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? LinguaTokens.primary900 : LinguaTokens.ink900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
