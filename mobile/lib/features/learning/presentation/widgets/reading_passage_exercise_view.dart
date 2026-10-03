import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_selection_card.dart';
import '../../domain/models/exercise_model.dart';
import '../../../../app/providers/audio_provider.dart';

class ReadingPassageExerciseView extends ConsumerStatefulWidget {
  final ExerciseModel exercise;
  final String? selectedOption;
  final ValueChanged<String> onSelectOption;
  final bool isLocked;

  const ReadingPassageExerciseView({
    super.key,
    required this.exercise,
    required this.selectedOption,
    required this.onSelectOption,
    this.isLocked = false,
  });

  @override
  ConsumerState<ReadingPassageExerciseView> createState() => _ReadingPassageExerciseViewState();
}

class _ReadingPassageExerciseViewState extends ConsumerState<ReadingPassageExerciseView> {
  double _fontSize = 16.0;
  bool _lineFocusMode = false;
  bool _dyslexiaSpacing = false;

  void _toggleTts(String passage) {
    final ttsState = ref.read(ttsControllerProvider);
    final ttsNotifier = ref.read(ttsControllerProvider.notifier);

    if (ttsState.isPlaying) {
      ttsNotifier.pause();
    } else if (ttsState.isPaused) {
      ttsNotifier.resume();
    } else {
      ttsNotifier.speak(passage);
    }
  }

  void _cycleFontSize() {
    setState(() {
      if (_fontSize == 16.0) {
        _fontSize = 19.0;
      } else if (_fontSize == 19.0) {
        _fontSize = 22.0;
      } else {
        _fontSize = 16.0;
      }
    });
  }

  void _toggleLineFocus() {
    setState(() {
      _lineFocusMode = !_lineFocusMode;
    });
  }

  void _toggleDyslexiaSpacing() {
    setState(() {
      _dyslexiaSpacing = !_dyslexiaSpacing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final passage = widget.exercise.readingPassage ?? '';
    final options = widget.exercise.options;
    final questionPrompt = widget.exercise.question ?? widget.exercise.prompt;
    final ttsState = ref.watch(ttsControllerProvider);
    final isPlayingTts = ttsState.isPlaying;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instruction badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: LinguaTokens.dyslexiaTrackBg,
            borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
            border: Border.all(color: LinguaTokens.dyslexiaTrack.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book_outlined, size: 18, color: LinguaTokens.dyslexiaTrack),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.exercise.instruction,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: LinguaTokens.dyslexiaTrack,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LinguaTokens.space12),

        // Accessible Reading Aids Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: LinguaTokens.paper100,
            borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
            border: Border.all(color: LinguaTokens.borderSubtle),
          ),
          child: Row(
            children: [
              // TTS Button
              IconButton(
                icon: Icon(
                  isPlayingTts ? Icons.pause_circle_filled : Icons.volume_up_outlined,
                  color: isPlayingTts ? LinguaTokens.dyslexiaTrack : LinguaTokens.ink700,
                  size: 22,
                ),
                tooltip: isPlayingTts ? 'Pause read-aloud' : 'Read passage aloud (TTS)',
                onPressed: () => _toggleTts(passage),
              ),
              const SizedBox(width: 4),

              // Font Size Cycle
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.format_size, size: 18, color: LinguaTokens.ink700),
                label: Text(
                  _fontSize == 16.0 ? 'A' : (_fontSize == 19.0 ? 'A+' : 'A++'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: LinguaTokens.ink700),
                ),
                onPressed: _cycleFontSize,
              ),
              const Spacer(),

              // Line Focus Mode Toggle
              IconButton(
                icon: Icon(
                  _lineFocusMode ? Icons.vertical_align_center : Icons.line_style,
                  color: _lineFocusMode ? LinguaTokens.dyslexiaTrack : LinguaTokens.ink700,
                  size: 20,
                ),
                tooltip: _lineFocusMode ? 'Disable line focus guide' : 'Enable line focus guide',
                onPressed: _toggleLineFocus,
              ),

              // Dyslexia Spacing Toggle
              IconButton(
                icon: Icon(
                  _dyslexiaSpacing ? Icons.space_bar : Icons.font_download_outlined,
                  color: _dyslexiaSpacing ? LinguaTokens.dyslexiaTrack : LinguaTokens.ink700,
                  size: 20,
                ),
                tooltip: _dyslexiaSpacing ? 'Default letter spacing' : 'High-legibility letter spacing',
                onPressed: _toggleDyslexiaSpacing,
              ),
            ],
          ),
        ),
        const SizedBox(height: LinguaTokens.space12),

        // Accessible Reading Passage Card
        Container(
          padding: const EdgeInsets.all(LinguaTokens.space20),
          decoration: BoxDecoration(
            color: _lineFocusMode ? const Color(0xFFFDFCF7) : Colors.white,
            borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
            border: Border.all(
              color: _lineFocusMode ? LinguaTokens.dyslexiaTrack.withValues(alpha: 0.5) : LinguaTokens.borderSubtle,
              width: _lineFocusMode ? 2.0 : 1.5,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_stories_outlined, size: 18, color: LinguaTokens.dyslexiaTrack),
                      SizedBox(width: 6),
                      Text(
                        'Reading Passage',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: LinguaTokens.dyslexiaTrack,
                        ),
                      ),
                    ],
                  ),
                  if (isPlayingTts)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: LinguaTokens.dyslexiaTrackBg,
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                      ),
                      child: const Text(
                        'Reading Aloud...',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: LinguaTokens.dyslexiaTrack),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: LinguaTokens.space12),
              Text(
                passage,
                style: TextStyle(
                  fontSize: _fontSize,
                  height: _lineFocusMode ? 1.85 : 1.6,
                  letterSpacing: _dyslexiaSpacing ? 0.8 : 0.2,
                  wordSpacing: _dyslexiaSpacing ? 2.0 : 0.0,
                  color: LinguaTokens.ink900,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LinguaTokens.space20),

        // Comprehension Question Prompt
        Text(
          questionPrompt,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: LinguaTokens.ink900,
          ),
        ),
        const SizedBox(height: LinguaTokens.space16),

        // Options List
        ...options.map((opt) {
          final isSelected = widget.selectedOption == opt;
          return Padding(
            padding: const EdgeInsets.only(bottom: LinguaTokens.space12),
            child: LinguaSelectionCard(
              title: opt,
              isSelected: isSelected,
              onSelected: widget.isLocked ? () {} : () => widget.onSelectOption(opt),
            ),
          );
        }),
      ],
    );
  }
}
