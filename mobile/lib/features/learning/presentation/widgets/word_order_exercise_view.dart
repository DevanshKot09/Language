import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../domain/models/exercise_model.dart';

class WordOrderExerciseView extends StatefulWidget {
  final ExerciseModel exercise;
  final List<String> currentArrangement;
  final ValueChanged<List<String>> onArrangementChanged;
  final bool isLocked;

  const WordOrderExerciseView({
    super.key,
    required this.exercise,
    required this.currentArrangement,
    required this.onArrangementChanged,
    this.isLocked = false,
  });

  @override
  State<WordOrderExerciseView> createState() => _WordOrderExerciseViewState();
}

class _WordOrderExerciseViewState extends State<WordOrderExerciseView> {
  late List<String> _bankWords;

  @override
  void initState() {
    super.initState();
    _resetBank();
  }

  @override
  void didUpdateWidget(covariant WordOrderExerciseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _resetBank();
    }
  }

  void _resetBank() {
    final allTokens = List<String>.from(widget.exercise.tokens);
    for (final word in widget.currentArrangement) {
      allTokens.remove(word);
    }
    _bankWords = allTokens;
  }

  void _addWord(String word) {
    if (widget.isLocked) return;
    setState(() {
      _bankWords.remove(word);
      final updated = List<String>.from(widget.currentArrangement)..add(word);
      widget.onArrangementChanged(updated);
    });
  }

  void _removeWordAt(int index) {
    if (widget.isLocked) return;
    setState(() {
      final removed = widget.currentArrangement[index];
      _bankWords.add(removed);
      final updated = List<String>.from(widget.currentArrangement)..removeAt(index);
      widget.onArrangementChanged(updated);
    });
  }

  void _clearAll() {
    if (widget.isLocked) return;
    setState(() {
      _bankWords = List<String>.from(widget.exercise.tokens);
      widget.onArrangementChanged([]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instruction badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: LinguaTokens.accent100.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sort, size: 18, color: LinguaTokens.accent600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.exercise.instruction,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: LinguaTokens.ink700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LinguaTokens.space16),

        // Prompt
        Text(
          widget.exercise.prompt,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: LinguaTokens.ink700,
          ),
        ),
        const SizedBox(height: LinguaTokens.space16),

        // Assembled Sentence Area
        Container(
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.all(LinguaTokens.space16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
            border: Border.all(
              color: widget.currentArrangement.isNotEmpty
                  ? LinguaTokens.primary500
                  : LinguaTokens.borderSubtle,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: widget.currentArrangement.isEmpty
              ? const Center(
                  child: Text(
                    'Tap words below to arrange your sentence',
                    style: TextStyle(
                      fontSize: 14,
                      color: LinguaTokens.inkMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(widget.currentArrangement.length, (idx) {
                    final token = widget.currentArrangement[idx];
                    return ActionChip(
                      label: Text(
                        token,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: LinguaTokens.primary700,
                        ),
                      ),
                      avatar: const Icon(Icons.close, size: 16, color: LinguaTokens.primary600),
                      backgroundColor: LinguaTokens.primary50,
                      side: const BorderSide(color: LinguaTokens.primary100),
                      onPressed: () => _removeWordAt(idx),
                    );
                  }),
                ),
        ),

        const SizedBox(height: LinguaTokens.space12),

        // Clear action row
        if (widget.currentArrangement.isNotEmpty && !widget.isLocked)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.refresh, size: 16, color: LinguaTokens.ink700),
              label: const Text(
                'Reset words',
                style: TextStyle(fontSize: 12, color: LinguaTokens.ink700),
              ),
            ),
          ),

        const SizedBox(height: LinguaTokens.space16),

        const Text(
          'Word Bank:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: LinguaTokens.ink700),
        ),
        const SizedBox(height: 8),

        // Available Bank Words
        Container(
          padding: const EdgeInsets.all(LinguaTokens.space12),
          decoration: BoxDecoration(
            color: LinguaTokens.paper100,
            borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
            border: Border.all(color: LinguaTokens.borderSubtle),
          ),
          child: _bankWords.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      'All words placed!',
                      style: TextStyle(fontSize: 13, color: LinguaTokens.success600, fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: _bankWords.map((word) {
                    return ActionChip(
                      label: Text(
                        word,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: LinguaTokens.ink900,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: LinguaTokens.borderSubtle),
                      elevation: 1,
                      onPressed: widget.isLocked ? null : () => _addWord(word),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
